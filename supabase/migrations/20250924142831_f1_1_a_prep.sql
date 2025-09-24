-- F1.1-A — Preparação de migrações e padrões (seguro e não disruptivo)
-- Este arquivo configura padrões e helpers sem alterar tabelas existentes.
-- Pode ser aplicado em DEV com segurança; reversível sem efeitos colaterais.

-- Ajustes defensivos de sessão (não persistentes):
SET statement_timeout TO '5min';
SET lock_timeout TO '1min';
SET idle_in_transaction_session_timeout TO '2min';
SET check_function_bodies = off;

-- Extensão para UUIDs (recomendada pelo Supabase)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Helper genérico para updated_at (aplicado por tabela nas próximas subfases)
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.set_updated_at IS 'Trigger para atualizar coluna updated_at em UPDATE; aplicar por tabela quando criada (F1.1-B+).';

-- Observações:
-- - Nenhuma tabela foi criada/alterada aqui.
-- - Policies RLS serão adicionadas por tabela nas próximas subfases (F1.1-E).
-- - Seeds DEV virão em arquivo separado (F1.1-F).
