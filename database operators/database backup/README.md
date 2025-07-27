# Database Backup/Restore Operator

![Kubernetes](https://img.shields.io/badge/Kubernetes-1.20+-326CE5?logo=kubernetes)
![Go](https://img.shields.io/badge/Go-1.19+-00ADD8?logo=go)
![License](https://img.shields.io/badge/License-Apache--2.0-blue)

A Kubernetes operator that automates scheduled backups for multiple database types (PostgreSQL, MySQL, MongoDB) to S3-compatible storage.

## Features

- **Multi-Database Support**
  - PostgreSQL (pg_dump/pg_restore)
  - MySQL (mysqldump)
  - MongoDB (mongodump/mongorestore)
  
- **Storage Backends**
  - AWS S3
  - MinIO
  - Any S3-compatible storage

- **Backup Management**
  - Scheduled backups (cron syntax)
  - Configurable retention policies
  - Backup status tracking
  - Encryption support

- **Restoration**
  - Point-in-time recovery
  - Cross-namespace restore
  - Dry-run validation

## Architecture

```mermaid
graph TD
    A[DatabaseBackup CR] --> B(Operator)
    B --> C[CronJob]
    C --> D[Backup Pod]
    D -->|Upload| E[(S3/MinIO)]
    B --> F[Status Updates]
    
Installation
Prerequisites
Kubernetes 1.20+

kubectl configured

S3/MinIO bucket credentials

1. Install CRD and Operator
kubectl apply -f deploy/crd.yaml
kubectl apply -f deploy/rbac.yaml
kubectl apply -f deploy/operator.yaml

2. Verify Installation
kubectl get pods -n db-backup-system
Usage

1. Create Database Credentials Secret
kubectl create secret generic postgres-creds \
  --from-literal=DB_USER=admin \
  --from-literal=DB_PASSWORD=secret \
  --from-literal=DB_HOST=postgres.default.svc \
  --from-literal=DB_NAME=mydb

2. Create S3 Credentials Secret
kubectl create secret generic s3-creds \
  --from-literal=AWS_ACCESS_KEY_ID=key \
  --from-literal=AWS_SECRET_ACCESS_KEY=secret

3. Create Backup Configuration (examples/postgres-backup.yaml)

Apply the configuration:
kubectl apply -f examples/postgres-backup.yaml

Monitoring

View backup status:
kubectl get databasebackups
kubectl describe databasebackup postgres-prod-backup

Check backup jobs:
kubectl get cronjobs
kubectl get pods -l job-name=<backup-job>

Restoring Data
1. Create Restore CR (examples/postgres-restore.yaml)

Trigger Restore
kubectl apply -f examples/postgres-restore.yaml

Development

Build Locally
make docker-build IMG=db-backup-operator:dev

Deploy to Cluster
make deploy IMG=db-backup-operator:dev

Run Tests
make test

Uninstallation

kubectl delete databasebackups --all
kubectl delete -f deploy/operator.yaml
kubectl delete -f deploy/crd.yaml
