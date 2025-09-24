-- F1.2 — Tests (claims helpers)
-- DEV-ONLY. This script does not change schema.
-- It validates that current_role() and current_vendor_id() read from top-level, app_metadata and user_metadata.

SET search_path TO public;
SET statement_timeout TO '5min';
SET lock_timeout TO '1min';
SET idle_in_transaction_session_timeout TO '2min';
SET check_function_bodies = off;

-- Ensure we execute under the 'authenticated' role so RLS applies consistently
SET LOCAL ROLE authenticated;

-- UUID used for vendor tests
-- 101: b0b7a1a2-0000-4b11-8000-000000000101

-- 1) Top-level claims
SELECT set_config('request.jwt.claims', '{"role":"buyer","vendor_id":"b0b7a1a2-0000-4b11-8000-000000000101"}', true);
SELECT 'top.level' AS scope, * FROM public.debug_current_claims;

-- 2) app_metadata claims
SELECT set_config('request.jwt.claims', '{"app_metadata":{"role":"buyer","vendor_id":"b0b7a1a2-0000-4b11-8000-000000000101"}}', true);
SELECT 'app_metadata' AS scope, * FROM public.debug_current_claims;

-- 3) user_metadata claims
SELECT set_config('request.jwt.claims', '{"user_metadata":{"role":"buyer","vendor_id":"b0b7a1a2-0000-4b11-8000-000000000101"}}', true);
SELECT 'user_metadata' AS scope, * FROM public.debug_current_claims;

-- 4) No claims
SELECT set_config('request.jwt.claims', '{}', true);
SELECT 'none' AS scope, * FROM public.debug_current_claims;
