```mermaid

%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  %% === Clientes ===
  subgraph Clients["Clients"]
    Web["Web App"]
    Mobile["Mobile App"]
    Partner["Parceiros"]
  end

  %% === API / Presentation ===
  subgraph Api["Presentation Layer (API)"]
    Controller["Controllers Auth/JWT ProblemDetails"]
  end

  %% === Core DDD ===
  subgraph DDD["Core Application (DDD)"]
    subgraph Application["Application Layer"]
      UseCases["UseCases"]
      Validators["FluentValidation"]
      DTOs["DTOs / Mappers"]
    end
    subgraph Domain["Domain Layer"]
      Entities["Entities / ValueObjects"]
      Services["Domain Services"]
    end
    subgraph Infrastructure["Infrastructure Layer"]
      Repos["Repositories (Procs)"]
      Messaging["Messaging (Producer/Consumer)"]
    end
  end

  %% === DB & Broker separados ===
  DB[(SQL Server Stored Procedures)]
  Broker{{Message Broker RabbitMQ / Kafka}}

  %% === Worker ===
  subgraph Worker["Worker Layer"]
    Jobs["Jobs (cleanup, audit, etc.)"]
    Consumer["Message Consumers"]
  end

  %% Fluxos principais
  Clients --> Api
  Api --> Application
  Application --> Domain
  Application --> Infrastructure

  %% Infra saídas paralelas
  Infrastructure --> DB
  Infrastructure --> Broker

  %% Worker conexões (sem cruzar)
  Worker --> DB
  Worker --> Broker


```

# Application Architecture

```mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Application["Application Layer"]
    DTOs["DTOs Entrada/Saída de Dados Simples e sem lógica de negócio"]
    Mappers["Mappers Conversão DTO ⇄ Entities Isolamento entre camadas"]
    Interfaces["Interfaces Contratos p/ Serviços Abstrações p/ Domain/Infra"]
    Services["App Services Orquestram casos de uso Chama Domain & Infra Regras de aplicação"]
    UseCases["UseCases Casos de Uso específicos Fluxo de negócio orquestrado"]
    Validators["Validators (FluentValidation) Validação de DTOs e Requests"]
    Handlers["Handlers (Command/Query) Implementam CQRS Integração com Mediator"]
    Notifications["Notifications Mensagens de domínio convertidas p/ app Notificação de erros ou eventos"]
    Exceptions["Exceptions Tratamento de falhas Regras de exceção de aplicação"]
  end

```

# 📂 Estrutura e responsabilidades da Application Layer

## DTOs → Objetos de transporte, usados para entrada (requests) e saída (responses) da API. Não têm lógica de negócio.

## Mappers → Fazem a conversão entre DTOs e Entities (Domain). Garantem isolamento entre camadas.

## Interfaces → Contratos de serviços, que podem ser implementados por Domain ou Infra.

## Services (Application Services) → Contêm a lógica de orquestração dos casos de uso, chamando Domain Services e Infra Repositories.

## UseCases → Representam cenários de negócio específicos (ex: Criar Usuário, Processar Pagamento).

## Validators (FluentValidation) → Validação de DTOs e inputs antes de chegar ao Domain.

## Handlers (CQRS) → Implementação de Commands (escrita) e Queries (leitura), geralmente integrados com MediatR.

## Notifications → Canal para erros, warnings ou eventos que precisam ser propagados.

## Exceptions → Exceções de aplicação, isolando regras de erro que não pertencem ao Domain.

# Dtos

```mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph DTOs["Application/DTOs"]
    direction TB

    subgraph Requests["Requests"]
      R_desc["Entrada da API Validação antes do Domain Somente dados (sem regra)"]
      R_examples["Exemplos: CreateUserRequest UpdateExpenseRequest SearchExpenseRequest"]
    end

    subgraph Responses["Responses"]
      S_desc["Saída da API Modelos de retorno/paginação Sem lógica de negócio"]
      S_examples["Exemplos: UserResponse ExpenseSummaryResponse PagedResultResponse"]
    end

    subgraph Shared["Shared / Common (opcional)"]
      Sh_desc["Tipos reutilizáveis Endereço, Documento, Paginação, Filtros"]
      Sh_examples["Exemplos: AddressDto DocumentDto PaginationDto FilterDto"]
    end

    subgraph Profiles["Profiles / MappingConfig (opcional)"]
      P_desc["Configurações de mapping (AutoMapper) Perfil por agregado / feature"]
      P_examples["Exemplos: UserProfile ExpenseProfile"]
    end
  end

  %% Relações de uso
  Shared --> Requests
  Shared --> Responses
  Profiles --> Requests
  Profiles --> Responses
  Requests --> Responses

```

# Mappers

```mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Mappers["Application/Mappers"]
    direction TB

    subgraph Profiles["Profiles"]
      P_desc["Configuração de mapeamentos (AutoMapper) Agrupadas por agregado/feature Ex.: UserProfile, ExpenseProfile"]
    end

    subgraph Converters["Converters / TypeConverters"]
      C_desc["Conversões complexas DTO ⇄ Entity Ex.: string ⇄ enum, normalização de datas"]
    end

    subgraph Resolvers["ValueResolvers / MemberValueResolvers"]
      R_desc["Regras para campos específicos Ex.: compor NomeCompleto, calcular Status"]
    end

    subgraph Transformers["ValueTransformers (opcional)"]
      T_desc["Transformações globais de tipo Ex.: trim em strings, UTC ⇄ LocalTime"]
    end

    subgraph Extensions["Extensions (opcional)"]
      E_desc["Métodos de extensão p/ facilitar uso Ex.: obj.ToDto(), obj.ToEntity()"]
    end

    subgraph Config["MappingConfig / Registration"]
      MC_desc["Registro central do AutoMapper AddProfiles(), validação de configuração"]
    end
  end

  %% Relações
  Profiles --> Converters
  Profiles --> Resolvers
  Profiles --> Transformers
  Extensions --> Profiles
  Config --> Profiles

```


# Interfaces
```mermaid


%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Interfaces["Application/Interfaces"]
    direction TB

    subgraph Repositories["Repositories"]
      R_desc["Contratos p/ acesso a dados Infra implementa Ex.: IUserRepository, IExpenseRepository"]
    end

    subgraph Services["Services"]
      S_desc["Serviços de aplicação Usados pela API/Worker Ex.: IEmailService, INotificationService"]
    end

    subgraph Messaging["Messaging (opcional)"]
      M_desc["Contratos p/ mensageria Ex.: IMessageProducer, IMessageConsumer"]
    end

    subgraph External["External / Gateways (opcional)"]
      E_desc["Contratos p/ integrações externas Ex.: IPaymentGateway, IAuthProvider"]
    end

    subgraph Common["Common (opcional)"]
      C_desc["Interfaces utilitárias/genéricas Ex.: IUnitOfWork, ILoggerAdapter"]
    end
  end

  %% Relações
  Repositories --> Services
  Services --> Messaging
  Messaging --> External
  External --> Common
```

# Services
```mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Services["Application/Services"]
    direction TB

    subgraph AppServices["AppServices (Core)"]
      A_desc["Orquestram casos de uso Chamam Domain e Infra Ex.: UserAppService, ExpenseAppService"]
    end

    subgraph CommandHandlers["CommandHandlers (opcional)"]
      CH_desc["Manipulam Commands (escrita) Ex.: CreateUserCommandHandler, DeleteExpenseCommandHandler"]
    end

    subgraph QueryHandlers["QueryHandlers (opcional)"]
      QH_desc["Manipulam Queries (leitura) Ex.: GetUserByIdQueryHandler, GetExpensesByCategoryQueryHandler"]
    end

    subgraph Orchestrators["Orchestrators / Coordinators (opcional)"]
      O_desc["Coordenam fluxos complexos Ex.: CheckoutOrchestrator, ExpenseSyncCoordinator"]
    end

    subgraph Decorators["Decorators / Pipeline (opcional)"]
      D_desc["Cross-cutting concerns Ex.: Logging, Retry, Metrics"]
    end
  end

  %% Relações
  AppServices --> CommandHandlers
  AppServices --> QueryHandlers
  AppServices --> Orchestrators
  AppServices --> Decorators
```

# UseCases
```mermaid

%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph UseCases["Application/UseCases"]
    direction TB

    subgraph Commands["Commands"]
      C_desc["Casos de uso de escrita Create, Update, Delete Ex.: CreateUserCommand, UpdateExpenseCommand"]
    end

    subgraph Queries["Queries"]
      Q_desc["Casos de uso de leitura Consultas e relatórios Ex.: GetUserByIdQuery, GetExpensesByCategoryQuery"]
    end

    subgraph Events["Events / Notifications (opcional)"]
      E_desc["Casos de uso disparados por eventos Ex.: UserCreatedEventHandler, ExpenseDeletedEventHandler"]
    end

    subgraph Pipelines["Pipelines / Interactors (opcional)"]
      P_desc["Fluxos compostos de múltiplos casos de uso Ex.: CloseMonthInteractor"]
    end
  end

  %% Relações
  Commands --> Queries
  Commands --> Events
  Queries --> Events
  Events --> Pipelines
```

# Validators
```mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Validators["Application/Validators"]
    direction TB

    subgraph Features["Features (por módulo)"]
      UsersV["Users • CreateUserRequestValidator • UpdateUserRequestValidator"]
      ExpensesV["Expenses • CreateExpenseRequestValidator • UpdateExpenseRequestValidator"]
      CategoriesV["Categories • CreateCategoryRequestValidator"]
    end

    subgraph Common["Common / Shared"]
      Rules["Rules • Regras reutilizáveis • Ex.: CpfRule, EmailRule, MoneyRule"]
      Extensions["Extensions • Métodos de extensão FluentValidation • Ex.: NotEmptyTrimmed(), ValidEnum()"]
      Messages["Messages / ErrorCodes • Mensagens padronizadas • Enum de códigos de erro"]
      Helpers["Helpers • Utilidades de validação • Normalização, regex, datas"]
    end

    subgraph Pipeline["Pipeline (opcional)"]
      Behavior["ValidationBehavior<TReq,TRes> • Executa validação antes do Handler • Agrega erros em ProblemDetails"]
      Adapt["Adapters (opcional) • Mapeia ValidationFailure → Error DTO"]
    end
  end

  %% Relações
  Common --> Features
  Pipeline --> Features
```

# Handlers
```mermaid

%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Handlers["Application/Handlers"]
    direction TB

    subgraph Commands["CommandHandlers (Escrita)"]
      C_desc["Manipulam Commands Create/Update/Delete Transação + UoW Chamam Domain/Repos"]
      C_examples["Ex.: CreateUserCommandHandler UpdateExpenseCommandHandler DeleteCategoryCommandHandler"]
    end

    subgraph Queries["QueryHandlers (Leitura)"]
      Q_desc["Manipulam Queries Consultas otimizadas Projeções para DTOs Paginação/Filtros"]
      Q_examples["Ex.: GetUserByIdQueryHandler GetExpensesByCategoryQueryHandler ListTransactionsPagedHandler"]
    end

    subgraph Notifications["NotificationHandlers (Eventos)"]
      N_desc["Reagem a eventos (publish/subscribe) Side-effects: e-mail, auditoria, outbox Integração assíncrona"]
      N_examples["Ex.: UserCreatedNotificationHandler ExpenseDeletedNotificationHandler"]
    end

    subgraph Pipeline["PipelineBehaviors (opcional)"]
      PB_val["ValidationBehavior Valida Requests antes do Handler"]
      PB_log["LoggingBehavior Métricas/Tracing/CorrelationId"]
      PB_retry["RetryBehavior Polly/Resiliência (somente leitura ou idempotente)"]
      PB_perf["PerformanceBehavior Tempo por handler"]
    end

    subgraph Mappings["Mappings (opcional)"]
      MP_desc["Adaptadores entre Command/Query e DTOs Normalização/Enriquecimento de dados"]
    end
  end

  %% Relações (opcional)
  Pipeline --> Commands
  Pipeline --> Queries
  Notifications --> Commands
  Notifications --> Queries
  Mappings --> Commands
  Mappings --> Queries


```

# Notifications
```mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Notifications["Application/Notifications"]
    direction TB

    subgraph Events["Events (Application/Domain→App)"]
      E_desc["Contratos de eventos/notificações Ex.: UserCreated, ExpenseDeleted"]
    end

    subgraph Publishers["Publishers"]
      P_desc["Publicam notificações (in-proc via MediatR ou outbox → broker) Ex.: NotificationPublisher"]
    end

    subgraph Handlers["Handlers"]
      H_desc["Reagem aos eventos (side-effects) Ex.: enviar e-mail, auditoria, projeções de leitura"]
    end

    subgraph Adapters["Adapters / Translators (opcional)"]
      A_desc["Mapeiam DomainEvent → AppNotification Normalizam payloads para fila/API externa"]
    end

    subgraph Outbox["Outbox (opcional)"]
      O_desc["Tabela de saída transacional Processador de outbox para broker (Rabbit/Kafka)"]
    end

    subgraph Policies["Policies (opcional)"]
      PL_desc["Retry/Backoff/Dead-letter Idempotência e deduplicação"]
    end
  end

  %% Relações
  Events --> Publishers
  Publishers --> Handlers
  Adapters --> Publishers
  Outbox --> Publishers
  Policies --> Handlers
  Policies --> Publishers

  ```

  # Exceptions
  ```mermaid

%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Exceptions["Application/Exceptions"]
    direction TB

    subgraph Types["Types"]
      T_desc["Hierarquia de exceções de Aplicação • ApplicationException (base) • ValidationException • NotFoundException • ConflictException • UnauthorizedException • ForbiddenException • BusinessRuleException"]
    end

    subgraph Mapping["Mapping / ProblemDetails"]
      M_desc["Mapeia Exception → ProblemDetails (RFC 7807) • status, type, title, detail, instance • errorCode, traceId, fieldErrors"]
    end

    subgraph Translators["Translators / Adapters"]
      TR_desc["DomainException → ApplicationException InfraException → ApplicationException Normalização e códigos"]
    end

    subgraph Middleware["Middleware / Filters"]
      MW_desc["ExceptionHandlingMiddleware ApiExceptionFilter (opcional) Oculta stack em produção"]
    end

    subgraph Policies["Policies (opcional)"]
      P_desc["Retryable vs NonRetryable Idempotência/CorrelationId Telemetria/Logging"]
    end

    subgraph Codes["ErrorCodes / Messages"]
      C_desc["Enum de códigos Mensagens padronizadas/i18n Catálogo de erros"]
    end
  end

  %% Relações
  Types --> Mapping
  Translators --> Types
  Middleware --> Mapping
  Policies --> Middleware
  Codes --> Mapping

  ```

  # Presentation Layer
```mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Presentation["Presentation Layer (API)"]
    direction TB

    subgraph Controllers["Controllers"]
      C_desc["Expondo endpoints REST/GraphQL/gRPC Chamam Application Services ou Handlers Ex.: UserController, ExpenseController"]
    end

    subgraph Filters["Filters"]
      F_desc["Filtros de ação e exceção Ex.: ApiExceptionFilter, ValidationFilter"]
    end

    subgraph Middleware["Middleware"]
      M_desc["Pipeline HTTP (Request → Response) Ex.: ExceptionHandlingMiddleware, CorrelationIdMiddleware"]
    end

    subgraph Auth["Auth / Security"]
      A_desc["Autenticação e Autorização Ex.: JWT Bearer, OAuth2, AuthorizationPolicies"]
    end

    subgraph ProblemDetails["ProblemDetails / Error Handling"]
      PD_desc["Padrão RFC 7807 Mapeamento de exceções p/ HTTP Ex.: ProblemDetailsFactory, ValidationProblemDetails"]
    end

    subgraph Config["Config"]
      Co_desc["Configurações auxiliares da API Ex.: SwaggerConfig, ApiVersioningConfig"]
    end
  end

  %% Relações
  Controllers --> Filters
  Controllers --> Middleware
  Controllers --> Auth
  Controllers --> ProblemDetails
  Controllers --> Config
```

# Controller
```mermaid  

%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Controllers["Presentation/Controllers"]
    direction TB

    subgraph Users["Users"]
      U_desc["UserController CRUD de usuários Gestão de perfis e permissões"]
    end

    subgraph Expenses["Expenses"]
      E_sync["ExpenseControllerSync Operações síncronas (REST direto)"]
      E_async["ExpenseControllerAsync Operações assíncronas (mensageria, fila)"]
    end

    subgraph Categories["Categories"]
      C_desc["CategoryController Gestão de categorias de despesas"]
    end

    subgraph Transactions["Transactions"]
      T_desc["TransactionController Gerencia transações financeiras Ex.: registrar, listar, consultar"]
    end

    subgraph Auth["Auth / Identity"]
      A_auth["AuthController Login, RefreshToken, Logout"]
      A_account["AccountController Cadastro e gerenciamento de contas"]
    end

    subgraph Admin["Admin / Management"]
      Adm_sys["SystemController Status do sistema, health check"]
      Adm_mon["MonitoringController Logs, métricas, auditoria"]
    end

    subgraph Base["Base (opcional)"]
      B_base["ApiControllerBase Helper p/ respostas padronizadas Ex.: Ok(), Problem(), CreatedAt()"]
    end
  end
```

# Filters
```mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Filters["Presentation/Filters"]
    direction TB

    subgraph ExceptionFilters["ExceptionFilters"]
      Ex1["ApiExceptionFilter Captura exceções → ProblemDetails"]
      Ex2["DomainExceptionFilter DomainException → ApplicationException"]
    end

    subgraph ValidationFilters["ValidationFilters"]
      V1["ValidationFilter Valida ModelState/DTOs Integra FluentValidation"]
    end

    subgraph ActionFilters["ActionFilters"]
      A1["LoggingActionFilter Log de requests/responses"]
      A2["AuditActionFilter Auditoria de chamadas críticas"]
    end

    subgraph AuthorizationFilters["AuthorizationFilters"]
      AU1["RoleAuthorizationFilter Regras customizadas de roles/policies"]
    end

    subgraph ResultFilters["ResultFilters"]
      R1["ResponseWrapperFilter Padroniza formato de resposta (ex.: envelopar em { data, errors })"]
    end
  end
```

# Middleware
```mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%
flowchart TB

  subgraph Middleware["Presentation/Middleware"]
    direction TB

    Ex["ExceptionHandlingMiddleware Captura exceções globais → ProblemDetails"]
    Corr["CorrelationIdMiddleware Gera e propaga CorrelationId p/ rastreamento"]
    Log["LoggingMiddleware Log de Request/Response + Métricas básicas"]
    Time["RequestTimingMiddleware Mede tempo de execução + Telemetria/Tracing"]
    Auth["AuthenticationMiddleware (opcional) Autenticação customizada/OAuth2"]
    Rate["RateLimitingMiddleware (opcional) Controle de chamadas Throttling/Quota"]
    Cache["CachingMiddleware (opcional) Cache de respostas"]
    Sec["SecurityHeadersMiddleware (opcional) Headers de segurança: CSP, CORS, HSTS"]
  end

  ```