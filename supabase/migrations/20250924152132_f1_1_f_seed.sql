-- F1.1-F — Seeds DEV mínimos para validação de RLS
-- Seguro, diligente e idempotente: utiliza IDs fixos e ON CONFLICT DO NOTHING.
-- Estes dados servem para validar leituras por papéis internos e vendor.

SET search_path TO public;
SET statement_timeout TO '5min';
SET lock_timeout TO '1min';
SET idle_in_transaction_session_timeout TO '2min';
SET check_function_bodies = off;

-- users (interno buyer)
INSERT INTO public.users (id, name, email, role, active)
VALUES ('b0b7a1a2-0000-4b11-8000-000000000001'::uuid, 'Buyer Dev', 'buyer.dev@budtrainer.local', 'buyer', true)
ON CONFLICT (id) DO NOTHING;

-- vendors
INSERT INTO public.vendors (id, name, cnpj_tax_id, email, phone, address, active)
VALUES
  ('b0b7a1a2-0000-4b11-8000-000000000101'::uuid, 'FocusBox', '00.000.000/0001-00', 'contact@focusbox.dev', '+1-111-111-1111', 'Toronto, CA', true),
  ('b0b7a1a2-0000-4b11-8000-000000000102'::uuid, 'HB Baiger', '00.000.000/0002-00', 'hello@hbbaiger.dev', '+1-222-222-2222', 'Vancouver, CA', true)
ON CONFLICT (id) DO NOTHING;

-- sku
INSERT INTO public.skus (id, sku_code, description, family, image_url, active)
VALUES ('b0b7a1a2-0000-4b11-8000-000000000201'::uuid, 'SKU-001', 'Sample Training Product', 'Accessories', NULL, true)
ON CONFLICT (id) DO NOTHING;

-- sku_vendors
INSERT INTO public.sku_vendors (id, sku_id, vendor_id, moq_min, lead_time_days, currency, incoterm, active)
VALUES
  ('b0b7a1a2-0000-4b11-8000-000000000301'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000201'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000101'::uuid, 1000, 21, 'CAD', 'FOB', true),
  ('b0b7a1a2-0000-4b11-8000-000000000302'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000201'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000102'::uuid, 1000, 28, 'CAD', 'FOB', true)
ON CONFLICT (id) DO NOTHING;

-- rfq
INSERT INTO public.rfqs (id, sku_id, created_by, deadline, status, notes)
VALUES ('b0b7a1a2-0000-4b11-8000-000000000401'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000201'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000001'::uuid, now() + interval '7 days', 'sent', 'DEV seed RFQ for validation')
ON CONFLICT (id) DO NOTHING;

-- rfq_vendors (um por fornecedor)
INSERT INTO public.rfq_vendors (id, rfq_id, vendor_id, status, opened_at, responded_at)
VALUES
  ('b0b7a1a2-0000-4b11-8000-000000000501'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000401'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000101'::uuid, 'sent', NULL, NULL),
  ('b0b7a1a2-0000-4b11-8000-000000000502'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000401'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000102'::uuid, 'sent', NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- threads
INSERT INTO public.threads (id, rfq_vendor_id, created_by, subject)
VALUES ('b0b7a1a2-0000-4b11-8000-000000000601'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000501'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000001'::uuid, 'Negotiation thread (DEV)')
ON CONFLICT (id) DO NOTHING;

-- thread_messages (mensagem inicial do interno)
INSERT INTO public.thread_messages (id, thread_id, author_type, author_id, content)
VALUES ('b0b7a1a2-0000-4b11-8000-000000000701'::uuid, 'b0b7a1a2-0000-4b11-8000-000000000601'::uuid, 'internal', 'b0b7a1a2-0000-4b11-8000-000000000001'::uuid, 'Initial message for validation (DEV).')
ON CONFLICT (id) DO NOTHING;

-- Observações:
-- - Quotes, invoices e POs não são estritamente necessários para validar RLS inicial.
-- - Para testes de vendor, gere um JWT com claims: { "role": "vendor", "vendor_id": 'b0b7a1a2-0000-4b11-8000-000000000101' }.
-- - Para testes internos, use claims: { "role": "buyer" } (ou admin/finance/reader).
