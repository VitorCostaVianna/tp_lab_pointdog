# Relatório Técnico — Sprint 4
## PointDog: Aplicativo do Prestador e Integração Final

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Instituição:** PUC Minas — Engenharia de Software  
**Aluno:** Vitor Costa Vianna  
**Data:** Junho de 2026  

**Vídeo de demonstração (com áudio):** [https://youtu.be/5ssTpoYluIE](https://youtu.be/5ssTpoYluIE)

---

## 1. Introdução

Esta sprint encerra o ciclo de desenvolvimento do PointDog com a entrega do aplicativo Flutter para o prestador de serviços e a integração completa do fluxo ponta a ponta: desde a solicitação criada pelo cliente até a conclusão pelo prestador, com comunicação assíncrona via Message-Oriented Middleware (MOM) e notificação em tempo real via WebSocket.

O sistema foi construído ao longo de quatro sprints incrementais, seguindo os princípios de Clean Architecture (MARTIN, 2019) e Event-Driven Architecture (EDA), com cada sprint adicionando uma camada funcional sobre a anterior:

- **Sprint 1:** Backend REST (Node.js/Express/Prisma/SQLite) com separação em camadas segundo Clean Architecture
- **Sprint 2:** Mensageria assíncrona com RabbitMQ (MOM/EDA), implementando os padrões *Publish-Subscribe Channel* e *Topic Exchange* descritos por Hohpe e Woolf (2003)
- **Sprint 3:** Aplicativo Flutter do cliente com integração REST, gerenciamento de estado com Provider e atualização em tempo real via WebSocket
- **Sprint 4:** Aplicativo Flutter do prestador integrado ao mesmo projeto, com roteamento WebSocket bidirecional e fluxo de ciclo de vida completo de agendamentos

A escolha de WebSocket para notificações em tempo real e RabbitMQ para processamento assíncrono segue os princípios de sistemas distribuídos estabelecidos por Coulouris et al. (2011): canais de comunicação indireta permitem desacoplar produtores de consumidores, aumentando a escalabilidade e a resiliência do sistema.

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

A decisão central da Sprint 4 foi implementar o app do prestador dentro do **mesmo projeto Flutter** (`client/`), usando views condicionadas pela role do usuário, em vez de criar um segundo projeto separado. Essa abordagem aplica o princípio DRY (Don't Repeat Yourself): a infraestrutura de rede, os modelos e os gerenciadores de estado são compartilhados entre cliente e prestador, diferenciando apenas a camada de apresentação.

```
AuthStorage.role == 'PRESTADOR'
         │
         ├── GoRouter redirect → /provider/pending
         ├── AppShell → bottom nav com 3 tabs do prestador
         └── AppointmentsNotifier → ouve appointment.created via WS
```

Essa abordagem reduz drasticamente o boilerplate: os providers (`AppointmentsNotifier`, `AuthNotifier`), repositórios e serviços de rede são **compartilhados** entre cliente e prestador. Apenas as telas diferem, mantendo coesão e evitando duplicação de lógica.

### 2.4 Camadas da Arquitetura Flutter

Seguindo Martin (2019), o app Flutter mantém a separação em camadas com dependências apontando apenas para dentro:

| Camada | Componentes | Responsabilidade |
|---|---|---|
| **Entidades (Models)** | `Appointment`, `Pet`, `Service`, `User` | Estrutura de dados, serialização JSON |
| **Repositórios** | `AuthRepository`, `AppointmentsRepository` | Acesso à API REST via Dio |
| **Notifiers (Use Cases)** | `AppointmentsNotifier`, `AuthNotifier` | Lógica de estado, filtros, ações |
| **Telas (Screens)** | LoginScreen, ProviderPendingScreen, etc. | Apresentação, sem lógica de negócio |
| **Infraestrutura** | `AuthStorage`, `WebSocketService`, `AppHttpClient` | Persistência, rede, WebSocket |

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
  const event = payload as RoutableEvent
  const message = JSON.stringify(payload)
  const targets = new Set<string>()
  if (event?.payload?.clientId)   targets.add(event.payload.clientId)
  if (event?.payload?.providerId) targets.add(event.payload.providerId)
  for (const userId of targets) this.sendToUser(userId, message)
}
```

**Alternativa considerada e descartada:** polling periódico via `GET /appointments`. Descartada por consumir mais recursos, introduzir latência artificial e desperdiçar conexões numa arquitetura que já possui WebSocket disponível. Conforme Coulouris et al. (2011), a comunicação indireta baseada em eventos é preferível ao polling em sistemas distribuídos onde a latência de notificação é requisito.

### 3.2 Persistência da Role em `SharedPreferences`

A role (`CLIENTE` / `PRESTADOR`) é extraída da resposta do `POST /auth/login` (campo `user.role`) e persistida localmente em `SharedPreferences`, ao lado do token JWT e do `userId`. Isso permite que:
- O redirect do GoRouter aconteça **sincronamente** no `initState` (sem esperar o backend)
- O `AppShell` renderize o bottom nav correto na primeira frame

**Risco:** dessincronização se a role for alterada no backend sem novo login. Para este projeto acadêmico, o risco é aceitável; em produção, o ideal seria incluir a role no payload do JWT e validá-la a cada requisição autenticada, conforme as melhores práticas de segurança para sistemas distribuídos.

### 3.3 Recarregamento via REST no `appointment.created`

Quando o prestador recebe o evento `appointment.created` via WebSocket, o payload contém apenas IDs (`appointmentId`, `clientId`, `petId`), sem os nomes enriquecidos (pet, serviço). A decisão foi **disparar um `loadAll()` via REST** em vez de tentar montar o objeto a partir do payload:

```dart
if (eventType == 'appointment.created') {
  if (auth.role == 'PRESTADOR' && providerId == auth.userId) {
    loadAll(); // REST GET /appointments — retorna dados enriquecidos
  }
}
```

**Trade-off:** um round-trip HTTP extra, mas garante consistência dos dados exibidos. Alternativa seria um `GET /appointments/:id` por evento, com a mesma latência mas menos dados transferidos. O `loadAll()` foi escolhido pela simplicidade de implementação e pelo contexto acadêmico do projeto.

### 3.4 MOM vs. WebSocket — Divisão de Responsabilidades

O RabbitMQ e o WebSocket coexistem com **responsabilidades distintas**, seguindo a arquitetura de publicação/assinatura descrita por Hohpe e Woolf (2003):

| Canal | Responsabilidade | Por que |
|---|---|---|
| RabbitMQ (MOM) | Processamento assíncrono de eventos de domínio | Durabilidade, desacoplamento, reprocessamento |
| WebSocket | Entrega em tempo real ao app | Baixa latência, conexão persistente já existente |

O worker do RabbitMQ (`appointment.worker.ts`) simula notificações push (ex.: FCM para notificação fora do app). Em produção, este seria o componente responsável por enviar push notifications quando o usuário está com o app fechado — caso de uso que Richardson (2018) denomina "notificação assíncrona desacoplada".

### 3.5 Implementação por Role-Based Views em Projeto Único

A alternativa de criar um segundo projeto Flutter para o prestador foi descartada porque geraria duplicação imediata: dois conjuntos de modelos, dois repositórios REST, dois `AppointmentsNotifier`, dois `WebSocketService`. A solução de projeto único aproveita que o Flutter separa a lógica de apresentação da lógica de negócio: um único `AppointmentsNotifier` serve tanto o cliente (que vê seus próprios agendamentos) quanto o prestador (que vê solicitações direcionadas a ele), com a diferenciação feita pelos getters de filtro (`pending`, `active`, `history`).

---

## 4. Dificuldades Encontradas e Soluções Adotadas

### 4.1 Autenticação no WebSocket

Uma dificuldade que surgiu cedo foi como autenticar o usuário na conexão WebSocket. No HTTP comum, o token JWT vai no cabeçalho `Authorization`, mas a API WebSocket dos navegadores não permite definir cabeçalhos na hora de abrir a conexão. Isso inviabilizou reusar o mesmo mecanismo de autenticação das rotas REST.

A saída foi passar o token diretamente na URL: `ws://host/ws?token=<jwt>`. No servidor, o token é extraído da query string, validado, e a conexão é associada ao `userId` do payload. Funciona bem para o contexto do projeto, embora em produção o ideal fosse usar tokens de vida curta para minimizar o risco de exposição do JWT na URL.

### 4.2 Payload do WebSocket sem dados enriquecidos

Quando o prestador recebia o evento `appointment.created` via WebSocket, o payload trazia apenas IDs — `appointmentId`, `clientId`, `petId` — sem os nomes de pet ou serviço. Exibir IDs brutos para o usuário não era aceitável.

A solução adotada foi, ao receber o evento, disparar uma chamada REST (`GET /appointments`) para recarregar a lista completa com todos os dados. Há um round-trip extra, mas garante que o que aparece na tela é sempre consistente com o banco. Uma alternativa seria buscar só o agendamento específico por ID, mas o `loadAll` foi suficiente para o escopo do projeto.

### 4.3 Reconexão automática do WebSocket

Durante os testes no emulador, quedas esporádicas de rede quebravam a conexão WebSocket sem que o app percebesse. O `WebSocketService` detecta a desconexão mas não tenta reconectar automaticamente — a atualização em tempo real simplesmente parava de funcionar até o usuário reiniciar o app.

Para o escopo acadêmico, a solução foi garantir conexão estável durante a demonstração. A implementação correta exigiria um mecanismo de reconexão com tentativas espaçadas (por exemplo, aguardar 1s, depois 2s, depois 4s) — algo que Coulouris et al. (2011) apontam como prática essencial em sistemas distribuídos, onde falhas de rede são eventos esperados, não exceções.

### 4.4 Dificuldades nos testes

Os testes do `WebSocketEventPublisher` foram um desafio porque a classe cria um servidor WebSocket real internamente, o que tornava difícil testar o comportamento de roteamento de mensagens de forma isolada. A solução foi injetar conexões simuladas diretamente no mapa interno do publisher durante os testes, evitando a necessidade de abrir sockets reais.

Outro problema menor foi o arquivo `widget_test.dart` padrão do Flutter, que referenciava `MyApp` — o nome gerado automaticamente no `flutter create` — em vez de `PointDogApp`. Causava erro no `flutter analyze` e foi substituído por um teste mínimo que verifica apenas que a árvore de widgets inicializa sem exceções.

---

## 5. Reflexão sobre os Padrões Estudados

### 5.1 Event-Driven Architecture (EDA)

O projeto implementa EDA de forma prática: os use cases do backend publicam **eventos de domínio** (`appointment.created`, `appointment.status_changed`) sem conhecer quem os consome. Isso desacopla completamente o produtor (API REST) dos consumidores (worker RabbitMQ, WebSocket publisher).

Conforme Richardson (2018), o padrão *Event-Driven* é especialmente adequado quando múltiplos serviços precisam reagir ao mesmo evento sem acoplamento direto. No PointDog, o `CompositePublisher` implementa exatamente esse papel: delega para múltiplos `IEventPublisher` sem que os use cases de negócio saibam da existência de RabbitMQ ou WebSocket.

A interface `IEventPublisher` age como contrato de abstração que permite substituir ou adicionar mecanismos de entrega (ex.: FCM, e-mail) sem alterar a lógica de negócio — o Princípio Aberto/Fechado de Martin (2019) aplicado à camada de infraestrutura.

### 5.2 Message-Oriented Middleware (MOM)

O RabbitMQ com **Topic Exchange** permite que múltiplos consumidores se inscrevam em padrões de routing key (`appointment.*`) sem modificar o produtor. Conforme Hohpe e Woolf (2003), o Topic Exchange combina o padrão *Publish-Subscribe Channel* — que permite o fan-out de mensagens para múltiplos consumidores — com o padrão *Message Filter*, pelo qual o roteador determina dinamicamente quais filas recebem cada mensagem com base no padrão de routing key.

A fila `pointdog.notifications` é durável e as mensagens são persistentes (`persistent: true`), garantindo que eventos não sejam perdidos mesmo que o worker esteja temporariamente indisponível. Esse comportamento é o padrão *Guaranteed Delivery* descrito por Hohpe e Woolf (2003): a infraestrutura assume a responsabilidade pela entrega, liberando o produtor de implementar mecanismos de retry.

A separação entre o canal síncrono (WebSocket, para notificações em tempo real ao usuário ativo) e o canal assíncrono (RabbitMQ, para processamento de backend) reflete a distinção que Coulouris et al. (2011) fazem entre comunicação síncrona e assíncrona: cada canal serve a um caso de uso distinto e não é substituível pelo outro.

### 5.3 Clean Architecture no Backend

O backend segue os princípios de Clean Architecture (MARTIN, 2019):
- **Entidades:** `Appointment`, `Pet`, `Service`, `User` — independentes de frameworks
- **Use Cases:** `CreateAppointmentUseCase`, `UpdateAppointmentStatusUseCase` — lógica de negócio pura, sem importações de Express ou Prisma
- **Adaptadores:** controllers Express, repositórios Prisma, publishers de evento — traduzem entre o mundo externo e as entidades
- **Frameworks:** Express, Prisma, RabbitMQ, WebSocket — apenas na camada mais externa

A **Regra de Dependência** é o invariante central: as dependências de código-fonte apontam sempre para dentro (em direção às entidades), nunca para fora. Um use case pode chamar uma interface de repositório, mas nunca uma implementação Prisma diretamente. Isso permite que a mesma lógica de negócio seja testada com repositórios em memória (como nos testes unitários) sem nenhuma modificação.

**DRY aplicado no domínio:** a regra de autorização de acesso a agendamentos — "CLIENTE só acessa seus próprios agendamentos; PRESTADOR só acessa os seus" — aparecia duplicada em `GetAppointmentUseCase` e `UpdateAppointmentStatusUseCase`. Foi extraída para `appointments/domain/appointment.access.ts` como a função `assertAppointmentAccess(appointment, userId, role)`, eliminando a duplicação sem criar acoplamento adicional: a função pertence ao domínio (sem dependências externas) e ambos os use cases a chamam diretamente.

```typescript
// appointments/domain/appointment.access.ts
export function assertAppointmentAccess(
  appointment: Appointment,
  requestingUserId: string,
  requestingRole: 'CLIENTE' | 'PRESTADOR',
): void {
  if (requestingRole === 'CLIENTE' && appointment.clientId !== requestingUserId)
    throw new AppError('Acesso negado', 403)
  if (requestingRole === 'PRESTADOR' && appointment.providerId !== requestingUserId)
    throw new AppError('Acesso negado', 403)
}
```

### 5.4 Clean Architecture no Flutter

No app Flutter, a mesma separação é aplicada com adaptação ao ecossistema. Bailey (2023) detalha essa organização para projetos Flutter estruturados: models, repositories, state management e screens como camadas discretas com dependências unidirecionais:

- **Models:** `Appointment`, `Pet`, `Service`, `User` — serialização JSON pura, sem dependência de Flutter
- **Repositories:** acesso REST via Dio, WebSocket via `web_socket_channel` — apenas a camada de repositório conhece o protocolo HTTP
- **Notifiers (Use Cases):** `AppointmentsNotifier`, `AuthNotifier` — lógica de estado e negócio; dependem de repositórios via instância direta (injeção manual sem container DI)
- **Screens:** puro Flutter Widget, consomem notifiers via `context.read<>()` / `Consumer<>()`, sem lógica de negócio

A adição das telas do prestador na Sprint 4 não exigiu modificações nas camadas de modelo ou repositório — validando empiricamente que a separação de camadas facilita extensão sem modificação (Open/Closed Principle).

### 5.5 REST

Os endpoints seguem as convenções REST com recursos bem definidos (`/appointments`, `/pets`, `/services`), verbos HTTP semânticos (`GET`, `POST`, `PATCH`, `DELETE`) e códigos de status apropriados (`201 Created`, `200 OK`, `401 Unauthorized`, `403 Forbidden`).

O uso de `PATCH /appointments/:id/status` — em vez de `PUT` — reflete corretamente a semântica de **atualização parcial** de recurso: apenas o campo `status` é modificado, sem necessidade de enviar o recurso completo. A distinção entre `PUT` (substituição total) e `PATCH` (modificação parcial) é fundamental para a corretude semântica de APIs REST.

O controle de transições de status no `UpdateAppointmentStatusUseCase` (ex.: somente `PENDENTE→CONFIRMADO` é válida para o prestador; `CONFIRMADO→CONCLUIDO` não é acessível ao cliente) introduz lógica de máquina de estados sobre o recurso, mantendo a regra de negócio no use case e expondo apenas o endpoint genérico de atualização de status via REST.

---

## 6. Estratégia de Testes

A suíte de testes do backend é executada com **Jest + ts-jest** e totaliza **55 testes automatizados**, distribuídos em **12 suítes**, todos passando (`Test Suites: 12 passed, 12 total / Tests: 55 passed, 55 total`). Os testes combinam duas estratégias complementares: **testes unitários** dos use cases e da infraestrutura de mensageria (com mocks) e **testes de integração** dos controllers (HTTP real ponta a ponta).

### 6.1 Mapa de Testes (arquivo por arquivo)

| Arquivo | Tipo | Testes | O que cobre |
|---|---|---:|---|
| `src/app.test.ts` | Integração | 1 | Health check `GET /health` |
| `modules/users/application/use-cases/register-user.usecase.test.ts` | Unitário | 2 | Registro: hash + e-mail duplicado (409) |
| `modules/users/application/use-cases/login-user.usecase.test.ts` | Unitário | 3 | Login: token válido, e-mail inexistente (401), senha errada (401) |
| `modules/users/presentation/user.controller.test.ts` | Integração | 6 | `POST /auth/register` e `POST /auth/login` (201/409/400/200/401) |
| `modules/pets/application/create-pet.use-case.test.ts` | Unitário | 2 | Criação válida + tamanho inválido (400) |
| `modules/pets/presentation/pet.controller.test.ts` | Integração | 8 | CRUD de pets + isolamento por dono (401/403/404) |
| `modules/services/presentation/service.controller.test.ts` | Integração | 9 | CRUD de serviços + RBAC PRESTADOR + filtro por `providerId` |
| `modules/appointments/application/create-appointment.use-case.test.ts` | Unitário | 3 | Cria + publica `appointment.created`; data passada; pet inexistente |
| `modules/appointments/application/update-appointment-status.use-case.test.ts` | Unitário | 3 | Transição válida + evento; transição inválida; 404 |
| `modules/appointments/presentation/appointment.controller.test.ts` | Integração | 12 | Ciclo de vida completo do agendamento + RBAC + máquina de estados |
| `shared/messaging/composite.publisher.test.ts` | Unitário | 2 | Fan-out para N publishers + propagação de falha |
| `shared/messaging/websocket.server.test.ts` | Unitário | 4 | Roteamento de eventos por `clientId`/`providerId` |
| **Total** | | **55** | |

### 6.2 Cobertura por Módulo

| Módulo | Unitários | Integração | Total |
|---|---:|---:|---:|
| Users / Auth | 5 | 6 | 11 |
| Pets | 2 | 8 | 10 |
| Services | 0 | 9 | 9 |
| Appointments | 6 | 12 | 18 |
| Shared / Messaging | 6 | 0 | 6 |
| App (health) | 0 | 1 | 1 |
| **Total** | **19** | **36** | **55** |

### 6.3 Estratégia: Unitário vs. Integração

**Testes unitários (19)** — exercitam os use cases e a mensageria de forma isolada. As dependências externas são substituídas por *mocks* do Jest tipados (`jest.Mocked<IAppointmentRepository>`, `jest.fn()`), de modo que apenas a regra de negócio é avaliada, sem I/O. Exemplos: `CreateAppointmentUseCase` verifica que o evento `appointment.created` é publicado com o payload correto; `UpdateAppointmentStatusUseCase` valida a máquina de transições; `CompositePublisher` confirma o fan-out para múltiplos `IEventPublisher`. Essa abordagem só é possível porque os use cases dependem de **abstrações** (interfaces), não de implementações concretas — uma consequência direta da Regra de Dependência (Martin, 2019).

**Testes de integração (36)** — exercitam os controllers através da pilha HTTP real, usando **Supertest** sobre a instância Express produzida por `createApp(testPrisma)`. Cada teste percorre o caminho completo: roteamento Express → middlewares de autenticação (`authenticate`) e autorização (`requireRole`) → controller → use case → repositório Prisma → banco SQLite. O helper `cleanDatabase()` (em `src/test-utils/db.ts`) é chamado em `beforeEach` para garantir isolamento entre casos. Esses testes validam não apenas a lógica, mas também os contratos REST (códigos de status `201/200/400/401/403/404/409`), o RBAC e o controle de transições de status do agendamento.

### 6.4 Por que a Suíte Roda Sem Docker

Um requisito de design da suíte foi permitir sua execução em qualquer máquina **sem subir contêineres**. Três decisões tornam isso possível:

1. **`NullEventPublisher` no lugar do RabbitMQ.** A função `createApp()` recebe um `IEventPublisher` com valor padrão `new NullEventPublisher()` (`src/app.ts`, linha 13). Esse publisher implementa a mesma interface, mas seu `publish()` é um *no-op*. Como os use cases dependem apenas da interface `IEventPublisher` — e não do `RabbitMQPublisher` concreto —, eles publicam eventos normalmente nos testes, porém para um destino vazio. **Nenhum broker AMQP precisa estar de pé.** Essa é a aplicação prática do Princípio da Inversão de Dependência: trocar a implementação de infraestrutura sem tocar na regra de negócio (o padrão *Null Object* aplicado à mensageria).

2. **SQLite em arquivo no lugar de um Postgres conteinerizado.** O banco de testes é um arquivo local (`file:./test.db`) acessado via adaptador `better-sqlite3`. O `globalSetup` do Jest (`src/test-utils/global-setup.ts`) roda `prisma migrate deploy` sobre esse arquivo antes da suíte, dispensando qualquer servidor de banco externo.

3. **Sockets simulados nos testes de WebSocket.** Os testes de `WebSocketEventPublisher` injetam conexões falsas diretamente no mapa interno de clientes, em vez de abrir sockets reais — validando o roteamento de mensagens sem rede.

### 6.5 Como Executar

```bash
cd backend
npm install            # instala dependências (se ainda não instaladas)
npm test               # jest --runInBand --forceExit
```

O `globalSetup` aplica as migrações no `test.db` automaticamente; não é necessário `docker-compose up` nem `npm run infra:up` para rodar os testes. A flag `--runInBand` força execução serial (os testes de integração compartilham o mesmo arquivo SQLite), e `--forceExit` encerra o processo após a conclusão.

---

## 7. Estrutura do Repositório

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
    └── sprint4/                # Este relatório + vídeo
```

---

## 8. Instruções de Execução

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

## 9. Referências Bibliográficas

BAILEY, Thomas. **Flutter for beginners**. 3rd ed. Birmingham: Packt, 2023. ISBN 978-1-80323-765-8. (Referência principal para o desenvolvimento dos aplicativos móveis com Flutter 3.x e Dart 3.x, incluindo gerenciamento de estado com Provider e navegação com GoRouter.)

COULOURIS, George et al. **Distributed Systems: concepts and design**. 5th ed. Boston: Addison-Wesley, 2011. ISBN 978-0-132-14301-1. (Conceitos de sistemas distribuídos, comunicação indireta, middlewares e tratamento de falhas de rede — base teórica para o design do WebSocket e do MOM.)

FIELDING, Roy Thomas. **Architectural Styles and the Design of Network-based Software Architectures**. Tese de Doutorado. University of California, Irvine, 2000. Disponível em: https://ics.uci.edu/~fielding/pubs/dissertation/top.htm. (Tese que define os princípios REST, fundamenta a distinção entre PUT e PATCH e os critérios de uniformidade de interface.)

HOHPE, Gregor; WOOLF, Bobby. **Enterprise Integration Patterns: Designing, Building, and Deploying Messaging Solutions**. Boston: Addison-Wesley, 2003. ISBN 978-0-321-20068-6. (Padrões de integração por mensagens: Publish-Subscribe Channel, Topic Exchange, Guaranteed Delivery — base teórica para o RabbitMQ e o CompositePublisher.)

MARTIN, Robert C. **Arquitetura limpa: o guia do artesão para estrutura e design de software**. Rio de Janeiro: Alta Books, 2019. ISBN 978-85-508-0608-0. (Fundamenta os princípios de Clean Architecture adotados na organização do backend Node.js e do app Flutter: Regra de Dependência, separação em camadas e o Princípio Aberto/Fechado.)

RICHARDSON, Chris. **Microservices patterns: with examples in Java**. Shelter Island: Manning, 2018. ISBN 978-1-617-29454-1. (Padrões de EDA e comunicação assíncrona entre serviços — fundamenta a escolha do CompositePublisher e a separação de responsabilidades entre RabbitMQ e WebSocket.)
