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

## Arquitetura do App Flutter — Clean Architecture

Diagrama de camadas conforme padrão Clean Architecture:

```
┌─────────────────────────────────────────────────────┐
│                     SCREENS                         │
│  login, register, services, appointments, pets      │
│  → exibe dados, captura ações do usuário            │
│  → pasta: lib/screens/                              │
├─────────────────────────────────────────────────────┤
│                     WIDGETS                         │
│  AppointmentsNotifier, AuthNotifier,                │
│  PetsNotifier, ServicesNotifier                     │
│  → gerencia estado (ChangeNotifier / Provider)      │
│  → pasta: lib/providers/                            │
├─────────────────────────────────────────────────────┤
│                     SERVICES                        │
│  AppointmentsRepository, PetsRepository,            │
│  AuthRepository, ServicesRepository                 │
│  HTTP Client (Dio + JWT), WebSocketService          │
│  → acessa o backend REST e WebSocket                │
│  → pasta: lib/repositories/ + lib/core/network/    │
├─────────────────────────────────────────────────────┤
│                     MODELS                          │
│  Appointment, Pet, Service, User                    │
│  → estrutura dos dados, fromJson(), copyWith()      │
│  → pasta: lib/models/                               │
└─────────────────────────────────────────────────────┘
                        ↕ HTTP / WebSocket
             Backend Node.js (Express + Prisma + SQLite)
```

### Regra de dependência

Cada camada só conhece a camada imediatamente abaixo:

| Camada | Pasta | Conhece |
|--------|-------|---------|
| Screens | `lib/screens/` | Widgets (providers) |
| Widgets | `lib/providers/` | Services (repositories) |
| Services | `lib/repositories/` + `lib/core/` | Models |
| Models | `lib/models/` | Nada (independente) |

### Estrutura de Pastas

```
lib/
├── core/           # HTTP client (Dio + JWT), WebSocket, auth, config, tema
├── models/         # Appointment, Pet, Service, User
├── repositories/   # Acesso REST — camada Services
├── providers/      # Estado (ChangeNotifier) — camada Widgets
└── screens/        # Interface do usuário — camada Screens
```
