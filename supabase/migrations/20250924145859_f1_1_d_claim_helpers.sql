-- F1.1-D — Helpers de segurança (claims)
-- Seguro, diligente e não disruptivo: apenas funções utilitárias para ler claims do JWT.
-- Policies continuarão a usar auth.jwt() diretamente ou estes helpers, a critério das próximas subfases.

SET search_path TO public;
SET statement_timeout TO '5min';
SET lock_timeout TO '1min';
SET idle_in_transaction_session_timeout TO '2min';
SET check_function_bodies = off;

-- Helpers mínimos, estáveis e idempotentes
-- Retorna o papel atual a partir do JWT ("", se ausente)
CREATE OR REPLACE FUNCTION public.current_role()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(auth.jwt() ->> 'role', '')::text;
$$;
COMMENT ON FUNCTION public.current_role IS 'Retorna o claim role do JWT atual (text; vazio se ausente).';

-- Retorna o vendor_id atual (UUID) a partir do JWT (NULL se ausente)
CREATE OR REPLACE FUNCTION public.current_vendor_id()
RETURNS uuid
LANGUAGE sql
STABLE
AS $$
  SELECT NULLIF(auth.jwt() ->> 'vendor_id', '')::uuid;
$$;
COMMENT ON FUNCTION public.current_vendor_id IS 'Retorna o claim vendor_id do JWT atual (uuid; NULL se ausente).';

-- Conveniências para policies simples
CREATE OR REPLACE FUNCTION public.is_vendor()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT public.current_role() = 'vendor';
$$;
COMMENT ON FUNCTION public.is_vendor IS 'Retorna true se o claim role do JWT é vendor.';

CREATE OR REPLACE FUNCTION public.is_internal()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT public.current_role() IN ('admin','buyer','finance','reader');
$$;
COMMENT ON FUNCTION public.is_internal IS 'Retorna true se o claim role do JWT é um dos papéis internos.';

-- Observações:
-- - Nenhuma tabela/policy alterada aqui.
-- - Próxima subfase (F1.1-E) poderá usar estes helpers para legibilidade, ou manter auth.jwt() inline.
