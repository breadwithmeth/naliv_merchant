import { useQuery } from '@tanstack/react-query';
import { MapPin, RefreshCw, Truck } from 'lucide-react';
import { useMemo } from 'react';
import { useParams, useSearchParams } from 'react-router-dom';
import { ApiError } from '../api/client';
import { getCourierLocations } from '../api/couriers';
import { getOrderDetails } from '../api/orders';
import { Button } from '../components/Button';
import { CourierMap, type MapPoint } from '../components/CourierMap';
import { EmptyState } from '../components/EmptyState';
import { ErrorState } from '../components/ErrorState';
import { LoadingState } from '../components/LoadingState';
import { buildAddressText, formatDateTime, readCoordinates, safeText, toNumber } from '../lib/format';
import { queryKeys } from '../lib/query';
import type { CourierLocationPoint, CourierLocationsData } from '../types/api';

export function CourierLocationsPage() {
  const { orderId: routeOrderId } = useParams();
  const [searchParams] = useSearchParams();
  const orderId = routeOrderId ?? searchParams.get('order_id') ?? undefined;

  const locationsQuery = useQuery({
    queryKey: queryKeys.courierLocations(orderId),
    queryFn: () => getCourierLocations(orderId),
    refetchInterval: 15_000,
  });

  const orderQuery = useQuery({
    queryKey: queryKeys.order(orderId ?? ''),
    queryFn: () => getOrderDetails(orderId!),
    enabled: Boolean(orderId),
  });

  const courierLocations = useMemo(
    () => extractCourierLocations(locationsQuery.data),
    [locationsQuery.data],
  );

  const points = useMemo(() => {
    const courierPoints: MapPoint[] = courierLocations.map((location, index) => ({
      id: `courier-${location.courier_id ?? location.id ?? index}`,
      label: safeText(location.name ?? location.login ?? location.courier?.name, 'Курьер'),
      subtitle: location.updated_at
        ? `Обновлено: ${formatDateTime(location.updated_at)}`
        : undefined,
      lat: readLocationLat(location),
      lon: readLocationLon(location),
      kind: 'courier',
    }));

    const businessPoint = readCoordinates(orderQuery.data?.business?.coordinates);
    const deliveryPoint = readCoordinates(orderQuery.data?.order?.delivery_address?.coordinates);

    return [
      ...courierPoints,
      ...(businessPoint
        ? [
            {
              id: 'business',
              label: safeText(orderQuery.data?.business?.name, 'Магазин'),
              subtitle: safeText(orderQuery.data?.business?.address, ''),
              lat: businessPoint.lat,
              lon: businessPoint.lon,
              kind: 'business' as const,
            },
          ]
        : []),
      ...(deliveryPoint
        ? [
            {
              id: 'delivery',
              label: 'Адрес доставки',
              subtitle: buildAddressText(orderQuery.data?.order?.delivery_address),
              lat: deliveryPoint.lat,
              lon: deliveryPoint.lon,
              kind: 'delivery' as const,
            },
          ]
        : []),
    ];
  }, [courierLocations, orderQuery.data]);

  const isCourierNotAssigned =
    locationsQuery.error instanceof ApiError && locationsQuery.error.status === 409;

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-ink">
            {orderId ? `Локации по заказу #${orderId}` : 'Локации курьеров'}
          </h1>
          <p className="mt-1 text-sm text-muted">
            Карта обновляется каждые 15 секунд и подгоняется под все доступные точки.
          </p>
        </div>
        <Button
          variant="secondary"
          onClick={() => void locationsQuery.refetch()}
          icon={<RefreshCw className="h-4 w-4" />}
        >
          Обновить
        </Button>
      </div>

      {locationsQuery.isLoading ? <LoadingState label="Загрузка локаций" /> : null}

      {locationsQuery.isError && !isCourierNotAssigned ? (
        <ErrorState
          message={locationsQuery.error.message}
          onRetry={() => void locationsQuery.refetch()}
        />
      ) : null}

      {isCourierNotAssigned ? (
        <EmptyState
          title="Курьер не назначен"
          message={locationsQuery.error?.message || 'У заказа пока нет назначенного курьера.'}
          icon={<Truck className="h-6 w-6" />}
        />
      ) : null}

      {!locationsQuery.isLoading && !locationsQuery.isError && !points.length ? (
        <EmptyState
          title="Локаций нет"
          message="Backend вернул пустой список координат."
          icon={<MapPin className="h-6 w-6" />}
        />
      ) : null}

      {points.length ? (
        <div className="grid gap-4 xl:grid-cols-[1fr_360px]">
          <CourierMap points={points} />
          <section className="rounded-lg border border-line bg-white p-4 shadow-sm">
            <h2 className="text-base font-semibold text-ink">Список точек</h2>
            <div className="mt-3 space-y-2">
              {points.map((point) => (
                <div key={point.id} className="rounded-lg bg-slate-50 px-3 py-2 text-sm">
                  <p className="font-semibold text-ink">{point.label}</p>
                  {point.subtitle ? (
                    <p className="mt-1 text-muted">{point.subtitle}</p>
                  ) : null}
                  <p className="mt-1 text-xs text-muted">
                    {point.lat.toFixed(6)}, {point.lon.toFixed(6)}
                  </p>
                </div>
              ))}
            </div>
          </section>
        </div>
      ) : null}
    </div>
  );
}

function extractCourierLocations(data?: CourierLocationsData) {
  const candidates: CourierLocationPoint[] = [];

  if (Array.isArray(data)) {
    candidates.push(...data);
  } else if (data && typeof data === 'object') {
    if (Array.isArray(data.couriers)) candidates.push(...data.couriers);
    if (Array.isArray(data.locations)) candidates.push(...data.locations);
    if (Array.isArray(data.items)) candidates.push(...data.items);
    if (Array.isArray(data.data)) candidates.push(...data.data);
  }

  return candidates.filter((location) => {
    const lat = readLocationLat(location);
    const lon = readLocationLon(location);
    return Number.isFinite(lat) && Number.isFinite(lon);
  });
}

function readLocationLat(location: CourierLocationPoint) {
  return toNumber(location.location?.lat ?? location.latitude ?? location.lat, Number.NaN);
}

function readLocationLon(location: CourierLocationPoint) {
  return toNumber(
    location.location?.lon ??
      location.location?.lng ??
      location.longitude ??
      location.lon ??
      location.lng,
    Number.NaN,
  );
}
