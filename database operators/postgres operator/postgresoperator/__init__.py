# postgres-operator/postgresoperator/__init__.py
"""
PostgreSQL Auto-Scaling Operator

A Kubernetes operator that automatically scales PostgreSQL replicas based on query load metrics.
"""

__version__ = "0.1.0"
__all__ = [
    'operator',
    'metrics',
    'scaling',
    'config'
]

import logging
from typing import Optional

# Package-level logger configuration
_logger = logging.getLogger(__name__)
_logger.addHandler(logging.NullHandler())

class OperatorError(Exception):
    """Base exception class for operator-specific errors"""
    pass

class ConfigurationError(OperatorError):
    """Raised when invalid configuration is detected"""
    pass

class MetricsCollectionError(OperatorError):
    """Raised when metrics collection fails"""
    pass

def initialize_logging(level: int = logging.INFO) -> None:
    """
    Initialize package logging configuration
    
    Args:
        level: Logging level (default: logging.INFO)
    """
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[logging.StreamHandler()]
    )
    _logger.info(f"PostgreSQL Operator v{__version__} initialized")

def get_version() -> str:
    """Return the current package version"""
    return __version__

# Initialize logging with default settings when package is imported
initialize_logging()

# Package-level variables
_operator_instance: Optional['operator.PostgresOperator'] = None  # noqa: F821