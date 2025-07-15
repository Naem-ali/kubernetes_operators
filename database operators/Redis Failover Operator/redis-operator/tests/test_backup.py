import unittest
from unittest.mock import patch
from redisoperator.backup import create_backup
from redis.exceptions import RedisError

class TestBackup(unittest.TestCase):
    @patch('redis.Redis')
    @patch('boto3.client')
    def test_create_backup_s3(self, mock_boto, mock_redis):
        mock_redis.return_value.execute_command.return_value = True
        mock_boto.return_value.upload_fileobj.return_value = True
        
        config = {
            's3': {
                'bucket': 'my-bucket',
                'endpoint': 's3.amazonaws.com',
                'accessKeySecret': {'key': 'access-key'},
                'secretKeySecret': {'key': 'secret-key'}
            }
        }
        
        result = create_backup('test', 'default', config)
        self.assertTrue(result)

if __name__ == '__main__':
    unittest.main()

