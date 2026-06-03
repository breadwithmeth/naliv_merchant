export const queryKeys = {
  orders: (page: number) => ['orders', page] as const,
  order: (orderId: string | number) => ['order', String(orderId)] as const,
  courierLocations: (orderId?: string | number) =>
    ['courier-locations', orderId ? String(orderId) : 'all'] as const,
  courierReports: (start: string, end: string) =>
    ['courier-reports', start, end] as const,
  courierShifts: (courierId?: string | number) =>
    ['courier-shifts', courierId ? String(courierId) : 'all'] as const,
  courierShift: (shiftId: string | number, courierId: string | number) =>
    ['courier-shift', String(shiftId), String(courierId)] as const,
};
