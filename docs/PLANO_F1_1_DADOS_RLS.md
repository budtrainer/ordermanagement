# Plano F1.1 — Modelagem de dados e RLS (núcleo)

Este documento descreve, em fases bem definidas e exaustivas, a execução da F1.1, com foco em modelagem de dados e políticas de Row Level Security (RLS) no Supabase/Postgres. A sequência foi pensada para ser super segura, diligente e inteligente, sem mudanças disruptivas na arquitetura atual, mantendo integridade e funcionamento do sistema.

---

## Contexto e Objetivo

- Criar o núcleo de tabelas, FKs, índices e policies RLS para sustentar RFQ → Cotação → Negociação/Aprovação → Invoice (IA mínima) → PO no CIN7.
- Garantir que fornecedores (papel `vendor`) só acessem dados do próprio escopo via `vendor_id` presente no JWT.
- Preparar seeds mínimos e migrações reversíveis para permitir rollback rápido.

## Princípios

- Ativar RLS por padrão e ser explícito em cada policy.
- Policies simples e verificáveis (preferir condição única por tabela, com helpers quando necessário).
- Nunca expor `service_role` no cliente (somente no servidor/API e Functions internas).
- Migrações sempre reversíveis; sem alterações destrutivas sem backup/export prévio.

## Escopo (incluído nesta fase)

- Criação das tabelas centrais conforme PRD (núcleo para RFQ, Quotes, Threads, Invoices, POs, Activities).
- Índices essenciais para consultas previstas.
- Policies RLS iniciais para leituras/escritas mais comuns.
- Seeds mínimos de teste (DEV) para validação manual.

## Fora de escopo (mover para fases seguintes)

- Telas e endpoints de CRUD completos (F1.5+).
- Hardening amplo de segurança/performance (F1.14).
- Integrações completas (CIN7 PO e OCR detalhado) — apenas requisitos de dados aqui.

---

## Sequência (subfases)

### F1.1-A — Preparação de migrações e padrões

- Criar migração inicial `supabase/migrations/<timestamp>_f11_core.sql`.
- Declarar `SET check_function_bodies = off;` e `SET statement_timeout = '5min';` (defensivo).
- Ativar RLS por padrão nas tabelas que criaremos.
- Padrão de timestamps: `created_at TIMESTAMPTZ NOT NULL DEFAULT now()`, `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` + trigger `UPDATED_AT` (opcional nesta fase, pode ficar para F1.14 se preferir simplicidade).

### F1.1-B — Tabelas (núcleo)

Criar tabelas com o mínimo necessário para o fluxo MVP (nomes e campos alinhados ao PRD):

- `users` (internos) {id uuid pk, name, email unique, role text, active bool, created_at}
- `vendors` {id uuid pk, name, cnpj_tax_id, email, phone, address, active bool, created_at}
- `skus` {id uuid pk, sku_code unique, description, family, image_url, active bool, created_at}
- `sku_vendors` {id uuid pk, sku_id fk, vendor_id fk, moq_min int, lead_time_days int, currency text, incoterm text, active bool, created_at}
- `sku_vendor_files` {id uuid pk, sku_vendor_id fk, file_path text, file_kind text, version int, active bool, created_at}
- `rfqs` {id uuid pk, sku_id fk, created_by uuid, deadline timestamptz, status text, notes text, created_at}
- `rfq_vendors` {id uuid pk, rfq_id fk, vendor_id fk, status text, opened_at timestamptz, responded_at timestamptz, created_at}
- `rfq_vendor_quotes` {id uuid pk, rfq_vendor_id fk, qty_range text, unit_price numeric(12,4), notes text, production_date date, delivery_date date, currency text, created_at}
- `threads` {id uuid pk, rfq_vendor_id fk, created_by uuid, subject text, created_at}
- `thread_messages` {id uuid pk, thread_id fk, author_type text, author_id uuid, content text, file_path text null, created_at}
- `invoices` {id uuid pk, rfq_vendor_id fk, vendor_invoice_number text, file_path text, parsed_json jsonb, ai_flags text[], ai_score numeric(5,2), status text, created_at}
- `purchase_orders` {id uuid pk, rfq_vendor_id fk, cin7_po_id text, status text, created_at, updated_at}
- `purchase_order_lines` {id uuid pk, purchase_order_id fk, sku_id fk, qty numeric(12,3), unit_price numeric(12,4), currency text, created_at}
- `activities` {id uuid pk, entity_type text, entity_id uuid, action text, actor_type text, actor_id uuid, timestamp timestamptz, details_json jsonb}
- `notifications` {id uuid pk, user_id uuid null, vendor_id uuid null, type text, payload_json jsonb, read bool default false, created_at}

Notas:

- Usar `uuid_generate_v4()` (ou `gen_random_uuid()`) conforme extensão disponível no projeto.
- Manter `status` como `text` nesta fase (enums ficam para F1.14 caso necessário endurecer valores).

### F1.1-C — Índices essenciais

- `rfqs`: `(sku_id, status)` → `idx_rfqs_sku_status`
- `rfq_vendors`: `(rfq_id, status)` → `idx_rfq_vendors_status`
- `activities`: `(entity_type, entity_id)` → `idx_activities_entity`
- `purchase_order_lines`: `(purchase_order_id)`
- `sku_vendors`: `(sku_id, vendor_id)` unique parcial quando `active = true` (opcional)

### F1.1-D — Helpers de segurança (claims)

- Premissa: JWT contém `role` e, para fornecedores, `vendor_id`.
- Sem criar funções complexas: usar diretamente `auth.jwt() ->> 'role'` e `auth.jwt() ->> 'vendor_id'` nas policies.

### F1.1-E — RLS: políticas iniciais (por tabela)

Habilitar RLS e criar policies. Exemplos (ajustar nomes conforme migração):

```sql
-- RFQs: internos (admin/buyer/finance/reader) podem ler; vendor lê apenas via junção com rfq_vendors
ALTER TABLE rfqs ENABLE ROW LEVEL SECURITY;
CREATE POLICY rfqs_read_internal ON rfqs
  FOR SELECT TO authenticated
  USING ( (auth.jwt() ->> 'role') IN ('admin','buyer','finance','reader') );

-- rfq_vendors: vendor só lê linhas do seu vendor_id; internos leem tudo
ALTER TABLE rfq_vendors ENABLE ROW LEVEL SECURITY;
CREATE POLICY rfq_vendors_read_internal ON rfq_vendors
  FOR SELECT TO authenticated
  USING ( (auth.jwt() ->> 'role') IN ('admin','buyer','finance','reader') );
CREATE POLICY rfq_vendors_read_vendor ON rfq_vendors
  FOR SELECT TO authenticated
  USING ( (auth.jwt() ->> 'role') = 'vendor' AND vendor_id::text = (auth.jwt() ->> 'vendor_id') );

-- thread_messages: vendor só acessa threads ligadas ao seu rfq_vendor; internos leem todas
ALTER TABLE thread_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY thread_messages_read_internal ON thread_messages
  FOR SELECT TO authenticated
  USING ( (auth.jwt() ->> 'role') IN ('admin','buyer','finance','reader') );
CREATE POLICY thread_messages_read_vendor ON thread_messages
  FOR SELECT TO authenticated
  USING (
    (auth.jwt() ->> 'role') = 'vendor' AND EXISTS (
      SELECT 1 FROM threads t
      JOIN rfq_vendors rv ON rv.id = t.rfq_vendor_id
      WHERE t.id = thread_id AND rv.vendor_id::text = (auth.jwt() ->> 'vendor_id')
    )
  );

-- purchase_orders: leitura restrita (vendor só as suas; internos todas)
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY po_read_internal ON purchase_orders
  FOR SELECT TO authenticated
  USING ( (auth.jwt() ->> 'role') IN ('admin','buyer','finance','reader') );
CREATE POLICY po_read_vendor ON purchase_orders
  FOR SELECT TO authenticated
  USING (
    (auth.jwt() ->> 'role') = 'vendor' AND EXISTS (
      SELECT 1 FROM rfq_vendors rv WHERE rv.id = purchase_orders.rfq_vendor_id
      AND rv.vendor_id::text = (auth.jwt() ->> 'vendor_id')
    )
  );

-- writes mínimos (exemplos): vendor pode inserir mensagem na própria thread
CREATE POLICY thread_messages_insert_vendor ON thread_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    (auth.jwt() ->> 'role') = 'vendor' AND EXISTS (
      SELECT 1 FROM threads t
      JOIN rfq_vendors rv ON rv.id = t.rfq_vendor_id
      WHERE t.id = thread_id AND rv.vendor_id::text = (auth.jwt() ->> 'vendor_id')
    )
  );

-- internos podem inserir/alterar RFQs, RFQ_VENDORS, etc. (escopo admin/buyer/finance conforme necessidade)
CREATE POLICY rfqs_write_internal ON rfqs
  FOR INSERT TO authenticated
  WITH CHECK ( (auth.jwt() ->> 'role') IN ('admin','buyer') );
```

Observações:

- Aplicar o mesmo padrão a `invoices`, `purchase_order_lines`, `sku_vendor_files` (vendor lê apenas as suas, internos todas; insert/update por papéis internos; vendor só escreve onde fizer sentido — ex.: enviar invoice/QA mais adiante).
- Policies de UPDATE/DELETE podem ser adicionadas de forma incremental, evitando superfície de risco.

### F1.1-F — Seeds mínimos (DEV)

- 1 `sku`, 2 `vendors`, 1 relação `sku_vendors`, 1 `rfq` com 2 `rfq_vendors`, 1 `thread` e 1 `message`.
- Objetivo: validar rapidamente permissões de leitura e escrita.

### F1.1-G — Validação e testes (SQL)

Checklist prático (usar tokens com claims simuladas ou `SET` de JWT conforme suporte):

- Interno `buyer`: SELECT em `rfqs`, `rfq_vendors`, `thread_messages` deve retornar todas as linhas.
- Vendor (claim `role=vendor`, `vendor_id=<id>`):
  - SELECT em `rfq_vendors` retorna apenas suas linhas.
  - SELECT em `thread_messages` retorna apenas mensagens das suas threads.
  - INSERT em `thread_messages` com `thread_id` da sua RFQ deve passar; de outra RFQ deve negar.
- Tentativas de escrita fora do escopo devem ser bloqueadas (403/denied) e registradas nos logs da API.

### F1.1-H — Rollout e rollback

- Rollout: aplicar migração em DEV, validar checklist; somente após validação, marcar tarefa como concluída.
- Rollback: migração reversível remove tables/policies criadas por esta fase. Alternativa: desabilitar policies específicas via `DROP POLICY` e `ALTER TABLE ... DISABLE ROW LEVEL SECURITY` (DEV apenas) para recuperar acesso temporariamente.

---

## Entregáveis

- Migração SQL em `supabase/migrations/<timestamp>_f11_core.sql` (tabelas, FKs, índices, policies RLS).
- Seeds em `supabase/seed/<timestamp>_f11_seed.sql` (DEV).
- Documento: este plano `docs/PLANO_F1_1_DADOS_RLS.md`.

## Critérios de aceite

- Policies RLS confirmadas via testes SQL: vendor enxerga apenas seu escopo; internos enxergam o necessário por papel.
- Seeds carregam e permitem a execução dos testes de permissão.
- API local continua funcionando sem erros (rota `/health` e futuras), sem quebra de integridade.

## Riscos & Mitigações

- RLS excessivamente permissiva → checklist de testes por tabela + revisão a 4 olhos.
- Deadlocks ou performance ruim → índices essenciais criados; monitorar planos de consulta.
- Campos obrigatórios faltando → começar minimalista e evoluir com migrações adicionais.

## Plano de comunicação

- Registrar resumo de mudanças no `README` (se necessário) e no changelog do repositório.
- PR com descrição "What/Why/How" e plano de rollback.

## Timeline sugerida

- D1: Migração base (tabelas/FKs/índices) + RLS para leitura.
- D2: Policies de escrita mínimas + Seeds.
- D3: Validação, ajustes finos e documentação final.

---

## Anexos e referências

- `docs/prd_order_management_supplier_portal_cin_7_only_supabase.md`
- `docs/arquitetura.md`
- `docs/PLANO_FASE1_MVP.md`
- `docs/PLANO_F1_0_FUNDACOES.md`
