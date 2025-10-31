import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 100 },
    { duration: '2m', target: 100 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(99)<1000'],
  },
  userAgent: 'k6-loadtest-plaintext/1.0',
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

function correlationId() {
  return `cid-${Date.now()}-${__VU}-${__ITER}-${Math.floor(Math.random() * 1e9)}`;
}

export default function () {
  const res = http.get(`${BASE_URL}/plaintext`, {
    headers: {
      'X-Correlation-ID': correlationId(),
    },
  });

  check(res, {
    'status is 200': (r) => r.status === 200,
    'body is hello world': (r) => r.body === 'Hello, World!',
  });
}
