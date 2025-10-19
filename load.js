import http from 'k6/http';
import { check, sleep } from 'k6';

// Load test configuration
export const options = {
  stages: [
    { duration: '30s', target: 20 },  // ramp up to 20 VUs (virtual users)
    { duration: '2m', target: 20 },   // stay at 20 VUs for 2 minutes
    { duration: '30s', target: 0 },   // ramp down
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],   // less than 1% of requests should fail
    http_req_duration: ['p(95)<500'], // 95% of requests < 500ms
  },
};

export default function () {
  const url = 'http://localhost:8080'; // or your ClusterIP/Ingress URL
  const res = http.get(url);

  check(res, {
    'status is 200': (r) => r.status === 200,
  });

  // Small sleep to simulate real-world usage
  sleep(0.1);
}
