# redis-operator/redisoperator/sentinel.py
import redis
import logging
from typing import Tuple, List, Optional
from redis.exceptions import RedisError, ConnectionError, TimeoutError

logger = logging.getLogger(__name__)

class SentinelManager:
    """Manages Redis Sentinel operations for failover handling"""
    
    def __init__(self, name: str, namespace: str, sentinel_port: int = 26379):
        self.name = name
        self.namespace = namespace
        self.sentinel_port = sentinel_port
        self.sentinel_hosts = [
            f"{name}-sentinel-{i}.{name}-sentinel.{namespace}.svc.cluster.local"
            for i in range(3)  # Assuming 3 sentinels
        ]
        self.connection_timeout = 5
        self.socket_timeout = 10

    def get_sentinel_connection(self) -> redis.sentinel.Sentinel:
        """Create a Sentinel connection pool"""
        return redis.sentinel.Sentinel(
            [(host, self.sentinel_port) for host in self.sentinel_hosts],
            socket_timeout=self.socket_timeout,
            connection_timeout=self.connection_timeout
        )

    def get_master_info(self) -> Optional[Tuple[str, int]]:
        """Get current master node information"""
        try:
            sentinel = self.get_sentinel_connection()
            master_name = f"mymaster-{self.name}"
            return sentinel.discover_master(master_name)
        except (RedisError, ConnectionError, TimeoutError) as e:
            logger.error(f"Failed to get master info: {e}")
            return None

    def get_slaves_info(self) -> List[Tuple[str, int]]:
        """Get list of all slave nodes"""
        try:
            sentinel = self.get_sentinel_connection()
            master_name = f"mymaster-{self.name}"
            return sentinel.discover_slaves(master_name)
        except (RedisError, ConnectionError, TimeoutError) as e:
            logger.error(f"Failed to get slaves info: {e}")
            return []

    def check_sentinel_quorum(self) -> bool:
        """Verify if Sentinel has quorum"""
        try:
            sentinel = self.get_sentinel_connection()
            master_name = f"mymaster-{self.name}"
            
            # Check if majority of Sentinels agree
            sentinel_count = 0
            for host in self.sentinel_hosts:
                s = redis.StrictRedis(
                    host=host,
                    port=self.sentinel_port,
                    socket_timeout=self.socket_timeout
                )
                if s.ping():
                    sentinel_count += 1
            
            return sentinel_count >= (len(self.sentinel_hosts) // 2) + 1
        except Exception as e:
            logger.error(f"Quorum check failed: {e}")
            return False

    def force_failover(self) -> bool:
        """Force a failover if quorum exists"""
        if not self.check_sentinel_quorum():
            logger.error("Cannot failover - no sentinel quorum")
            return False

        try:
            sentinel = self.get_sentinel_connection()
            master_name = f"mymaster-{self.name}"
            sentinel.failover(master_name)
            logger.info(f"Failover initiated for {master_name}")
            return True
        except redis.sentinel.FailoverError as e:
            logger.error(f"Failover rejected: {e}")
            return False
        except Exception as e:
            logger.error(f"Failover failed: {e}")
            return False

    def get_sentinel_monitoring_info(self) -> dict:
        """Get detailed sentinel monitoring information"""
        try:
            master_name = f"mymaster-{self.name}"
            sentinel_info = {}
            
            for host in self.sentinel_hosts:
                s = redis.StrictRedis(
                    host=host,
                    port=self.sentinel_port,
                    socket_timeout=self.socket_timeout
                )
                info = s.sentinel(master_name)
                sentinel_info[host] = {
                    'master': info[0],
                    'slaves': info[1],
                    'sentinels': info[2]
                }
            
            return sentinel_info
        except Exception as e:
            logger.error(f"Failed to get sentinel monitoring info: {e}")
            return {}