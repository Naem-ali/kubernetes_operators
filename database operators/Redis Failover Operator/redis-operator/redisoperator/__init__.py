# redis-operator/redisoperator/__init__.py

__version__ = "0.1.0"
__all__ = [
    'operator',
    'failover',
    'backup',
    'config'
]

# Initialize package-level logging
import logging
from .config import OperatorConfig

# Set up basic logging configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Create package logger
logger = logging.getLogger(__name__)
logger.info(f"Initializing Redis Operator v{__version__}")

# Package initialization code can go here
def init():
    """Initialize operator components"""
    logger.info("Redis Operator package initialized")