import { request, unwrapData } from './client';
import type {
  ApiEnvelope,
  OrderDetailsData,
  OrdersData,
} from '../types/api';

export async function getOrders(params: {
  page?: number;
  limit?: number;
  dateFrom?: string;
}) {
  const searchParams = new URLSearchParams({
    page: String(params.page ?? 1),
    limit: String(params.limit ?? 10),
  });

  if (params.dateFrom) {
    searchParams.set('date_from', params.dateFrom);
  }

  const payload = await request<ApiEnvelope<OrdersData>>(
    `/api/business/orders?${searchParams.toString()}`,
  );

  return unwrapData(payload);
}

export async function getOrderDetails(orderId: string | number) {
  const payload = await request<ApiEnvelope<OrderDetailsData>>(
    `/api/business/orders/${orderId}`,
  );

  return unwrapData(payload);
}

export async function updateOrderStatus(
  orderId: string | number,
  transitionPath: string,
) {
  await request(`/api/businesses/orders/${orderId}/status/${transitionPath}`, {
    method: 'PATCH',
    expectedStatus: 200,
  });

  return true;
}

export async function cancelOrder(orderId: string | number, status: number) {
  await request(`/api/businesses/orders/${orderId}/status/cancel`, {
    method: 'PATCH',
    expectedStatus: 200,
    body: JSON.stringify({ status }),
  });

  return true;
}

export async function updateOrderItemAmount(params: {
  orderId: string | number;
  itemRelationId: string | number;
  amount: number;
}) {
  await request(
    `/api/business/orders/${params.orderId}/items/${params.itemRelationId}`,
    {
      method: 'PATCH',
      expectedStatus: 200,
      body: JSON.stringify({ amount: params.amount }),
    },
  );

  return true;
}
