-- F1.1-G — Validação e testes (RLS)
-- DEV-ONLY. Este script NÃO altera schema. Todos os testes de escrita estão comentados por padrão.
-- Use em conjunto com os seeds da F1.1-F. Execute blocos individualmente para observar comportamentos.

SET search_path TO public;
SET statement_timeout TO '5min';
SET lock_timeout TO '1min';
SET idle_in_transaction_session_timeout TO '2min';
SET check_function_bodies = off;

-- Garantir que RLS está ativa no contexto de 'authenticated'
SET LOCAL ROLE authenticated;

-- UUIDs conforme seeds F1.1-F
-- Vendor1: b0b7a1a2-0000-4b11-8000-000000000101
-- Vendor2: b0b7a1a2-0000-4b11-8000-000000000102
-- Thread1 (vendor1): b0b7a1a2-0000-4b11-8000-000000000601

-- =====================================================================
-- 1) Interno (buyer)
-- =====================================================================
SELECT set_config('request.jwt.claims', '{"role":"buyer"}', true);

-- Deve retornar linhas dos cadastros e RFQ (seeds criados)
SELECT 'internal.rfqs.count' AS check, COUNT(*) FROM public.rfqs;
SELECT 'internal.rfq_vendors.count' AS check, COUNT(*) FROM public.rfq_vendors;
SELECT 'internal.thread_messages.count' AS check, COUNT(*) FROM public.thread_messages;
SELECT 'internal.skus.count' AS check, COUNT(*) FROM public.skus;
SELECT 'internal.vendors.count' AS check, COUNT(*) FROM public.vendors;

-- Tabelas restritas por design
SELECT 'internal.activities.count' AS check, COUNT(*) FROM public.activities; -- esperado: 0 se não houver seeds
SELECT 'internal.notifications.count' AS check, COUNT(*) FROM public.notifications; -- esperado: 0 se não houver seeds

-- =====================================================================
-- 2) Vendor1 (escopo: vendor_id = ...0101)
-- =====================================================================
SELECT set_config('request.jwt.claims', '{"role":"vendor","vendor_id":"b0b7a1a2-0000-4b11-8000-000000000101"}', true);

-- Deve ver apenas seus vínculos e dados relacionados
SELECT 'vendor1.rfq_vendors.count' AS check, COUNT(*) FROM public.rfq_vendors; -- esperado: 1
SELECT 'vendor1.threads.count' AS check, COUNT(*) FROM public.threads; -- esperado: 1 (thread do vendor1)
SELECT 'vendor1.thread_messages.count' AS check,
  COUNT(*)
FROM public.thread_messages tm
JOIN public.threads t ON t.id = tm.thread_id
JOIN public.rfq_vendors rv ON rv.id = t.rfq_vendor_id
WHERE rv.vendor_id = public.current_vendor_id(); -- esperado: 1

-- Deve ver SKUs apenas quando há vínculo em sku_vendors
SELECT 'vendor1.skus.linked.count' AS check,
  COUNT(DISTINCT s.id)
FROM public.skus s
JOIN public.sku_vendors sv ON sv.sku_id = s.id
WHERE sv.vendor_id = public.current_vendor_id(); -- esperado: >=1

-- Tabelas com restrição
SELECT 'vendor1.activities.count' AS check, COUNT(*) FROM public.activities; -- esperado: 0 (sem policy para vendor)
SELECT 'vendor1.notifications.count' AS check, COUNT(*) FROM public.notifications WHERE vendor_id = public.current_vendor_id(); -- esperado: 0 se não houver seeds

-- =====================================================================
-- 3) Vendor2 (escopo: vendor_id = ...0102)
-- =====================================================================
SELECT set_config('request.jwt.claims', '{"role":"vendor","vendor_id":"b0b7a1a2-0000-4b11-8000-000000000102"}', true);

-- Deve ver apenas suas próprias linhas
SELECT 'vendor2.rfq_vendors.count' AS check, COUNT(*) FROM public.rfq_vendors; -- esperado: 1
SELECT 'vendor2.threads.count' AS check, COUNT(*) FROM public.threads; -- esperado: 0 (seeds não criaram thread para vendor2)
SELECT 'vendor2.thread_messages.count' AS check,
  COUNT(*)
FROM public.thread_messages tm
JOIN public.threads t ON t.id = tm.thread_id
JOIN public.rfq_vendors rv ON rv.id = t.rfq_vendor_id
WHERE rv.vendor_id = public.current_vendor_id(); -- esperado: 0

-- =====================================================================
-- 4) (Opcional) Testes de escrita — NÃO PERSISTENTES (comentados por padrão)
-- =====================================================================
-- Recomendado executar em DEV local. Descomente para validar comportamentos.

-- a) Vendor1 pode inserir mensagem na própria thread (esperado: sucesso)
-- SELECT set_config('request.jwt.claims', '{"role":"vendor","vendor_id":"b0b7a1a2-0000-4b11-8000-000000000101"}', true);
-- BEGIN;
--   INSERT INTO public.thread_messages (thread_id, author_type, author_id, content)
--   VALUES ('b0b7a1a2-0000-4b11-8000-000000000601'::uuid, 'vendor', 'b0b7a1a2-0000-4b11-8000-000000000101'::uuid, 'DEV test: vendor reply (will be rolled back)');
-- ROLLBACK;

-- b) Vendor2 NÃO pode inserir mensagem na thread do Vendor1 (esperado: falha de RLS)
-- SELECT set_config('request.jwt.claims', '{"role":"vendor","vendor_id":"b0b7a1a2-0000-4b11-8000-000000000102"}', true);
-- BEGIN;
--   INSERT INTO public.thread_messages (thread_id, author_type, author_id, content)
--   VALUES ('b0b7a1a2-0000-4b11-8000-000000000601'::uuid, 'vendor', 'b0b7a1a2-0000-4b11-8000-000000000102'::uuid, 'DEV test: should fail');
-- -- Esperado: erro de RLS. Se executar num cliente que interrompe a transação, finalize com ROLLBACK manualmente.
-- ROLLBACK;

-- Reset claims ao final (opcional)
SELECT set_config('request.jwt.claims', '{}', true);
