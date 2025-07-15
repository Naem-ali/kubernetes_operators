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
