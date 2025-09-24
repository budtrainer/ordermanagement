-- F1.1-C — Índices essenciais (seguros e não disruptivos)
-- Apenas criação de índices; nenhuma alteração de schema/tabelas existentes.

SET search_path TO public;
SET statement_timeout TO '5min';
SET lock_timeout TO '1min';
SET idle_in_transaction_session_timeout TO '2min';
SET check_function_bodies = off;

-- Índices previstos no plano
CREATE INDEX IF NOT EXISTS idx_rfqs_sku_status ON public.rfqs (sku_id, status);
CREATE INDEX IF NOT EXISTS idx_rfq_vendors_status ON public.rfq_vendors (rfq_id, status);
CREATE INDEX IF NOT EXISTS idx_activities_entity ON public.activities (entity_type, entity_id);

-- Índices recomendados em FKs e colunas de junção/consulta frequente
CREATE INDEX IF NOT EXISTS idx_sku_vendors_sku ON public.sku_vendors (sku_id);
CREATE INDEX IF NOT EXISTS idx_sku_vendors_vendor ON public.sku_vendors (vendor_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_sku_vendor ON public.sku_vendors (sku_id, vendor_id) WHERE active;

CREATE INDEX IF NOT EXISTS idx_sku_vendor_files_sku_vendor ON public.sku_vendor_files (sku_vendor_id);

-- rfq/ecossistema
-- (idx_rfqs_sku_status já cobre prefixo por sku_id)
CREATE INDEX IF NOT EXISTS idx_rfq_vendors_vendor ON public.rfq_vendors (vendor_id);
CREATE INDEX IF NOT EXISTS idx_rfq_vendor_quotes_rfq_vendor ON public.rfq_vendor_quotes (rfq_vendor_id);

CREATE INDEX IF NOT EXISTS idx_threads_rfq_vendor ON public.threads (rfq_vendor_id);
CREATE INDEX IF NOT EXISTS idx_thread_messages_thread ON public.thread_messages (thread_id);

-- invoices/PO
CREATE INDEX IF NOT EXISTS idx_invoices_rfq_vendor ON public.invoices (rfq_vendor_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_rfq_vendor ON public.purchase_orders (rfq_vendor_id);
CREATE INDEX IF NOT EXISTS idx_pol_purchase_order ON public.purchase_order_lines (purchase_order_id);
CREATE INDEX IF NOT EXISTS idx_pol_sku ON public.purchase_order_lines (sku_id);

-- notificações
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_vendor ON public.notifications (vendor_id);

-- Observações:
-- - Sem uso de CONCURRENTLY para compatibilidade com transações de migração.
-- - Todos os índices usam IF NOT EXISTS para idempotência.
