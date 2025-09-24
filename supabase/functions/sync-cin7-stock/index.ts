// Supabase Edge Function: sync-cin7-stock (stub)
// - Validates/accepts a minimal payload
// - Logs context and returns { results: [] }
// - Includes CORS and safe error handling

import { corsHeaders, err, isOptions, ok, readJson } from '../_shared/utils.ts';

Deno.serve(async (req: Request): Promise<Response> => {
  // CORS preflight
  if (isOptions(req)) {
    return new Response(null, { headers: corsHeaders, status: 204 });
  }

  const requestId = crypto.randomUUID();
  const startedAt = Date.now();

  try {
    if (req.method !== 'POST') {
      const r = err('Only POST is allowed', 405, 'method_not_allowed');
      r.headers.set('x-request-id', requestId);
      return r;
    }

    type Payload = {
      skus?: string[];
      since?: string; // ISO timestamp
      force?: boolean;
    };

    const [body, parseError] = await readJson<Payload>(req);
    if (parseError) {
      parseError.headers.set('x-request-id', requestId);
      return parseError;
    }

    // Minimal validation (non-blocking stub)
    if (body && body.since) {
      const isIso = !Number.isNaN(Date.parse(body.since));
      if (!isIso) {
        const r = err("'since' must be ISO date string", 400, 'invalid_since');
        r.headers.set('x-request-id', requestId);
        return r;
      }
    }

    // Stub response
    const durationMs = Date.now() - startedAt;
    console.info(
      JSON.stringify({
        fn: 'sync-cin7-stock',
        event: 'request_completed',
        requestId,
        hasSkus: Boolean(body?.skus?.length),
        since: body?.since ?? null,
        force: Boolean(body?.force),
        durationMs,
      }),
    );
    const r = ok(
      {
        results: [],
        received: body ?? {},
        requestId,
        durationMs,
      },
      200,
    );
    r.headers.set('x-request-id', requestId);
    return r;
  } catch (e) {
    const durationMs = Date.now() - startedAt;
    console.error(
      JSON.stringify({
        fn: 'sync-cin7-stock',
        event: 'error',
        requestId,
        durationMs,
        err: String(e),
      }),
    );
    const r = err('Internal error', 500, 'internal_error');
    r.headers.set('x-request-id', requestId);
    return r;
  }
});
