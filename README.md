```mermaid
%% =====================================================================
%% Arquitetura da Application Layer - FSI.Authentication
%% =====================================================================

%% VISÃO GERAL DA SOLUÇÃO (DDD/CQRS)
flowchart TB

  subgraph Clients["Clients"]
    Web["Web App"]
    Mobile["Mobile App"]
    Partner["Parceiros"]
  end

  subgraph Api["Presentation Layer (API)"]
    Controller["Controllers\n+ Auth/JWT\n+ ProblemDetails"]
  end

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

  DB[(SQL Server\nStored Procedures)]
  Broker{{Message Broker\nRabbitMQ / Kafka}}

  subgraph Worker["Worker Layer"]
    Jobs["Jobs"]
    Consumer["Message Consumers"]
  end

  Clients --> Api
  Api --> Application
  Application --> Domain
  Application --> Infrastructure
  Infrastructure --> DB
  Infrastructure --> Broker
  Worker --> DB
  Worker --> Broker

%% =====================================================================
%% DETALHAMENTO DA APPLICATION LAYER (PASTAS E ARQUIVOS)
%% =====================================================================

flowchart TB

  A["/Application"] --> B["/Contracts"]
  B --> B1["/Requests"]
  B1 --> BR1["LoginRequest.cs"]
  B1 --> BR2["RefreshTokenRequest.cs"]
  B1 --> BR3["RevokeTokenRequest.cs"]
  B1 --> BR4["CreateUserRequest.cs"]
  B1 --> BR5["GetUserByIdRequest.cs"]

  B --> B2["/Responses"]
  B2 --> BS1["LoginResponse.cs"]
  B2 --> BS2["RefreshTokenResponse.cs"]
  B2 --> BS3["RevokeTokenResponse.cs"]
  B2 --> BS4["UserResponse.cs"]

  B --> B3["IAuthAppService.cs"]
  B --> B4["IUserAppService.cs"]

  A --> C["/UseCases"]
  C --> C1["/Auth"]
  C1 --> C1a["LoginUseCase.cs"]
  C1 --> C1b["RefreshTokenUseCase.cs"]
  C1 --> C1c["RevokeTokenUseCase.cs"]
  C --> C2["/User"]
  C2 --> C2a["CreateUserUseCase.cs"]
  C2 --> C2b["GetUserByIdUseCase.cs"]
  C2 --> C2c["UpdatePasswordUseCase.cs"]

  A --> D["/Validators"]
  D --> D1["LoginRequestValidator.cs"]
  D --> D2["RefreshTokenRequestValidator.cs"]
  D --> D3["RevokeTokenRequestValidator.cs"]
  D --> D4["CreateUserValidator.cs"]
  D --> D5["GetUserByIdValidator.cs"]

  A --> E["/Mapping"]
  E --> E1["AuthMappingProfile.cs"]
  E --> E2["UserMappingProfile.cs"]

  A --> F["/Common"]
  F --> F1["Result.cs"]
  F --> F2["Errors.cs"]
  F --> F3["PagedResult.cs"]
  F --> F4["OperationStatus.cs"]

  A --> G["/Behaviors (opcional)"]
  G --> G1["LoggingBehavior.cs"]
  G --> G2["ValidationBehavior.cs"]
  G --> G3["PerformanceBehavior.cs"]

  A --> H["/Exceptions (opcional)"]
  H --> H1["ApplicationException.cs"]
  H --> H2["ValidationException.cs"]

%% =====================================================================
%% FUNÇÃO DE CADA PASTA
%% =====================================================================

flowchart LR

  subgraph Application["Application Layer (DDD/CQRS)"]
    Contracts["/Contracts"]
    UseCases["/UseCases"]
    Validators["/Validators"]
    Mapping["/Mapping"]
    Common["/Common"]
    Behaviors["/Behaviors (opcional)"]
    Exceptions["/Exceptions (opcional)"]
  end

  Contracts -->|Entrada/Saída| DescContracts["DTOs de Request/Response\n+ Interfaces de Serviços de Aplicação\nExposição para a camada Presentation.\nSem regra de negócio."]
  UseCases -->|Orquestra| DescUseCases["Casos de uso (Application Services)\nValida → chama Domain/Infra → monta Response.\nSem lógica de domínio."]
  Validators -->|Garante| DescValidators["Validação de entrada (ex.: FluentValidation)\nFormato/consistência antes do uso."]
  Mapping -->|Converte| DescMapping["Mapeamentos Domain ↔ DTOs\nAutoMapper ou manual, centralizados."]
  Common -->|Utilidades| DescCommon["Tipos utilitários: Result<T>, Errors,\nPagedResult, OperationStatus, helpers."]
  Behaviors -->|Pipeline| DescBehaviors["Cross-cutting (ex.: MediatR):\nLogging, Validation, Performance, Retry."]
  Exceptions -->|Erros| DescExceptions["Exceções da camada Application\npara falhas controladas/padronizadas."]
```
