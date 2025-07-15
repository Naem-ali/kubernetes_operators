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
