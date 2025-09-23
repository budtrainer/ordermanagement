// Supabase Edge Function: invoice-ocr-extract (stub)
// - Accepts JSON: { fileUrl?: string }
// - Logs context and returns { parsed_json: {}, ai_flags: [] }
// - Includes CORS and safe error handling

import { corsHeaders, err, isOptions, ok, readJson } from '../_shared/utils.ts';

Deno.serve(async (req: Request): Promise<Response> => {
  // CORS preflight
  if (isOptions(req)) {
    return new Response(null, { headers: corsHeaders, status: 204 });
  }

  const requestId = crypto.randomUUID();

  try {
    if (req.method !== 'POST') {
      const r = err('Only POST is allowed', 405, 'method_not_allowed');
      r.headers.set('x-request-id', requestId);
      return r;
    }

    type Payload = {
      fileUrl?: string; // Remote file to parse later
    };

    const [body, parseError] = await readJson<Payload>(req);
    if (parseError) {
      parseError.headers.set('x-request-id', requestId);
      return parseError;
    }

    // Minimal validation (optional for stub)
    if (body && body.fileUrl && !/^https?:\/\//i.test(body.fileUrl)) {
      const r = err("'fileUrl' must be http(s) URL", 400, 'invalid_file_url');
      r.headers.set('x-request-id', requestId);
      return r;
    }

    console.info(
      JSON.stringify({ fn: 'invoice-ocr-extract', requestId, hasFileUrl: Boolean(body?.fileUrl) }),
    );

    const r = ok(
      {
        parsed_json: {}, // to be filled by OCR pipeline in future phases
        ai_flags: [], // e.g., ["missing_vendor", "mismatch_total"] in later phases
        requestId,
      },
      200,
    );
    r.headers.set('x-request-id', requestId);
    return r;
  } catch (e) {
    console.error(JSON.stringify({ fn: 'invoice-ocr-extract', requestId, err: String(e) }));
    const r = err('Internal error', 500, 'internal_error');
    r.headers.set('x-request-id', requestId);
    return r;
  }
});
