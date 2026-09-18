import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/post_dto.dart';

/// Talks to Supabase for the `posts` table + `post-media` storage bucket +
/// `post_likes` and `bookmarks` junction tables.
/// Returns DTOs, throws raw exceptions. RLS scopes reads/writes.
class PostsRemoteDataSource {
  PostsRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  static const _table = 'posts';
  static const _likesTable = 'post_likes';
  static const _bookmarksTable = 'bookmarks';
  static const _bucket = 'post-media';

  // Embed the author's profile and team so the feed renders without extra queries.
  static const _select =
      '*, author:profiles!author_id(display_name, username, profile_photo_url), team:teams!linked_team_id(team_name, logo_url, logo_monogram, team_colors)';

  String _requireUid() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw UnauthorizedException('Must be signed in');
    return id;
  }

  Future<List<PostDto>> _enrichWithUserInteractions(List<PostDto> dtos) async {
    final currentUid = _supabase.auth.currentUser?.id;
    if (currentUid == null || dtos.isEmpty) return dtos;

    final postIds = dtos.map((d) => d.postId).toList();

    try {
      final likesFuture = _supabase
          .from(_likesTable)
          .select('post_id')
          .eq('user_id', currentUid)
          .inFilter('post_id', postIds);

      final bookmarksFuture = _supabase
          .from(_bookmarksTable)
          .select('post_id')
          .eq('user_id', currentUid)
          .inFilter('post_id', postIds);

      final results = await Future.wait([likesFuture, bookmarksFuture]);
      final likedPostIds = (results[0] as List)
          .map((r) => r['post_id'] as String)
          .toSet();
      final bookmarkedPostIds = (results[1] as List)
          .map((r) => r['post_id'] as String)
          .toSet();

      return dtos.map((d) {
        return d.copyWith(
          isLiked: likedPostIds.contains(d.postId),
          isBookmarked: bookmarkedPostIds.contains(d.postId),
        );
      }).toList();
    } catch (_) {
      return dtos;
    }
  }

  Future<List<PostDto>> _enrichWithTeams(List<PostDto> dtos) async {
    if (dtos.isEmpty) return dtos;

    final teamIds = dtos
        .where((d) =>
            d.authorContext == 'team_manager' ||
            (d.linkedTeamId != null && d.linkedTeamId!.isNotEmpty))
        .map((d) => d.contextEntityId ?? d.linkedTeamId)
        .whereType<String>()
        .toSet()
        .toList();

    if (teamIds.isEmpty) return dtos;

    try {
      final teamRows = await _supabase
          .from('teams')
          .select('team_id, team_name, logo_url, logo_monogram, team_colors')
          .inFilter('team_id', teamIds);

      final teamsById = {
        for (final r in (teamRows as List))
          r['team_id'] as String: r as Map<String, dynamic>,
      };

      return dtos.map((d) {
        final tid = d.contextEntityId ?? d.linkedTeamId;
        if (tid != null && teamsById.containsKey(tid)) {
          final t = teamsById[tid]!;
          return d.copyWith(team: t);
        }
        return d;
      }).toList();
    } catch (_) {
      return dtos;
    }
  }

  Future<List<PostDto>> getFeed({
    required int limit,
    String filter = 'all',
    DateTime? before,
  }) async {
    try {
      var q = _supabase.from(_table).select(_select).eq('status', 'active');

      if (filter == 'people') {
        q = q.eq('author_context', 'personal');
      } else if (filter == 'teams') {
        q = q.eq('author_context', 'team_manager');
      } else if (filter == 'tournaments') {
        q = q.eq('author_context', 'tournament_organizer');
      } else if (filter == 'matches') {
        q = q.eq('post_type', 'match_announcement');
      }

      if (before != null) q = q.lt('created_at', before.toIso8601String());
      final rows = await q.order('created_at', ascending: false).limit(limit);
      final dtos = rows.map((r) => PostDto.fromJson(r)).toList();
      final withTeams = await _enrichWithTeams(dtos);
      return _enrichWithUserInteractions(withTeams);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<PostDto>> getByAuthor(
    String authorId, {
    required int limit,
    DateTime? before,
  }) async {
    try {
      var q = _supabase
          .from(_table)
          .select(_select)
          .eq('author_id', authorId)
          .eq('status', 'active');
      if (before != null) q = q.lt('created_at', before.toIso8601String());
      final rows = await q.order('created_at', ascending: false).limit(limit);
      final dtos = rows.map((r) => PostDto.fromJson(r)).toList();
      final withTeams = await _enrichWithTeams(dtos);
      return _enrichWithUserInteractions(withTeams);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  Future<List<PostDto>> getByTeam(
    String teamId, {
    required int limit,
    DateTime? before,
  }) async {
    try {
      var q = _supabase
          .from(_table)
          .select(_select)
          .or('context_entity_id.eq.$teamId,linked_team_id.eq.$teamId')
          .eq('status', 'active');
      if (before != null) q = q.lt('created_at', before.toIso8601String());
      final rows = await q.order('created_at', ascending: false).limit(limit);
      final dtos = rows.map((r) => PostDto.fromJson(r)).toList();
      final withTeams = await _enrichWithTeams(dtos);
      return _enrichWithUserInteractions(withTeams);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Toggle post like for authenticated user. Returns `true` if liked, `false` if unliked.
  Future<bool> togglePostLike(String postId) async {
    try {
      final uid = _requireUid();
      final existing = await _supabase
          .from(_likesTable)
          .select('like_id')
          .eq('post_id', postId)
          .eq('user_id', uid)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from(_likesTable)
            .delete()
            .eq('post_id', postId)
            .eq('user_id', uid);
        return false;
      } else {
        await _supabase.from(_likesTable).insert({
          'post_id': postId,
          'user_id': uid,
        });
        return true;
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Toggle bookmark for authenticated user. Returns `true` if bookmarked, `false` if removed.
  Future<bool> toggleBookmark(String postId) async {
    try {
      final uid = _requireUid();
      final existing = await _supabase
          .from(_bookmarksTable)
          .select('bookmark_id')
          .eq('post_id', postId)
          .eq('user_id', uid)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from(_bookmarksTable)
            .delete()
            .eq('post_id', postId)
            .eq('user_id', uid);
        return false;
      } else {
        await _supabase.from(_bookmarksTable).insert({
          'post_id': postId,
          'user_id': uid,
        });
        return true;
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Fetch posts bookmarked by the current user.
  Future<List<PostDto>> getBookmarkedPosts({
    required int limit,
    DateTime? before,
  }) async {
    try {
      final uid = _requireUid();
      var q = _supabase
          .from(_bookmarksTable)
          .select('created_at, post:posts!post_id($_select)')
          .eq('user_id', uid);

      if (before != null) q = q.lt('created_at', before.toIso8601String());
      final rows = await q.order('created_at', ascending: false).limit(limit);

      final dtos = <PostDto>[];
      for (final r in rows) {
        final postMap = r['post'] as Map<String, dynamic>?;
        if (postMap != null && postMap['status'] == 'active') {
          dtos.add(
            PostDto.fromJson(postMap).copyWith(isBookmarked: true),
          );
        }
      }
      final withTeams = await _enrichWithTeams(dtos);
      return _enrichWithUserInteractions(withTeams);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Insert the post row FIRST (storage RLS `is_post_author` requires the row
  /// to exist before media upload). Returns the row with the author embed.
  Future<PostDto> insertPost(Map<String, dynamic> payload) async {
    try {
      final row = await _supabase
          .from(_table)
          .insert({...payload, 'author_id': _requireUid()})
          .select(_select)
          .single();
      final dto = PostDto.fromJson(row);
      final withTeams = await _enrichWithTeams([dto]);
      return withTeams.first;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Upload each already-resized JPEG to `post-media/<postId>/<i>.jpg`.
  Future<void> uploadMedia(String postId, List<File> files) async {
    try {
      for (var i = 0; i < files.length; i++) {
        await _supabase.storage.from(_bucket).upload(
              '$postId/$i.jpg',
              files[i],
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      }
    } on StorageException catch (e) {
      throw ServerException(e.message);
    }
  }

  /// Public URL for a stored object (the bucket is public).
  String publicUrl(String path) =>
      _supabase.storage.from(_bucket).getPublicUrl(path);

  /// Soft-delete (preserve audit trail, per the schema's status posture).
  Future<void> deletePost(String id) async {
    try {
      _requireUid(); // fast explicit failure rather than a silent zero-row RLS no-op
      await _supabase
          .from(_table)
          .update({'status': 'deleted'}).eq('post_id', id);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
