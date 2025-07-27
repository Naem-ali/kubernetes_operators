# 💾 Database Backup/Restore Operator

<div align="center">
  <img src="https://raw.githubusercontent.com/kubernetes/community/master/icons/svg/resources/unlisted/backup.svg" width="150">
  <br>
  <strong>Because losing data is scarier than Monday mornings!</strong>
  <br><br>
</div>

![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-326CE5?logo=kubernetes&style=for-the-badge)
![Go](https://img.shields.io/badge/Go-1.19+-00ADD8?logo=go&style=for-the-badge)
![License](https://img.shields.io/badge/License-Apache--2.0-blue?style=for-the-badge)

## 🎯 Supported Databases

<div align="center">
  <img src="https://raw.githubusercontent.com/postgres/postgres/master/doc/src/sgml/logos/postgresql-logo.png" width="100">
  <img src="https://raw.githubusercontent.com/mysql/mysql-server/8.0/router/src/http/static/icons/mysql.svg" width="100">
  <img src="https://raw.githubusercontent.com/mongodb/mongo/master/docs/leaf.svg" width="100">
</div>

## 🌟 Features

- 🗄️ **Multi-Database Support**
  - PostgreSQL (`pg_dump`/`pg_restore`)
  - MySQL (`mysqldump`)
  - MongoDB (`mongodump`/`mongorestore`)
  
- 📦 **Storage Options**
  - AWS S3 <img src="https://raw.githubusercontent.com/aws/aws-sdk-go-v2/main/logo.png" width="20">
  - MinIO <img src="https://min.io/resources/img/logo.svg" width="20">
  - Any S3-compatible storage

- 🔄 **Backup Features**
  - 📅 Scheduled backups (cron syntax)
  - 🗑️ Smart retention policies
  - 📊 Real-time status tracking
  - 🔐 End-to-end encryption

## 🏗️ Architecture

```mermaid
graph TD
    subgraph Kubernetes Cluster
        A[DatabaseBackup CR] -->|Creates| B(Backup Operator)
        B -->|Schedules| C[CronJob]
        C -->|Spawns| D[Backup Pod]
        
        subgraph Backup Process
            D -->|1. Connect| E[Database]
            D -->|2. Dump| F[Temp Storage]
            D -->|3. Compress| G[Archive]
            D -->|4. Encrypt| H[Secure Archive]
        end
        
        H -->|Upload| I[(S3/MinIO)]
        B -->|Updates| J[Status]
        
        subgraph Monitoring
            B -->|Metrics| K[Prometheus]
            K -->|Display| L[Grafana]
        end
    end

    style Kubernetes fill:#326CE5,stroke:#fff,stroke-width:2px
    style Backup Process fill:#00ADD8,stroke:#fff,stroke-width:2px
    style Monitoring fill:#E6522C,stroke:#fff,stroke-width:2px
```

## 🚀 Quick Start

### Prerequisites
- Kubernetes 1.20+ (because old clusters are like old backups - unreliable! 😉)
- `kubectl` configured
- S3/MinIO credentials (your data's VIP pass to the cloud)

### 1️⃣ Installation

```bash
# Deploy the operator (it's like hiring a very reliable robot)
kubectl apply -f deploy/crd.yaml
kubectl apply -f deploy/rbac.yaml
kubectl apply -f deploy/operator.yaml
```

### 2️⃣ Configuration

```yaml
apiVersion: backup.database.example.com/v1
kind: DatabaseBackup
metadata:
  name: prod-db-backup
spec:
  schedule: "0 2 * * *"  # 2 AM daily (when the bugs are sleeping 🐛)
  database:
    type: postgresql
    name: my-precious-data
  retention:
    days: 30
    copies: 5
```

## 📊 Monitoring Dashboard

<div align="center">
  <img src="https://grafana.com/api/dashboards/12345/images/8765" width="600" alt="Backup Dashboard">
</div>

## 🔧 Troubleshooting

| Issue | Solution | Panic Level |
|-------|----------|-------------|
| Backup Failed | Check credentials | 😰 |
| Storage Full | Clean old backups | 😱 |
| Slow Backup | Optimize DB | 🥱 |

## 🎯 Development

```bash
# Build it yourself (like LEGO, but for data)
make docker-build IMG=db-backup-operator:dev

# Deploy your creation
make deploy IMG=db-backup-operator:dev

# Test it (because YOLO is not a backup strategy)
make test
```

## 🧪 Testing Your Backups

Because "untested backup" is like "undefined behavior" - scary and unpredictable!

## 💭 Dad Jokes Corner

> Why did the database admin leave his wife?
> 
> He had too many commitment issues and couldn't guarantee atomicity! 

> What's a DBA's favorite band?
>
> The Backup Plan!

---
<div align="center">
  <sub>Built with 💾 by people who learned about backups the hard way</sub>
  <br>
  <sub>Remember: "To err is human, to backup divine!"</sub>
</div>
