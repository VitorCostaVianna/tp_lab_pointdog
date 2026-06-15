# PointDog — Cliente Flutter (Sprint 3)

Video -> https://youtu.be/dNRl7bRGK-w

App mobile de agendamento de serviços para pets, desenvolvido em Flutter com arquitetura em camadas, integração REST com backend Node.js e atualização de estado em tempo real via WebSocket.

---

## Fluxo Completo da Aplicação

```
Registro / Login
      ↓
Lista de Serviços  →  Detalhe do Serviço
                              ↓
                    Criar Agendamento
                    (seleciona pet, data/hora, observações)
                              ↓
                    Lista de Agendamentos  ←─── atualização em tempo real (WS)
                              ↓
                    Detalhe do Agendamento
                              ↓
                    Cancelar Agendamento

Pets  →  Listar / Adicionar / Remover
```

---

## Como Executar

### Pré-requisitos
- Flutter SDK instalado
- Backend rodando (`npm run dev` na pasta `/backend`)
- RabbitMQ rodando (`npm run infra:up` na pasta `/backend`)
- Worker rodando (`npm run worker` na pasta `/backend`)
- Emulador Android (LDPlayer ou AVD) conectado via ADB

### Passos

```bash
# 1. Instalar dependências
flutter pub get

# 2. Rodar no emulador
flutter run -d localhost:5555

# 3. Rodar no Chrome (desenvolvimento web)
flutter run -d chrome
```

### Configuração de URL

A URL base é configurável via variável de ambiente em tempo de compilação:

```bash
flutter run --dart-define=BASE_URL=http://SEU_IP:3000 --dart-define=WS_URL=ws://SEU_IP:3000/ws
```

O valor padrão está definido em `lib/core/config/app_config.dart`.

---

## Arquitetura — Separação em Camadas

O projeto segue uma arquitetura em camadas inspirada em Clean Architecture, com responsabilidades bem definidas:

```
lib/
├── core/                          # Infraestrutura transversal
│   ├── auth/
│   │   └── auth_storage.dart      # Persistência de token JWT (SharedPreferences)
│   ├── config/
│   │   └── app_config.dart        # URLs base (BASE_URL, WS_URL)
│   ├── network/
│   │   ├── http_client.dart       # Singleton Dio + interceptor JWT
│   │   └── websocket_service.dart # Singleton WebSocket + broadcast stream
│   └── theme.dart                 # Design system (cores, tipografia)
│
├── models/                        # Entidades de dados
│   ├── appointment.dart
│   ├── pet.dart
│   ├── service.dart
│   └── user.dart
│
├── repositories/                  # Acesso a dados (REST)
│   ├── appointments_repository.dart
│   ├── auth_repository.dart
│   ├── pets_repository.dart
│   └── services_repository.dart
│
├── providers/                     # Gerenciamento de estado (ChangeNotifier)
│   ├── appointments_notifier.dart  ← também escuta WebSocket
│   ├── auth_notifier.dart          ← gerencia login/logout + conexão WS
│   ├── pets_notifier.dart
│   └── services_notifier.dart
│
└── screens/                       # Interface do usuário
    ├── app_shell.dart             # ShellRoute com BottomNavigationBar
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











