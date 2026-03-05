# PedeAí — CLAUDE.md

Marketplace de alimentação brasileiro onde restaurantes e lojas de comida
se cadastram e ganham uma página pública em `pedeai.com.br/[slug]`.

---

## Stack

- **Frontend:** Next.js 15 (App Router), TypeScript, Tailwind CSS
- **Backend:** FastAPI (Python 3.11+), Pydantic v2
- **Mensageria:** RabbitMQ (via `aio-pika`)
- **Banco de dados:** PostgreSQL (via SQLAlchemy async + Alembic)
- **Cache / Sessões:** Redis
- **Autenticação:** JWT (python-jose) + NextAuth.js
- **Tempo real:** WebSocket nativo do FastAPI
- **Infra local:** Docker Compose
- **Infra produção:** AWS EC2 t3.micro (us-east-1) + Docker Compose + Nginx + Certbot
- **IaC:** Terraform (provider AWS) — nunca criar recursos manualmente no console

---

## Comandos

### Frontend

**Criação do projeto (rodar apenas uma vez):**

```bash
# Comando oficial da documentação Next.js — NUNCA criar arquivos manualmente
npx create-next-app@latest frontend
# Responder os prompts:
# ✔ TypeScript? Yes
# ✔ ESLint? Yes
# ✔ Tailwind CSS? Yes
# ✔ src/ directory? No
# ✔ App Router? Yes
# ✔ Turbopack? Yes
# ✔ Import alias (@/*)? Yes
```

**Dev:**

```bash
cd frontend
npm run dev          # dev server na porta 3000 (com Turbopack)
npm run build        # build de produção
npm run lint         # ESLint
npm run test         # Jest
npm run test:e2e     # Playwright
```

### Backend

```bash
cd backend
uvicorn app.main:app --reload          # dev server na porta 8000
alembic upgrade head                   # rodar migrations
alembic revision --autogenerate -m ""  # gerar nova migration
pytest                                 # rodar testes
pytest --cov=app                       # com cobertura
```

### Docker

```bash
docker-compose up          # sobe tudo (frontend, backend, postgres, redis, rabbitmq)
docker-compose up -d       # em background
docker-compose down -v     # derruba e remove volumes
```

---

## Estrutura do Projeto

```
pedeai/
├── frontend/                  # Next.js App
│   └── app/
│       ├── (public)/          # home e páginas das lojas
│       │   ├── page.tsx       # home da plataforma
│       │   └── [slug]/        # página da loja
│       ├── dashboard/         # painel do lojista (autenticado)
│       └── admin/             # painel admin (autenticado)
│
├── backend/                        # FastAPI — Clean Architecture
│   └── app/
│       ├── main.py                 # entrypoint
│       │
│       ├── domain/                 # 🔴 camada mais interna — zero dependências externas
│       │   ├── entities/           # objetos de negócio puros (sem ORM, sem Pydantic)
│       │   │   ├── pedido.py       # ex: class Pedido, class ItemPedido
│       │   │   └── loja.py
│       │   ├── repositories/       # interfaces (ABCs) — o que o domínio precisa persistir
│       │   │   ├── pedido_repo.py  # ex: class PedidoRepository(ABC)
│       │   │   └── loja_repo.py
│       │   └── exceptions/         # exceções de negócio (ex: LojaNaoEncontrada)
│       │
│       ├── use_cases/              # 🟡 casos de uso — orquestram o domínio
│       │   ├── pedidos/
│       │   │   ├── criar_pedido.py    # ex: class CriarPedido
│       │   │   └── aceitar_pedido.py
│       │   └── lojas/
│       │       ├── cadastrar_loja.py
│       │       └── aprovar_loja.py
│       │
│       ├── infrastructure/         # 🟢 implementações concretas (banco, rabbit, etc.)
│       │   ├── database/
│       │   │   ├── models.py       # modelos SQLAlchemy
│       │   │   ├── session.py      # AsyncSession factory
│       │   │   └── repositories/   # implementações concretas dos repos do domínio
│       │   ├── events/
│       │   │   ├── bus.py          # publisher RabbitMQ (aio-pika)
│       │   │   └── handlers/       # consumers por domínio
│       │   └── migrations/         # Alembic
│       │
│       └── api/                    # 🔵 camada externa — HTTP (FastAPI)
│           ├── routes/             # endpoints REST por domínio
│           ├── schemas/            # schemas Pydantic (request/response)
│           └── dependencies/       # Depends() — auth, db session, etc.
│
└── docker-compose.yml
```

---

## Perfis e Rotas

| Role      | Acessa                             |
| --------- | ---------------------------------- |
| `cliente` | `/`, `/[slug]`, `/[slug]/checkout` |
| `lojista` | `/dashboard/*`                     |
| `admin`   | `/admin/*`                         |

A proteção de rotas é feita via middleware do Next.js (`middleware.ts`) e
dependências de autenticação no FastAPI.

---

## Convenções de Código

### TypeScript / Next.js

- Sempre usar `named exports` — nunca `default export` em componentes
- TypeScript strict mode — sem `any`
- Tailwind para todo CSS — sem arquivos `.css` separados
- Nomes de componentes: `PascalCase`
- Nomes de funções e variáveis: `camelCase`
- Nomes de arquivos: `kebab-case`

### Python / FastAPI — Clean Architecture

**Regra de dependência:** as setas apontam sempre para dentro.
`api` → `use_cases` → `domain` ← (nunca o contrário)

- `domain/` não importa nada de fora — zero FastAPI, zero SQLAlchemy, zero Pydantic
- `use_cases/` importa apenas `domain/` — nunca `infrastructure/` diretamente
- `infrastructure/` implementa as interfaces definidas em `domain/repositories/`
- `api/` recebe requests, chama use cases, devolve responses — sem lógica de negócio
- Injeção de dependência via `Depends()` — use cases recebem repos via construtor
- Pydantic v2 **apenas** na camada `api/schemas/` — entidades do domínio são dataclasses puras
- SQLAlchemy async (`AsyncSession`) — nunca sessões síncronas
- Cada arquivo de route tem seu próprio `APIRouter`
- Nomes: `snake_case` para funções/variáveis, `PascalCase` para classes

**Exemplo de fluxo:**

```
POST /pedidos
  → api/routes/pedidos.py        # valida schema Pydantic, chama use case
  → use_cases/pedidos/criar_pedido.py  # orquestra domínio
  → domain/entities/pedido.py    # regra de negócio pura
  → domain/repositories/pedido_repo.py  # interface
  → infrastructure/database/repositories/pedido_repo.py  # implementação
```

---

## Modelo de Eventos (RabbitMQ)

Eventos publicados pelo backend:

| Evento                 | Trigger                         | Handlers                            |
| ---------------------- | ------------------------------- | ----------------------------------- |
| `pedido.criado`        | POST /pedidos                   | notifica_loja, inicia_cobranca      |
| `pedido.aceito`        | PATCH /pedidos/{id}/aceitar     | notifica_cliente                    |
| `pedido.entregue`      | PATCH /pedidos/{id}/entregar    | calcula_comissao, dispara_avaliacao |
| `loja.aprovada`        | PATCH /admin/lojas/{id}/aprovar | envia_email_boas_vindas             |
| `pagamento.confirmado` | webhook do gateway              | libera_pedido                       |

Publicar um evento:

```python
await event_bus.publish("pedido.criado", {"pedido_id": 1, "loja_id": 5})
```

---

## Banco de Dados

### Entidades principais

- `lojas` — id, slug (único), nome, status, plano_id
- `usuarios` — id, email, senha_hash, role (`cliente|lojista|admin`)
- `produtos` — id, loja_id, nome, preco, disponivel
- `pedidos` — id, loja_id, cliente_id, status, total
- `pedido_itens` — id, pedido_id, produto_id, quantidade, preco_unitario
- `planos` — id, nome, comissao_pct, preco_mensal

### Status de pedido

`aguardando_pagamento` → `pago` → `aceito` → `em_preparo` → `saiu_para_entrega` → `entregue` → `cancelado`

### Migrations

- SEMPRE gerar migration via Alembic ao alterar models
- NUNCA editar migration já aplicada em produção

---

## NUNCA fazer

- Commitar `.env` ou qualquer secret
- Usar `any` no TypeScript
- Usar sessões síncronas do SQLAlchemy
- Fazer queries diretas no banco dentro de routes — sempre via use case → repository
- Importar SQLAlchemy ou aio-pika dentro de `domain/` ou `use_cases/` — só em `infrastructure/`
- Colocar lógica de negócio em `api/` — routes só orquestram request/response
- Criar use case que chama outro use case — extrair para o domínio
- Retornar senhas ou tokens de refresh no payload de resposta
- Fazer lógica de negócio dentro de handlers de evento — delegar para services

---

## Variáveis de Ambiente

Copiar `.env.example` para `.env`. As principais:

```
DATABASE_URL=postgresql+asyncpg://...
REDIS_URL=redis://localhost:6379
RABBITMQ_URL=amqp://guest:guest@localhost:5672/
JWT_SECRET=...
NEXTAUTH_SECRET=...
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## Infraestrutura e Deploy

### Hospedagem

**AWS EC2 (t3.micro) + Docker Compose** — produção desde o dia 1.

- Servidor: EC2 t3.micro (~$8/mês), Ubuntu 24 LTS, região `us-east-1`
- PostgreSQL, Redis e RabbitMQ rodam no mesmo EC2 via Docker Compose
- SSL: Certbot + Let's Encrypt (renovação automática via cron)
- Domínio: pedeai.com.br → aponta para o Elastic IP do EC2
- Elastic IP: IP fixo que sobrevive a reboots da instância

### Ambientes

| Ambiente   | Branch    | URL                   |
| ---------- | --------- | --------------------- |
| Production | `main`    | pedeai.com.br         |
| Staging    | `staging` | staging.pedeai.com.br |

Banco de dados separado por ambiente (`pedeai_prod` e `pedeai_staging`).
RabbitMQ e Redis compartilhados com virtual hosts / prefixos separados.

### Serviços no EC2

```
EC2 t3.micro (us-east-1)
└── Docker Compose
    ├── next-prod          → frontend produção  (porta 3000)
    ├── next-staging       → frontend staging   (porta 3001)
    ├── fastapi-prod       → backend produção   (porta 8000)
    ├── fastapi-staging    → backend staging    (porta 8001)
    ├── postgresql         → banco de dados     (porta 5432)
    ├── redis              → cache              (porta 6379)
    └── rabbitmq           → mensageria         (porta 5672)

Nginx como reverse proxy na frente de tudo (portas 80/443)
```

### CI/CD — GitHub Actions

**Branch `staging`** (push automático):

```
1. Lint (ruff + eslint)
2. Testes (pytest + jest)
3. Build Docker
4. SSH no EC2 → docker compose pull + up (staging)
5. Smoke test pós-deploy
```

**Branch `main`** (somente via PR aprovado de staging):

```
1. Lint + Testes
2. Build Docker
3. SSH no EC2 → docker compose pull + up (produção)
4. Smoke test pós-deploy
5. Rollback automático se smoke test falhar
```

Nunca fazer push direto na `main`. Todo código vai para `staging` primeiro.

### Infra as Code (Terraform)

Toda infraestrutura é gerenciada via Terraform. **Nunca criar recursos manualmente** no console da AWS — sempre via código.

```
infra/
├── main.tf           # provider AWS e configurações gerais
├── variables.tf      # variáveis
├── outputs.tf        # outputs (IP, DNS, SSH command)
├── ec2.tf            # instância EC2 + Elastic IP + user_data
├── vpc.tf            # VPC, subnet, internet gateway
├── security.tf       # Security Groups (firewall)
├── dns.tf            # Route 53 (opcional) ou instruções p/ Registro.br
└── terraform.tfvars  # valores sensíveis (não commitar — no .gitignore)
```

Comandos:

```bash
cd infra
terraform init        # inicializar providers
terraform plan        # ver o que vai mudar
terraform apply       # aplicar mudanças
terraform destroy     # destruir tudo (cuidado!)
```

State armazenado remotamente no Terraform Cloud (gratuito até 500 recursos).
**Nunca commitar `terraform.tfstate` ou `terraform.tfvars`.**

---

```
pedeai/
├── .github/workflows/
│   ├── staging.yml     # pipeline do staging
│   └── production.yml  # pipeline da produção
├── frontend/
│   └── Dockerfile
├── backend/
│   └── Dockerfile
└── docker-compose.prod.yml   # referência local de produção
```

---

## Extreme Programming (XP) — Regras do Pair

Este projeto usa XP com Claude como pair programmer. As regras abaixo são
**obrigatórias** em toda sessão de desenvolvimento.

### Papel do Claude neste projeto

Claude é o **pair programmer** — não um assistente passivo. Isso significa:

- Questionar decisões de design quando parecerem complexas demais
- Sugerir refactor sempre que o código ficar difícil de ler
- Recusar implementar código sem teste correspondente
- Apontar violações das convenções deste arquivo imediatamente
- Ser direto: se uma abordagem for ruim, dizer o porquê e propor alternativa

### TDD no Frontend

O frontend tem 3 camadas de teste com ferramentas e ciclos distintos:

**1. Lógica pura — Jest (TDD clássico)**

Hooks, utils, formatadores, validadores. Ciclo idêntico ao backend.

```
test → implementa → refatora → commit
```

```ts
// PRIMEIRO o teste
it("ao adicionar item já existente, incrementa quantidade", () => {
  const { result } = renderHook(() => useCarrinho());
  act(() => result.current.adicionar(mockItem));
  act(() => result.current.adicionar(mockItem));
  expect(result.current.itens[0].qty).toBe(2);
});
// DEPOIS implementa useCarrinho
```

**2. Componentes — React Testing Library (comportamento)**

Testa o que o usuário vê e faz, não a estrutura interna do componente.
Nunca testar classes CSS, estrutura HTML ou detalhes de implementação.

```
teste de comportamento → componente mínimo → refatora
```

```ts
// PRIMEIRO o teste
it('exibe total quando há itens no carrinho', () => {
  render(<Carrinho itens={mockItens} />)
  expect(screen.getByText('R$ 49,90')).toBeInTheDocument()
})
// DEPOIS implementa <Carrinho />
```

**3. Fluxos completos — Playwright (E2E)**

Páginas inteiras e fluxos críticos. Escrito antes da página existir.
Roda contra o ambiente de staging — nunca mocka o backend.

```
teste E2E → implementa a página → passa no E2E → commit
```

```ts
// PRIMEIRO o teste
test("cliente acessa cardápio e adiciona item ao carrinho", async ({
  page,
}) => {
  await page.goto("/sushi-da-hora");
  await page
    .getByText("Combo 20 peças")
    .getByRole("button", { name: "Adicionar" })
    .click();
  await expect(page.getByTestId("carrinho-total")).toContainText("R$ 49,90");
});
// DEPOIS implementa a página /[slug]
```

**O que NUNCA testar:**

- Estilos Tailwind ou CSS — não existe teste de pixel
- Animações e transições — testa comportamento, não visual
- Snapshot tests — frágeis, não documentam intenção
- Detalhes internos de implementação de componentes

**Onde cada teste vive:**

```
frontend/
├── __tests__/
│   ├── hooks/          # Jest — lógica de hooks
│   └── components/     # RTL — comportamento de componentes
└── e2e/                # Playwright — fluxos completos
```

### TDD — Fluxo obrigatório

Todo código novo segue o ciclo Red → Green → Refactor:

```
1. Claude escreve o teste (RED)
2. Humano lê e aprova o teste
3. Claude implementa o mínimo para passar (GREEN)
4. Claude propõe refactor se necessário (REFACTOR)
5. Commit — próxima história
```

Claude NUNCA escreve implementação antes do teste ser aprovado.
Se o humano pedir para "só implementar logo", Claude deve lembrar o ciclo.

### Princípios que Claude deve aplicar ativamente

- **YAGNI** (You Aren't Gonna Need It) — não implementar o que não foi pedido
- **KISS** (Keep It Simple) — questionar toda abstração prematura
- **DRY** (Don't Repeat Yourself) — apontar duplicação antes de prosseguir
- **Small releases** — cada história entregue deve ser commitável e funcional
- **Collective ownership** — Claude conhece e cuida de todo o codebase

### Formato de uma história

Ao iniciar uma nova história, Claude deve confirmar o entendimento assim:

```
História: [nome]
Como [perfil], quero [ação] para [benefício]

Critérios de aceitação:
- [ ] ...
- [ ] ...

Vou escrever os testes para esses critérios. Posso prosseguir?
```

### Definição de Done (DoD)

Uma história só está pronta quando:

- [ ] Testes escritos e passando (`pytest` ou `jest`)
- [ ] Cobertura não regrediu
- [ ] Lint sem erros (`ruff` e `eslint`)
- [ ] Migration gerada se houve mudança no banco
- [ ] Código revisado e refatorado se necessário
- [ ] Commitado com mensagem descritiva

### Fluxo de branches

**Regra absoluta:** antes de iniciar qualquer história, o agente deve verificar
se a história anterior foi mergeada em `staging`. Se não foi, deve parar e avisar.

```
⚠️ Antes de começar a S1-02:
1. A S1-01 foi mergeada em staging?
   → NÃO: avisar o humano e aguardar antes de continuar
   → SIM: prosseguir
```

**Iniciar uma história:**

```bash
# SEMPRE a partir de staging atualizado — sem exceção
git checkout staging
git pull origin staging
git checkout -b S{numero}-{slug-da-historia}

# Exemplos:
# git checkout -b S1-01-cadastro-lojista
# git checkout -b S2-03-aprovar-loja
```

**Commit + push a cada ação do ciclo TDD:**

```bash
# 1. Após escrever o teste (RED)
git add . && git commit -m "test(escopo): descreve o teste" && git push origin S{numero}-{slug}

# 2. Após implementação passar (GREEN)
git add . && git commit -m "feat(escopo): implementação mínima" && git push origin S{numero}-{slug}

# 3. Após refatorar (REFACTOR)
git add . && git commit -m "refactor(escopo): melhoria" && git push origin S{numero}-{slug}

# 4. Ao final da história
git add . && git commit -m "chore(escopo): finaliza S{numero}" && git push origin S{numero}-{slug}
```

**Ao finalizar a história**, o agente deve avisar:

```
✅ S1-01 concluída e pushed.
👉 Abra o PR: S1-01-cadastro-lojista → staging
   Após merge, avise para começarmos a S1-02.
```

O agente NUNCA deve:

- Iniciar história nova sem confirmar que a anterior foi mergeada em staging
- Criar branch a partir de outro feature branch — sempre de staging
- Acumular múltiplas ações num único commit
- Fazer o merge — isso é responsabilidade do humano via PR

### Mensagens de commit

Seguir o padrão Conventional Commits:

```
feat(pedidos): adiciona endpoint de criação de pedido
test(pedidos): adiciona testes para criação de pedido
fix(auth): corrige validação de token expirado
refactor(lojas): extrai lógica de slug para service
chore(deps): atualiza fastapi para 0.111
```

---

## Referências

- PRD: `docs/PRD.docx`
- Protótipo: `docs/prototipo.jsx`
- Docs FastAPI: https://fastapi.tiangolo.com
- Docs Next.js: https://nextjs.org/docs
- Docs aio-pika: https://aio-pika.readthedocs.io
