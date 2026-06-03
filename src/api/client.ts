import type { ApiEnvelope } from '../types/api';

export const BASE_URL = 'https://njt25.naliv.kz';
export const AUTH_TOKEN_KEY = 'auth_token';

export class ApiError extends Error {
  status: number;
  payload: unknown;

  constructor(message: string, status: number, payload: unknown) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.payload = payload;
  }
}

type RequestOptions = RequestInit & {
  expectedStatus?: number;
};

export function getAuthToken() {
  return localStorage.getItem(AUTH_TOKEN_KEY);
}

export function setAuthToken(token: string) {
  localStorage.setItem(AUTH_TOKEN_KEY, token);
}

export function clearAuthToken() {
  localStorage.removeItem(AUTH_TOKEN_KEY);
}

export function getAuthHeaders(): HeadersInit {
  const token = getAuthToken();
  return {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token ?? ''}`,
  };
}

function buildUrl(path: string) {
  if (path.startsWith('http')) return path;
  return `${BASE_URL}${path}`;
}

async function parseResponse(response: Response) {
  const text = await response.text();
  if (!text) return null;

  try {
    return JSON.parse(text) as unknown;
  } catch {
    return text;
  }
}

function resolveErrorMessage(payload: unknown, fallback: string) {
  if (payload && typeof payload === 'object') {
    const envelope = payload as ApiEnvelope<unknown>;
    return (
      envelope.error?.message ||
      envelope.message ||
      fallback
    );
  }

  if (typeof payload === 'string' && payload.trim()) return payload;
  return fallback;
}

export async function request<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const { expectedStatus, headers, ...init } = options;
  const response = await fetch(buildUrl(path), {
    ...init,
    headers: {
      ...getAuthHeaders(),
      ...headers,
    },
  });

  const payload = await parseResponse(response);
  const statusMismatch =
    expectedStatus !== undefined && response.status !== expectedStatus;

  if (!response.ok || statusMismatch) {
    if (response.status === 401 || response.status === 403) {
      clearAuthToken();
      if (window.location.pathname !== '/login') {
        window.location.assign('/login');
      }
    }

    throw new ApiError(
      resolveErrorMessage(payload, `HTTP ${response.status}`),
      response.status,
      payload,
    );
  }

  return payload as T;
}

export function unwrapData<T>(payload: ApiEnvelope<T> | T): T {
  if (payload && typeof payload === 'object' && 'data' in payload) {
    return (payload as ApiEnvelope<T>).data as T;
  }

  return payload as T;
}
