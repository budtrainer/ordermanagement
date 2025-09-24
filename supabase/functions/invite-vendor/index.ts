// Supabase Edge Function: invite-vendor (stub)
// - Validates payload and logs intent to generate a magic link for vendor onboarding/access
// - Returns 200 with echo payload. No external calls or email sending in this stub.
// - Includes CORS and safe error handling.

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
      vendorEmail: string;
      rfqVendorId?: string; // Optional context to tie this invite to a specific RFQ-Vendor row
      expiresInDays?: number; // Optional, default 7
    };

    const [body, parseError] = await readJson<Payload>(req);
    if (parseError) {
      parseError.headers.set('x-request-id', requestId);
      return parseError;
    }

    // Basic validation
    if (!body || typeof body.vendorEmail !== 'string' || body.vendorEmail.length < 5) {
      const r = err("'vendorEmail' is required", 400, 'missing_vendor_email');
      r.headers.set('x-request-id', requestId);
      return r;
    }
    const emailOk = /.+@.+\..+/.test(body.vendorEmail);
    if (!emailOk) {
      const r = err("'vendorEmail' must be a valid email", 400, 'invalid_vendor_email');
      r.headers.set('x-request-id', requestId);
      return r;
    }

    if (
      body.rfqVendorId &&
      !/^([0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})$/i.test(
        body.rfqVendorId,
      )
    ) {
      const r = err("'rfqVendorId' must be a UUID if provided", 400, 'invalid_rfq_vendor_id');
      r.headers.set('x-request-id', requestId);
      return r;
    }

    const expiresInDays = Number.isFinite(body.expiresInDays)
      ? Math.max(1, Math.min(30, Number(body.expiresInDays)))
      : 7;

    // Log intent (no external calls)
    const durationMs = Date.now() - startedAt;
    console.info(
      JSON.stringify({
        fn: 'invite-vendor',
        event: 'request_completed',
        requestId,
        vendorEmail: body.vendorEmail,
        rfqVendorId: body.rfqVendorId ?? null,
        expiresInDays,
        durationMs,
      }),
    );

    const r = ok(
      {
        ok: true,
        action: 'invite_vendor',
        vendorEmail: body.vendorEmail,
        rfqVendorId: body.rfqVendorId ?? null,
        expiresInDays,
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
        fn: 'invite-vendor',
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
