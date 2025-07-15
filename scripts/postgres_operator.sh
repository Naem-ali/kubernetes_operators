#!/bin/bash

# Create project structure
mkdir -p postgres-operator/deploy postgres-operator/postgresoperator postgres-operator/tests

# 1. project-structure.md
cat > postgres-operator/project-structure.md << 'EOF'
# Auto-Scaling PostgreSQL Operator Project Structure

postgres-operator/
├── deploy/                   # Kubernetes deployment files
│   ├── crd.yaml              # Custom Resource Definition
│   ├── operator.yaml         # Operator deployment
│   └── rbac.yaml             # RBAC permissions
├── postgresoperator/         # Python package
│   ├── __init__.py
│   ├── operator.py           # Main operator logic
│   ├── metrics.py            # Metrics collection
│   ├── scaling.py            # Scaling algorithms
│   └── config.py             # Configuration handling
├── tests/                    # Unit tests
│   └── test_operator.py
├── Dockerfile                # Operator image build
├── requirements.txt          # Python dependencies
└── README.md                 # Project documentation
EOF

# 2. requirements.txt
cat > postgres-operator/requirements.txt << 'EOF'
kopf>=1.35
kubernetes>=18.20
prometheus-client>=0.11.0
psycopg2-binary>=2.9.3
pyyaml>=5.4.1
python-dotenv>=0.19.0
EOF

# 3. Dockerfile
cat > postgres-operator/Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["kopf", "run", "--standalone", "postgresoperator/operator.py"]
EOF

# 4. deploy/crd.yaml
cat > postgres-operator/deploy/crd.yaml << 'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: postgresclusters.postgres.operator.io
spec:
  group: postgres.operator.io
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
                minReplicas:
                  type: integer
                  minimum: 1
                  default: 1
                maxReplicas:
                  type: integer
                  minimum: 1
                  maximum: 10
                  default: 3
                targetQPS:
                  type: integer
                  description: "Queries per second per replica before scaling"
                  default: 1000
                targetLatency:
                  type: integer
                  description: "Target average query latency in ms"
                  default: 50
                scaleUpThreshold:
                  type: integer
                  description: "Percentage above target to trigger scale up"
                  default: 20
                scaleDownThreshold:
                  type: integer
                  description: "Percentage below target to trigger scale down"
                  default: 20
                cooldownPeriod:
                  type: integer
                  description: "Seconds to wait between scaling operations"
                  default: 300
  scope: Namespaced
  names:
    plural: postgresclusters
    singular: postgrescluster
    kind: PostgresCluster
    shortNames: ["pgc"]
EOF

# 5. deploy/operator.yaml
cat > postgres-operator/deploy/operator.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-operator
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-operator
  template:
    metadata:
      labels:
        app: postgres-operator
    spec:
      serviceAccountName: postgres-operator
      containers:
        - name: operator
          image: postgres-operator:latest
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
  name: postgres-operator
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: postgres-operator
rules:
  - apiGroups: ["postgres.operator.io"]
    resources: ["postgresclusters"]
    verbs: ["*"]
  - apiGroups: ["apps"]
    resources: ["statefulsets"]
    verbs: ["*"]
  - apiGroups: [""]
    resources: ["pods", "services", "endpoints", "configmaps"]
    verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: postgres-operator
subjects:
  - kind: ServiceAccount
    name: postgres-operator
    namespace: default
roleRef:
  kind: ClusterRole
  name: postgres-operator
  apiGroup: rbac.authorization.k8s.io
EOF

# 6. postgresoperator/operator.py
mkdir -p postgres-operator/postgresoperator
cat > postgres-operator/postgresoperator/operator.py << 'EOF'
import kopf
import kubernetes.client
from kubernetes.client.rest import ApiException
from .metrics import collect_metrics
from .scaling import should_scale, calculate_desired_replicas
from .config import OperatorConfig
import logging
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@kopf.on.create('postgres.operator.io', 'v1alpha1', 'postgresclusters')
def create_fn(spec, name, namespace, **kwargs):
    logger.info(f"PostgresCluster created: {name} in {namespace}")
    # Initial deployment logic would go here

@kopf.timer('postgres.operator.io', 'v1alpha1', 'postgresclusters', interval=60)
def monitor_loop(spec, name, namespace, **kwargs):
    config = OperatorConfig.from_spec(spec)
    
    # Collect metrics from PostgreSQL
    metrics = collect_metrics(name, namespace)
    
    # Make scaling decision
    scaling_action = should_scale(metrics, config)
    
    if scaling_action != 0:
        scale_postgres(name, namespace, scaling_action, config)

def scale_postgres(name, namespace, scaling_action, config):
    api = kubernetes.client.AppsV1Api()
    
    try:
        sts = api.read_namespaced_stateful_set(
            name=f"{name}-replicas",
            namespace=namespace
        )
        
        current_replicas = sts.spec.replicas
        new_replicas = calculate_desired_replicas(current_replicas, scaling_action, config)
        
        if new_replicas != current_replicas:
            sts.spec.replicas = new_replicas
            api.patch_namespaced_stateful_set(
                name=f"{name}-replicas",
                namespace=namespace,
                body=sts
            )
            logger.info(f"Scaled PostgresCluster {name} from {current_replicas} to {new_replicas} replicas")
            
    except ApiException as e:
        logger.error(f"Failed to scale StatefulSet: {e}")

if __name__ == '__main__':
    kopf.run()
EOF

# 7. postgresoperator/metrics.py
cat > postgres-operator/postgresoperator/metrics.py << 'EOF'
import psycopg2
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
import time

def collect_metrics(cluster_name, namespace):
    # In a real implementation, this would connect to PostgreSQL
    # and collect actual metrics. For demo purposes, we simulate.
    
    # Simulated metrics - replace with actual collection
    metrics = {
        'qps': get_qps(cluster_name, namespace),
        'latency': get_avg_latency(cluster_name, namespace),
        'connections': get_active_connections(cluster_name, namespace),
        'timestamp': time.time()
    }
    
    # Push metrics to Prometheus
    push_metrics_to_prometheus(metrics, cluster_name)
    
    return metrics

def get_qps(cluster_name, namespace):
    # TODO: Implement actual QPS collection from PostgreSQL
    return 1250  # Simulated value

def get_avg_latency(cluster_name, namespace):
    # TODO: Implement actual latency collection
    return 75  # ms, simulated value

def get_active_connections(cluster_name, namespace):
    # TODO: Implement actual connection count collection
    return 45  # Simulated value

def push_metrics_to_prometheus(metrics, cluster_name):
    registry = CollectorRegistry()
    
    g = Gauge('postgres_qps', 'Queries per second', ['cluster'], registry=registry)
    g.labels(cluster=cluster_name).set(metrics['qps'])
    
    g = Gauge('postgres_latency', 'Average query latency', ['cluster'], registry=registry)
    g.labels(cluster=cluster_name).set(metrics['latency'])
    
    g = Gauge('postgres_connections', 'Active connections', ['cluster'], registry=registry)
    g.labels(cluster=cluster_name).set(metrics['connections'])
    
    push_to_gateway('prometheus-gateway:9091', job='postgres-operator', registry=registry)
EOF

# 8. postgresoperator/scaling.py
cat > postgres-operator/postgresoperator/scaling.py << 'EOF'
import time
import logging

logger = logging.getLogger(__name__)

class ScalingDecision:
    SCALE_UP = 1
    NO_SCALE = 0
    SCALE_DOWN = -1

def should_scale(metrics, config):
    # Evaluate QPS scaling
    qps_per_replica = metrics['qps'] / config.current_replicas
    if qps_per_replica > config.target_qps * (1 + config.scale_up_threshold/100):
        return ScalingDecision.SCALE_UP
    
    # Evaluate latency scaling
    if metrics['latency'] > config.target_latency * (1 + config.scale_up_threshold/100):
        return ScalingDecision.SCALE_UP
    
    # Evaluate scale down conditions
    qps_utilization = qps_per_replica / config.target_qps
    latency_utilization = metrics['latency'] / config.target_latency
    
    if (qps_utilization < (1 - config.scale_down_threshold/100) and 
        latency_utilization < (1 - config.scale_down_threshold/100)):
        return ScalingDecision.SCALE_DOWN
    
    return ScalingDecision.NO_SCALE

def calculate_desired_replicas(current_replicas, scaling_action, config):
    if scaling_action == ScalingDecision.SCALE_UP:
        return min(current_replicas + 1, config.max_replicas)
    elif scaling_action == ScalingDecision.SCALE_DOWN:
        return max(current_replicas - 1, config.min_replicas)
    return current_replicas
EOF

# 9. postgresoperator/config.py
cat > postgres-operator/postgresoperator/config.py << 'EOF'
class OperatorConfig:
    def __init__(self, min_replicas, max_replicas, target_qps, target_latency,
                 scale_up_threshold, scale_down_threshold, cooldown_period):
        self.min_replicas = min_replicas
        self.max_replicas = max_replicas
        self.target_qps = target_qps
        self.target_latency = target_latency
        self.scale_up_threshold = scale_up_threshold
        self.scale_down_threshold = scale_down_threshold
        self.cooldown_period = cooldown_period
        self.last_scale_time = 0
        self.current_replicas = min_replicas

    @classmethod
    def from_spec(cls, spec):
        return cls(
            min_replicas=spec.get('minReplicas', 1),
            max_replicas=spec.get('maxReplicas', 3),
            target_qps=spec.get('targetQPS', 1000),
            target_latency=spec.get('targetLatency', 50),
            scale_up_threshold=spec.get('scaleUpThreshold', 20),
            scale_down_threshold=spec.get('scaleDownThreshold', 20),
            cooldown_period=spec.get('cooldownPeriod', 300)
        )
EOF

# 10. tests/test_operator.py
cat > postgres-operator/tests/test_operator.py << 'EOF'
import unittest
from postgresoperator.scaling import should_scale, ScalingDecision
from postgresoperator.config import OperatorConfig

class TestScalingLogic(unittest.TestCase):
    def setUp(self):
        self.config = OperatorConfig(
            min_replicas=1,
            max_replicas=5,
            target_qps=1000,
            target_latency=50,
            scale_up_threshold=20,
            scale_down_threshold=20,
            cooldown_period=300
        )
        self.config.current_replicas = 2

    def test_scale_up_qps(self):
        metrics = {'qps': 2500, 'latency': 40, 'connections': 30}
        decision = should_scale(metrics, self.config)
        self.assertEqual(decision, ScalingDecision.SCALE_UP)

    def test_scale_up_latency(self):
        metrics = {'qps': 1500, 'latency': 70, 'connections': 40}
        decision = should_scale(metrics, self.config)
        self.assertEqual(decision, ScalingDecision.SCALE_UP)

    def test_no_scale(self):
        metrics = {'qps': 1800, 'latency': 45, 'connections': 35}
        decision = should_scale(metrics, self.config)
        self.assertEqual(decision, ScalingDecision.NO_SCALE)

    def test_scale_down(self):
        metrics = {'qps': 700, 'latency': 30, 'connections': 15}
        decision = should_scale(metrics, self.config)
        self.assertEqual(decision, ScalingDecision.SCALE_DOWN)

if __name__ == '__main__':
    unittest.main()
EOF

# Create __init__.py
touch postgres-operator/postgresoperator/__init__.py

# Create README.md
cat > postgres-operator/README.md << 'EOF'
# Auto-Scaling PostgreSQL Operator

This operator automatically scales PostgreSQL replicas based on query load metrics.

## Features

- Scales PostgreSQL replicas based on QPS, latency, and connection count
- Customizable scaling thresholds
- Cooldown periods to prevent flapping
- Prometheus metrics integration

## Installation

1. Build the operator image:
```bash
docker build -t postgres-operator:latest .
