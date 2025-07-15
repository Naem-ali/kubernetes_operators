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
