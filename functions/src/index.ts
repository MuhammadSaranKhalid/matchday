import { onTaskDispatched } from "firebase-functions/v2/tasks";
import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFunctions } from "firebase-admin/functions";
import { initializeApp } from "firebase-admin/app";
import { createClient } from "@supabase/supabase-js";
import { createFeedReadyAsset, createOptimizationVariants } from "./sharp_worker";
import type { ProcessMediaTaskPayload, PostMediaRow, VariantMap } from "./types";

initializeApp();

const SUPABASE_URL = process.env.SUPABASE_URL || "";
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || "";

function getSupabase() {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in media worker environment");
  }
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/**
 * HIGH PRIORITY Task Queue: Generates 1080 WebP + BlurHash and activates the post
 * as soon as all attached media items are feed-ready.
 */
export const processMediaFeedReady = onTaskDispatched<ProcessMediaTaskPayload>(
  {
    retryConfig: {
      maxAttempts: 5,
      minBackoffSeconds: 5,
      maxBackoffSeconds: 60,
    },
    rateLimits: {
      maxConcurrentDispatches: 8, // Backpressure: controlled concurrency
    },
    memory: "1GiB",
    timeoutSeconds: 120,
  },
  async (req) => {
    const { mediaId } = req.data;
    if (!mediaId) {
      console.error("[processMediaFeedReady] Missing mediaId");
      return;
    }

    const supabase = getSupabase();

    // 1. Fetch canonical media row from PostgreSQL
    const { data: mediaRow, error: fetchError } = await supabase
      .from("post_media")
      .select("*")
      .eq("media_id", mediaId)
      .single();

    if (fetchError || !mediaRow) {
      console.error(`[processMediaFeedReady] Failed to fetch media row for ${mediaId}`, fetchError);
      return;
    }

    const row = mediaRow as PostMediaRow;

    // Idempotency: if already feed_ready or beyond, skip
    if (["feed_ready", "optimizing", "optimized"].includes(row.status)) {
      console.log(`[processMediaFeedReady] Media ${mediaId} already processed (status: ${row.status}). Idempotent no-op.`);
      return;
    }

    // 2. Mark processing_feed in Postgres
    await supabase
      .from("post_media")
      .update({
        status: "processing_feed",
        processing_started_at: new Date().toISOString(),
        processing_attempts: (row.processing_attempts || 0) + 1,
      })
      .eq("media_id", mediaId);

    // 3. Download private staging JPEG from Supabase Storage
    const { data: fileData, error: downloadError } = await supabase.storage
      .from("post-media-staging")
      .download(row.staging_path);

    if (downloadError || !fileData) {
      const errMsg = `Failed to download staging file ${row.staging_path}: ${downloadError?.message}`;
      console.error(`[processMediaFeedReady] ${errMsg}`);
      await supabase
        .from("post_media")
        .update({ status: "processing_failed", last_processing_error: errMsg })
        .eq("media_id", mediaId);
      throw new Error(errMsg);
    }

    const sourceBuffer = Buffer.from(await fileData.arrayBuffer());

    // 4. Sharp feed-ready processing (1080 WebP + BlurHash)
    const { buffer: feedBuffer, width, height, blurhash } = await createFeedReadyAsset(sourceBuffer);

    // 5. Upload canonical 1080 variant to public post-media bucket
    const feedVariantPath = `${row.final_prefix}1080.webp`;
    const { error: uploadError } = await supabase.storage
      .from("post-media")
      .upload(feedVariantPath, feedBuffer, {
        contentType: "image/webp",
        cacheControl: "public, max-age=31536000, immutable",
        upsert: true,
      });

    if (uploadError) {
      const errMsg = `Failed to upload 1080 variant to ${feedVariantPath}: ${uploadError.message}`;
      console.error(`[processMediaFeedReady] ${errMsg}`);
      throw new Error(errMsg);
    }

    const variants: VariantMap = {
      "1080": {
        path: feedVariantPath,
        width,
        height,
        sizeBytes: feedBuffer.length,
        mimeType: "image/webp",
      },
    };

    // 6. Atomically transition media row and evaluate post activation
    const { error: rpcError } = await supabase.rpc("mark_media_feed_ready", {
      p_media_id: mediaId,
      p_source_width: width,
      p_source_height: height,
      p_display_width: width,
      p_display_height: height,
      p_blurhash: blurhash,
      p_variants: variants,
    });

    if (rpcError) {
      console.error(`[processMediaFeedReady] mark_media_feed_ready failed for ${mediaId}`, rpcError);
      throw new Error(rpcError.message);
    }

    console.log(`[processMediaFeedReady] Media ${mediaId} is FEED READY!`);

    // 7. Enqueue lower-priority optimization task for background variants
    const queue = getFunctions().taskQueue("processMediaOptimize");
    await queue.enqueue({ mediaId });
  }
);

/**
 * LOW PRIORITY Task Queue: Generates 360, 540, 720, and 2048 WebP derivatives in background.
 * A failure here NEVER takes an active post offline.
 */
export const processMediaOptimize = onTaskDispatched<ProcessMediaTaskPayload>(
  {
    retryConfig: {
      maxAttempts: 3,
      minBackoffSeconds: 10,
    },
    rateLimits: {
      maxConcurrentDispatches: 4, // Controlled low-priority background pool
    },
    memory: "1GiB",
    timeoutSeconds: 180,
  },
  async (req) => {
    const { mediaId } = req.data;
    if (!mediaId) return;

    const supabase = getSupabase();

    const { data: mediaRow, error: fetchError } = await supabase
      .from("post_media")
      .select("*")
      .eq("media_id", mediaId)
      .single();

    if (fetchError || !mediaRow) return;
    const row = mediaRow as PostMediaRow;

    if (row.status === "optimized") {
      console.log(`[processMediaOptimize] Media ${mediaId} already optimized. No-op.`);
      return;
    }

    await supabase
      .from("post_media")
      .update({ status: "optimizing" })
      .eq("media_id", mediaId);

    const { data: fileData, error: downloadError } = await supabase.storage
      .from("post-media-staging")
      .download(row.staging_path);

    if (downloadError || !fileData) {
      console.error(`[processMediaOptimize] Failed to download staging file for optimization`, downloadError);
      await supabase
        .from("post_media")
        .update({ status: "optimization_failed", last_processing_error: downloadError?.message })
        .eq("media_id", mediaId);
      return;
    }

    const sourceBuffer = Buffer.from(await fileData.arrayBuffer());
    const singleVariants = await createOptimizationVariants(sourceBuffer);

    const updatedVariants: VariantMap = { ...(row.variants || {}) };

    for (const v of singleVariants) {
      const variantPath = `${row.final_prefix}${v.widthKey}.webp`;
      const { error: uploadError } = await supabase.storage
        .from("post-media")
        .upload(variantPath, v.buffer, {
          contentType: "image/webp",
          cacheControl: "public, max-age=31536000, immutable",
          upsert: true,
        });

      if (!uploadError) {
        updatedVariants[v.widthKey.toString()] = {
          path: variantPath,
          width: v.width,
          height: v.height,
          sizeBytes: v.sizeBytes,
          mimeType: "image/webp",
        };
      }
    }

    await supabase
      .from("post_media")
      .update({
        status: "optimized",
        variants: updatedVariants,
      })
      .eq("media_id", mediaId);

    console.log(`[processMediaOptimize] Media ${mediaId} OPTIMIZED with variants: ${Object.keys(updatedVariants).join(", ")}`);
  }
);

/**
 * HTTP endpoint to dispatch feed-ready image processing after Flutter uploads to staging.
 * Validates media existence in Supabase before queuing (no confused-deputy).
 */
export const enqueueMediaProcessing = onRequest(
  {
    cors: true,
    maxInstances: 20,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Method Not Allowed" });
      return;
    }

    const { mediaId, mediaIds } = req.body || {};
    const ids: string[] = mediaIds || (mediaId ? [mediaId] : []);

    if (ids.length === 0) {
      res.status(400).json({ error: "Missing mediaId or mediaIds parameter" });
      return;
    }

    const supabase = getSupabase();
    const queue = getFunctions().taskQueue<ProcessMediaTaskPayload>("processMediaFeedReady");
    const enqueued: string[] = [];

    for (const id of ids) {
      // 1. Verify existence and ownership in Postgres
      const { data: row } = await supabase
        .from("post_media")
        .select("media_id, status")
        .eq("media_id", id)
        .single();

      if (!row) {
        console.warn(`[enqueueMediaProcessing] Media ${id} not found in database. Skipping.`);
        continue;
      }

      // Mark uploaded if awaiting
      if (row.status === "awaiting_upload") {
        await supabase
          .from("post_media")
          .update({ status: "uploaded" })
          .eq("media_id", id);
      }

      // 2. Enqueue Cloud Task
      await queue.enqueue({ mediaId: id });
      enqueued.push(id);
    }

    res.status(200).json({
      success: true,
      enqueuedCount: enqueued.length,
      enqueuedIds: enqueued,
    });
  }
);

/**
 * Scheduled reconciliation worker (Point 40: Queue is not truth).
 * Runs every 5 minutes to detect lost queue tasks or stuck processing.
 */
export const reconcileStuckMedia = onSchedule(
  {
    schedule: "every 5 minutes",
    timeoutSeconds: 60,
  },
  async () => {
    const supabase = getSupabase();
    const queue = getFunctions().taskQueue<ProcessMediaTaskPayload>("processMediaFeedReady");

    const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000).toISOString();
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000).toISOString();

    // 1. Find uploaded rows that never entered processing
    const { data: stuckUploaded } = await supabase
      .from("post_media")
      .select("media_id, processing_attempts")
      .eq("status", "uploaded")
      .lt("created_at", twoMinutesAgo)
      .limit(50);

    if (stuckUploaded && stuckUploaded.length > 0) {
      console.log(`[reconcileStuckMedia] Found ${stuckUploaded.length} unstarted uploaded media jobs. Enqueuing...`);
      for (const item of stuckUploaded) {
        if ((item.processing_attempts || 0) < 5) {
          await queue.enqueue({ mediaId: item.media_id });
        } else {
          await supabase
            .from("post_media")
            .update({ status: "processing_failed", last_processing_error: "Exceeded max processing attempts in reconciliation" })
            .eq("media_id", item.media_id);
        }
      }
    }

    // 2. Find stuck processing_feed rows (hung workers)
    const { data: stuckProcessing } = await supabase
      .from("post_media")
      .select("media_id, processing_attempts")
      .eq("status", "processing_feed")
      .lt("processing_started_at", fiveMinutesAgo)
      .limit(50);

    if (stuckProcessing && stuckProcessing.length > 0) {
      console.log(`[reconcileStuckMedia] Found ${stuckProcessing.length} hung processing_feed jobs. Resetting...`);
      for (const item of stuckProcessing) {
        if ((item.processing_attempts || 0) < 5) {
          await supabase
            .from("post_media")
            .update({ status: "uploaded" })
            .eq("media_id", item.media_id);
          await queue.enqueue({ mediaId: item.media_id });
        } else {
          await supabase
            .from("post_media")
            .update({ status: "processing_failed", last_processing_error: "Processing hung repeatedly and timed out" })
            .eq("media_id", item.media_id);
        }
      }
    }
  }
);
