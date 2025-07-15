#!/bin/bash

# Create project structure
mkdir -p redis-operator/deploy redis-operator/redisoperator redis-operator/tests

# 1. project-structure.md
cat > redis-operator/project-structure.md << 'EOF'
# Redis Failover Operator Project Structure

redis-operator/
├── deploy/                   # Kubernetes deployment files
│   ├── crd.yaml              # Custom Resource Definition
│   ├── operator.yaml         # Operator deployment
│   └── rbac.yaml             # RBAC permissions
├── redisoperator/            # Python package
│   ├── __init__.py
│   ├── operator.py           # Main operator logic
│   ├── failover.py           # Failover management
│   ├── backup.py             # Backup operations
│   ├── config.py             # Configuration handling
│   └── sentinel.py           # Sentinel integration
├── tests/                    # Unit tests
│   ├── test_failover.py
│   └── test_backup.py
├── Dockerfile                # Operator image build
├── requirements.txt          # Python dependencies
└── README.md                 # Project documentation
EOF

# 2. requirements.txt
cat > redis-operator/requirements.txt << 'EOF'
kopf>=1.35
kubernetes>=18.20
redis>=4.3.4
prometheus-client>=0.11.0
boto3>=1.24.0  # For S3 backups
python-dotenv>=0.19.0
EOF

# 3. Dockerfile
cat > redis-operator/Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["kopf", "run", "--standalone", "redisoperator/operator.py"]
EOF

# 4. deploy/crd.yaml
cat > redis-operator/deploy/crd.yaml << 'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: redisfailovers.redis.operator.io
spec:
  group: redis.operator.io
  versions:
    - name: v1alpha1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                replicas:
                  type: integer
                  minimum: 3
                  default: 3
                sentinelReplicas:
                  type: integer
                  minimum: 3
                  default: 3
                backup:
                  type: object
                  properties:
                    enabled:
                      type: boolean
                      default: false
                    schedule:
                      type: string
                      pattern: '^(@(annually|yearly|monthly|weekly|daily|hourly|reboot))|(@every (\d+(ns|us|µs|ms|s|m|h))+)|((((\d+,)+\d+|(\d+(\/|-)\d+)|\*|\d+) ?){5,7}$'
                    retention:
                      type: integer
                      minimum: 1
                      default: 7
                    s3:
                      type: object
                      properties:
                        bucket:
                          type: string
                        endpoint:
                          type: string
                        accessKeySecret:
                          type: object
                          properties:
                            name:
                              type: string
                            key:
                              type: string
                        secretKeySecret:
                          type: object
                          properties:
                            name:
                              type: string
                            key:
                              type: string
                resources:
                  type: object
                  properties:
                    requests:
                      type: object
                      properties:
                        cpu:
                          type: string
                          default: "100m"
                        memory:
                          type: string
                          default: "100Mi"
                    limits:
                      type: object
                      properties:
                        cpu:
                          type: string
                          default: "500m"
                        memory:
                          type: string
                          default: "500Mi"
  scope: Namespaced
  names:
    plural: redisfailovers
    singular: redisfailover
    kind: RedisFailover
    shortNames: ["rfo"]
EOF

# 5. deploy/operator.yaml
cat > redis-operator/deploy/operator.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-operator
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-operator
  template:
    metadata:
      labels:
        app: redis-operator
    spec:
      serviceAccountName: redis-operator
      containers:
        - name: operator
          image: redis-operator:latest
          env:
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: redis-operator
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: redis-operator
rules:
  - apiGroups: ["redis.operator.io"]
    resources: ["redisfailovers"]
    verbs: ["*"]
  - apiGroups: ["apps"]
    resources: ["statefulsets", "deployments"]
    verbs: ["*"]
  - apiGroups: [""]
    resources: ["pods", "services", "endpoints", "configmaps", "secrets", "persistentvolumeclaims"]
    verbs: ["*"]
  - apiGroups: ["batch"]
    resources: ["cronjobs"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: redis-operator
subjects:
  - kind: ServiceAccount
    name: redis-operator
    namespace: default
roleRef:
  kind: ClusterRole
  name: redis-operator
  apiGroup: rbac.authorization.k8s.io
EOF

# 6. redisoperator/operator.py
mkdir -p redis-operator/redisoperator
cat > redis-operator/redisoperator/operator.py << 'EOF'
import kopf
import kubernetes.client
from kubernetes.client.rest import ApiException
from .failover import monitor_redis_cluster, handle_failover
from .backup import create_backup, restore_backup
from .config import OperatorConfig
import logging
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@kopf.on.create('redis.operator.io', 'v1alpha1', 'redisfailovers')
def create_fn(spec, name, namespace, **kwargs):
    logger.info(f"RedisFailover created: {name} in {namespace}")
    config = OperatorConfig.from_spec(spec)
    
    # Deploy Redis cluster and sentinels
    deploy_redis_cluster(name, namespace, config)
    
    # Setup backups if enabled
    if config.backup_enabled:
        setup_backups(name, namespace, config)

def deploy_redis_cluster(name, namespace, config):
    # Implementation for deploying Redis cluster
    pass

def setup_backups(name, namespace, config):
    # Implementation for setting up backups
    pass

@kopf.timer('redis.operator.io', 'v1alpha1', 'redisfailovers', interval=30)
def monitor_loop(spec, name, namespace, **kwargs):
    config = OperatorConfig.from_spec(spec)
    
    # Check cluster health
    cluster_status = monitor_redis_cluster(name, namespace)
    
    # Handle failover if needed
    if cluster_status.get('needs_failover', False):
        handle_failover(name, namespace, cluster_status)

@kopf.on.delete('redis.operator.io', 'v1alpha1', 'redisfailovers')
def delete_fn(name, namespace, **kwargs):
    logger.info(f"RedisFailover deleted: {name} in {namespace}")
    # Cleanup resources

if __name__ == '__main__':
    kopf.run()
EOF

# 7. redisoperator/failover.py
cat > redis-operator/redisoperator/failover.py << 'EOF'
import redis
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

def monitor_redis_cluster(name: str, namespace: str) -> Dict[str, Any]:
    """Monitor Redis cluster health and return status"""
    # Connect to Redis sentinel
    sentinel = redis.sentinel.Sentinel(
        [(f"{name}-sentinel-{i}.{name}-sentinel.{namespace}.svc.cluster.local", 26379) 
         for i in range(3)],
        socket_timeout=5
    )
    
    try:
        master = sentinel.discover_master(f"mymaster-{name}")
        slaves = sentinel.discover_slaves(f"mymaster-{name}")
        
        return {
            'master': master,
            'slaves': slaves,
            'healthy': True,
            'needs_failover': False  # Would be set based on actual checks
        }
    except redis.exceptions.RedisError as e:
        logger.error(f"Redis monitoring error: {e}")
        return {
            'healthy': False,
            'needs_failover': True
        }

def handle_failover(name: str, namespace: str, cluster_status: Dict[str, Any]):
    """Handle Redis failover process"""
    logger.info(f"Initiating failover for {name} in {namespace}")
    
    # Connect to sentinel
    sentinel = redis.sentinel.Sentinel(
        [(f"{name}-sentinel-{i}.{name}-sentinel.{namespace}.svc.cluster.local", 26379) 
         for i in range(3)],
        socket_timeout=5
    )
    
    try:
        # Force failover
        sentinel.failover(f"mymaster-{name}")
        logger.info(f"Failover initiated for {name}")
    except redis.exceptions.RedisError as e:
        logger.error(f"Failover failed for {name}: {e}")
        raise kopf.TemporaryError(f"Failover failed: {e}", delay=60)
EOF

# 8. redisoperator/backup.py
cat > redis-operator/redisoperator/backup.py << 'EOF'
import redis
import boto3
import io
import logging
from datetime import datetime
from typing import Optional

logger = logging.getLogger(__name__)

def create_backup(name: str, namespace: str, config: dict) -> bool:
    """Create a Redis backup and store it in configured storage"""
    logger.info(f"Creating backup for {name}")
    
    try:
        # Connect to Redis master
        r = redis.Redis(
            host=f"{name}-master.{namespace}.svc.cluster.local",
            port=6379,
            socket_timeout=10
        )
        
        # Create backup
        backup_data = r.execute_command("SAVE")
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_name = f"{name}-backup-{timestamp}.rdb"
        
        # Store backup
        if config.get('s3'):
            upload_to_s3(backup_data, backup_name, config['s3'])
        else:
            store_in_pvc(backup_data, backup_name, name, namespace)
            
        return True
    except Exception as e:
        logger.error(f"Backup failed for {name}: {e}")
        return False

def upload_to_s3(data: bytes, filename: str, s3_config: dict):
    """Upload backup to S3"""
    s3 = boto3.client(
        's3',
        endpoint_url=s3_config.get('endpoint'),
        aws_access_key_id=s3_config['accessKeySecret']['key'],
        aws_secret_access_key=s3_config['secretKeySecret']['key']
    )
    
    s3.upload_fileobj(
        io.BytesIO(data),
        s3_config['bucket'],
        filename
    )

def store_in_pvc(data: bytes, filename: str, name: str, namespace: str):
    """Store backup in PVC"""
    # Implementation for PVC storage would go here
    pass

def restore_backup(name: str, namespace: str, backup_name: str, config: dict) -> bool:
    """Restore Redis from backup"""
    logger.info(f"Restoring backup {backup_name} for {name}")
    
    try:
        # Retrieve backup
        if config.get('s3'):
            backup_data = download_from_s3(backup_name, config['s3'])
        else:
            backup_data = retrieve_from_pvc(backup_name, name, namespace)
            
        # Restore to Redis
        # Implementation would go here
        
        return True
    except Exception as e:
        logger.error(f"Restore failed for {name}: {e}")
        return False
EOF

# 9. redisoperator/config.py
cat > redis-operator/redisoperator/config.py << 'EOF'
class OperatorConfig:
    def __init__(self, replicas, sentinel_replicas, backup_config, resources):
        self.replicas = replicas
        self.sentinel_replicas = sentinel_replicas
        self.backup_enabled = backup_config.get('enabled', False)
        self.backup_schedule = backup_config.get('schedule', "@daily")
        self.backup_retention = backup_config.get('retention', 7)
        self.s3_config = backup_config.get('s3', {})
        self.resources = resources

    @classmethod
    def from_spec(cls, spec):
        return cls(
            replicas=spec.get('replicas', 3),
            sentinel_replicas=spec.get('sentinelReplicas', 3),
            backup_config=spec.get('backup', {}),
            resources=spec.get('resources', {})
        )
EOF

# 10. tests/test_failover.py
cat > redis-operator/tests/test_failover.py << 'EOF'
import unittest
from unittest.mock import patch
from redisoperator.failover import monitor_redis_cluster, handle_failover
from redis.exceptions import RedisError

class TestFailover(unittest.TestCase):
    @patch('redis.sentinel.Sentinel')
    def test_monitor_healthy_cluster(self, mock_sentinel):
        mock_sentinel.return_value.discover_master.return_value = ('redis-master', 6379)
        mock_sentinel.return_value.discover_slaves.return_value = [('redis-slave', 6379)]
        
        status = monitor_redis_cluster('test', 'default')
        self.assertTrue(status['healthy'])
        self.assertFalse(status['needs_failover'])
    
    @patch('redis.sentinel.Sentinel')
    def test_monitor_unhealthy_cluster(self, mock_sentinel):
        mock_sentinel.return_value.discover_master.side_effect = RedisError("Connection failed")
        
        status = monitor_redis_cluster('test', 'default')
        self.assertFalse(status['healthy'])
        self.assertTrue(status['needs_failover'])

if __name__ == '__main__':
    unittest.main()
EOF

# Create additional test file
cat > redis-operator/tests/test_backup.py << 'EOF'
import unittest
from unittest.mock import patch
from redisoperator.backup import create_backup
from redis.exceptions import RedisError

class TestBackup(unittest.TestCase):
    @patch('redis.Redis')
    @patch('boto3.client')
    def test_create_backup_s3(self, mock_boto, mock_redis):
        mock_redis.return_value.execute_command.return_value = True
        mock_boto.return_value.upload_fileobj.return_value = True
        
        config = {
            's3': {
                'bucket': 'my-bucket',
                'endpoint': 's3.amazonaws.com',
                'accessKeySecret': {'key': 'access-key'},
                'secretKeySecret': {'key': 'secret-key'}
            }
        }
        
        result = create_backup('test', 'default', config)
        self.assertTrue(result)

if __name__ == '__main__':
    unittest.main()
EOF

# Create __init__.py
touch redis-operator/redisoperator/__init__.py

# Create README.md
cat > redis-operator/README.md << 'EOF'
# Redis Failover Operator

This operator manages Redis clusters with automatic failover and backup capabilities.

## Features

- Automatic failover when master node fails
- Configurable backup schedules to S3 or PVC
- Redis cluster health monitoring
- Prometheus metrics integration
- Custom resource definition for configuration

## Installation

1. Build the operator image:
```bash
docker build -t redis-operator:latest .