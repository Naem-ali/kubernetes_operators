import unittest
from postgresoperator.scaling import should_scale, ScalingDecision
from postgresoperator.config import OperatorConfig

class TestScalingLogic(unittest.TestCase):
    def setUp(self):
        self.config = OperatorConfig(
            min_replicas=1,
            max_replicas=5,
            target_qps=1000,
            target_latency=50,
            scale_up_threshold=20,
            scale_down_threshold=20,
            cooldown_period=300
        )
        self.config.current_replicas = 2

    def test_scale_up_qps(self):
        metrics = {'qps': 2500, 'latency': 40, 'connections': 30}
        decision = should_scale(metrics, self.config)
        self.assertEqual(decision, ScalingDecision.SCALE_UP)

    def test_scale_up_latency(self):
        metrics = {'qps': 1500, 'latency': 70, 'connections': 40}
        decision = should_scale(metrics, self.config)
        self.assertEqual(decision, ScalingDecision.SCALE_UP)

    def test_no_scale(self):
        metrics = {'qps': 1800, 'latency': 45, 'connections': 35}
        decision = should_scale(metrics, self.config)
        self.assertEqual(decision, ScalingDecision.NO_SCALE)

    def test_scale_down(self):
        metrics = {'qps': 700, 'latency': 30, 'connections': 15}
        decision = should_scale(metrics, self.config)
        self.assertEqual(decision, ScalingDecision.SCALE_DOWN)

if __name__ == '__main__':
    unittest.main()
