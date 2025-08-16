```mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%
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

```
  
---

## 🔑 Detalhes importantes
- O bloco precisa começar com **\`\`\`mermaid** e terminar com **\`\`\`**.  
- A linha `%%{init: ...}%%` é aceita, mas precisa estar **dentro** do bloco.  
- Se deixar fora, o GitHub trata como texto simples (o que aconteceu no seu caso).

---

👉 Faz esse ajuste, commita e atualiza no GitHub. Aí o gráfico vai renderizar no próprio README.  

Quer que eu te monte já um **README.md completo** com o diagrama + árvore de pastas da camada `Application` para você colar direto no repo?
