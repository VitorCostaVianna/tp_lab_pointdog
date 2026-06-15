# PointDog

Plataforma de agendamento de serviços para pets.

**Demonstração Sprint 3:** https://youtu.be/e-qaSETyqBA

---

## Estrutura do Repositório

```
tp_lab_pointdog/
├── backend/    # API REST + WebSocket + Worker RabbitMQ (Node.js)
├── client/     # App mobile Flutter
```

---

## Arquitetura Geral

```
App Flutter
  screens → providers → repositories → Dio
       │ REST              │ WebSocket
       ▼                   ▼
  Backend Node.js (Express + Prisma + SQLite)
       │ AMQP
       ▼
  Worker RabbitMQ
```

---

## Fluxo da Aplicação

```
Login / Registro
      ↓
Serviços → Detalhe → Criar Agendamento
                           ↓
              Agendamentos ←── WebSocket (tempo real)
                           ↓
                  Detalhe → Cancelar

Pets → Listar / Adicionar / Editar / Remover
```

---

## Estrutura Flutter (`/client`)

```
lib/
├── core/           # HTTP client, WebSocket, auth, config, tema
├── models/         # Appointment, Pet, Service, User
├── repositories/   # Acesso REST (Dio)
├── providers/      # Estado (ChangeNotifier)
└── screens/        # UI (auth, services, appointments, pets)
```
