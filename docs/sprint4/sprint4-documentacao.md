# Relatório Técnico — Sprint 4
## PointDog: Aplicativo do Prestador e Integração Final

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Instituição:** PUC Minas — Engenharia de Software  
**Aluno:** Vitor Costa Vianna  
**Data:** Junho de 2026  

---

## 1. Introdução

Esta sprint encerra o ciclo de desenvolvimento do PointDog com a entrega do aplicativo Flutter para o prestador de serviços e a integração completa do fluxo ponta a ponta: desde a solicitação criada pelo cliente até a conclusão pelo prestador, com comunicação assíncrona via MOM e notificação em tempo real via WebSocket.

O sistema foi construído ao longo de quatro sprints incrementais, acumulando:
- **Sprint 1:** Backend REST (Node.js/Express/Prisma/SQLite) com Clean Architecture
- **Sprint 2:** Mensageria assíncrona com RabbitMQ (MOM/EDA)
- **Sprint 3:** App Flutter do cliente (Clean Architecture, Provider, GoRouter, WebSocket)
- **Sprint 4:** App Flutter do prestador + integração final ponta a ponta

---

## 2. Arquitetura Implementada

### 2.1 Visão Geral do Sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                        App Flutter (client/)                        │
│                                                                     │
│  ┌─────────────────────────┐     ┌─────────────────────────────┐   │
│  │    App do CLIENTE       │     │    App do PRESTADOR         │   │
│  │                         │     │                             │   │
│  │ ServicesListScreen      │     │ ProviderPendingScreen       │   │
│  │ AppointmentsListScreen  │     │ ProviderActiveScreen        │   │
│  │ PetsScreen              │     │ ProviderHistoryScreen       │   │
│  │                         │     │ ProviderAppointmentDetail   │   │
│  └─────────────────────────┘     └─────────────────────────────┘   │
│              │ role=CLIENTE                │ role=PRESTADOR         │
│              └──────────────┬─────────────┘                        │
│                             │ AppShell (bottom nav condicional)     │
│                             │ GoRouter (redirect por role)         │
│                             │ AppointmentsNotifier (WS shared)     │
└─────────────────────────────┼───────────────────────────────────────┘
                              │ REST (Dio + JWT)  │ WebSocket
                              ▼                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Backend Node.js (backend/)                      │
│                                                                     │
│  Express Router → Controllers → Use Cases → Repositories → Prisma  │
│                                    │                                │
│                         CompositePublisher                          │
│                         ┌───────────────────┐                      │
│                         │  RabbitMQPublisher│                      │
│                         │  WebSocketPublisher│                     │
│                         └───────────────────┘                      │
└─────────────────────────────┬───────────────────────────────────────┘
                              │ AMQP
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       RabbitMQ (Docker)                             │
│                                                                     │
│  Exchange: pointdog.events (topic)                                  │
│  Fila: pointdog.notifications                                       │
│  Binding: appointment.*                                             │
│                                                                     │
│  Worker (appointment.worker.ts): consome e processa eventos         │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Fluxo Ponta a Ponta

```
[Cliente] Criar Agendamento (POST /appointments)
    │
    ▼
[Backend] CreateAppointmentUseCase
    │  salva no banco (Prisma/SQLite)
    │
    ├──► [RabbitMQ] publica appointment.created
    │         │
    │         └──► [Worker] loga evento (processamento assíncrono)
    │
    └──► [WebSocket] envia appointment.created
              ├──► clientId → AppointmentsNotifier do cliente (atualiza lista)
              └──► providerId → AppointmentsNotifier do prestador
                        │
                        └──► ProviderPendingScreen atualiza em tempo real

[Prestador] Aceitar Solicitação (PATCH /appointments/:id/status)
    │
    ▼
[Backend] UpdateAppointmentStatusUseCase
    │  valida role PRESTADOR + transição PENDENTE→CONFIRMADO
    │
    ├──► [RabbitMQ] publica appointment.status_changed
    │
    └──► [WebSocket] envia appointment.status_changed
              └──► clientId → AppointmentsNotifier do cliente
                        │
                        └──► AppointmentsListScreen atualiza status em tempo real
```

### 2.3 Arquitetura do App Flutter — Role-Based Views

A decisão central da Sprint 4 foi implementar o app do prestador dentro do **mesmo projeto Flutter** (`client/`), usando views condicionadas pela role do usuário, em vez de criar um segundo projeto separado.

```
AuthStorage.role == 'PRESTADOR'
         │
         ├── GoRouter redirect → /provider/pending
         ├── AppShell → bottom nav com 3 tabs do prestador
         └── AppointmentsNotifier → ouve appointment.created via WS
```

Essa abordagem reduz drasticamente o boilerplate: os providers (`AppointmentsNotifier`, `AuthNotifier`), repositórios e serviços de rede são **compartilhados** entre cliente e prestador. Apenas as telas diferem.

---

## 3. Decisões de Design

### 3.1 Roteamento WebSocket por `providerId`

**Problema:** o `WebSocketEventPublisher` original só roteava eventos para o `clientId`. O prestador nunca recebia notificação de novos agendamentos.

**Solução:** refatorar o método `publish()` para extrair ambos `clientId` e `providerId` do payload, usando um `Set<string>` como destinos. Isso garante que:
- `appointment.created` → entregue ao prestador E ao cliente
- `appointment.status_changed` → entregue a ambos (permitindo que o prestador também veja mudanças refletidas)
- Se `clientId === providerId` (caso improvável), a mensagem é enviada uma única vez

```typescript
async publish(_routingKey: string, payload: unknown): Promise<void> {
  const targets = new Set<string>()
  if (event?.payload?.clientId)   targets.add(event.payload.clientId)
  if (event?.payload?.providerId) targets.add(event.payload.providerId)
  for (const userId of targets) this.sendToUser(userId, message)
}
```

**Alternativa considerada e descartada:** polling periódico. Descartada por consumir mais recursos e introduzir latência artificial numa arquitetura que já tem WebSocket disponível.

### 3.2 Persistência da Role em `SharedPreferences`

A role (`CLIENTE` / `PRESTADOR`) é extraída da resposta do `POST /auth/login` (campo `user.role`) e persistida localmente em `SharedPreferences`, ao lado do token JWT e do `userId`. Isso permite que:
- O redirect do GoRouter aconteça **sincronamente** no `initState` (sem esperar o backend)
- O `AppShell` renderize o bottom nav correto na primeira frame

**Risco:** dessincronização se a role for alterada no backend sem novo login. Para este projeto acadêmico, o risco é aceitável; em produção, o ideal seria validar a role via endpoint ou incluí-la no JWT.

### 3.3 Recarregamento via REST no `appointment.created`

Quando o prestador recebe o evento `appointment.created` via WebSocket, o payload contém apenas IDs (`appointmentId`, `clientId`, `petId`), sem os nomes enriquecidos (pet, serviço). A decisão foi **disparar um `loadAll()` via REST** em vez de tentar montar o objeto a partir do payload:

```dart
if (eventType == 'appointment.created') {
  if (auth.role == 'PRESTADOR' && providerId == auth.userId) {
    loadAll(); // REST GET /appointments — retorna dados enriquecidos
  }
}
```

**Trade-off:** um round-trip HTTP extra, mas garante consistência dos dados exibidos. Alternativa seria um `GET /appointments/:id` por evento, que teria a mesma latência mas com menos dados transferidos. O `loadAll()` foi escolhido pela simplicidade.

### 3.4 MOM vs. WebSocket — Divisão de Responsabilidades

O RabbitMQ e o WebSocket coexistem com **responsabilidades distintas**:

| Canal | Responsabilidade | Por que |
|---|---|---|
| RabbitMQ (MOM) | Processamento assíncrono de eventos de domínio | Durabilidade, desacoplamento, reprocessamento |
| WebSocket | Entrega em tempo real ao app | Baixa latência, conexão persistente já existente |

O worker do RabbitMQ (`appointment.worker.ts`) simula notificações push (ex.: FCM para notificação fora do app). Em produção, este seria o componente responsável por enviar push notifications quando o usuário está com o app fechado.

---

## 4. Dificuldades Encontradas e Soluções Adotadas

### 4.1 Subagentes sem permissão de escrita em CI

Durante o desenvolvimento assistido, os subagentes de implementação retornaram status `NEEDS_CONTEXT` por não terem permissão para criar arquivos no ambiente. A solução foi executar todas as implementações diretamente na sessão principal, onde as permissões do usuário estavam disponíveis.

### 4.2 Reconexão do WebSocket

O `WebSocketService` atual seta `_channel = null` ao detectar desconexão, sem reconectar automaticamente. Durante testes em emulador, quedas esporádicas de rede quebravam a atualização em tempo real. A solução de curto prazo foi garantir que o emulador tivesse conexão estável durante a demonstração. Uma solução robusta envolveria um mecanismo de reconnect com backoff exponencial.

### 4.3 `flutter analyze` com exit code 1 em warnings

O `flutter analyze` retorna código de saída 1 mesmo para avisos de nível `info`, o que falsamente indicava falha. A distinção importante é que **zero erros** (`error`) existem no código — apenas avisos de boas práticas (`prefer_const_constructors`) pré-existentes de sprints anteriores.

### 4.4 Widget test desatualizado

O `test/widget_test.dart` padrão do Flutter referenciava `MyApp` (nome gerado automaticamente pelo framework), nunca atualizado para `PointDogApp`. Causava erro de compilação no analyze. Substituído por um placeholder mínimo.

---

## 5. Reflexão sobre os Padrões Estudados

### 5.1 Event-Driven Architecture (EDA)

O projeto implementa EDA de forma prática: os use cases do backend publicam **eventos de domínio** (`appointment.created`, `appointment.status_changed`) sem conhecer quem os consome. Isso desacopla completamente o produtor (API) dos consumidores (worker RabbitMQ, WebSocket publisher).

Conforme FOWLER (2002), esse padrão aumenta a coesão dos componentes e reduz o acoplamento estrutural. A `IEventPublisher` age como contrato de abstração que permite substituir o mecanismo de entrega sem alterar a lógica de negócio.

### 5.2 Message-Oriented Middleware (MOM)

O RabbitMQ com **Topic Exchange** permite que múltiplos consumidores se inscrevam em padrões de routing key (`appointment.*`) sem modificar o produtor. Conforme HOHPE & WOOLF (2003), o Topic Exchange é o padrão *Publish-Subscribe Channel* com filtragem por tópico.

A fila `pointdog.notifications` é durável e as mensagens são persistentes (`persistent: true`), garantindo que eventos não sejam perdidos mesmo que o worker esteja temporariamente indisponível.

### 5.3 Clean Architecture no Backend

O backend segue os princípios de Clean Architecture (MARTIN, 2017):
- **Entidades:** `Appointment`, `Pet`, `Service`, `User` (independentes de frameworks)
- **Use Cases:** `CreateAppointmentUseCase`, `UpdateAppointmentStatusUseCase` (lógica de negócio pura)
- **Adaptadores:** controllers Express, repositórios Prisma, publishers de evento
- **Frameworks:** Express, Prisma, RabbitMQ, WebSocket — apenas na camada externa

A regra de dependência é rigorosamente aplicada: use cases não importam nada do Express ou do Prisma diretamente.

### 5.4 Clean Architecture no Flutter

No app Flutter, a mesma separação é aplicada com adaptação ao ecossistema:
- **Models:** `Appointment`, `Pet`, `Service`, `User` — serialização JSON pura
- **Repositories (Services):** acesso REST via Dio, WebSocket via `web_socket_channel`
- **Notifiers (Use Cases):** `AppointmentsNotifier`, `AuthNotifier` — lógica de estado
- **Screens:** puro Flutter Widget, sem lógica de negócio

### 5.5 REST

Os endpoints seguem as convenções REST com recursos bem definidos (`/appointments`, `/pets`, `/services`), verbos HTTP semânticos (`GET`, `POST`, `PATCH`, `DELETE`) e códigos de status apropriados (`201 Created`, `200 OK`, `401 Unauthorized`, `403 Forbidden`).

O uso de `PATCH /appointments/:id/status` — em vez de `PUT` — reflete corretamente a semântica de **atualização parcial** de recurso, conforme FIELDING (2000).

---

## 6. Estrutura do Repositório

```
tp_lab_pointdog/
├── backend/                    # API REST + WebSocket + Worker RabbitMQ
│   ├── src/
│   │   ├── modules/            # Domínio: auth, appointments, pets, services
│   │   ├── shared/             # Infraestrutura: JWT, WebSocket, MOM
│   │   └── workers/            # Worker RabbitMQ
│   ├── prisma/                 # Schema + migrations SQLite
│   └── docker-compose.yml      # RabbitMQ
│
├── client/                     # App Flutter (cliente + prestador)
│   └── lib/
│       ├── core/               # Auth, network, tema
│       ├── models/             # Entidades
│       ├── repositories/       # Acesso REST
│       ├── providers/          # Estado (ChangeNotifier)
│       └── screens/
│           ├── auth/           # Login, Register
│           ├── appointments/   # Telas do cliente
│           ├── pets/
│           ├── services/
│           └── provider/       # Telas do prestador (Sprint 4)
│
└── docs/
    ├── sprint1/                # Enunciado do projeto
    ├── sprint2/                # Documentação MOM + PDF + vídeo
    ├── sprint3/                # Navigation flow + vídeo
    └── sprint4/                # Este relatório + vídeo (a adicionar)
```

---

## 7. Instruções de Execução

### Pré-requisitos

- Node.js 18+
- Flutter SDK 3.x
- Docker Desktop

### Backend

```bash
cd backend

# 1. Subir RabbitMQ
npm run infra:up

# 2. Instalar dependências e preparar banco
npm install
npx prisma migrate deploy

# 3. Iniciar API
npm run dev

# 4. Iniciar Worker (terminal separado)
npm run worker
```

### App Flutter

```bash
cd client

# Instalar dependências
flutter pub get

# Rodar no emulador Android (LDPlayer ou AVD)
flutter run -d localhost:5555

# Rodar no Chrome
flutter run -d chrome

# Configurar URL do backend (se IP diferente de localhost)
flutter run --dart-define=BASE_URL=http://SEU_IP:3000 --dart-define=WS_URL=ws://SEU_IP:3000/ws
```

### Credenciais de Teste

Criar dois usuários via tela de registro:
- **Cliente:** selecionar "Cliente" no toggle e fazer login
- **Prestador:** selecionar "Prestador" no toggle e fazer login

> O backend requer que o prestador tenha serviços vinculados. Use `GET /services` para listar os serviços disponíveis e criar agendamentos apontando para o `providerId` do prestador cadastrado.

---

## 8. Referências Bibliográficas

FIELDING, Roy Thomas. **Architectural Styles and the Design of Network-based Software Architectures**. Tese de Doutorado. University of California, Irvine, 2000. Disponível em: https://ics.uci.edu/~fielding/pubs/dissertation/top.htm

FOWLER, Martin. **Patterns of Enterprise Application Architecture**. Boston: Addison-Wesley, 2002. ISBN 978-0-321-12521-7.

HOHPE, Gregor; WOOLF, Bobby. **Enterprise Integration Patterns: Designing, Building, and Deploying Messaging Solutions**. Boston: Addison-Wesley, 2003. ISBN 978-0-321-20068-6.

MARTIN, Robert C. **Clean Architecture: A Craftsman's Guide to Software Structure and Design**. Upper Saddle River: Prentice Hall, 2017. ISBN 978-0-13-468599-1.

NEWMAN, Sam. **Building Microservices: Designing Fine-Grained Systems**. 2. ed. Sebastopol: O'Reilly Media, 2021. ISBN 978-1-492-03402-0.
