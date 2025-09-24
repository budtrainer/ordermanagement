-- F1.2 — Auth & RBAC (helpers de claims reforçados + view de debug)
-- Seguro e não disruptivo: redefine funções utilitárias e cria uma view de debug.
-- Não altera tabelas nem policies nesta subfase.

SET search_path TO public;
SET statement_timeout TO '5min';
SET lock_timeout TO '1min';
SET idle_in_transaction_session_timeout TO '2min';
SET check_function_bodies = off;

-- current_role(): lê de claim top-level, app_metadata.role e user_metadata.role
CREATE OR REPLACE FUNCTION public.current_role()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    auth.jwt() ->> 'role',
    (auth.jwt() -> 'app_metadata') ->> 'role',
    (auth.jwt() -> 'user_metadata') ->> 'role',
    ''
  );
$$;
COMMENT ON FUNCTION public.current_role IS 'Retorna o role do JWT (top-level/app_metadata/user_metadata); vazio se ausente.';

-- current_vendor_id(): tenta extrair vendor_id e converter com segurança para uuid
CREATE OR REPLACE FUNCTION public.current_vendor_id()
RETURNS uuid
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v text;
  u uuid;
BEGIN
  v := COALESCE(
    auth.jwt() ->> 'vendor_id',
    (auth.jwt() -> 'app_metadata') ->> 'vendor_id',
    (auth.jwt() -> 'user_metadata') ->> 'vendor_id'
  );

  IF v IS NULL OR v = '' THEN
    RETURN NULL;
  END IF;

  BEGIN
    u := v::uuid;
    RETURN u;
  EXCEPTION WHEN others THEN
    RETURN NULL;
  END;
END;
$$;
COMMENT ON FUNCTION public.current_vendor_id IS 'Retorna vendor_id do JWT (top-level/app_metadata/user_metadata) como uuid; NULL se inválido/ausente.';

-- is_vendor() e is_internal() baseados no current_role() reforçado
CREATE OR REPLACE FUNCTION public.is_vendor()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT public.current_role() = 'vendor';
$$;
COMMENT ON FUNCTION public.is_vendor IS 'True se role=vendor (considerando metadados).';

CREATE OR REPLACE FUNCTION public.is_internal()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT public.current_role() IN ('admin','buyer','finance','reader');
$$;
COMMENT ON FUNCTION public.is_internal IS 'True para papéis internos (considerando metadados).';

-- View de debug (DEV): inspecionar claims correntes
CREATE OR REPLACE VIEW public.debug_current_claims AS
SELECT
  current_setting('request.jwt.claims', true) AS raw_claims,
  public.current_role() AS role,
  public.current_vendor_id() AS vendor_id;

COMMENT ON VIEW public.debug_current_claims IS 'DEV-ONLY: inspeção de claims correntes; remover/desabilitar em produção se necessário.';
