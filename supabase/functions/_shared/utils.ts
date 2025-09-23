// Shared utilities for Edge Functions (Deno runtime)
// Keep these helpers minimal and side-effect free.

export const corsHeaders: HeadersInit = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-request-id',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

export function withCors(body: BodyInit | null, init: ResponseInit = {}): Response {
  const headers = new Headers(init.headers ?? {});
  Object.entries(corsHeaders).forEach(([k, v]) => headers.set(k, v as string));
  return new Response(body, { ...init, headers });
}

export function isOptions(req: Request): boolean {
  return req.method === 'OPTIONS';
}

export function ok(data: unknown, status = 200): Response {
  return withCors(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export function err(message: string, status = 500, code = 'internal_error'): Response {
  return withCors(JSON.stringify({ error: code, message }), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export async function readJson<T>(req: Request): Promise<[T | null, Response | null]> {
  try {
    const raw = await req.text();
    if (!raw) return [{} as T, null];
    const json = JSON.parse(raw) as T;
    return [json, null];
  } catch (_e) {
    return [null, err('Invalid JSON body', 400, 'invalid_json')];
  }
}
