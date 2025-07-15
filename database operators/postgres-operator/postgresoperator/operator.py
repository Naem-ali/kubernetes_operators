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
