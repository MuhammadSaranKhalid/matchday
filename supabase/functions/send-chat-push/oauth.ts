interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

const serviceAccount = () =>
  JSON.parse(
    Deno.env.get("FCM_SERVICE_ACCOUNT")!,
  ) as ServiceAccount;

// Google OAuth service-account assertion flow.
//
// The access token is cached in-memory for its lifetime so notification bursts
// do not repeatedly hit Google's token endpoint.
let cachedToken: {
  token: string;
  expiresAt: number;
} | null = null;

export async function getAccessToken(): Promise<string> {
  if (
    cachedToken &&
    cachedToken.expiresAt >
      Date.now() + 60_000
  ) {
    return cachedToken.token;
  }

  const sa = serviceAccount();
  const now = Math.floor(Date.now() / 1000);

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const claim = {
    iss: sa.client_email,
    scope:
      "https://www.googleapis.com/auth/firebase.messaging",
    aud:
      sa.token_uri ??
      "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encoder = new TextEncoder();

  const encode = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");

  const headerB64 = encode(header);
  const claimB64 = encode(claim);
  const signingInput =
    `${headerB64}.${claimB64}`;

  const pem = sa.private_key
    .replace(
      /-----BEGIN PRIVATE KEY-----/,
      "",
    )
    .replace(
      /-----END PRIVATE KEY-----/,
      "",
    )
    .replace(/\s+/g, "");

  const der = Uint8Array.from(
    atob(pem),
    (char) => char.charCodeAt(0),
  );

  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signature =
      await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(signingInput),
  );

  const signatureB64 = btoa(
    String.fromCharCode(
      ...new Uint8Array(signature),
    ),
  )
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const jwt =
    `${signingInput}.${signatureB64}`;

  const response = await fetch(
    claim.aud,
    {
      method: "POST",
      headers: {
        "content-type":
          "application/x-www-form-urlencoded",
      },
      signal: AbortSignal.timeout(10000),
      body: new URLSearchParams({
        grant_type:
          "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: jwt,
      }),
    },
  );

  if (!response.ok) {
    throw new Error(
      `google oauth failed: `
      + `${response.status} `
      + `${await response.text()}`,
    );
  }

  const data = await response.json() as {
    access_token: string;
    expires_in: number;
  };

  cachedToken = {
    token: data.access_token,
    expiresAt:
      Date.now() +
      (data.expires_in - 60) * 1000,
  };

  return cachedToken.token;
}
