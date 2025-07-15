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
