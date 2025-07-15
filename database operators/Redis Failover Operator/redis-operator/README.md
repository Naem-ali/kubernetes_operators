# 🔄 Redis Failover Operator

<div align="center">
  <img src="https://redis.io/images/redis-white.png" width="200" style="background-color: #222;">
  <br>
  <strong>Automated Redis Cluster Management for Kubernetes</strong>
  <br><br>
</div>

[![License](https://img.shields.io/badge/license-Apache%202.0-red.svg)](LICENSE)
[![Go](https://img.shields.io/badge/go-v1.19+-blue.svg)](https://golang.org/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%3E%3D%201.19-brightgreen.svg)](https://kubernetes.io/)
[![Redis](https://img.shields.io/badge/redis-6.2+-red.svg)](https://redis.io/)

## 🎯 Features

- ⚡ **High Availability**
  - Automatic failover on master node failure
  - Seamless replica promotion
  - Zero-downtime configuration updates

- 💾 **Backup & Recovery**
  - Scheduled backups to S3 or PVC
  - Point-in-time recovery
  - Configurable retention policies

- 📊 **Monitoring**
  - Redis cluster health monitoring
  - Prometheus metrics integration
  - Custom alerting rules

- 🔒 **Security**
  - TLS encryption support
  - Password authentication
  - Role-based access control

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (v1.19+)
- Helm v3
- kubectl CLI
- Access to container registry

### Installation

1. **Deploy the operator:**
```bash
# Install CRDs
kubectl apply -f deploy/crds/

# Deploy operator
kubectl apply -f deploy/operator.yaml
```

2. **Create a Redis cluster:**
```yaml
apiVersion: redis.example.com/v1
kind: RedisCluster
metadata:
  name: my-redis
spec:
  replicas: 3
  version: "6.2"
  persistence:
    enabled: true
    size: 10Gi
```

## 🏗️ Architecture

```mermaid
graph TD
    A[Operator Controller] -->|Manages| B[Redis Master]
    B -->|Replicates to| C[Redis Replica 1]
    B -->|Replicates to| D[Redis Replica 2]
    A -->|Monitors| E[Health Checks]
    A -->|Configures| F[Backups]
```

### Detailed Architecture
```mermaid
graph TD
    subgraph Kubernetes Cluster
        API[Kubernetes API Server] -->|Watch Events| Controller[Redis Operator Controller]
        
        subgraph Operator Components
            Controller -->|Manages| CRD[Redis CRD]
            Controller -->|Configures| Config[Redis Configuration]
            Controller -->|Monitors| Sentinel[Redis Sentinel]
            Controller -->|Controls| Services[Service Objects]
            Controller -->|Collects| Metrics[Metrics Exporter]
            Controller -->|Manages| Backup[Backup Manager]
        end
        
        subgraph Redis Cluster
            Master[Redis Master] -->|Writes| PVC1[Master PVC]
            Replica1[Redis Replica 1] -->|Reads| PVC2[Replica PVC 1]
            Replica2[Redis Replica 2] -->|Reads| PVC3[Replica PVC 2]
            Master -->|Replicates to| Replica1
            Master -->|Replicates to| Replica2
        end
        
        subgraph Sentinel Layer
            Sentinel -->|Monitors| Master
            Sentinel -->|Monitors| Replica1
            Sentinel -->|Monitors| Replica2
            Sentinel -->|Triggers| Failover[Failover Process]
        end
        
        subgraph Monitoring
            Metrics -->|Exports| Prometheus[Prometheus]
            Prometheus -->|Displays| Grafana[Grafana]
        end
        
        subgraph Backup Infrastructure
            Backup -->|Schedules| BackupJob[Backup Jobs]
            BackupJob -->|Stores| Storage[S3/PVC Storage]
        end
    end

    style Kubernetes Cluster fill:#f5f5f5,stroke:#333,stroke-width:2px
    style Operator Components fill:#ffebee,stroke:#c62828,stroke-width:2px
    style Redis Cluster fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style Sentinel Layer fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style Monitoring fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style Backup Infrastructure fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
```

## 📊 Monitoring

Access Redis metrics at `:9121/metrics`:
- Command execution stats
- Memory usage
- Connection stats
- Replication status

## ⚙️ Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicas` | Number of Redis replicas | 2 |
| `persistence.enabled` | Enable persistent storage | true |
| `resources.requests.memory` | Memory request | 1Gi |
| `monitoring.enabled` | Enable Prometheus metrics | true |

## 🛠️ Development

```bash
# Build operator
make build

# Run tests
make test

# Generate manifests
make manifests
```

## 🚨 Troubleshooting

Common issues and solutions:
- 🔍 Failover not working
- 🔌 Connection issues
- 💽 Persistence problems

## 📚 Documentation

- [Detailed Setup Guide](docs/setup.md)
- [Configuration Reference](docs/configuration.md)
- [Backup & Recovery](docs/backup.md)
- [Monitoring Guide](docs/monitoring.md)

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md)


## 💬 Support

- 📧 [Email Support](mailto:naeem.ali@devopshound.com)
---
<div align="center">
  <sub>Built with ❤️ for the Kubernetes community</sub>
</div>


