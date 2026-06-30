# Sprint 1 — Arquitetura e Backend REST

## Entregas

- **Proposta de domínio:** ver `point_dog.pdf` nesta pasta.
- **Diagrama de arquitetura:** descrito no `README.md` da raiz e no arquivo de spec em `docs/superpowers/specs/2026-05-04-sprint1-design.md`.
- **Coleção de testes (Postman):** [`../sprint2/pointdog-sprint2-demo.postman_collection.json`](../sprint2/pointdog-sprint2-demo.postman_collection.json)

## Endpoints implementados

| Método | Rota | Descrição | Role |
|--------|------|-----------|------|
| `POST` | `/auth/register` | Cadastro (`role`: `CLIENTE` ou `PRESTADOR`) | — |
| `POST` | `/auth/login` | Login → retorna JWT + `user.role` | — |
| `GET` | `/appointments` | Lista agendamentos do usuário autenticado | CLIENTE + PRESTADOR |
| `GET` | `/appointments/:id` | Detalhe do agendamento | CLIENTE + PRESTADOR |
| `POST` | `/appointments` | Criar agendamento | CLIENTE |
| `PATCH` | `/appointments/:id/status` | Atualizar status (PRESTADOR: confirmar/concluir/cancelar; CLIENTE: cancelar) | CLIENTE + PRESTADOR |
| `GET` | `/pets` | Lista pets do usuário | CLIENTE |
| `POST` | `/pets` | Criar pet | CLIENTE |
| `PUT` | `/pets/:id` | Editar pet | CLIENTE |
| `DELETE` | `/pets/:id` | Remover pet | CLIENTE |
| `GET` | `/services` | Lista serviços disponíveis | CLIENTE |
| `GET` | `/services/:id` | Detalhe do serviço | CLIENTE |

## Como executar

```bash
cd backend
npm install
npx prisma migrate deploy
npm run dev   # porta 3000
```

Ver instruções completas no `README.md` da raiz.
