import type { Coordinates, DeliveryAddress, Nullable } from '../types/api';

export function toNumber(value: unknown, fallback = 0) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const parsed = Number(value.replace(',', '.'));
    if (Number.isFinite(parsed)) return parsed;
  }
  return fallback;
}

export function toInt(value: unknown, fallback = 0) {
  return Math.trunc(toNumber(value, fallback));
}

export function formatMoney(value: unknown) {
  const number = toNumber(value);
  return new Intl.NumberFormat('ru-KZ', {
    style: 'currency',
    currency: 'KZT',
    maximumFractionDigits: 0,
  }).format(number);
}

export function formatDateTime(value: Nullable<string | Date>) {
  if (!value) return 'Не указано';
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return 'Не указано';

  return new Intl.DateTimeFormat('ru-RU', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}

export function formatDateForApi(date: Date) {
  const two = (value: number) => String(value).padStart(2, '0');
  const three = (value: number) => String(value).padStart(3, '0');
  const offset = -date.getTimezoneOffset();
  const sign = offset >= 0 ? '+' : '-';
  const absolute = Math.abs(offset);
  const hours = two(Math.floor(absolute / 60));
  const minutes = two(absolute % 60);

  return `${date.getFullYear()}-${two(date.getMonth() + 1)}-${two(date.getDate())}T${two(
    date.getHours(),
  )}:${two(date.getMinutes())}:${two(date.getSeconds())}.${three(
    date.getMilliseconds(),
  )}${sign}${hours}:${minutes}`;
}

export function formatDateInput(date: Date) {
  const two = (value: number) => String(value).padStart(2, '0');
  return `${date.getFullYear()}-${two(date.getMonth() + 1)}-${two(date.getDate())}`;
}

export function buildAddressText(address?: DeliveryAddress | string | null) {
  if (!address) return 'Адрес не указан';
  if (typeof address === 'string') return address;

  const base = address.address || address.name || 'Адрес не указан';
  const details = address.details;
  const parts = [
    details?.apartment ? `кв. ${details.apartment}` : null,
    details?.entrance ? `подъезд ${details.entrance}` : null,
    details?.floor ? `этаж ${details.floor}` : null,
  ].filter(Boolean);

  return parts.length ? `${base} (${parts.join(', ')})` : base;
}

export function readCoordinates(coordinates?: Coordinates | null) {
  if (!coordinates) return null;
  const lat = toNumber(coordinates.lat ?? coordinates.latitude, Number.NaN);
  const lon = toNumber(
    coordinates.lon ?? coordinates.lng ?? coordinates.longitude,
    Number.NaN,
  );

  if (!Number.isFinite(lat) || !Number.isFinite(lon)) return null;
  if (lat === 0 && lon === 0) return null;
  return { lat, lon };
}

export function safeText(value: unknown, fallback = 'Не указано') {
  if (typeof value === 'string' && value.trim()) return value.trim();
  if (typeof value === 'number') return String(value);
  return fallback;
}
