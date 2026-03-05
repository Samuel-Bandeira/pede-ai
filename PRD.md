# 🍽️ PedeAí — Product Requirements Document

> Marketplace de Alimentação — v1.0

|             |                                                   |
| ----------- | ------------------------------------------------- |
| **Versão**  | 1.0                                               |
| **Status**  | Draft                                             |
| **Produto** | PedeAí — pedeai.com.br                            |
| **Stack**   | Next.js · FastAPI · RabbitMQ · PostgreSQL · Redis |

---

## 1. Visão Geral do Produto

### 1.1 Problema

Pequenos restaurantes, lanchonetes e estabelecimentos de alimentação no Brasil têm dificuldade de criar e manter uma presença digital própria para receber pedidos online. As plataformas existentes (iFood, Rappi) cobram altas comissões e não oferecem autonomia ao lojista.

### 1.2 Solução

O PedeAí é um marketplace de alimentação que permite que qualquer estabelecimento tenha sua própria página de cardápio e receba pedidos online em minutos, acessível via URL amigável:

```
pedeai.com.br/nome-do-restaurante
```

A plataforma conecta clientes finais, donos de estabelecimentos (franqueados) e o administrador da plataforma num único sistema integrado.

### 1.3 Proposta de Valor

- **Cliente:** encontrar e pedir comida de estabelecimentos locais de forma rápida e simples
- **Lojista:** ter presença digital própria com baixo custo e fácil gestão
- **Plataforma:** marketplace escalável com receita via comissão e planos mensais

### 1.4 Público-Alvo

- **Clientes finais:** qualquer pessoa que queira pedir comida online
- **Lojistas:** restaurantes, lanchonetes, açaís, pizzarias, mercadinhos e afins
- **Administrador:** equipe interna do PedeAí

---

## 2. Perfis de Usuário

### 2.1 Cliente Final

Usuário que acessa a página de uma loja, navega pelo cardápio e realiza pedidos. Pode ou não ter conta cadastrada na plataforma.

- Acessa: `pedeai.com.br/[slug-da-loja]`
- Pode criar conta para salvar histórico e endereços
- Realiza pedidos e acompanha status

### 2.2 Lojista (Franqueado)

Dono ou gestor de um estabelecimento de alimentação cadastrado na plataforma.

- Acessa: `pedeai.com.br/dashboard`
- Gerencia produtos, pedidos, configurações e relatórios
- Pode estar no plano Básico ou Pro

### 2.3 Administrador

Equipe interna do PedeAí responsável pela gestão da plataforma.

- Acessa: `pedeai.com.br/admin`
- Aprova, bloqueia e gerencia todas as lojas
- Visualiza métricas globais e configura planos e comissões

---

## 3. Funcionalidades

### 3.1 Área Pública — Home e Página da Loja

| Funcionalidade         | Descrição                                                  | Prioridade | MVP |
| ---------------------- | ---------------------------------------------------------- | ---------- | --- |
| Home da plataforma     | Página inicial com busca por loja/categoria e destaques    | Alta       | ✅  |
| Página da loja         | Cardápio público acessível via /slug com produtos e preços | Alta       | ✅  |
| Carrinho de compras    | Carrinho lateral com itens, quantidades e total            | Alta       | ✅  |
| Checkout               | Fluxo de finalização de pedido com endereço e pagamento    | Alta       | ✅  |
| Busca por categoria    | Filtrar lojas por tipo (Japonês, Pizza, Burger etc.)       | Média      | ❌  |
| Avaliações             | Clientes avaliam pedidos com nota e comentário             | Média      | ❌  |
| Rastreamento de pedido | Acompanhar status do pedido em tempo real                  | Alta       | ✅  |

### 3.2 Painel do Lojista

| Funcionalidade             | Descrição                                                     | Prioridade | MVP |
| -------------------------- | ------------------------------------------------------------- | ---------- | --- |
| Visão geral                | Dashboard com pedidos do dia, receita e avaliação média       | Alta       | ✅  |
| Fila de pedidos            | Kanban com colunas Novo → Preparo → Entregue                  | Alta       | ✅  |
| Gestão de produtos         | CRUD de produtos com foto, preço, categoria e disponibilidade | Alta       | ✅  |
| Configurações da loja      | Horário, taxa de entrega, raio, meios de pagamento            | Alta       | ✅  |
| Relatórios financeiros     | Receita por período, pedidos, ticket médio                    | Média      | ❌  |
| Notificações em tempo real | Alerta de novo pedido via WebSocket                           | Alta       | ✅  |
| Personalização visual      | Logo, banner e cores da página pública                        | Média      | ❌  |

### 3.3 Painel Administrativo

| Funcionalidade         | Descrição                                            | Prioridade | MVP |
| ---------------------- | ---------------------------------------------------- | ---------- | --- |
| Métricas da plataforma | Total de lojas, pedidos, receita e comissões         | Alta       | ✅  |
| Gestão de lojas        | Listar, aprovar, bloquear e editar lojas cadastradas | Alta       | ✅  |
| Aprovação de cadastros | Fila de novas lojas aguardando aprovação             | Alta       | ✅  |
| Gestão de planos       | Configurar planos Básico e Pro e comissões           | Alta       | ✅  |
| Log de eventos         | Histórico de todos os eventos do sistema             | Média      | ❌  |
| Relatório financeiro   | Receita da plataforma e repasses por loja            | Média      | ❌  |

---

## 4. Arquitetura Técnica

### 4.1 Stack Tecnológica

| Camada         | Tecnologia              | Justificativa                                            |
| -------------- | ----------------------- | -------------------------------------------------------- |
| Frontend       | Next.js 14 (App Router) | SSR nativo, roteamento por /[slug], otimizado para SEO   |
| Backend        | FastAPI (Python 3.11+)  | Alta performance, async nativo, tipagem com Pydantic     |
| Mensageria     | RabbitMQ                | Event-driven para pedidos, notificações e cobranças      |
| Banco de dados | PostgreSQL              | Relacional, robusto, suporte a JSON para dados flexíveis |
| Cache          | Redis                   | Sessões, filas temporárias e cache de cardápios          |
| Autenticação   | JWT + NextAuth.js       | Tokens stateless com refresh, suporte a OAuth            |
| Deploy         | Hetzner VPS + Coolify   | Mais barato, controle total, SSL automático              |
| IaC            | Terraform               | Infraestrutura versionada e reproduzível                 |
| Tempo real     | WebSocket (FastAPI)     | Notificações de novos pedidos para o lojista             |

### 4.2 Ambientes

| Ambiente   | Branch    | URL                   |
| ---------- | --------- | --------------------- |
| Production | `main`    | pedeai.com.br         |
| Staging    | `staging` | staging.pedeai.com.br |

### 4.3 Modelo de Eventos (RabbitMQ)

O backend utiliza RabbitMQ como message broker para desacoplar ações do sistema. Os consumers rodam dentro do próprio processo FastAPI.

| Evento                 | Trigger                         | Handlers                            |
| ---------------------- | ------------------------------- | ----------------------------------- |
| `pedido.criado`        | POST /pedidos                   | notifica_loja, inicia_cobranca      |
| `pedido.aceito`        | PATCH /pedidos/{id}/aceitar     | notifica_cliente                    |
| `pedido.entregue`      | PATCH /pedidos/{id}/entregar    | calcula_comissao, dispara_avaliacao |
| `loja.aprovada`        | PATCH /admin/lojas/{id}/aprovar | envia_email_boas_vindas             |
| `pagamento.confirmado` | webhook do gateway              | libera_pedido                       |

### 4.4 Estrutura de Rotas (Next.js)

```
# Área Pública
/                          → Home da plataforma
/[slug]                    → Página pública da loja
/[slug]/checkout           → Finalizar pedido

# Painel do Lojista
/dashboard                 → Visão geral
/dashboard/pedidos         → Fila de pedidos
/dashboard/produtos        → Gestão de produtos
/dashboard/configuracoes   → Configurações da loja

# Painel Administrativo
/admin                     → Métricas gerais
/admin/lojas               → Gestão de lojas
/admin/financeiro          → Comissões e repasses
```

---

## 5. Modelo de Dados

### 5.1 Entidades Principais

| Tabela         | Campos principais                                                     |
| -------------- | --------------------------------------------------------------------- |
| `lojas`        | id, slug (único), nome, logo, categoria, status, plano_id, created_at |
| `usuarios`     | id, nome, email, senha_hash, role (`cliente\|lojista\|admin`)         |
| `produtos`     | id, loja_id, nome, descricao, preco, categoria, foto_url, disponivel  |
| `pedidos`      | id, loja_id, cliente_id, total, status, endereco, created_at          |
| `pedido_itens` | id, pedido_id, produto_id, quantidade, preco_unitario                 |
| `planos`       | id, nome, comissao_pct, preco_mensal                                  |
| `eventos_log`  | id, tipo, payload (JSON), created_at                                  |

### 5.2 Status de Pedido

```
aguardando_pagamento → pago → aceito → em_preparo → saiu_para_entrega → entregue → cancelado
```

### 5.3 Status de Loja

```
pendente → ativo → suspenso → bloqueado
```

---

## 6. Modelo de Negócio

### 6.1 Planos

|                             | Básico    | Pro       | Enterprise   |
| --------------------------- | --------- | --------- | ------------ |
| **Mensalidade**             | Grátis    | R$ 99/mês | Sob consulta |
| **Comissão por pedido**     | 12%       | 8%        | 5%           |
| **Produtos cadastrados**    | Ilimitado | Ilimitado | Ilimitado    |
| **Notificações tempo real** | ✅        | ✅        | ✅           |
| **Relatórios avançados**    | ❌        | ✅        | ✅           |
| **Suporte prioritário**     | ❌        | ✅        | ✅           |

---

## 7. Roadmap

### Fase 1 — MVP (0 a 3 meses)

- [ ] Cadastro e aprovação de lojas
- [ ] Página pública da loja com cardápio
- [ ] Carrinho e checkout básico
- [ ] Painel do lojista: produtos e fila de pedidos
- [ ] Painel admin: gestão de lojas
- [ ] Autenticação com roles
- [ ] Notificações em tempo real (WebSocket)
- [ ] Infraestrutura via Terraform + Coolify

### Fase 2 — Crescimento (3 a 6 meses)

- [ ] Avaliações e comentários
- [ ] Rastreamento de pedido com mapa
- [ ] Relatórios financeiros para lojista
- [ ] Plano Pro com funcionalidades extras
- [ ] Integração com gateway de pagamento (Stripe/Pagar.me)
- [ ] App mobile (React Native ou PWA)

### Fase 3 — Escala (6 a 12 meses)

- [ ] Sistema de cupons e promoções
- [ ] Programa de fidelidade para clientes
- [ ] API pública para integrações
- [ ] Múltiplos idiomas
- [ ] Migração para microserviços se necessário

---

## 8. Requisitos Não-Funcionais

### 8.1 Performance

- Página da loja carrega em menos de 2 segundos (LCP)
- API responde em menos de 300ms para endpoints críticos
- Suporte a pelo menos 500 usuários simultâneos no MVP

### 8.2 Segurança

- Autenticação via JWT com refresh token
- HTTPS obrigatório em todos os ambientes
- Rate limiting nas APIs públicas
- Dados sensíveis criptografados em repouso
- LGPD: consentimento de dados e opção de exclusão de conta

### 8.3 Disponibilidade

- SLA de 99.5% de uptime para MVP
- Backups automáticos diários do PostgreSQL
- Logs centralizados para diagnóstico

### 8.4 Escalabilidade

- Arquitetura event-driven permite escalar consumers independentemente
- Redis para cache reduz carga no banco
- Terraform permite replicar ambiente em minutos

---

## 9. Fora do Escopo — MVP

- Entregadores próprios (integração com motoboy)
- Chat entre cliente e loja
- Marketplace de ingredientes B2B
- Programa de afiliados
- App nativo iOS/Android

---

## 10. Glossário

| Termo                    | Definição                                                               |
| ------------------------ | ----------------------------------------------------------------------- |
| **Slug**                 | Identificador único de URL da loja (ex: `sushi-da-hora`)                |
| **Lojista / Franqueado** | Dono de estabelecimento cadastrado na plataforma                        |
| **Event-driven**         | Arquitetura onde ações disparam eventos processados de forma assíncrona |
| **MVP**                  | Minimum Viable Product — versão mínima funcional do produto             |
| **PRD**                  | Product Requirements Document — este documento                          |
| **IaC**                  | Infrastructure as Code — infraestrutura gerenciada via Terraform        |

---

_— Fim do Documento —_
