# Topologia do laboratório SRE

Snapshot do ambiente em 8 de outubro de 2026.

## Diagrama

```mermaid
flowchart TB
    subgraph LOCAL["Estação de trabalho"]
        WSL["WSL / Ubuntu<br/>git · terraform · kubectl · helm"]
        BROWSER["Navegador"]
    end

    subgraph GIT["GitHub"]
        REPO["sre-platform-lab<br/>main · 2711f93"]
    end

    subgraph OCI["Oracle Cloud Infrastructure"]
        OKE["OKE: sre-platform-lab-oke<br/>Kubernetes v1.36.4<br/>1 node · Ready"]

        subgraph NS_ARGO["Namespace: argocd"]
            ARGO["Argo CD<br/>Application: platform-api<br/>Synced · Healthy"]
        end

        subgraph NS_APP["Namespace: platform-api"]
            API1["platform-api<br/>réplica 1"]
            API2["platform-api<br/>réplica 2"]
            SM["ServiceMonitor<br/>platform-api"]
        end

        subgraph NS_OBS["Namespace: observability"]
            PROM["Prometheus<br/>2/2 containers"]
            GRAF["Grafana<br/>3/3 containers"]
            PVC["PVC do Prometheus<br/>50Gi · Bound · oci-bv"]
            EXPORTERS["node-exporter<br/>kube-state-metrics"]
        end

        subgraph NS_TRAEFIK["Namespace: traefik"]
            TRAEFIK["Traefik<br/>Ingress controller"]
        end
    end

    WSL -->|"git push"| REPO
    WSL -->|"Terraform / kubectl / Helm"| OKE
    ARGO -->|"consulta e sincroniza manifests"| REPO
    ARGO -->|"gerencia a aplicação"| API1
    ARGO -->|"gerencia a aplicação"| API2
    SM -->|"descoberta do alvo"| PROM
    PROM -->|"scrape de métricas"| API1
    PROM -->|"scrape de métricas"| API2
    PROM --> EXPORTERS
    PROM -->|"dados de séries temporais"| PVC
    GRAF -->|"consulta de métricas"| PROM
    BROWSER -->|"localhost:3000 via kubectl port-forward"| GRAF
    BROWSER -->|"localhost:9090 via kubectl port-forward"| PROM
```

## Componentes

- **Estação local:** WSL/Ubuntu usado para executar Git, Terraform, `kubectl` e Helm.
- **GitHub:** repositório do laboratório; o commit `2711f93` contém o ajuste de recursos e a estratégia `Recreate` do Grafana.
- **OCI / OKE:** cluster `sre-platform-lab-oke`, Kubernetes v1.36.4, com um node `Ready`.
- **Argo CD:** monitora a aplicação `platform-api`, reportada como `Synced` e `Healthy`.
- **Aplicação:** `platform-api`, com duas réplicas e um `ServiceMonitor`.
- **Observabilidade:** Prometheus, Grafana, `node-exporter` e `kube-state-metrics`.
- **Persistência:** PVC do Prometheus com 50Gi, estado `Bound`, usando a StorageClass `oci-bv`.
- **Acesso às interfaces:** `kubectl port-forward` disponibiliza Grafana em `localhost:3000` e Prometheus em `localhost:9090`; esses encaminhamentos são locais e temporários.

## Estado registrado

- Grafana: `3/3 Running`, 0 restarts na última checagem compartilhada.
- Prometheus: `2/2 Running`, 0 restarts na última checagem compartilhada.
- `platform-api`: duas réplicas `Running`; aplicação `Synced` e `Healthy` no Argo CD.
- PVC do Prometheus: `Bound`, 50Gi.
- Git: `main` em `2711f93`, alinhado com `origin/main` na última checagem compartilhada.
