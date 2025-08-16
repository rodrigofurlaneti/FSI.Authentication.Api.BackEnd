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
      R_desc["Contratos p/ acesso a dados\nInfra implementa\nEx.: IUserRepository, IExpenseRepository"]
    end

    subgraph Services["Services"]
      S_desc["Serviços de aplicação\nUsados pela API/Worker\nEx.: IEmailService, INotificationService"]
    end

    subgraph Messaging["Messaging (opcional)"]
      M_desc["Contratos p/ mensageria\nEx.: IMessageProducer, IMessageConsumer"]
    end

    subgraph External["External / Gateways (opcional)"]
      E_desc["Contratos p/ integrações externas\nEx.: IPaymentGateway, IAuthProvider"]
    end

    subgraph Common["Common (opcional)"]
      C_desc["Interfaces utilitárias/genéricas\nEx.: IUnitOfWork, ILoggerAdapter"]
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
      A_desc["Orquestram casos de uso\nChamam Domain e Infra\nEx.: UserAppService, ExpenseAppService"]
    end

    subgraph CommandHandlers["CommandHandlers (opcional)"]
      CH_desc["Manipulam Commands (escrita)\nEx.: CreateUserCommandHandler, DeleteExpenseCommandHandler"]
    end

    subgraph QueryHandlers["QueryHandlers (opcional)"]
      QH_desc["Manipulam Queries (leitura)\nEx.: GetUserByIdQueryHandler, GetExpensesByCategoryQueryHandler"]
    end

    subgraph Orchestrators["Orchestrators / Coordinators (opcional)"]
      O_desc["Coordenam fluxos complexos\nEx.: CheckoutOrchestrator, ExpenseSyncCoordinator"]
    end

    subgraph Decorators["Decorators / Pipeline (opcional)"]
      D_desc["Cross-cutting concerns\nEx.: Logging, Retry, Metrics"]
    end
  end

  %% Relações
  AppServices --> CommandHandlers
  AppServices --> QueryHandlers
  AppServices --> Orchestrators
  AppServices --> Decorators
```