# PedeAí

Marketplace de alimentação brasileiro onde restaurantes e lojas de comida se cadastram e ganham uma página pública em `pedeai.com.br/[slug]`.

## Stack

- **Frontend:** Next.js 15 (App Router), TypeScript, Tailwind CSS
- **Backend:** FastAPI (Python 3.11+), Pydantic v2
- **Mensageria:** RabbitMQ (via `aio-pika`)
- **Banco de dados:** PostgreSQL (via SQLAlchemy async + Alembic)
- **Cache / Sessões:** Redis
- **Infra local:** Docker Compose

---

## Setup Local

### Pré-requisitos

- [Docker](https://www.docker.com/products/docker-desktop) e Docker Compose
- [Node.js 20+](https://nodejs.org/)
- [Python 3.11+](https://www.python.org/)

### 1. Clonar o repositório

```bash
git clone https://github.com/seu-usuario/pede-ai.git
cd pede-ai
```

### 2. Configurar variáveis de ambiente

```bash
cp .env.example .env
# Editar .env com seus valores
```

### 3. Subir a infraestrutura (PostgreSQL, Redis, RabbitMQ)

```bash
docker-compose up -d
```

Serviços disponíveis após o `up`:

| Serviço     | URL / Porta                      |
| ----------- | -------------------------------- |
| PostgreSQL  | `localhost:5432`                 |
| Redis       | `localhost:6379`                 |
| RabbitMQ    | `localhost:5672`                 |
| RabbitMQ UI | http://localhost:15672           |

### 4. Backend (FastAPI)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head               # aplicar migrations
uvicorn app.main:app --reload      # http://localhost:8000
```

Documentação interativa: http://localhost:8000/docs

### 5. Frontend (Next.js)

```bash
cd frontend
npm install
npm run dev                        # http://localhost:3000
```

---

## Comandos úteis

```bash
# Backend
cd backend
pytest                             # rodar testes
pytest --cov=app                   # com cobertura
alembic revision --autogenerate -m "descricao"  # nova migration
ruff check .                       # lint

# Frontend
cd frontend
npm run test                       # Jest
npm run test:e2e                   # Playwright
npm run lint                       # ESLint
npm run build                      # build de produção
```

---

## Estrutura do projeto

```
pede-ai/
├── frontend/          # Next.js App (porta 3000)
├── backend/           # FastAPI (porta 8000)
├── infra/             # Terraform — infraestrutura como código
├── docs/              # Documentação (PRD, Stories)
├── .github/workflows/ # CI/CD GitHub Actions
├── docker-compose.yml # Serviços de infraestrutura local
└── CLAUDE.md          # Guia para desenvolvimento com IA
```

---

## Branches

| Branch    | Finalidade                            |
| --------- | ------------------------------------- |
| `main`    | Produção — só via PR aprovado         |
| `staging` | Homologação — deploy automático no CI |

Nunca fazer push direto em `main`. Toda história começa em um branch criado a partir de `staging`.

---

## Documentação

- [PRD — Product Requirements Document](docs/PRD.md)
- [Stories — User Stories e backlog](docs/STORIES.md)
- [CLAUDE.md — Guia de desenvolvimento](CLAUDE.md)
