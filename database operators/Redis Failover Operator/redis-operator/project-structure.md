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
