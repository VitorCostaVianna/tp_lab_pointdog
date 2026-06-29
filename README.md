# PointDog

Plataforma de agendamento de serviços para pets (banho, tosa e similares), desenvolvida ao longo de 4 sprints como projeto da disciplina **Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas** — PUC Minas, Engenharia de Software, 1º Semestre 2026.

**Aluno:** Vitor Costa Vianna

---

## Demonstrações

| Sprint | Vídeo |
|--------|-------|
| Sprint 2 — Backend + MOM | [`docs/sprint2/video_sprint2.mp4`](docs/sprint2/video_sprint2.mp4) |
| Sprint 3 — App Cliente Flutter | [`docs/sprint3/video_sprint3.mp4`](docs/sprint3/video_sprint3.mp4) |
| Sprint 4 — App Prestador + Fluxo Completo | [https://youtu.be/5ssTpoYluIE](https://youtu.be/5ssTpoYluIE) |

---

## Estrutura do Repositório

```
tp_lab_pointdog/
├── backend/          # API REST + WebSocket + Worker RabbitMQ (Node.js/TypeScript)
├── client/           # App Flutter — cliente e prestador (role-based)
└── docs/
    ├── sprint1/      # Enunciado do projeto (PDF)
    ├── sprint2/      # Documentação MOM, Postman collection, PDF, vídeo
    ├── sprint3/      # Navigation flow, vídeo
    └── sprint4/      # Relatório técnico final, vídeo (a adicionar)
```

---

## Arquitetura Geral

```
┌──────────────────────────────────────────────────────────────────────┐
│                         App Flutter (client/)                        │
│                                                                      │
│   CLIENTE                          PRESTADOR                         │
│   ─────────────────────────────    ──────────────────────────────    │
│   ServicesListScreen               ProviderPendingScreen             │
│   AppointmentsListScreen           ProviderActiveScreen              │
│   PetsScreen                       ProviderHistoryScreen             │
│   AppointmentDetailScreen          ProviderAppointmentDetailScreen   │
│                                                                      │
│   ──────── GoRouter (redirect por role) + AppShell ────────────      │
│   ──────── AppointmentsNotifier + AuthNotifier (compartilhados) ─    │
└──────────────────────────┬───────────────────────────────────────────┘
                           │ REST (Dio + JWT)  │ WebSocket
                           ▼                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    Backend Node.js (backend/)                        │
│                                                                      │
│  Express → Controllers → Use Cases → Repositories → Prisma/SQLite   │
│                              │                                       │
│                    CompositePublisher                                │
│                    ├── RabbitMQPublisher  ──► RabbitMQ (MOM)        │
│                    └── WebSocketPublisher ──► App em tempo real      │
└──────────────────────────────────────────────────────────────────────┘
                                │ AMQP
                                ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    RabbitMQ (Docker Compose)                         │
│   Exchange: pointdog.events (topic)                                  │
│   Fila: pointdog.notifications  |  Binding: appointment.*            │
│   Worker: appointment.worker.ts → processa eventos assíncronos       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Fluxo Completo Ponta a Ponta

```
[Cliente] cria agendamento → POST /appointments
      │
      ▼
[Backend] salva → publica appointment.created
      ├──► RabbitMQ → Worker (processamento assíncrono)
      └──► WebSocket → clientId + providerId
                              │
                  ┌───────────┴───────────┐
                  ▼                       ▼
         [Cliente] lista         [Prestador] ProviderPendingScreen
         atualiza                atualiza em tempo real (sem refresh)

[Prestador] aceita → PATCH /appointments/:id/status { CONFIRMADO }
      │
      ▼
[Backend] valida role PRESTADOR → publica appointment.status_changed
      └──► WebSocket → clientId
                          │
                          ▼
                 [Cliente] status atualiza em tempo real
```

---

## Backend

### Tecnologias

| Tecnologia | Versão | Uso |
|---|---|---|
| Node.js | 18+ | Runtime |
| TypeScript | 6.x | Linguagem |
| Express | 4.x | API REST |
| Prisma | 6.x | ORM |
| SQLite | — | Banco de dados |
| JWT (`jsonwebtoken`) | — | Autenticação |
| RabbitMQ (`amqplib`) | — | Message broker (MOM) |
| `ws` | — | WebSocket server |
| Jest | — | Testes (55 testes) |
| Docker Compose | — | Infraestrutura local |

### Endpoints da API

#### Autenticação
| Método | Rota | Descrição |
|--------|------|-----------|
| `POST` | `/auth/register` | Cadastro (`role`: `CLIENTE` ou `PRESTADOR`) |
| `POST` | `/auth/login` | Login → retorna JWT + `user.role` |

#### Agendamentos
| Método | Rota | Descrição | Role |
|--------|------|-----------|------|
| `GET` | `/appointments` | Lista agendamentos do usuário autenticado | CLIENTE + PRESTADOR |
| `GET` | `/appointments/:id` | Detalhe do agendamento | CLIENTE + PRESTADOR |
| `POST` | `/appointments` | Criar agendamento | CLIENTE |
| `PATCH` | `/appointments/:id/status` | Atualizar status | PRESTADOR |

#### Pets
| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/pets` | Lista pets do usuário |
| `POST` | `/pets` | Criar pet |
| `PUT` | `/pets/:id` | Editar pet |
| `DELETE` | `/pets/:id` | Remover pet |

#### Serviços
| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/services` | Lista serviços disponíveis |
| `GET` | `/services/:id` | Detalhe do serviço |

### Eventos MOM

| Evento | Publicado por | Routing Key | Payload principal |
|--------|--------------|-------------|-------------------|
| `appointment.created` | `CreateAppointmentUseCase` | `appointment.created` | `appointmentId`, `clientId`, `providerId`, `petId`, `serviceId` |
| `appointment.status_changed` | `UpdateAppointmentStatusUseCase` | `appointment.status_changed` | `appointmentId`, `clientId`, `providerId`, `previousStatus`, `newStatus` |

### Executar o Backend

```bash
cd backend

# 1. Subir RabbitMQ (Docker)
npm run infra:up

# 2. Instalar dependências e migrar banco
npm install
npx prisma migrate deploy

# 3. Iniciar API REST
npm run dev                 # porta 3000

# 4. Iniciar Worker RabbitMQ (terminal separado)
npm run worker

# 5. Rodar testes
npm test                    # 55 testes
```

### Arquitetura do Backend (Clean Architecture)

```
src/
├── modules/
│   ├── auth/
│   │   ├── application/        # LoginUserUseCase, RegisterUserUseCase
│   │   ├── domain/             # User, IUserRepository
│   │   └── infrastructure/     # UserRepository (Prisma), AuthController
│   ├── appointments/
│   │   ├── application/        # CreateAppointmentUseCase, UpdateAppointmentStatusUseCase
│   │   ├── domain/             # Appointment, IAppointmentRepository
│   │   └── infrastructure/     # AppointmentRepository (Prisma), AppointmentsController
│   ├── pets/
│   └── services/
├── shared/
│   ├── messaging/              # IEventPublisher, RabbitMQPublisher, WebSocketPublisher, CompositePublisher
│   └── services/               # JwtService
└── workers/
    └── appointment.worker.ts   # Consumidor RabbitMQ
```

---

## App Flutter

### Tecnologias

| Pacote | Versão | Uso |
|---|---|---|
| Flutter | 3.x | Framework |
| `provider` | ^6.x | Gerenciamento de estado |
| `go_router` | ^14.x | Navegação declarativa |
| `dio` | ^5.x | HTTP client |
| `web_socket_channel` | ^3.x | WebSocket |
| `shared_preferences` | ^2.x | Persistência local (JWT, role) |
| `google_fonts` | ^6.x | Tipografia |

### Telas

#### App do Cliente (role = CLIENTE)
| Tela | Rota | Descrição |
|------|------|-----------|
| `LoginScreen` | `/login` | Autenticação |
| `RegisterScreen` | `/register` | Cadastro com toggle CLIENTE/PRESTADOR |
| `ServicesListScreen` | `/services` | Lista de serviços disponíveis |
| `ServiceDetailScreen` | `/services/:id` | Detalhe + botão Agendar |
| `CreateAppointmentScreen` | `/appointments/new` | Criar agendamento |
| `AppointmentsListScreen` | `/appointments` | Agendamentos (atualização WS) |
| `AppointmentDetailScreen` | `/appointments/:id` | Detalhe + cancelar |
| `PetsScreen` | `/pets` | Gerenciar pets |

#### App do Prestador (role = PRESTADOR)
| Tela | Rota | Descrição |
|------|------|-----------|
| `ProviderPendingScreen` | `/provider/pending` | Solicitações PENDENTE (WS) |
| `ProviderActiveScreen` | `/provider/active` | Agendamentos CONFIRMADO |
| `ProviderHistoryScreen` | `/provider/history` | Histórico CANCELADO + CONCLUÍDO |
| `ProviderAppointmentDetailScreen` | `/provider/appointments/:id` | Detalhe + Aceitar/Recusar/Concluir/Cancelar |

### Executar o App

```bash
cd client

# Instalar dependências
flutter pub get

# Emulador Android (LDPlayer ou AVD)
flutter run -d localhost:5555

# Chrome (desenvolvimento web)
flutter run -d chrome

# URL personalizada (IP diferente de localhost)
flutter run \
  --dart-define=BASE_URL=http://SEU_IP:3000 \
  --dart-define=WS_URL=ws://SEU_IP:3000/ws
```

### Arquitetura do App (Clean Architecture)

```
lib/
├── core/
│   ├── auth/auth_storage.dart       # Token JWT + role (SharedPreferences)
│   ├── config/app_config.dart       # URLs base
│   ├── network/
│   │   ├── http_client.dart         # Dio singleton + interceptor JWT
│   │   └── websocket_service.dart   # WS singleton + broadcast stream
│   └── theme.dart                   # Design system
├── models/                          # Appointment, Pet, Service, User
├── repositories/                    # REST: Appointments, Auth, Pets, Services
├── providers/                       # ChangeNotifier: Appointments, Auth, Pets, Services
└── screens/
    ├── app_shell.dart               # Bottom nav condicional por role
    ├── auth/                        # Login, Register (toggle de role)
    ├── appointments/                # Telas do cliente
    ├── pets/
    ├── services/
    └── provider/                    # Telas do prestador (Sprint 4)
```

---

## Documentação por Sprint

| Sprint | Foco | Documentação |
|--------|------|-------------|
| Sprint 1 | Backend REST + Clean Architecture | [`docs/sprint1/projeto-pointdog-enunciado.pdf`](docs/sprint1/projeto-pointdog-enunciado.pdf) |
| Sprint 2 | Mensageria assíncrona (RabbitMQ/MOM) | [`docs/sprint2/sprint2-documentacao.md`](docs/sprint2/sprint2-documentacao.md) |
| Sprint 3 | App Flutter do cliente | [`docs/sprint3/navigation-flow.md`](docs/sprint3/navigation-flow.md) |
| Sprint 4 | App prestador + integração final | [`docs/sprint4/sprint4-documentacao.md`](docs/sprint4/sprint4-documentacao.md) |

---

## Testes

```bash
# Backend — 55 testes (Jest)
cd backend && npm test

# Flutter — análise estática
cd client && flutter analyze
```
