# PointDog — App Flutter (Cliente + Prestador)

App mobile de agendamento de serviços para pets, desenvolvido em Flutter com arquitetura em camadas (Clean Architecture), integração REST com backend Node.js e comunicação em tempo real via WebSocket.

O app suporta dois perfis de usuário — **CLIENTE** e **PRESTADOR** — selecionáveis no momento do cadastro. Após o login, o GoRouter redireciona automaticamente para a navegação correta de acordo com a role.

---

## Como Executar

### Pré-requisitos
- Flutter SDK 3.x instalado
- Backend rodando (`npm run dev` em `/backend`)
- RabbitMQ rodando (`npm run infra:up` em `/backend`)
- Worker rodando (`npm run worker` em `/backend`)
- Emulador Android (LDPlayer ou AVD) **ou** Chrome

### Passos

```bash
# 1. Instalar dependências
flutter pub get

# 2. Emulador Android
flutter run -d localhost:5555

# 3. Chrome (web)
flutter run -d chrome

# 4. Backend em IP diferente de localhost
flutter run \
  --dart-define=BASE_URL=http://SEU_IP:3000 \
  --dart-define=WS_URL=ws://SEU_IP:3000/ws
```

---

## Telas

### App do Cliente (role = CLIENTE)

| Tela | Rota | Descrição |
|------|------|-----------|
| `LoginScreen` | `/login` | Autenticação com JWT |
| `RegisterScreen` | `/register` | Cadastro com toggle CLIENTE/PRESTADOR |
| `ServicesListScreen` | `/services` | Lista de serviços disponíveis |
| `ServiceDetailScreen` | `/services/:id` | Detalhe + botão Agendar |
| `CreateAppointmentScreen` | `/appointments/new` | Criar agendamento (pet, data, observações) |
| `AppointmentsListScreen` | `/appointments` | Lista com atualização em tempo real (WS) |
| `AppointmentDetailScreen` | `/appointments/:id` | Detalhe + cancelar |
| `PetsScreen` | `/pets` | Listar / Adicionar / Editar / Remover |

### App do Prestador (role = PRESTADOR)

| Tela | Rota | Descrição |
|------|------|-----------|
| `ProviderPendingScreen` | `/provider/pending` | Solicitações PENDENTE — atualiza via WS sem refresh |
| `ProviderActiveScreen` | `/provider/active` | Agendamentos CONFIRMADO |
| `ProviderHistoryScreen` | `/provider/history` | Histórico: CANCELADO + CONCLUÍDO (somente leitura) |
| `ProviderAppointmentDetailScreen` | `/provider/appointments/:id` | Detalhe com ações contextuais por status |

#### Ações contextuais do prestador

| Status atual | Ações disponíveis |
|---|---|
| `PENDENTE` | Aceitar (→ CONFIRMADO) · Recusar (→ CANCELADO) |
| `CONFIRMADO` | Concluir (→ CONCLUÍDO) · Cancelar (→ CANCELADO) |
| `CANCELADO` / `CONCLUÍDO` | Somente leitura |

---

## Arquitetura — Clean Architecture

```
┌─────────────────────────────────────────────────────┐
│                    SCREENS                          │
│  auth/, appointments/, pets/, services/, provider/ │
│  → consome Providers e lê estado                    │
├─────────────────────────────────────────────────────┤
│                    PROVIDERS                        │
│  AppointmentsNotifier, AuthNotifier,                │
│  PetsNotifier, ServicesNotifier                     │
│  → ChangeNotifier, orquestra chamadas REST + WS     │
├─────────────────────────────────────────────────────┤
│                    REPOSITORIES                     │
│  AppointmentsRepository, AuthRepository,            │
│  PetsRepository, ServicesRepository                 │
│  → acesso REST via Dio                              │
├─────────────────────────────────────────────────────┤
│                    MODELS                           │
│  Appointment, Pet, Service, User                    │
│  → fromJson(), copyWith()                           │
└─────────────────────────────────────────────────────┘
                        ↕ HTTP / WebSocket
             Backend Node.js (Express + Prisma + SQLite)
```

### Estrutura de Pastas

```
lib/
├── core/
│   ├── auth/auth_storage.dart       # Token JWT + userId + role (SharedPreferences)
│   ├── config/app_config.dart       # BASE_URL, WS_URL (--dart-define)
│   ├── network/
│   │   ├── http_client.dart         # Dio singleton + interceptor JWT automático
│   │   └── websocket_service.dart   # WS singleton + broadcast stream
│   └── theme.dart                   # Design system (cores, tipografia)
├── models/
│   ├── appointment.dart
│   ├── pet.dart
│   ├── service.dart
│   └── user.dart
├── repositories/
│   ├── appointments_repository.dart  # GET, POST, updateStatus()
│   ├── auth_repository.dart          # login(), register(role:)
│   ├── pets_repository.dart
│   └── services_repository.dart
├── providers/
│   ├── appointments_notifier.dart    # Estado + WS listener (ambos os roles)
│   ├── auth_notifier.dart            # Login/logout + role + WS connect
│   ├── pets_notifier.dart
│   └── services_notifier.dart
└── screens/
    ├── app_shell.dart                # Bottom nav condicional por role
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart      # Toggle CLIENTE / PRESTADOR
    ├── appointments/                 # Telas do cliente
    ├── pets/
    ├── services/
    └── provider/                     # Telas do prestador (Sprint 4)
        ├── provider_appointment_card.dart
        ├── provider_pending_screen.dart
        ├── provider_active_screen.dart
        ├── provider_history_screen.dart
        └── provider_appointment_detail_screen.dart
```

---

## Atualização em Tempo Real (WebSocket)

### Fluxo

```
Backend WebSocketPublisher
        │  ws://host:3000/ws?token=JWT
        ▼
WebSocketService (singleton, broadcast stream)
        │
AppointmentsNotifier.startListening()
        │
        ├── appointment.status_changed → copyWith(status:) na lista local
        │       → UI do CLIENTE atualiza sem HTTP
        │
        └── appointment.created (role=PRESTADOR)
                → loadAll() via REST
                → ProviderPendingScreen atualiza automaticamente
```

### Roteamento de eventos no backend

| Evento | Destinatários |
|--------|--------------|
| `appointment.created` | `clientId` + `providerId` |
| `appointment.status_changed` | `clientId` + `providerId` |

---

## Navegação

Utiliza `go_router` com `ShellRoute` e redirect automático baseado em `AuthStorage.role`:

```dart
redirect: (context, state) {
  if (!loggedIn && !isAuthRoute) return '/login';
  if (loggedIn && isAuthRoute) {
    return AuthStorage().role == 'PRESTADOR'
        ? '/provider/pending'
        : '/services';
  }
  return null;
},
```

---

## Dependências Principais

```yaml
dependencies:
  provider: ^6.x            # Gerenciamento de estado
  go_router: ^14.x          # Navegação declarativa
  dio: ^5.x                 # HTTP client
  web_socket_channel: ^3.x  # WebSocket
  shared_preferences: ^2.x  # Persistência local (JWT + role)
  google_fonts: ^6.x        # Tipografia (Bricolage Grotesque)
```
