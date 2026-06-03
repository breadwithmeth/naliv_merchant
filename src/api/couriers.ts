import { request, unwrapData } from './client';
import type {
  ApiEnvelope,
  CourierLocationsData,
  CourierReportData,
  CourierShift,
} from '../types/api';

export async function getCourierLocations(orderId?: string | number) {
  const params = new URLSearchParams();
  if (orderId) params.set('order_id', String(orderId));

  const suffix = params.toString() ? `?${params.toString()}` : '';
  const payload = await request<ApiEnvelope<CourierLocationsData>>(
    `/api/businesses/couriers/locations${suffix}`,
  );

  return unwrapData(payload);
}

export async function getCourierReports(params: {
  startDate: string;
  endDate: string;
}) {
  const searchParams = new URLSearchParams({
    start_date: params.startDate,
    end_date: params.endDate,
  });

  const payload = await request<ApiEnvelope<CourierReportData>>(
    `/api/businesses/reports/couriers?${searchParams.toString()}`,
  );

  return unwrapData(payload);
}

export async function getCourierShifts(courierId?: string | number) {
  const params = new URLSearchParams();
  if (courierId) params.set('courier_id', String(courierId));

  const suffix = params.toString() ? `?${params.toString()}` : '';
  const payload = await request<ApiEnvelope<CourierShift[] | CourierShift>>(
    `/api/businesses/reports/courier-shifts${suffix}`,
  );

  const data = unwrapData(payload);
  if (Array.isArray(data)) return data;

  if (data && typeof data === 'object') {
    const maybeItems = (data as { shifts?: CourierShift[]; items?: CourierShift[] })
      .shifts ?? (data as { items?: CourierShift[] }).items;
    return maybeItems ?? [];
  }

  return [];
}

export async function getCourierShiftDetail(params: {
  shiftId: string | number;
  courierId: string | number;
}) {
  const searchParams = new URLSearchParams({
    courier_id: String(params.courierId),
  });

  const payload = await request<ApiEnvelope<CourierShift>>(
    `/api/businesses/reports/courier-shifts/${params.shiftId}?${searchParams.toString()}`,
  );

  return unwrapData(payload);
}
