import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

export let errorRate = new Rate('errores');
export let duracionFrio = new Trend('duracion_frio');

export const options = {
  vus: 1,
  iterations: 1,
  thresholds: {
    http_req_failed: [{ threshold: 'rate<1', abortOnFail: false }],
  },
  summaryTrendStats: ['avg', 'med', 'min', 'max', 'p(50)', 'p(90)', 'p(95)', 'p(99)'],
};

const BASE_URL = __ENV.BASE_URL || 'https://sgroas-backend.onrender.com';

export function setup() {
  const loginPayload = JSON.stringify({
    email: 'admin@sgroas.com',
    password: 'admin123',
  });

  const res = http.post(`${BASE_URL}/api/auth/login`, loginPayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  const cookies = res.cookies;
  let token = null;

  if (cookies.access_token && cookies.access_token.length > 0) {
    token = cookies.access_token[0].value;
  }

  if (!token) {
    const body = res.json();
    token = body.accessToken;
  }

  if (!token) {
    throw new Error('No se pudo obtener el token de autenticacion');
  }

  return { token };
}

export default function (data) {
  const res = http.get(`${BASE_URL}/api/conductores`, {
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${data.token}`,
    },
  });

  duracionFrio.add(res.timings.duration);

  const exitoso = check(res, {
    'status es 200': (r) => r.status === 200,
  });

  errorRate.add(!exitoso);

  sleep(1);
}