-- F1.1-E — RLS (políticas iniciais)
-- Seguro, diligente e não disruptivo: cria apenas policies de SELECT (e INSERT mínimo em thread_messages)
-- para papéis internos e para vendor com escopo por vendor_id. Sem UPDATE/DELETE nesta subfase.

SET search_path TO public;
SET statement_timeout TO '5min';
SET lock_timeout TO '1min';
SET idle_in_transaction_session_timeout TO '2min';
SET check_function_bodies = off;

-- Nota: RLS já está habilitado nas tabelas (subfase F1.1-B). Mantemos explicitamente onde relevante.

------------------------
-- users (internos)
------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS users_select_internal ON public.users;
CREATE POLICY users_select_internal ON public.users
  FOR SELECT TO authenticated
  USING (public.is_internal());

------------------------
-- vendors
------------------------
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS vendors_select_internal ON public.vendors;
CREATE POLICY vendors_select_internal ON public.vendors
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS vendors_select_vendor ON public.vendors;
CREATE POLICY vendors_select_vendor ON public.vendors
  FOR SELECT TO authenticated
  USING (public.is_vendor() AND id = public.current_vendor_id());

------------------------
-- skus
------------------------
ALTER TABLE public.skus ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS skus_select_internal ON public.skus;
CREATE POLICY skus_select_internal ON public.skus
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS skus_select_vendor ON public.skus;
CREATE POLICY skus_select_vendor ON public.skus
  FOR SELECT TO authenticated
  USING (
    public.is_vendor() AND EXISTS (
      SELECT 1 FROM public.sku_vendors sv
      WHERE sv.sku_id = public.skus.id
        AND sv.vendor_id = public.current_vendor_id()
        AND sv.active
    )
  );

------------------------
-- sku_vendors
------------------------
ALTER TABLE public.sku_vendors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS sku_vendors_select_internal ON public.sku_vendors;
CREATE POLICY sku_vendors_select_internal ON public.sku_vendors
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS sku_vendors_select_vendor ON public.sku_vendors;
CREATE POLICY sku_vendors_select_vendor ON public.sku_vendors
  FOR SELECT TO authenticated
  USING (public.is_vendor() AND vendor_id = public.current_vendor_id());

------------------------
-- sku_vendor_files
------------------------
ALTER TABLE public.sku_vendor_files ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS sku_vendor_files_select_internal ON public.sku_vendor_files;
CREATE POLICY sku_vendor_files_select_internal ON public.sku_vendor_files
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS sku_vendor_files_select_vendor ON public.sku_vendor_files;
CREATE POLICY sku_vendor_files_select_vendor ON public.sku_vendor_files
  FOR SELECT TO authenticated
  USING (
    public.is_vendor() AND EXISTS (
      SELECT 1 FROM public.sku_vendors sv
      WHERE sv.id = public.sku_vendor_files.sku_vendor_id
        AND sv.vendor_id = public.current_vendor_id()
    )
  );

------------------------
-- rfqs
------------------------
ALTER TABLE public.rfqs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rfqs_select_internal ON public.rfqs;
CREATE POLICY rfqs_select_internal ON public.rfqs
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS rfqs_select_vendor ON public.rfqs;
CREATE POLICY rfqs_select_vendor ON public.rfqs
  FOR SELECT TO authenticated
  USING (
    public.is_vendor() AND EXISTS (
      SELECT 1 FROM public.rfq_vendors rv
      WHERE rv.rfq_id = public.rfqs.id
        AND rv.vendor_id = public.current_vendor_id()
    )
  );

------------------------
-- rfq_vendors
------------------------
ALTER TABLE public.rfq_vendors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rfq_vendors_select_internal ON public.rfq_vendors;
CREATE POLICY rfq_vendors_select_internal ON public.rfq_vendors
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS rfq_vendors_select_vendor ON public.rfq_vendors;
CREATE POLICY rfq_vendors_select_vendor ON public.rfq_vendors
  FOR SELECT TO authenticated
  USING (public.is_vendor() AND vendor_id = public.current_vendor_id());

------------------------
-- rfq_vendor_quotes
------------------------
ALTER TABLE public.rfq_vendor_quotes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS rfq_vendor_quotes_select_internal ON public.rfq_vendor_quotes;
CREATE POLICY rfq_vendor_quotes_select_internal ON public.rfq_vendor_quotes
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS rfq_vendor_quotes_select_vendor ON public.rfq_vendor_quotes;
CREATE POLICY rfq_vendor_quotes_select_vendor ON public.rfq_vendor_quotes
  FOR SELECT TO authenticated
  USING (
    public.is_vendor() AND EXISTS (
      SELECT 1 FROM public.rfq_vendors rv
      WHERE rv.id = public.rfq_vendor_quotes.rfq_vendor_id
        AND rv.vendor_id = public.current_vendor_id()
    )
  );

------------------------
-- threads
------------------------
ALTER TABLE public.threads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS threads_select_internal ON public.threads;
CREATE POLICY threads_select_internal ON public.threads
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS threads_select_vendor ON public.threads;
CREATE POLICY threads_select_vendor ON public.threads
  FOR SELECT TO authenticated
  USING (
    public.is_vendor() AND EXISTS (
      SELECT 1 FROM public.rfq_vendors rv
      WHERE rv.id = public.threads.rfq_vendor_id
        AND rv.vendor_id = public.current_vendor_id()
    )
  );

------------------------
-- thread_messages
------------------------
ALTER TABLE public.thread_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS thread_messages_select_internal ON public.thread_messages;
CREATE POLICY thread_messages_select_internal ON public.thread_messages
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS thread_messages_select_vendor ON public.thread_messages;
CREATE POLICY thread_messages_select_vendor ON public.thread_messages
  FOR SELECT TO authenticated
  USING (
    public.is_vendor() AND EXISTS (
      SELECT 1 FROM public.threads t
      JOIN public.rfq_vendors rv ON rv.id = t.rfq_vendor_id
      WHERE t.id = public.thread_messages.thread_id
        AND rv.vendor_id = public.current_vendor_id()
    )
  );

-- INSERT mínimo: vendor pode inserir mensagens apenas em threads do seu escopo
DROP POLICY IF EXISTS thread_messages_insert_vendor ON public.thread_messages;
CREATE POLICY thread_messages_insert_vendor ON public.thread_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    public.is_vendor() AND EXISTS (
      SELECT 1 FROM public.threads t
      JOIN public.rfq_vendors rv ON rv.id = t.rfq_vendor_id
      WHERE t.id = public.thread_messages.thread_id
        AND rv.vendor_id = public.current_vendor_id()
    )
  );

-- INSERT interno: permitir para papéis internos
DROP POLICY IF EXISTS thread_messages_insert_internal ON public.thread_messages;
CREATE POLICY thread_messages_insert_internal ON public.thread_messages
  FOR INSERT TO authenticated
  WITH CHECK (public.is_internal());

------------------------
-- invoices
------------------------
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS invoices_select_internal ON public.invoices;
CREATE POLICY invoices_select_internal ON public.invoices
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS invoices_select_vendor ON public.invoices;
CREATE POLICY invoices_select_vendor ON public.invoices
  FOR SELECT TO authenticated
  USING (
    public.is_vendor() AND EXISTS (
      SELECT 1 FROM public.rfq_vendors rv
      WHERE rv.id = public.invoices.rfq_vendor_id
        AND rv.vendor_id = public.current_vendor_id()
    )
  );

------------------------
-- purchase_orders
------------------------
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS pos_select_internal ON public.purchase_orders;
CREATE POLICY pos_select_internal ON public.purchase_orders
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS pos_select_vendor ON public.purchase_orders;
CREATE POLICY pos_select_vendor ON public.purchase_orders
  FOR SELECT TO authenticated
  USING (
    public.is_vendor() AND EXISTS (
      SELECT 1 FROM public.rfq_vendors rv
      WHERE rv.id = public.purchase_orders.rfq_vendor_id
        AND rv.vendor_id = public.current_vendor_id()
    )
  );

------------------------
-- purchase_order_lines
------------------------
ALTER TABLE public.purchase_order_lines ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS pol_select_internal ON public.purchase_order_lines;
CREATE POLICY pol_select_internal ON public.purchase_order_lines
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS pol_select_vendor ON public.purchase_order_lines;
CREATE POLICY pol_select_vendor ON public.purchase_order_lines
  FOR SELECT TO authenticated
  USING (
    public.is_vendor() AND EXISTS (
      SELECT 1 FROM public.purchase_orders po
      JOIN public.rfq_vendors rv ON rv.id = po.rfq_vendor_id
      WHERE po.id = public.purchase_order_lines.purchase_order_id
        AND rv.vendor_id = public.current_vendor_id()
    )
  );

------------------------
-- activities (somente internos nesta fase; vendor será avaliado depois)
------------------------
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS activities_select_internal ON public.activities;
CREATE POLICY activities_select_internal ON public.activities
  FOR SELECT TO authenticated
  USING (public.is_internal());

------------------------
-- notifications
------------------------
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS notifications_select_internal ON public.notifications;
CREATE POLICY notifications_select_internal ON public.notifications
  FOR SELECT TO authenticated
  USING (public.is_internal());

DROP POLICY IF EXISTS notifications_select_vendor ON public.notifications;
CREATE POLICY notifications_select_vendor ON public.notifications
  FOR SELECT TO authenticated
  USING (public.is_vendor() AND vendor_id = public.current_vendor_id());

-- Observações:
-- - Sem UPDATE/DELETE nesta subfase para reduzir superfície de risco.
-- - Policies podem ser endurecidas/expandida em F1.14 (Hardening) e conforme surgirem necessidades em fases futuras.
