-- Camadas (Clients, Presentation, Application, Domain, Infrastructure, Worker)
CREATE TABLE dbo.Layer (
  LayerId       INT IDENTITY PRIMARY KEY,
  Name          NVARCHAR(50)  NOT NULL UNIQUE,
  Description   NVARCHAR(200) NULL
);

-- Itens/pastas dentro de cada camada (Controllers, DTOs, Services, etc.)
CREATE TABLE dbo.LayerItem (
  ItemId        INT IDENTITY PRIMARY KEY,
  LayerId       INT NOT NULL FOREIGN KEY REFERENCES dbo.Layer(LayerId),
  Name          NVARCHAR(80)  NOT NULL,
  Description   NVARCHAR(300) NULL,
  CONSTRAINT UQ_LayerItem UNIQUE (LayerId, Name)
);

-- Tipos de relacionamento (invokes, maps_to, implements, persists, etc.)
CREATE TABLE dbo.RelationshipType (
  RelationshipTypeId INT IDENTITY PRIMARY KEY,
  Name               NVARCHAR(40) NOT NULL UNIQUE
);

-- Relacionamentos entre itens (pasta A -> pasta B)
CREATE TABLE dbo.Relationship (
  RelationshipId     INT IDENTITY PRIMARY KEY,
  FromItemId         INT NOT NULL FOREIGN KEY REFERENCES dbo.LayerItem(ItemId),
  ToItemId           INT NOT NULL FOREIGN KEY REFERENCES dbo.LayerItem(ItemId),
  RelationshipTypeId INT NOT NULL FOREIGN KEY REFERENCES dbo.RelationshipType(RelationshipTypeId),
  Notes              NVARCHAR(300) NULL,
  CONSTRAINT CK_Relationship_NotSelf CHECK (FromItemId <> ToItemId)
);
GO
-- Camadas
INSERT dbo.Layer (Name, Description) VALUES
 ('Clients',        N'Aplicações consumidoras'),
 ('Presentation',   N'API / Controllers / Middleware'),
 ('Application',    N'Orquestração, casos de uso, DTOs'),
 ('Domain',         N'Regras de negócio puras'),
 ('Infrastructure', N'Persistência, mensageria, migrações'),
 ('Worker',         N'Jobs e consumers assíncronos');

-- Tipos de relacionamento
INSERT dbo.RelationshipType (Name) VALUES
 ('invokes'), ('maps_to'), ('implements'), ('persists'),
 ('uses'), ('publishes'), ('handles'), ('wraps'),
 ('secures'), ('formats_errors'), ('triggers'), ('configures');

-- ====== Itens por camada ======

-- Presentation
DECLARE @Presentation INT = (SELECT LayerId FROM dbo.Layer WHERE Name='Presentation');
INSERT dbo.LayerItem (LayerId, Name, Description) VALUES
 (@Presentation, N'Controllers', N'Endpoints HTTP'),
 (@Presentation, N'Filters',     N'Exception/Validation/Action/Result'),
 (@Presentation, N'Middleware',  N'Pipeline HTTP'),
 (@Presentation, N'Auth',        N'JWT/Policies/Claims'),
 (@Presentation, N'ProblemDetails', N'Erros RFC 7807'),
 (@Presentation, N'Admin',       N'Endpoints de operação'),
 (@Presentation, N'Models',      N'Requests/Responses/Binders'),
 (@Presentation, N'Config',      N'Swagger/CORS/Versioning/JSON');

-- Application
DECLARE @Application INT = (SELECT LayerId FROM dbo.Layer WHERE Name='Application');
INSERT dbo.LayerItem (LayerId, Name, Description) VALUES
 (@Application, N'DTOs',        N'Requests/Responses/Shared/Profiles'),
 (@Application, N'Mappers',     N'Profiles/Converters/Resolvers'),
 (@Application, N'Interfaces',  N'Repositories/Services/Messaging'),
 (@Application, N'Services',    N'AppServices/Decorators/Orchestrators'),
 (@Application, N'UseCases',    N'Commands/Queries/Events/Pipelines'),
 (@Application, N'Validators',  N'Features/Common/Pipeline'),
 (@Application, N'Handlers',    N'Commands/Queries/Notifications/Pipeline'),
 (@Application, N'Notifications', N'Events/Publishers/Outbox/Policies'),
 (@Application, N'Exceptions',  N'Tipos/Mapeamento/Middleware/Codes');

-- Domain
DECLARE @Domain INT = (SELECT LayerId FROM dbo.Layer WHERE Name='Domain');
INSERT dbo.LayerItem (LayerId, Name, Description) VALUES
 (@Domain, N'Entities',       N'Entidades com identidade'),
 (@Domain, N'ValueObjects',   N'Objetos de valor imutáveis'),
 (@Domain, N'Services',       N'Serviços de domínio'),
 (@Domain, N'Events',         N'Eventos de domínio'),
 (@Domain, N'Specifications', N'Regras/consultas encapsuladas'),
 (@Domain, N'Exceptions',     N'Erros de negócio'),
 (@Domain, N'Aggregates',     N'Raízes de agregado');

-- Infrastructure
DECLARE @Infra INT = (SELECT LayerId FROM dbo.Layer WHERE Name='Infrastructure');
INSERT dbo.LayerItem (LayerId, Name, Description) VALUES
 (@Infra, N'Repositories', N'Implementações de I*Repository'),
 (@Infra, N'Messaging',    N'Broker/Queues (Producer/Consumer)'),
 (@Infra, N'Outbox',       N'Processor do Outbox pattern'),
 (@Infra, N'Persistence',  N'DbContext/Conexões/UoW'),
 (@Infra, N'Migrations',   N'Scripts de evolução do schema');

-- Worker
DECLARE @Worker INT = (SELECT LayerId FROM dbo.Layer WHERE Name='Worker');
INSERT dbo.LayerItem (LayerId, Name, Description) VALUES
 (@Worker, N'Jobs',      N'Tarefas agendadas'),
 (@Worker, N'Consumers', N'Leitores de filas');

-- ====== Relacionamentos chave ======
DECLARE
  @Controllers INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Controllers'    AND LayerId=@Presentation),
  @UseCases    INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='UseCases'       AND LayerId=@Application),
  @Handlers    INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Handlers'       AND LayerId=@Application),
  @Validators  INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Validators'     AND LayerId=@Application),
  @Mappers     INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Mappers'        AND LayerId=@Application),
  @DTOs        INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='DTOs'           AND LayerId=@Application),
  @Interfaces  INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Interfaces'     AND LayerId=@Application),
  @Repositories INT= (SELECT ItemId FROM dbo.LayerItem WHERE Name='Repositories'   AND LayerId=@Infra),
  @DomainEntities INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Entities'    AND LayerId=@Domain),
  @Problem      INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='ProblemDetails'AND LayerId=@Presentation),
  @Auth         INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Auth'          AND LayerId=@Presentation),
  @Middleware   INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Middleware'    AND LayerId=@Presentation),
  @Outbox       INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Outbox'        AND LayerId=@Infra),
  @Notifications INT= (SELECT ItemId FROM dbo.LayerItem WHERE Name='Notifications' AND LayerId=@Application),
  @Messaging    INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Messaging'     AND LayerId=@Infra),
  @Jobs         INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Jobs'          AND LayerId=@Worker),
  @Consumers    INT = (SELECT ItemId FROM dbo.LayerItem WHERE Name='Consumers'     AND LayerId=@Worker);

-- Helpers p/ pegar ids de tipos
DECLARE
  @invokes INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='invokes'),
  @maps_to INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='maps_to'),
  @implements INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='implements'),
  @persists INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='persists'),
  @handles INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='handles'),
  @wraps INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='wraps'),
  @secures INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='secures'),
  @formats_errors INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='formats_errors'),
  @publishes INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='publishes'),
  @uses INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='uses'),
  @triggers INT = (SELECT RelationshipTypeId FROM dbo.RelationshipType WHERE Name='triggers');

-- Controllers → UseCases (invokes)
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId, Notes)
VALUES (@Controllers, @UseCases, @invokes, N'API chama casos de uso');

-- Handlers → UseCases (handles)
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Handlers, @UseCases, @handles);

-- Validators → Handlers (wraps)
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId, Notes)
VALUES (@Validators, @Handlers, @wraps, N'ValidationBehavior em CQRS');

-- Mappers → Domain.Entities (maps_to)
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Mappers, @DomainEntities, @maps_to);

-- Interfaces.Repositories → Infrastructure.Repositories (implements)
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Interfaces, @Repositories, @implements);

-- Infrastructure.Repositories → Domain.Entities (persists)
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Repositories, @DomainEntities, @persists);

-- Notifications (App) → Messaging (Infra) (publishes/uses)
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Notifications, @Messaging, @publishes);
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Notifications, @Outbox, @uses);

-- Middleware/Auth/ProblemDetails ligados aos Controllers
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Middleware, @Controllers, @wraps);
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Auth, @Controllers, @secures);
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Problem, @Controllers, @formats_errors);

-- Worker: Jobs/Consumers
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Jobs, @UseCases, @triggers);
INSERT dbo.Relationship (FromItemId, ToItemId, RelationshipTypeId)
VALUES (@Consumers, @Messaging, @uses);
-- 1) Ver todas as pastas (itens) por camada
SELECT L.Name  AS Layer, I.Name AS Item, I.Description
FROM dbo.LayerItem I
JOIN dbo.Layer L ON L.LayerId = I.LayerId
ORDER BY L.Name, I.Name;

-- 2) Ver o grafo de relacionamentos legível
SELECT
  Lf.Name AS FromLayer, Ifm.Name AS FromItem,
  Rt.Name AS RelType,
  Lt.Name AS ToLayer,   Ito.Name AS ToItem,
  R.Notes
FROM dbo.Relationship R
JOIN dbo.LayerItem Ifm ON Ifm.ItemId = R.FromItemId
JOIN dbo.Layer     Lf  ON Lf.LayerId = Ifm.LayerId
JOIN dbo.LayerItem Ito ON Ito.ItemId = R.ToItemId
JOIN dbo.Layer     Lt  ON Lt.LayerId = Ito.LayerId
JOIN dbo.RelationshipType Rt ON Rt.RelationshipTypeId = R.RelationshipTypeId
ORDER BY FromLayer, FromItem, RelType;

-- 3) Quem "invoca" UseCases?
SELECT
  LayerFrom.Name          AS FromLayer,
  LayerItemFrom.Name      AS FromItem,
  RelationshipType.Name   AS RelType,
  LayerTo.Name            AS ToLayer,
  LayerItemTo.Name        AS ToItem,
  Relationship.Notes
FROM dbo.Relationship AS Relationship
JOIN dbo.LayerItem AS LayerItemFrom 
     ON LayerItemFrom.ItemId = Relationship.FromItemId
JOIN dbo.Layer AS LayerFrom 
     ON LayerFrom.LayerId = LayerItemFrom.LayerId
JOIN dbo.LayerItem AS LayerItemTo 
     ON LayerItemTo.ItemId = Relationship.ToItemId
JOIN dbo.Layer AS LayerTo 
     ON LayerTo.LayerId = LayerItemTo.LayerId
JOIN dbo.RelationshipType AS RelationshipType 
     ON RelationshipType.RelationshipTypeId = Relationship.RelationshipTypeId
ORDER BY
  LayerFrom.Name, LayerItemFrom.Name, RelationshipType.Name;


