# PointDog — Cliente Flutter (Sprint 3)

Video -> https://youtu.be/e-qaSETyqBA

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











