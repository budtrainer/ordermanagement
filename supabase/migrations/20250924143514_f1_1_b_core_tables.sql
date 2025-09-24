-- F1.1-B — Tabelas (núcleo)
-- Seguro, diligente e não disruptivo: apenas criação de tabelas novas no schema public,
-- RLS habilitada (sem policies ainda) e gatilhos de updated_at. Sem alterações em objetos existentes.

SET search_path TO public;
SET statement_timeout TO '5min';
SET lock_timeout TO '1min';
SET idle_in_transaction_session_timeout TO '2min';
SET check_function_bodies = off;

-- Garantir extensão para UUIDs disponível (idempotente)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1) users (internos)
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  role text NOT NULL,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 2) vendors
CREATE TABLE IF NOT EXISTS public.vendors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  cnpj_tax_id text,
  email text,
  phone text,
  address text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.vendors
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 3) skus
CREATE TABLE IF NOT EXISTS public.skus (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sku_code text NOT NULL UNIQUE,
  description text,
  family text,
  image_url text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.skus ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.skus
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 4) sku_vendors
CREATE TABLE IF NOT EXISTS public.sku_vendors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sku_id uuid NOT NULL REFERENCES public.skus(id) ON DELETE RESTRICT,
  vendor_id uuid NOT NULL REFERENCES public.vendors(id) ON DELETE RESTRICT,
  moq_min integer,
  lead_time_days integer,
  currency text,
  incoterm text,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.sku_vendors ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.sku_vendors
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 5) sku_vendor_files
CREATE TABLE IF NOT EXISTS public.sku_vendor_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sku_vendor_id uuid NOT NULL REFERENCES public.sku_vendors(id) ON DELETE RESTRICT,
  file_path text NOT NULL,
  file_kind text,
  version integer NOT NULL DEFAULT 1,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.sku_vendor_files ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.sku_vendor_files
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 6) rfqs
CREATE TABLE IF NOT EXISTS public.rfqs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sku_id uuid NOT NULL REFERENCES public.skus(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  deadline timestamptz,
  status text,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.rfqs ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.rfqs
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 7) rfq_vendors
CREATE TABLE IF NOT EXISTS public.rfq_vendors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rfq_id uuid NOT NULL REFERENCES public.rfqs(id) ON DELETE RESTRICT,
  vendor_id uuid NOT NULL REFERENCES public.vendors(id) ON DELETE RESTRICT,
  status text,
  opened_at timestamptz,
  responded_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_rfq_vendor UNIQUE (rfq_id, vendor_id)
);
ALTER TABLE public.rfq_vendors ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.rfq_vendors
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 8) rfq_vendor_quotes
CREATE TABLE IF NOT EXISTS public.rfq_vendor_quotes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rfq_vendor_id uuid NOT NULL REFERENCES public.rfq_vendors(id) ON DELETE RESTRICT,
  qty_range text NOT NULL,
  unit_price numeric(12,4) NOT NULL,
  notes text,
  production_date date,
  delivery_date date,
  currency text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.rfq_vendor_quotes ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.rfq_vendor_quotes
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 9) threads
CREATE TABLE IF NOT EXISTS public.threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rfq_vendor_id uuid NOT NULL REFERENCES public.rfq_vendors(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  subject text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.threads ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.threads
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 10) thread_messages
CREATE TABLE IF NOT EXISTS public.thread_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL REFERENCES public.threads(id) ON DELETE RESTRICT,
  author_type text NOT NULL,
  author_id uuid NOT NULL,
  content text NOT NULL,
  file_path text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.thread_messages ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.thread_messages
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 11) invoices
CREATE TABLE IF NOT EXISTS public.invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rfq_vendor_id uuid NOT NULL REFERENCES public.rfq_vendors(id) ON DELETE RESTRICT,
  vendor_invoice_number text,
  file_path text,
  parsed_json jsonb,
  ai_flags text[],
  ai_score numeric(5,2),
  status text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.invoices
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 12) purchase_orders
CREATE TABLE IF NOT EXISTS public.purchase_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rfq_vendor_id uuid NOT NULL REFERENCES public.rfq_vendors(id) ON DELETE RESTRICT,
  cin7_po_id text,
  status text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.purchase_orders ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.purchase_orders
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 13) purchase_order_lines
CREATE TABLE IF NOT EXISTS public.purchase_order_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id uuid NOT NULL REFERENCES public.purchase_orders(id) ON DELETE RESTRICT,
  sku_id uuid NOT NULL REFERENCES public.skus(id) ON DELETE RESTRICT,
  qty numeric(12,3) NOT NULL CHECK (qty >= 0),
  unit_price numeric(12,4) NOT NULL CHECK (unit_price >= 0),
  currency text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.purchase_order_lines ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.purchase_order_lines
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 14) activities
CREATE TABLE IF NOT EXISTS public.activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  action text NOT NULL,
  actor_type text NOT NULL,
  actor_id uuid,
  timestamp timestamptz NOT NULL DEFAULT now(),
  details_json jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.activities
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- 15) notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  vendor_id uuid,
  type text NOT NULL,
  payload_json jsonb,
  read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.notifications
FOR EACH ROW EXECUTE PROCEDURE public.set_updated_at();

-- Observações:
-- - Nenhuma policy foi criada aqui; acesso permanece negado por padrão (seguro) para roles regulares.
-- - Policies específicas por tabela serão adicionadas na subfase F1.1-E.
-- - Índices secundários serão adicionados em F1.1-C.
