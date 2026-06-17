# Relatório Técnico — Sprint 3
## PointDog: Aplicativo Flutter para o Cliente

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Instituição:** PUC Minas — Engenharia de Software  
**Aluno:** Vitor Costa Vianna  
**Data:** Junho de 2026  

---

## 1. Objetivo

Desenvolver o aplicativo móvel Flutter destinado ao usuário cliente, com integração funcional ao backend REST e recebimento de atualizações de estado por meio de WebSocket (mecanismo assíncrono equivalente ao MOM).

---

## 2. Funcionalidades Entregues

O app possui **7 telas funcionais** (acima do mínimo de 3 exigido), cobrindo o fluxo completo do cliente:

| Tela | Rota | Descrição |
|------|------|-----------|
| `LoginScreen` | `/login` | Autenticação com e-mail e senha |
| `RegisterScreen` | `/register` | Criação de conta |
| `ServicesListScreen` | `/services` | Listagem de serviços disponíveis |
| `ServiceDetailScreen` | `/services/:id` | Detalhes do serviço + botão Agendar |
| `CreateAppointmentScreen` | `/appointments/new` | Criação de agendamento (pet, data, observações) |
| `AppointmentsListScreen` | `/appointments` | Lista de agendamentos com atualização em tempo real |
| `AppointmentDetailScreen` | `/appointments/:id` | Detalhe do agendamento + opção de cancelar |
| `PetsScreen` | `/pets` | Gerenciamento de pets (listar / adicionar / editar / remover) |

### Fluxo Completo Executável

```
Registro / Login
      │
      ▼
Lista de Serviços  ──[tap]──►  Detalhe do Serviço
                                      │
                                      └──[Agendar]──►  Criar Agendamento
                                                              │
                                                              ▼
                                              Lista de Agendamentos  ◄── WS (tempo real)
                                                              │
                                                              └──[tap]──►  Detalhe
                                                                               │
                                                                               └──[Cancelar]

Pets ──►  Listar / Adicionar / Editar / Remover (swipe)
```

---

## 3. Integração com o Backend REST

### HTTP Client — Interceptor JWT Automático

Toda comunicação com o backend passa por um singleton `AppHttpClient` (Dio) com interceptor que injeta o JWT automaticamente em cada requisição:

```dart
_dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    final token = AuthStorage().token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  },
));
```

### Endpoints Consumidos

| Método | Endpoint | Tela que consome |
|--------|----------|-----------------|
| `POST` | `/auth/register` | `RegisterScreen` |
| `POST` | `/auth/login` | `LoginScreen` |
| `GET` | `/services` | `ServicesListScreen` |
| `GET` | `/services/:id` | `ServiceDetailScreen` |
| `GET` | `/appointments` | `AppointmentsListScreen` |
| `GET` | `/appointments/:id` | `AppointmentDetailScreen` |
| `POST` | `/appointments` | `CreateAppointmentScreen` |
| `PATCH` | `/appointments/:id/status` | `AppointmentDetailScreen` (cancelar) |
| `GET` | `/pets` | `PetsScreen`, `CreateAppointmentScreen` |
| `POST` | `/pets` | `PetsScreen` |
| `PUT` | `/pets/:id` | `PetsScreen` |
| `DELETE` | `/pets/:id` | `PetsScreen` |

### Configuração de URL (Runtime)

A URL base é configurável via `--dart-define` sem necessidade de recompilar:

```bash
flutter run \
  --dart-define=BASE_URL=http://SEU_IP:3000 \
  --dart-define=WS_URL=ws://SEU_IP:3000/ws
```

---

## 4. Atualização Assíncrona de Estado (WebSocket)

### Motivação

Quando o prestador aceita ou altera o status de um agendamento no backend, o app do cliente precisa refletir essa mudança **sem exigir ação manual** (sem pull-to-refresh). A solução adotada foi WebSocket, que já estava disponível no backend (Sprint 2) e oferece latência mínima comparado a polling.

### Arquitetura do Fluxo Assíncrono

```
Backend (Node.js)
    │  publica appointment.status_changed
    │  via WebSocketEventPublisher
    │
    │  ws://host:3000/ws?token=JWT
    ▼
WebSocketService (singleton, broadcast stream)
    │  jsonDecode → Map<String, dynamic>
    │  StreamController.broadcast()
    │
AppointmentsNotifier.startListening()
    │  filtra: eventType == 'appointment.status_changed'
    │  atualiza _appointments com copyWith(status: newStatus)
    │
ChangeNotifier.notifyListeners()
    │
Consumer<AppointmentsNotifier>
    │
    └──► UI atualiza imediatamente, sem nova requisição HTTP
```

### Implementação — `WebSocketService`

```dart
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  WebSocketChannel? _channel;

  void connect() {
    final token = AuthStorage().token;
    final uri = Uri.parse('${AppConfig.wsUrl}?token=$token');
    _channel = WebSocketChannel.connect(uri);
    _channel!.stream.listen(
      (data) => _controller.add(jsonDecode(data as String)),
    );
  }
}
```

- **Singleton:** uma única conexão WebSocket para todo o app
- **Broadcast stream:** múltiplos `Notifier` podem se inscrever no mesmo canal
- **Autenticação:** token JWT enviado como query parameter na abertura da conexão
- **Ciclo de vida:** conecta no login (`AuthNotifier.login()`), desconecta no logout

### Implementação — `AppointmentsNotifier` (listener WS)

```dart
void startListening() {
  _wsSub = _ws.stream.listen((event) {
    if (event['eventType'] == 'appointment.status_changed') {
      final appointmentId = event['payload']['appointmentId'] as String;
      final newStatus     = event['payload']['newStatus']     as String;

      _appointments = _appointments.map((a) =>
        a.id == appointmentId ? a.copyWith(status: newStatus) : a
      ).toList();

      if (_selected?.id == appointmentId) {
        _selected = _selected!.copyWith(status: newStatus);
      }

      notifyListeners(); // UI reage instantaneamente
    }
  });
}
```

### Indicador Visual "ao vivo"

A tela de agendamentos exibe um badge animado enquanto o WebSocket está ativo, fornecendo feedback visual ao usuário:

```
● ao vivo   ← ponto com FadeTransition repeat(reverse: true)
```

---

## 5. Arquitetura do App — Clean Architecture

O app segue o padrão Clean Architecture com 4 camadas bem definidas. A regra de dependência é rigorosamente aplicada: cada camada conhece apenas a camada imediatamente abaixo.

### Diagrama de Camadas

```
┌─────────────────────────────────────────────────────┐
│                    SCREENS                          │
│  login, register, services, appointments, pets      │
│  → captura ações do usuário, exibe estado           │
│  → pasta: lib/screens/                              │
├─────────────────────────────────────────────────────┤
│                    WIDGETS (Providers)              │
│  AppointmentsNotifier  AuthNotifier                 │
│  PetsNotifier          ServicesNotifier             │
│  → ChangeNotifier, orquestra REST + WS              │
│  → pasta: lib/providers/                            │
├─────────────────────────────────────────────────────┤
│                    SERVICES (Repositories)          │
│  AppointmentsRepository  AuthRepository             │
│  PetsRepository          ServicesRepository         │
│  HTTP Client (Dio + JWT interceptor)                │
│  WebSocketService                                   │
│  → acessa o backend REST e WebSocket                │
│  → pasta: lib/repositories/ + lib/core/network/    │
├─────────────────────────────────────────────────────┤
│                    MODELS                           │
│  Appointment  Pet  Service  User                    │
│  → estrutura dos dados, fromJson(), copyWith()      │
│  → pasta: lib/models/                               │
└─────────────────────────────────────────────────────┘
                        ↕ HTTP / WebSocket
             Backend Node.js (Express + Prisma + SQLite)
```

### Regra de Dependência

| Camada | Pasta | Conhece | Não conhece |
|--------|-------|---------|-------------|
| Screens | `lib/screens/` | Providers | Repositories, Dio |
| Providers | `lib/providers/` | Repositories, WebSocketService | Dio, screens |
| Repositories | `lib/repositories/` | Http client (Dio) | Providers, screens |
| Core/Network | `lib/core/network/` | AuthStorage, AppConfig | Qualquer camada acima |
| Models | `lib/models/` | Nada | Independente |

### Estrutura Completa de Pastas

```
lib/
├── core/
│   ├── auth/
│   │   └── auth_storage.dart        # Persistência JWT (SharedPreferences)
│   ├── config/
│   │   └── app_config.dart          # BASE_URL, WS_URL via --dart-define
│   ├── network/
│   │   ├── http_client.dart         # Singleton Dio + interceptor JWT
│   │   └── websocket_service.dart   # Singleton WS + broadcast stream
│   └── theme.dart                   # Design system (cores, tipografia)
│
├── models/
│   ├── appointment.dart             # fromJson(), copyWith()
│   ├── pet.dart
│   ├── service.dart
│   └── user.dart
│
├── repositories/
│   ├── appointments_repository.dart
│   ├── auth_repository.dart
│   ├── pets_repository.dart
│   └── services_repository.dart
│
├── providers/
│   ├── appointments_notifier.dart   # estado + listener WS
│   ├── auth_notifier.dart           # login/logout + conecta WS
│   ├── pets_notifier.dart
│   └── services_notifier.dart
│
└── screens/
    ├── app_shell.dart               # ShellRoute + BottomNavigationBar
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── appointments/
    │   ├── appointments_list_screen.dart
    │   └── appointment_detail_screen.dart
    ├── pets/
    │   └── pets_screen.dart
    └── services/
        ├── services_list_screen.dart
        ├── service_detail_screen.dart
        └── create_appointment_screen.dart
```

---

## 6. Gerenciamento de Estado

Utiliza o pacote `provider` com `ChangeNotifier`. Todos os notifiers são registrados globalmente no `main.dart` via `MultiProvider`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider.value(value: _authNotifier),         // autenticação + WS
    ChangeNotifierProvider(create: (_) => ServicesNotifier()),  // serviços
    ChangeNotifierProvider(create: (_) => PetsNotifier()),      // pets
    ChangeNotifierProvider.value(value: _appointmentsNotifier), // agendamentos + WS
  ],
)
```

Cada notifier expõe: `loading`, `error`, lista de dados e métodos de ação (`loadAll`, `create`, `cancel`, etc.).

---

## 7. Navegação

Utiliza `go_router` com:
- **`ShellRoute`** para a barra de navegação inferior (3 abas: Serviços / Agendamentos / Pets)
- **Redirect automático** por estado de autenticação
- **Rotas de detalhe** fora do shell (sem bottom nav)

```dart
redirect: (context, state) {
  if (!loggedIn && !isAuthRoute) return '/login';
  if (loggedIn && isAuthRoute)  return '/services';
  return null;
},
```

### Mapa de Navegação

```
/login
/register

ShellRoute (bottom nav)
├── /services
│       └── /services/:id  ──► /appointments/new
├── /appointments
│       └── /appointments/:id
└── /pets
```

---

## 8. Qualidade da Interface

O design segue um sistema visual consistente definido em `lib/core/theme.dart`:

- **Tema escuro** como padrão
- **Tipografia:** Google Fonts (Bricolage Grotesque) para títulos
- **Paleta de status de agendamento:**

| Status | Cor |
|--------|-----|
| `PENDENTE` | Âmbar |
| `CONFIRMADO` | Verde |
| `CANCELADO` | Vermelho |
| `CONCLUIDO` | Azul |

- **Feedback visual:** indicador "ao vivo" animado na lista de agendamentos enquanto o WebSocket está ativo
- **Pull-to-refresh** em todas as listas
- **Loading states** com `CircularProgressIndicator` durante chamadas REST
- **Error states** com `SnackBar` para falhas de rede

---

## 9. Como Executar

### Pré-requisitos

- Flutter SDK 3.x
- Backend rodando (`npm run dev` em `/backend`)
- RabbitMQ rodando (`npm run infra:up` em `/backend`)
- Worker rodando (`npm run worker` em `/backend`)
- Emulador Android (LDPlayer / AVD) **ou** Chrome

### Passos

```bash
cd client

flutter pub get

# Emulador Android
flutter run -d localhost:5555

# Chrome
flutter run -d chrome

# IP personalizado
flutter run \
  --dart-define=BASE_URL=http://SEU_IP:3000 \
  --dart-define=WS_URL=ws://SEU_IP:3000/ws
```

---

## 10. Evidências de Funcionamento

App executado com sucesso no LDPlayer (Android 9, API 28). Agendamento criado via app com evento processado pelo worker RabbitMQ:

```
[WORKER] ─── Evento recebido ───────────────────────
[WORKER] Tipo: appointment.created
[WORKER] Novo agendamento criado: f5c55579-43cf-4be1-a9c2-a591baa87287
[WORKER] Cliente: 286398d6-200d-48db-8e45-ff9946e1bf05
[WORKER] Pet: ebcf9565-9277-4b37-9526-e57ff1d03fc3
[WORKER] Prestador: 714a6541-b424-49f7-8d16-45c0c84c02b8
[WORKER] Serviço: 8d7a38e5-59fd-4458-80b5-107d2145ae8c
[WORKER] ✓ Notificação enviada.
[WORKER] ────────────────────────────────────────────
```

WebSocket conectado após login, atualizando status de agendamentos em tempo real sem recarregar a tela.

**Vídeo de demonstração:** [`video_sprint3.mp4`](video_sprint3.mp4)

---

## 11. Dependências Principais

```yaml
dependencies:
  provider: ^6.x            # Gerenciamento de estado
  go_router: ^14.x          # Navegação declarativa
  dio: ^5.x                 # HTTP client
  web_socket_channel: ^3.x  # WebSocket
  shared_preferences: ^2.x  # Persistência local (token JWT)
  google_fonts: ^6.x        # Tipografia
```
