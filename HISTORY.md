# PedeAí — User Stories

> Formato: XP + Clean Architecture + TDD  
> Cada história segue o ciclo: **teste → implementação → refactor → commit**

---

## Legenda

- 🔴 Não iniciado
- 🟡 Em progresso
- ✅ Concluído
- 🔵 MVP obrigatório
- ⚪ Pós-MVP

---

## Sprint 0 — Fundação

> **Meta:** projeto rodando localmente e em produção antes de qualquer feature.

---

### S0-01 — Repositório e estrutura base 🔵 ✅

**Como** desenvolvedor,
**quero** um repositório configurado com a estrutura correta,
**para que** o projeto tenha uma base sólida desde o início.

**Critérios de aceitação:**

- [x] Repositório criado com branches `main` e `staging`
- [x] `.gitignore` configurado (node_modules, .env, **pycache**, .terraform)
- [x] `README.md` com instruções de setup local
- [x] Estrutura de pastas criada: `frontend/`, `backend/`, `infra/`, `docs/`
- [x] `CLAUDE.md` e `docs/PRD.md` commitados

**Tasks técnicas:**

- [x] `git init` + criar repo no GitHub
- [x] Configurar branch protection em `main` (requer PR)
- [x] Criar `docs/` com `PRD.md` e `STORIES.md`

---

### S0-02 — Infraestrutura via Terraform 🔵 ✅

**Como** desenvolvedor,
**quero** provisionar o servidor na AWS via Terraform,
**para que** a infraestrutura seja reproduzível e versionada.

**Critérios de aceitação:**

- [x] `terraform apply` cria a instância EC2 t3.micro em `us-east-1` sem erros
- [x] Elastic IP atribuído à instância (IP fixo que sobrevive a reboots)
- [x] Security Group configurado (portas 22, 80, 443)
- [x] Docker + Nginx + Certbot instalados via cloud-init
- [x] SSH funcional: `ssh ubuntu@<elastic_ip>`
- [ ] State armazenado remotamente no Terraform Cloud _(adiado para S0-04)_

**Tasks técnicas:**

- [x] Criar conta AWS e gerar Access Key + Secret Key com permissões EC2
- [x] Criar conta Terraform Cloud e configurar workspace `pedeai-infra`
- [x] Preencher `infra/terraform.tfvars` com credenciais
- [x] Rodar `terraform init && terraform apply`
- [x] Validar output: IP, comando SSH e próximos passos
- [x] Testar acesso SSH e confirmar Docker instalado (`docker --version`)

---

### S0-03 — Docker Compose local 🔵

**Como** desenvolvedor,  
**quero** subir todos os serviços localmente com um comando,  
**para que** o ambiente de desenvolvimento seja idêntico ao de produção.

**Critérios de aceitação:**

- [ ] `docker-compose up` sobe: PostgreSQL, Redis, RabbitMQ
- [ ] Serviços acessíveis nas portas corretas (5432, 6379, 5672)
- [ ] RabbitMQ Management UI acessível em `localhost:15672`
- [ ] `.env.example` documenta todas as variáveis necessárias

**Tasks técnicas:**

- [ ] Criar `docker-compose.yml` com os 3 serviços de infra
- [ ] Criar `.env.example` com todas as vars
- [ ] Testar conexão com cada serviço via cliente local

---

### S0-04 — Pipeline CI/CD 🔵

**Como** desenvolvedor,  
**quero** um pipeline que rode testes e faça deploy automaticamente,  
**para que** todo código em `staging` seja verificado antes de ir pra produção.

**Critérios de aceitação:**

- [ ] Push em `staging` → executa lint + testes + deploy staging
- [ ] Push em `main` (via PR) → executa lint + testes + deploy produção
- [ ] Pipeline falha se lint ou testes falharem
- [ ] Secrets configurados no GitHub (HETZNER_TOKEN, COOLIFY_TOKEN)

**Tasks técnicas:**

- [ ] Criar `.github/workflows/staging.yml`
- [ ] Criar `.github/workflows/production.yml`
- [ ] Configurar secrets no repositório GitHub
- [ ] Migrar state do Terraform para Terraform Cloud (adicionar bloco `cloud {}` em `main.tf` e remover `profile` do provider)
- [ ] Fazer push de teste para validar o pipeline

---

## Sprint 1 — Autenticação

> **Meta:** usuários conseguem se cadastrar e fazer login com roles distintos.

---

### S1-01 — Cadastro de lojista 🔵

**Como** lojista,  
**quero** me cadastrar com nome, email e senha,  
**para que** eu possa acessar o painel e gerenciar minha loja.

**Critérios de aceitação:**

- [ ] POST `/auth/cadastro` cria usuário com role `lojista`
- [ ] Email deve ser único — retorna 409 se já existir
- [ ] Senha armazenada com hash bcrypt (nunca em texto puro)
- [ ] Retorna 201 com dados do usuário (sem senha)
- [ ] Validação: email válido, senha mínimo 8 caracteres

**Tasks técnicas:**

- [ ] `domain/entities/usuario.py` — entidade pura
- [ ] `domain/repositories/usuario_repo.py` — interface ABC
- [ ] `use_cases/auth/cadastrar_usuario.py` — caso de uso
- [ ] `infrastructure/database/models.py` — model SQLAlchemy
- [ ] `infrastructure/database/repositories/usuario_repo.py` — implementação
- [ ] `api/routes/auth.py` — endpoint POST /auth/cadastro
- [ ] `api/schemas/auth.py` — schemas Pydantic request/response
- [ ] Migration Alembic para tabela `usuarios`
- [ ] Testes: `pytest tests/use_cases/test_cadastrar_usuario.py`

---

### S1-02 — Login e JWT 🔵

**Como** lojista,  
**quero** fazer login com email e senha,  
**para que** eu receba um token JWT e acesse áreas protegidas.

**Critérios de aceitação:**

- [ ] POST `/auth/login` retorna `access_token` e `refresh_token`
- [ ] Token expira em 15 minutos (access) e 7 dias (refresh)
- [ ] Credenciais inválidas retornam 401
- [ ] POST `/auth/refresh` gera novo access token via refresh token

**Tasks técnicas:**

- [ ] `use_cases/auth/autenticar_usuario.py`
- [ ] `infrastructure/auth/jwt.py` — geração e validação de tokens
- [ ] `api/routes/auth.py` — endpoints login e refresh
- [ ] `api/dependencies/auth.py` — `Depends(get_current_user)`
- [ ] Testes: login com credenciais válidas e inválidas, refresh token

---

### S1-03 — Proteção de rotas no backend 🔵

**Como** sistema,  
**quero** que rotas protegidas rejeitem requisições sem token válido,  
**para que** apenas usuários autenticados acessem recursos privados.

**Critérios de aceitação:**

- [ ] Rota sem token retorna 401
- [ ] Token expirado retorna 401
- [ ] Token de role errado retorna 403 (ex: cliente tentando acessar `/admin`)
- [ ] `get_current_lojista` e `get_current_admin` como dependências reutilizáveis

**Tasks técnicas:**

- [ ] `api/dependencies/auth.py` — dependências por role
- [ ] Testes de integração para cada cenário de erro

---

### S1-04 — Proteção de rotas no frontend 🔵

**Como** sistema,  
**quero** que `/dashboard` e `/admin` redirecionem usuários não autenticados,  
**para que** apenas usuários com sessão válida acessem os painéis.

**Critérios de aceitação:**

- [ ] Acesso a `/dashboard` sem sessão redireciona para `/auth/login`
- [ ] Acesso a `/admin` sem role admin redireciona para `/`
- [ ] Sessão armazenada de forma segura via NextAuth.js

**Tasks técnicas:**

- [ ] Configurar NextAuth.js com provider `credentials`
- [ ] `middleware.ts` — proteção por role nas rotas
- [ ] Testes: acessar rota protegida sem sessão

---

### S1-05 — Seed do usuário admin 🔵

**Como** sistema,  
**quero** um script que crie o usuário admin inicial,  
**para que** o painel admin seja acessível após o primeiro deploy.

**Critérios de aceitação:**

- [ ] `python -m app.scripts.seed_admin` cria admin se não existir
- [ ] Script é idempotente (pode rodar múltiplas vezes sem duplicar)
- [ ] Credenciais lidas de variáveis de ambiente

**Tasks técnicas:**

- [ ] `backend/app/scripts/seed_admin.py`
- [ ] Adicionar chamada ao seed no startup da aplicação (apenas se admin não existir)

---

## Sprint 2 — Gestão de Lojas (Admin)

> **Meta:** admin consegue ver, aprovar e bloquear lojas cadastradas.

---

### S2-01 — Cadastro de loja 🔵

**Como** lojista,  
**quero** cadastrar minha loja com nome, slug e categoria,  
**para que** ela fique disponível na plataforma após aprovação.

**Critérios de aceitação:**

- [ ] POST `/lojas` cria loja com status `pendente`
- [ ] Slug deve ser único, lowercase, sem espaços (validação automática)
- [ ] Lojista só pode ter uma loja cadastrada
- [ ] Retorna 201 com dados da loja criada

**Tasks técnicas:**

- [ ] `domain/entities/loja.py`
- [ ] `domain/repositories/loja_repo.py`
- [ ] `use_cases/lojas/cadastrar_loja.py` — inclui geração/validação de slug
- [ ] `infrastructure/database/repositories/loja_repo.py`
- [ ] `api/routes/lojas.py`
- [ ] Migration: tabela `lojas`
- [ ] Testes: slug duplicado, slug inválido, lojista com loja já existente

---

### S2-02 — Listagem de lojas (admin) 🔵

**Como** admin,  
**quero** ver todas as lojas com status, categoria e métricas básicas,  
**para que** eu possa gerenciar os parceiros da plataforma.

**Critérios de aceitação:**

- [ ] GET `/admin/lojas` retorna lista paginada de lojas
- [ ] Filtro por status (`pendente`, `ativo`, `bloqueado`)
- [ ] Lojas pendentes aparecem no topo

**Tasks técnicas:**

- [ ] `use_cases/admin/listar_lojas.py`
- [ ] `api/routes/admin/lojas.py`
- [ ] Schema de resposta com paginação
- [ ] Testes: filtro por status, ordenação

---

### S2-03 — Aprovação de loja 🔵

**Como** admin,  
**quero** aprovar uma loja pendente,  
**para que** ela fique ativa e visível na plataforma.

**Critérios de aceitação:**

- [ ] PATCH `/admin/lojas/{id}/aprovar` muda status para `ativo`
- [ ] Dispara evento `loja.aprovada`
- [ ] Handler do evento envia email de boas-vindas ao lojista
- [ ] Retorna 400 se loja já estiver ativa

**Tasks técnicas:**

- [ ] `use_cases/admin/aprovar_loja.py`
- [ ] `infrastructure/events/handlers/loja_handlers.py` — handler `loja.aprovada`
- [ ] Testes: aprovação, tentativa de aprovar loja já ativa

---

### S2-04 — Bloquear e reativar loja 🔵

**Como** admin,  
**quero** bloquear ou reativar uma loja,  
**para que** eu possa moderar parceiros que violem os termos.

**Critérios de aceitação:**

- [ ] PATCH `/admin/lojas/{id}/bloquear` muda status para `bloqueado`
- [ ] PATCH `/admin/lojas/{id}/reativar` muda status para `ativo`
- [ ] Loja bloqueada não aparece na listagem pública

**Tasks técnicas:**

- [ ] `use_cases/admin/bloquear_loja.py`
- [ ] `use_cases/admin/reativar_loja.py`
- [ ] Testes: bloquear loja ativa, reativar loja bloqueada

---

## Sprint 3 — Cardápio (Lojista)

> **Meta:** lojista consegue gerenciar produtos da sua loja.

---

### S3-01 — Criar produto 🔵

**Como** lojista,  
**quero** cadastrar um produto com nome, preço, categoria e disponibilidade,  
**para que** ele apareça no cardápio da minha loja.

**Critérios de aceitação:**

- [ ] POST `/dashboard/produtos` cria produto vinculado à loja do lojista autenticado
- [ ] Preço deve ser maior que zero
- [ ] Produto criado como `disponivel=true` por padrão
- [ ] Retorna 201 com dados do produto

**Tasks técnicas:**

- [ ] `domain/entities/produto.py`
- [ ] `domain/repositories/produto_repo.py`
- [ ] `use_cases/produtos/criar_produto.py`
- [ ] `infrastructure/database/repositories/produto_repo.py`
- [ ] `api/routes/dashboard/produtos.py`
- [ ] Migration: tabela `produtos`
- [ ] Testes: preço inválido, lojista sem loja, produto criado com sucesso

---

### S3-02 — Editar produto 🔵

**Como** lojista,  
**quero** editar nome, preço, descrição e categoria de um produto,  
**para que** o cardápio esteja sempre atualizado.

**Critérios de aceitação:**

- [ ] PATCH `/dashboard/produtos/{id}` atualiza apenas os campos enviados
- [ ] Lojista só pode editar produtos da própria loja (403 caso contrário)
- [ ] Retorna 404 se produto não existir

**Tasks técnicas:**

- [ ] `use_cases/produtos/editar_produto.py`
- [ ] Testes: editar produto de outra loja, campos parciais

---

### S3-03 — Ativar e pausar produto 🔵

**Como** lojista,  
**quero** ativar ou pausar a disponibilidade de um produto,  
**para que** eu possa controlar o que está disponível sem deletar.

**Critérios de aceitação:**

- [ ] PATCH `/dashboard/produtos/{id}/disponibilidade` alterna `disponivel`
- [ ] Produto pausado não aparece no cardápio público
- [ ] Retorna o estado atual após a mudança

**Tasks técnicas:**

- [ ] `use_cases/produtos/alterar_disponibilidade.py`
- [ ] Testes: pausar produto disponível, ativar produto pausado

---

### S3-04 — Remover produto 🔵

**Como** lojista,  
**quero** remover um produto do cardápio,  
**para que** itens descontinuados não apareçam mais.

**Critérios de aceitação:**

- [ ] DELETE `/dashboard/produtos/{id}` remove o produto
- [ ] Produto com pedidos ativos não pode ser removido (retorna 409)
- [ ] Lojista só remove produtos da própria loja

**Tasks técnicas:**

- [ ] `use_cases/produtos/remover_produto.py`
- [ ] Testes: remover produto com pedido ativo, remover produto de outra loja

---

## Sprint 4 — Página Pública da Loja

> **Meta:** cliente acessa o cardápio de uma loja via URL pública.

---

### S4-01 — Página da loja 🔵

**Como** cliente,  
**quero** acessar `pedeai.com.br/[slug]` e ver o cardápio da loja,  
**para que** eu possa escolher o que quero pedir.

**Critérios de aceitação:**

- [ ] GET `/lojas/{slug}` retorna dados da loja e produtos disponíveis
- [ ] Produtos agrupados por categoria
- [ ] Loja inexistente retorna 404 → página 404 no frontend
- [ ] Loja bloqueada retorna 404 (não expõe o motivo)
- [ ] Página renderizada com SSR (Next.js) para SEO

**Tasks técnicas:**

- [ ] `use_cases/lojas/buscar_loja_por_slug.py`
- [ ] `api/routes/public/lojas.py` — GET /lojas/{slug}
- [ ] `frontend/app/[slug]/page.tsx` — Server Component
- [ ] Testes: slug válido, slug inexistente, loja bloqueada

---

### S4-02 — Carrinho de compras 🔵

**Como** cliente,  
**quero** adicionar e remover itens do carrinho,  
**para que** eu monte meu pedido antes de finalizar.

**Critérios de aceitação:**

- [ ] Adicionar item atualiza quantidade se já existir no carrinho
- [ ] Remover item diminui quantidade (remove se chegar a zero)
- [ ] Total calculado em tempo real
- [ ] Carrinho persiste ao navegar entre categorias
- [ ] Carrinho é limpo ao trocar de loja

**Tasks técnicas:**

- [ ] `frontend/app/[slug]/hooks/use-carrinho.ts` — estado via `useState`
- [ ] `frontend/app/[slug]/components/carrinho.tsx`
- [ ] Testes Jest: adicionar, remover, trocar de loja limpa carrinho

---

### S4-03 — Home da plataforma 🔵

**Como** visitante,  
**quero** ver a home do PedeAí com lojas em destaque,  
**para que** eu descubra estabelecimentos disponíveis.

**Critérios de aceitação:**

- [ ] GET `/lojas` retorna lojas ativas paginadas
- [ ] Home exibe grid de lojas com logo, nome, categoria e status
- [ ] Renderizada com SSR para SEO

**Tasks técnicas:**

- [ ] `use_cases/lojas/listar_lojas_publicas.py`
- [ ] `api/routes/public/lojas.py` — GET /lojas
- [ ] `frontend/app/page.tsx` — Server Component
- [ ] Testes: apenas lojas ativas aparecem

---

## Sprint 5 — Pedidos (Criação)

> **Meta:** cliente finaliza um pedido e lojista recebe a notificação.

---

### S5-01 — Criar pedido 🔵

**Como** cliente,  
**quero** finalizar meu pedido informando endereço de entrega,  
**para que** o restaurante receba e prepare meu pedido.

**Critérios de aceitação:**

- [ ] POST `/pedidos` cria pedido com status `aguardando_pagamento`
- [ ] Valida que todos os produtos pertencem à mesma loja
- [ ] Valida que produtos estão disponíveis no momento do pedido
- [ ] Total calculado no backend (nunca confiar no frontend)
- [ ] Dispara evento `pedido.criado`
- [ ] Retorna 201 com id e status do pedido

**Tasks técnicas:**

- [ ] `domain/entities/pedido.py` — com regra de negócio de cálculo de total
- [ ] `domain/repositories/pedido_repo.py`
- [ ] `use_cases/pedidos/criar_pedido.py`
- [ ] `infrastructure/database/repositories/pedido_repo.py`
- [ ] `api/routes/public/pedidos.py`
- [ ] Migration: tabelas `pedidos` e `pedido_itens`
- [ ] Testes: produtos de lojas diferentes, produto indisponível, total correto

---

### S5-02 — Notificação em tempo real para lojista 🔵

**Como** lojista,  
**quero** receber uma notificação instantânea quando um novo pedido chegar,  
**para que** eu possa iniciar o preparo rapidamente.

**Critérios de aceitação:**

- [ ] Handler do evento `pedido.criado` envia mensagem via WebSocket
- [ ] Lojista recebe notificação sem precisar recarregar a página
- [ ] Conexão WebSocket reconecta automaticamente se cair

**Tasks técnicas:**

- [ ] `infrastructure/events/handlers/pedido_handlers.py` — handler `pedido.criado`
- [ ] `api/routes/ws/notificacoes.py` — WebSocket endpoint
- [ ] `frontend/app/dashboard/hooks/use-notificacoes.ts` — client WebSocket
- [ ] Testes: handler recebe evento e notifica conexão ativa

---

### S5-03 — Fila de pedidos no painel do lojista 🔵

**Como** lojista,  
**quero** ver os pedidos novos no meu painel,  
**para que** eu possa gerenciar as entregas.

**Critérios de aceitação:**

- [ ] GET `/dashboard/pedidos` retorna pedidos da loja autenticada
- [ ] Filtro por status (novo, preparo, entregue)
- [ ] Ordenados por data de criação (mais recente primeiro)

**Tasks técnicas:**

- [ ] `use_cases/pedidos/listar_pedidos_loja.py`
- [ ] `api/routes/dashboard/pedidos.py`
- [ ] `frontend/app/dashboard/pedidos/page.tsx`
- [ ] Testes: lojista só vê pedidos da própria loja

---

## Sprint 6 — Pedidos (Fluxo de Status)

> **Meta:** lojista gerencia o ciclo completo de um pedido.

---

### S6-01 — Aceitar pedido 🔵

**Como** lojista,  
**quero** aceitar um pedido novo,  
**para que** o cliente saiba que o pedido foi confirmado.

**Critérios de aceitação:**

- [ ] PATCH `/dashboard/pedidos/{id}/aceitar` muda status para `aceito`
- [ ] Dispara evento `pedido.aceito`
- [ ] Só pode aceitar pedidos com status `pago` ou `aguardando_pagamento` (MVP sem pagamento)
- [ ] Retorna 409 se pedido já foi aceito

**Tasks técnicas:**

- [ ] `use_cases/pedidos/aceitar_pedido.py`
- [ ] `infrastructure/events/handlers/pedido_handlers.py` — handler `pedido.aceito`
- [ ] Testes: aceitar pedido válido, aceitar pedido já aceito

---

### S6-02 — Atualizar status do pedido 🔵

**Como** lojista,  
**quero** mover o pedido pelas etapas de preparo e entrega,  
**para que** o cliente acompanhe o andamento em tempo real.

**Critérios de aceitação:**

- [ ] PATCH `/dashboard/pedidos/{id}/status` aceita `em_preparo` e `saiu_para_entrega`
- [ ] Transições inválidas retornam 422 (ex: pular etapa)
- [ ] Cada mudança de status registra timestamp

**Tasks técnicas:**

- [ ] `domain/entities/pedido.py` — máquina de estados com validação de transição
- [ ] `use_cases/pedidos/atualizar_status_pedido.py`
- [ ] Testes: transições válidas e inválidas

---

### S6-03 — Marcar pedido como entregue 🔵

**Como** lojista,  
**quero** confirmar que um pedido foi entregue,  
**para que** a comissão seja calculada e o ciclo seja encerrado.

**Critérios de aceitação:**

- [ ] PATCH `/dashboard/pedidos/{id}/entregar` muda status para `entregue`
- [ ] Dispara evento `pedido.entregue`
- [ ] Handler calcula comissão e registra no histórico financeiro
- [ ] Pedido entregue não pode ter status alterado

**Tasks técnicas:**

- [ ] `use_cases/pedidos/entregar_pedido.py`
- [ ] `use_cases/financeiro/calcular_comissao.py`
- [ ] Migration: tabela `transacoes` para histórico financeiro
- [ ] Testes: cálculo de comissão por plano, pedido já entregue

---

### S6-04 — Acompanhar status do pedido (cliente) 🔵

**Como** cliente,  
**quero** ver o status atual do meu pedido,  
**para que** eu saiba quando minha comida vai chegar.

**Critérios de aceitação:**

- [ ] GET `/pedidos/{id}` retorna status atual e histórico de mudanças
- [ ] Página de acompanhamento atualiza status sem recarregar (polling ou WebSocket)
- [ ] Cliente só acessa seus próprios pedidos

**Tasks técnicas:**

- [ ] `use_cases/pedidos/buscar_pedido.py`
- [ ] `api/routes/public/pedidos.py` — GET /pedidos/{id}
- [ ] `frontend/app/pedidos/[id]/page.tsx`
- [ ] Testes: cliente acessando pedido de outro cliente

---

## Sprint 7 — Dashboard do Lojista

> **Meta:** lojista tem visão completa da operação da sua loja.

---

### S7-01 — Métricas do dia 🔵

**Como** lojista,  
**quero** ver pedidos do dia, receita e ticket médio no painel,  
**para que** eu acompanhe a performance da minha loja.

**Critérios de aceitação:**

- [ ] GET `/dashboard/metricas` retorna: total de pedidos, receita bruta, ticket médio
- [ ] Métricas filtradas pela data atual (timezone Brasil)
- [ ] Dados atualizados em tempo real conforme pedidos chegam

**Tasks técnicas:**

- [ ] `use_cases/dashboard/buscar_metricas_loja.py`
- [ ] `api/routes/dashboard/metricas.py`
- [ ] `frontend/app/dashboard/page.tsx` — cards de métricas
- [ ] Testes: métricas com pedidos em múltiplos status

---

### S7-02 — Configurações da loja 🔵

**Como** lojista,  
**quero** configurar horário de funcionamento e taxa de entrega,  
**para que** clientes vejam informações corretas na minha página.

**Critérios de aceitação:**

- [ ] PATCH `/dashboard/configuracoes` atualiza: horário, taxa de entrega, telefone
- [ ] Horário configurado por dia da semana
- [ ] Taxa de entrega pode ser zero (entrega grátis)

**Tasks técnicas:**

- [ ] `use_cases/lojas/atualizar_configuracoes_loja.py`
- [ ] Migration: colunas de configuração na tabela `lojas`
- [ ] `frontend/app/dashboard/configuracoes/page.tsx`
- [ ] Testes: horário inválido, taxa negativa

---

## Sprint 8 — Painel Admin + Finalização MVP

> **Meta:** admin tem visão completa da plataforma. MVP pronto para lançamento.

---

### S8-01 — Métricas globais (admin) 🔵

**Como** admin,  
**quero** ver métricas gerais da plataforma,  
**para que** eu monitore a saúde do negócio.

**Critérios de aceitação:**

- [ ] GET `/admin/metricas` retorna: lojas ativas, pedidos totais, receita total, comissões
- [ ] Filtro por período (hoje, semana, mês)

**Tasks técnicas:**

- [ ] `use_cases/admin/buscar_metricas_plataforma.py`
- [ ] `api/routes/admin/metricas.py`
- [ ] `frontend/app/admin/page.tsx`
- [ ] Testes: métricas com múltiplas lojas

---

### S8-02 — Gestão de planos (admin) 🔵

**Como** admin,  
**quero** visualizar e alterar o plano de uma loja,  
**para que** eu gerencie comissões e benefícios dos parceiros.

**Critérios de aceitação:**

- [ ] GET `/admin/planos` lista planos disponíveis
- [ ] PATCH `/admin/lojas/{id}/plano` altera plano da loja
- [ ] Mudança de plano registrada no histórico

**Tasks técnicas:**

- [ ] `use_cases/admin/alterar_plano_loja.py`
- [ ] Migration: tabela `planos` e seed com Básico e Pro
- [ ] Testes: alterar para plano inexistente

---

### S8-03 — Smoke tests de produção 🔵

**Como** desenvolvedor,  
**quero** um conjunto de testes que validem o ambiente de produção após cada deploy,  
**para que** deploys com problema sejam detectados automaticamente.

**Critérios de aceitação:**

- [ ] Smoke test valida: health check da API, conexão com banco, conexão com RabbitMQ
- [ ] Smoke test roda automaticamente após deploy no CI/CD
- [ ] Deploy é revertido automaticamente se smoke test falhar

**Tasks técnicas:**

- [ ] `backend/tests/smoke/test_health.py`
- [ ] Adicionar step de smoke test nos workflows do GitHub Actions
- [ ] Configurar rollback automático via script no CI/CD

---

## Pós-MVP ⚪

### PM-01 — Avaliações de pedidos ⚪

**Como** cliente,  
**quero** avaliar um pedido entregue com nota e comentário,  
**para que** outros clientes saibam a qualidade do restaurante.

---

### PM-02 — Relatórios financeiros para lojista ⚪

**Como** lojista,  
**quero** ver relatório de receita por período,  
**para que** eu acompanhe a evolução do meu negócio.

---

### PM-03 — Integração com gateway de pagamento ⚪

**Como** cliente,  
**quero** pagar com cartão ou Pix diretamente na plataforma,  
**para que** o pedido seja confirmado automaticamente.

---

### PM-04 — Upload de foto de produto ⚪

**Como** lojista,  
**quero** adicionar foto aos meus produtos,  
**para que** o cardápio seja mais atrativo para os clientes.

---

### PM-05 — Busca por categoria na home ⚪

**Como** cliente,  
**quero** filtrar lojas por tipo de comida,  
**para que** eu encontre rapidamente o que quero.

---

## Resumo

| Sprint                | Histórias                         | Status |
| --------------------- | --------------------------------- | ------ |
| 0 — Fundação          | S0-01 ✅, S0-02 ✅, S0-03, S0-04  | 🟡     |
| 1 — Autenticação      | S1-01, S1-02, S1-03, S1-04, S1-05 | 🔴     |
| 2 — Lojas (Admin)     | S2-01, S2-02, S2-03, S2-04        | 🔴     |
| 3 — Cardápio          | S3-01, S3-02, S3-03, S3-04        | 🔴     |
| 4 — Página Pública    | S4-01, S4-02, S4-03               | 🔴     |
| 5 — Pedidos (Criação) | S5-01, S5-02, S5-03               | 🔴     |
| 6 — Pedidos (Status)  | S6-01, S6-02, S6-03, S6-04        | 🔴     |
| 7 — Dashboard         | S7-01, S7-02                      | 🔴     |
| 8 — Admin + MVP final | S8-01, S8-02, S8-03               | 🔴     |
| Pós-MVP               | PM-01 a PM-05                     | ⚪     |

**Total MVP: 29 histórias · 8 sprints · ~8 semanas**
