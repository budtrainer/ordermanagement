# PRD — Order Management & Supplier Portal (CIN7-only, Supabase)

> **Produto**: SaaS de gestão de pedidos para suprimentos (Order Management) com **portal do fornecedor**
> **Integrações externas**: **única** integração com **CIN7** (Core/DEAR) para estoque, POs e anexos
> **Stack base**: Front-end web (React/Next.js), Back-end (Node/TypeScript ou Deno), **Supabase** (Auth + Postgres + Storage + Edge Functions).
> **Público-alvo primário**: Compradores/Operações (BudTrainer/BudPots). **Secundário**: Fornecedores (FocusBox, HB Baiger, etc.).
> **Linguagem/UI**: pt-BR, time zone default America/Sao_Paulo.

---

## 1) Visão geral

Centralizar todo o ciclo de compras por SKU em um único sistema — da **RFQ** ao **envio de invoice**, **negociação/aprovação**, **criação de PO** no CIN7 e **gestão de QAs** — com UX limpa e profissional, eliminando dependências de Slack/Sheets/Drive.

**Objetivos-chave:**
- **Uma só tela** para planejar pedidos por **SKU** com **estoque realtime do CIN7**.
- **RFQ** multi-fornecedor com histórico, anexos e prazos.
- **Portal do fornecedor** com login/link seguro para **cotação**, **observações**, **datas de produção/entrega**, **invoice** e **QAs**.
- **Negociação e aprovação** com trilha de auditoria.
- **Criação de PO no CIN7** (com preços/quantidades e anexos) após **IA pré-validação** + **validação humana**.
- **Supabase Storage** para todos os arquivos (templates, specs, QAs, invoices).
- **Dashboard operacional** com status, SLAs e alertas.

**Fora de escopo (MVP):** pagamentos ao fornecedor, reconciliação bancária, logística internacional, previsão de demanda.

---

## 2) Personas & papéis

- **Comprador/Operações (interno)**: seleciona SKU, define fornecedores-alvo, dispara RFQ, negocia, aprova, cria PO.
- **Financeiro/AP (interno)**: valida invoice, libera criação de PO, anexa documentos, controla conformidade.
- **Administrador (interno)**: gerencia SKUs, fornecedores, listas de templates por SKU→Fornecedor, permissões e integrações.
- **Fornecedor (externo)**: recebe link/convite, acessa portal, envia **cotações**, **observações**, **datas**, **invoices** e **QAs**, acompanha status.

**RBAC (níveis):** Admin, Comprador, Financeiro/AP, Leitor, Fornecedor (escopo restrito ao próprio vendor).

---

## 3) Fluxos principais (end-to-end)

### 3.1 Seleção de SKU e planejamento
1. Usuário interno acessa **Catálogo** → busca/filtra SKUs (código, família, marca, status).
2. Sistema traz **estoque em tempo real** (CIN7) e **consumo médio** (se disponível no futuro) para contexto de decisão.
3. Usuário clica **“Gerar RFQ”** para o SKU; sistema lista **fornecedores habilitados** para aquele SKU (configurado em Cadastros) e respectivos **templates/arquivos** vinculados.

### 3.2 RFQ multi-fornecedor
1. Usuário seleciona fornecedores (ex.: FocusBox e HB Baiger), define **quantidades por faixa** (ex.: 5k, 10k, 20k), prazo desejado, incoterm (opcional) e anexa templates do Supabase Storage (checklist de QA, labels, specs, etc.).
2. Sistema gera **RFQ** e envia **convite via e-mail** com **link seguro** para o **portal do fornecedor** (token expira; opção de criar senha na primeira visita).
3. RFQ fica em status **“Enviado”** com **deadline**; painel mostra **quem abriu** e **quem respondeu**.

### 3.3 Portal do fornecedor — cotação
1. Fornecedor abre link → vê **histórico de pedidos** daquele SKU e **RFQ atual**.
2. Fornecedor informa **preços unitários** por quantidade; adiciona **observações**; preenche **data de produção** e **data de entrega**.
3. Fornecedor pode **fazer upload** de anexos relevantes (ex.: planilha de custos, certificações). Tudo armazenado no **Supabase Storage**.
4. Ao submeter, status da resposta vira **“Cotação recebida”** (com carimbo de data e usuário), e comprador é notificado.

### 3.4 Negociação e aprovação
1. Na tela da RFQ, comprador compara cotações (tabela por faixa de quantidade, lead time, observações).
2. Comprador abre **“Sala de negociação”** (thread) com o fornecedor para ajustes de preço/prazo.
3. Quando convergir, comprador clica **“Aprovar cotação”** → sistema marca status **“Aprovada”** e dispara uma **confirmação** ao fornecedor.

### 3.5 Invoice e criação de PO (CIN7)
1. Fornecedor acessa o mesmo portal e **faz upload da Invoice** (PDF/Imagem), além de confirmar **quantidade final & preço unitário**.
2. **IA de pré-validação** extrai campos (número da invoice, supplier, SKU, quantidade, preço unitário, moeda, datas) e sinaliza **discrepâncias** (ex.: divergência > X%).
3. **Validação humana** (Financeiro/AP) revisa a sugestão da IA e confirma.
4. Sistema **cria/atualiza a Purchase Order no CIN7**, com **linha(s) do SKU** e **anexo da Invoice/QAs** (quando aplicável).
5. Status da RFQ/pedido passa para **“PO criada (CIN7)”**. Fornecedor recebe confirmação.

### 3.6 QAs
1. Para SKUs que exigem QA, o fornecedor pode **subir o PDF de QA** no portal (vinculado à **PO** específica).
2. Sistema anexa o QA à PO no CIN7 e atualiza status **“QA anexado”**.

---

## 4) Requisitos funcionais (MVP)

### 4.1 Catálogo de SKUs
- **Listar/buscar** SKUs (código, descrição, família, status, imagem).
- Exibir **estoque em tempo real** vindo do CIN7 (quantidade disponível/em produção/em trânsito).
- Ação **“Gerar RFQ”** por SKU.

**Aceite:**
- Dado um SKU cadastrado e integração com CIN7 ativa, ao acessar o catálogo deve exibir o estoque em ≤ 2s após resposta do CIN7.

### 4.2 Cadastros (Admin)
- **Fornecedores**: nome, e-mail(s), CNPJ/Tax ID, endereço, contatos, condições padrão, ativos/inativos.
- **SKU ↔ Fornecedor**: relação N:N com campos: mínimo de pedido, MOQs por faixa, lead time padrão, moeda, incoterm preferido.
- **Templates por SKU→Fornecedor**: lista de **arquivos** (Supabase Storage) a anexar automaticamente na RFQ.

**Aceite:**
- Admin consegue adicionar/remover fornecedor de um SKU e anexar/remover templates.

### 4.3 RFQ
- Criar RFQ para 1 SKU com 1+ fornecedores; suportar **faixas de quantidade**.
- Gerar **convites** ao portal do fornecedor (e-mail + link seguro).
- Mostrar **timeline** (enviado, aberto, respondido, prazo vencendo/vencido).
- Permitir **cancelar/reemitir** RFQ.

**Aceite:**
- Envio de RFQ registra evento e gera convite com expiração configurável (default 7 dias).

### 4.4 Portal do Fornecedor
- Login por **magic link** (token) e/ou senha. Escopo restrito ao **próprio vendor**.
- Tela de RFQ: campos de **preço por quantidade**, **observações**, **datas** (produção/entrega), **upload de anexos**.
- Histórico de RFQs e POs daquele fornecedor/sku.
- Upload de **Invoice** e **QA** após aprovação.

**Aceite:**
- Fornecedor consegue submeter cotação e depois invoice/QA, tudo fica visível no lado interno com timestamps.

### 4.5 Negociação & Aprovação
- Thread de **mensagens contextualizadas** por RFQ (interno↔fornecedor) com anexo e marcação de pessoas (interno apenas).
- Ação **“Aprovar cotação”** (bloqueia edição da cotação e notifica fornecedor).

**Aceite:**
- Ao aprovar, status muda para **“Aprovada”** e registro fica imutável (apenas nova rodada via “Reabrir negociação”).

### 4.6 Invoice com IA + PO no CIN7
- **Upload de invoice** pelo fornecedor.
- **OCR/extração** (IA) e **validação automática** (regras: divergência %, moeda, impostos, numeração).
- **Validação humana** (Financeiro/AP) com diff destacado e botão **“Criar/Atualizar PO no CIN7”**.
- **Anexar** invoice (e QA, se houver) na PO do CIN7.

**Aceite:**
- Ao aprovar, sistema cria/atualiza PO no CIN7 com as linhas corretas (SKU, qty, unit price) e anexa invoice; retorno de sucesso exibido.

### 4.7 Dashboard
- Lista de **pedidos por status**: RFQ enviado, aguardando cotação, cotação recebida, negociação, aprovada, invoice pendente, em validação IA, aguardando validação humana, PO criada (CIN7), QA pendente/anexado.
- Filtros: SKU, fornecedor, status, prazo, responsável.
- KPIs: lead time médio de resposta, taxa de resposta por fornecedor, variação de preço por lote.

**Aceite:**
- Grids com paginação/busca; clique abre **detalhe do pedido** (RFQ/negociação/invoice/PO/QA).

### 4.8 Notificações & SLAs
- E-mail e in-app para: RFQ enviada, cotação recebida, prazo em 24h, aprovação, invoice recebida, IA sinalizou divergência, PO criada, QA pendente>7 dias.
- Preferências por usuário (quais eventos e frequência).

**Aceite:**
- Eventos disparam notificações configuráveis; log auditável em “Atividade”.

### 4.9 Auditoria & Logs
- Registro de **quem fez o quê e quando** (CRUD, aprovações, integrações, anexos).
- Exportação CSV por período.

---

## 5) Integração com CIN7 (única integração externa)

**Casos de uso (MVP):**
1. **Consulta de estoque por SKU** (on-demand no Catálogo e cache transitório ≤ 10 min).
2. **Criação/atualização de Purchase Orders** com linhas (SKU, qty, unit price, supplier, datas previstas).
3. **Anexos na PO**: invoice (PDF) e QA (PDF) — upload após criação da PO.

**Estratégia técnica:**
- **Edge Function** no Supabase para orquestrar chamadas ao CIN7 com **retries/backoff** e **ratelimiting**.
- **Secrets** de API guardadas no **Supabase Vault/Config**.
- **Webhooks** (se disponíveis) para sincronizar status; se não, **polling** incremental (marca d’água por updatedAt).
- **Mapeamento** SKU local ↔ SKU no CIN7 (chave única).

**Erros & Resiliência:**
- Se falhar criação de PO, manter estado **“Erro de integração”** com botão **“Tentar novamente”**.
- Logs granulares com payload/responseID mascarados (sem dados sensíveis).

---

## 6) Modelagem de dados (Supabase / Postgres)

### 6.1 Entidades principais
- **users** (internos) {id, nome, e-mail, role, ativo}
- **vendors** {id, nome, cnpj_tax_id, email_principal, fone, endereco, ativo}
- **skus** {id, sku_code, descricao, familia, imagem_url, ativo}
- **sku_vendors** {id, sku_id, vendor_id, moq_min, lead_time_padrao_dias, moeda, incoterm, ativo}
- **sku_vendor_files** {id, sku_vendor_id, file_path, tipo (spec/label/qa/checklist/outros), versao, ativo}
- **rfqs** {id, sku_id, criado_por, deadline, status, observacoes}
- **rfq_vendors** {id, rfq_id, vendor_id, status (enviado/recebido/negociacao/aprovado/reprovado), opened_at, responded_at}
- **rfq_vendor_quotes** {id, rfq_vendor_id, faixa_qty, unit_price, obs, data_producao, data_entrega, currency}
- **threads** {id, rfq_vendor_id, created_by, assunto}
- **thread_messages** {id, thread_id, author_type (interno/vendor), author_id, conteudo, file_path?, created_at}
- **invoices** {id, rfq_vendor_id, vendor_invoice_number, file_path, parsed_json, ai_flags, ai_score, status (em_validacao/aprovada/reprovada)}
- **purchase_orders** {id, rfq_vendor_id, cin7_po_id, status, created_at, updated_at}
- **purchase_order_lines** {id, purchase_order_id, sku_id, qty, unit_price, currency}
- **qas** {id, purchase_order_id, file_path, status}
- **activities** {id, entity_type, entity_id, action, actor_id/actor_type, timestamp, details_json}
- **notifications** {id, user_id?, vendor_id?, tipo, payload_json, lida}

### 6.2 Regras & integridade
- `rfq_vendor_quotes` exige pelo menos uma faixa de quantidade por resposta.
- `purchase_orders` vinculadas a **rfq_vendor_id** aprovado.
- `sku_vendor_files` carregados no **Supabase Storage** com versionamento simples (campo `versao`).

---

## 7) UX/UI — navegação e telas

**Padrões de design**: layout com **barra lateral** (Dashboard, Catálogo, RFQs, Fornecedores, Cadastros, Configurações). Tabelas com filtros persistentes, botões primários claros, estados vazios pedagógicos, feedbacks de sucesso/erro e skeletons.

### 7.1 Dashboard
- Cards de KPIs (RFQs abertas, prazo 24h, negociações ativas, POs criadas semana, QAs pendentes).
- Tabela “Minha fila” (itens onde sou responsável) com ações rápidas.

### 7.2 Catálogo de SKUs
- Grid com foto, SKU, descrição, estoque (realtime do CIN7), botão **“Gerar RFQ”**.
- Drawer lateral com detalhes e histórico de compras por SKU.

### 7.3 Criar RFQ
- Form: fornecedores sugeridos (checkbox), faixas de quantidade (linha a linha), deadline, anexos pré-carregados (lista de templates do `sku_vendor_files`, com possibilidade de incluir outros arquivos do Storage), notas internas.
- Review step → **Enviar**.

### 7.4 RFQ — Detalhe
- Abas: **Resumo** (status por fornecedor), **Cotações** (comparativo), **Negociação** (thread), **Arquivos** (templates), **Linha do tempo** (auditoria).
- Ações por fornecedor: **Lembrar** (reenvio), **Negociar**, **Aprovar cotação**.

### 7.5 Portal do Fornecedor
- Página de RFQ: boxes para **preço por faixa**, **datas**, **observações**, **upload**; validações inline e botão **Enviar cotação**.
- Após aprovação: seção **Invoice & QA** para upload + status da PO.

### 7.6 Validação de Invoice (IA)
- Tela com **PDF à esquerda** e **campos extraídos à direita** (comparação vs. cotação aprovada). Destaque de divergências. Botões **Aprovar** / **Reprovar**.

### 7.7 PO & QA
- Após aprovação, botão **“Criar/Atualizar PO no CIN7”**; mostra resultado (PO ID). Aba **Anexos** com invoice e QA e status de sincronização.

---

## 8) Requisitos não-funcionais
- **Performance**: TTFB < 300ms (backend), páginas < 2s em 4G.
- **Disponibilidade**: 99,5% (MVP).
- **Segurança**: RBAC, **links de fornecedor com expiração**, 2FA opcional para internos, criptografia em trânsito/repouso, logs de auditoria.
- **Privacidade**: mínimo de dados pessoais de fornecedores; consentimento para e-mails.
- **Observabilidade**: logs estruturados, métricas (latência, erros), tracing básico para integrações.

---

## 9) IA de pré-validação de Invoice (MVP)
- **Extração**: número da invoice, fornecedor, SKU(s), quantidade(s), preço(s), moeda, datas.
- **Regras**:
  - Divergência de unit price > X% → **flag**.
  - Moeda diferente da cotação → **flag**.
  - Qty > aprovado → **flag**.
  - Campos obrigatórios ausentes → **flag**.
- **Saída**: `parsed_json`, `ai_flags`, `ai_score`.
- **Fallback**: se OCR falhar, informar usuário e exigir revisão manual.

---

## 10) Métricas & KPIs
- % de RFQs respondidas dentro do prazo.
- Lead time RFQ (envio → resposta) e (resposta → aprovação).
- Variação média de preço por faixa de qty vs. histórico.
- % de invoices aprovadas sem ajuste após IA.
- Tempo médio até criação de PO no CIN7 após aprovação.
- % de QAs anexadas antes de produção/embarque.

---

## 11) Roadmap (alto nível)
- **Fase 0**: Configurações (CIN7 keys), Cadastros básicos (SKUs, Vendors, SKU→Vendor, Templates), Storage.
- **Fase 1 (MVP)**: Catálogo, RFQ, Portal do Fornecedor (cotação), Negociação, Aprovação, Invoice com IA, PO no CIN7, Dashboard básico, Notificações, Auditoria.
- **Fase 2**: QAs integradas ao fluxo, KPIs avançados, Webhooks CIN7, comentários com @menções internas.
- **Fase 3**: Multi-SKU por RFQ, simulação de custos/logística, analytics históricos.

---

## 12) Riscos & Mitigações
- **Adoção do fornecedor**: facilitar com **magic link**, mobile-first, suporte a anexos grandes, ajuda contextual.
- **Latência CIN7**: cache de estoque e retries com backoff.
- **Dados divergentes**: IA + validação humana obrigatória antes de PO.
- **Controle de versões de templates**: versionamento por `sku_vendor_files.versao` e aviso ao fornecedor na RFQ.

---

## 13) Critérios de aceite (E2E)
1. Dado um SKU com 2 fornecedores configurados, ao **criar RFQ** com 3 faixas de quantidade e enviar, ambos recebem e conseguem **submeter** preços/datas; sistema registra "Cotação recebida".
2. Ao entrar em **Negociação** e alterar preços, o histórico é preservado e fica auditável; ao **aprovar**, a resposta fica **imutável**.
3. Fornecedor sobe **invoice**, IA destaca divergência de 12% → usuário ajusta/recusa; em caso de aprovação, o sistema **cria a PO** no CIN7 com a linha correta (qty, unit price) e **anexa** a invoice.
4. Fornecedor sobe **QA** e o anexo aparece na **PO** no CIN7; status local muda para **QA anexado**.
5. O **Dashboard** exibe corretamente os contadores e filtros; um clique leva ao detalhe do pedido correspondente.

---

## 14) Itens de engenharia (resumo técnico)
- **Auth**: Supabase Auth (e-mail/password + magic link para vendors), sandboxes por tenant (se multi-empresa no futuro).
- **API interna**: REST/GraphQL; camadas: controllers → services → repos; validação Zod/TypeBox; OpenAPI para integração futura.
- **Jobs**: Edge Functions para CIN7 (polling/webhook), e-mails, lembretes (cron).
- **Storage**: buckets: `templates/`, `rfqs/`, `invoices/`, `qas/`.
- **CDN**: para arquivos públicos com assinatura curta (fornecedor) e privados (interno) com Signed URLs.
- **Security**: Row Level Security (Supabase) por tenant e por papel; rotas vendor separadas.

---

## 15) Perguntas em aberto
- Precisaremos de **multi-SKU por RFQ** no MVP ou pós-MVP?
- Moeda única (USD) no início? Precisamos de **câmbio**/multimoeda?
- Algum **workflow de aprovação interna** (ex.: alçadas por valor) antes de enviar RFQ ou criar PO?
- Padrão de **nomenclatura de arquivos** (invoice/QA) que o fornecedor deve seguir?
- **SLA** de resposta do fornecedor (ex.: 5 dias úteis) e lembretes automáticos?
- Necessidade de **campos fiscais** específicos (ex.: NCM, impostos) já no MVP?

---

## 16) Anexos (exemplos de UI)
- **Comparativo de cotações**: tabela por faixa (5k/10k/20k) × fornecedor, com destaque de melhor preço/lead time.
- **Validação de invoice**: split-view (PDF / campos) com diffs.
- **Timeline**: eventos de RFQ→PO com ícones e cores de status.

---

### Conclusão
Este PRD entrega um **SaaS focado e enxuto**, com **UX clara** e **operações controladas** em torno de um único elo externo (CIN7). O sistema substitui Slack/Sheets/Drive por fluxos nativos, reduzindo risco operacional e aumentando rastreabilidade, enquanto prepara terreno para evoluções (analytics, multi-SKU, automações adicionais).

