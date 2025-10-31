import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 100 },
    { duration: '2m', target: 100 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.02'],
    http_req_duration: ['p(99)<3000'],
  },
  userAgent: 'k6-loadtest-interaction/1.0',
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

const interactionTypes = ['CALL', 'EMAIL', 'MEETING', 'SUPPORT', 'PURCHASE'];

function correlationId() {
  return `cid-${Date.now()}-${__VU}-${__ITER}-${Math.floor(Math.random() * 1e9)}`;
}

function buildInteractionPayload() {
  const interactionType = interactionTypes[__ITER % interactionTypes.length];
  const customerId = 1 + ((__VU + __ITER) % 100);
  const note = [
    'Load test interaction for customer contact follow-up.',
    `Iteration ${__ITER} by VU ${__VU}.`,
    'Validating transactional path under concurrent load.',
  ].join(' ');

  return {
    customerId,
    body: JSON.stringify({
      customerId,
      note,
      type: interactionType,
    }),
  };
}

export default function () {
  const payload = buildInteractionPayload();
  const res = http.post(`${BASE_URL}/interaction`, payload.body, {
    headers: {
      'Content-Type': 'application/json',
      'X-Correlation-ID': correlationId(),
    },
  });

  check(res, {
    'status is 201': (r) => r.status === 201,
    'customer id matches': (r) => {
      try {
        return JSON.parse(r.body).customer_id === payload.customerId;
      } catch (e) {
        return false;
      }
    },
  });
}
