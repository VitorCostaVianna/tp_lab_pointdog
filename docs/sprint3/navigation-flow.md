# Fluxo de Navegação — PointDog Cliente (Sprint 3)

## Visão Geral

App Flutter para o usuário **CLIENTE**, com autenticação JWT, bottom navigation e atualização em tempo real via WebSocket.

## Telas

| Tela | Rota | Endpoints consumidos | WebSocket |
|---|---|---|---|
| `LoginScreen` | `/login` | `POST /auth/login` | — |
| `RegisterScreen` | `/register` | `POST /auth/register` | — |
| `ServicesListScreen` | `/services` | `GET /services` | — |
| `ServiceDetailScreen` | `/services/:id` | `GET /services/:id` | — |
| `CreateAppointmentScreen` | `/appointments/new` | `POST /appointments`, `GET /pets` | — |
| `AppointmentsListScreen` | `/appointments` | `GET /appointments` | ✓ |
| `AppointmentDetailScreen` | `/appointments/:id` | `GET /appointments/:id`, `PATCH /appointments/:id/status` | ✓ |
| `PetsScreen` | `/pets` | `GET /pets`, `POST /pets` | — |

## Fluxo de Autenticação

```
LoginScreen ──→ RegisterScreen (link)
     │
     └──→ [JWT salvo] ──→ Bottom Navigation (3 abas)
```

## Bottom Navigation

```
┌─────────────────────────────────────────┐
│  🐾 Serviços │ 📅 Agendamentos │ 🐶 Pets │
└─────────────────────────────────────────┘
```

## Fluxo Principal por Aba

### Aba 1 — Serviços
```
ServicesListScreen
     │
     └──[tap serviço]──→ ServiceDetailScreen
                              │
                              └──[botão Agendar]──→ CreateAppointmentScreen
```

### Aba 2 — Agendamentos (WebSocket ativo)
```
AppointmentsListScreen ←── WebSocket (atualização automática de status)
     │
     └──[tap agendamento]──→ AppointmentDetailScreen
                                   │
                                   └──[cancelar se PENDENTE/CONFIRMADO]
```

### Aba 3 — Pets
```
PetsScreen (lista + botão "Novo Pet" → bottom sheet/dialog)
```

## WebSocket

- Conecta após login em `ws://<base_url>/ws?token=<jwt>`
- Recebe eventos `appointment.status_changed` do backend
- `AppointmentsNotifier` e `AppointmentDetailNotifier` escutam o stream e atualizam o estado automaticamente
