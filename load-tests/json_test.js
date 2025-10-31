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
    http_req_duration: ['p(99)<1500'],
  },
  userAgent: 'k6-loadtest-json/1.0',
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

const largePayload = JSON.stringify({
  customerId: 12345,
  personalInfo: {
    firstName: 'John',
    lastName: 'Smith',
    middleName: 'Robert',
    title: 'Mr.',
    dateOfBirth: '1985-06-15',
    gender: 'M',
    ssn: '123-45-6789',
    maritalStatus: 'Married',
  },
  contactInfo: {
    primaryEmail: 'john.smith@example.com',
    secondaryEmail: 'john.smith.work@example.com',
    phoneNumber: '+1-555-123-4567',
    mobileNumber: '+1-555-987-6543',
    workPhone: '+1-555-555-1234',
  },
  address: {
    street: '123 Main St',
    street2: 'Apt 4B',
    city: 'New York',
    state: 'NY',
    zipCode: '10001',
    country: 'USA',
    addressType: 'Home',
  },
  billingAddress: {
    street: '456 Business Ave',
    street2: 'Suite 200',
    city: 'New York',
    state: 'NY',
    zipCode: '10002',
    country: 'USA',
    addressType: 'Billing',
  },
  preferences: {
    language: 'en',
    timezone: 'America/New_York',
    currency: 'USD',
    marketingConsent: true,
    emailConsent: true,
    smsConsent: false,
  },
  membership: {
    tier: 'Premium',
    joinDate: '2020-01-15',
    expiryDate: '2025-01-15',
    autoRenew: true,
    points: 15000,
    status: 'Active',
  },
  financial: {
    creditScore: 750,
    annualIncome: 120000,
    employmentStatus: 'Employed',
    employer: 'Tech Corp',
    jobTitle: 'Senior Engineer',
  },
  interactions: [
    {
      id: 1,
      type: 'Email',
      date: '2024-01-10T10:30:00Z',
      subject: 'Monthly Newsletter',
      status: 'Delivered',
    },
    {
      id: 2,
      type: 'Call',
      date: '2024-01-08T14:20:00Z',
      duration: 300,
      agent: 'Agent Smith',
      status: 'Completed',
    },
    {
      id: 3,
      type: 'Purchase',
      date: '2024-01-05T09:15:00Z',
      amount: 299.99,
      product: 'Premium Subscription',
      status: 'Completed',
    },
  ],
  products: [
    {
      id: 'PROD001',
      name: 'Premium Support',
      category: 'Service',
      price: 99.99,
      active: true,
    },
    {
      id: 'PROD002',
      name: 'Cloud Storage',
      category: 'Digital',
      price: 19.99,
      active: true,
    },
  ],
  metadata: {
    createdAt: '2020-01-15T00:00:00Z',
    updatedAt: '2024-01-10T15:30:00Z',
    lastLogin: '2024-01-10T08:45:00Z',
    createdBy: 'system',
    updatedBy: 'agent_john',
    version: 3,
  },
  customFields: {
    referralSource: 'web',
    campaign: 'summer2023',
    preferredContactMethod: 'email',
    vipStatus: 'gold',
    riskScore: 0.15,
    lifetimeValue: 15000.0,
  },
});

function correlationId() {
  return `cid-${Date.now()}-${__VU}-${__ITER}-${Math.floor(Math.random() * 1e9)}`;
}

export default function () {
  const res = http.post(`${BASE_URL}/json`, largePayload, {
    headers: {
      'Content-Type': 'application/json',
      'X-Correlation-ID': correlationId(),
    },
  });

  check(res, {
    'status is 200': (r) => r.status === 200,
    'status field ok': (r) => {
      try {
        return JSON.parse(r.body).status === 'ok';
      } catch (e) {
        return false;
      }
    },
  });
}
