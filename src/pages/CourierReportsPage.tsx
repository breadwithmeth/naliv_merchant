import { useQuery } from '@tanstack/react-query';
import { CalendarDays, RefreshCw } from 'lucide-react';
import { useMemo, useState } from 'react';
import { getCourierReports } from '../api/couriers';
import { Button } from '../components/Button';
import { EmptyState } from '../components/EmptyState';
import { ErrorState } from '../components/ErrorState';
import { LoadingState } from '../components/LoadingState';
import { MoneyValue } from '../components/MoneyValue';
import { formatDateForApi, formatDateInput, safeText, toNumber } from '../lib/format';
import { queryKeys } from '../lib/query';
import type { CourierReportData, PaymentTypeSummary } from '../types/api';

type CourierBucket = {
  courierId: string;
  name: string;
  orders: number;
  deliveryRevenue: number;
  totalOrderSum: number;
  orderSumWithoutDelivery: number;
  paymentTypes: PaymentTypeSummary[];
};

export function CourierReportsPage() {
  const todayRange = makeDayRange(new Date());
  const [startDate, setStartDate] = useState(todayRange.start);
  const [endDate, setEndDate] = useState(todayRange.end);

  const startApi = formatDateForApi(startDate);
  const endApi = formatDateForApi(endDate);

  const reportQuery = useQuery({
    queryKey: queryKeys.courierReports(startApi, endApi),
    queryFn: () => getCourierReports({ startDate: startApi, endDate: endApi }),
  });

  const grouped = useMemo(() => groupByCourier(reportQuery.data), [reportQuery.data]);
  const summary = makeSummary(reportQuery.data, grouped);

  const applyPreset = (preset: 'today' | 'yesterday') => {
    const base = new Date();
    if (preset === 'yesterday') base.setDate(base.getDate() - 1);
    const range = makeDayRange(base);
    setStartDate(range.start);
    setEndDate(range.end);
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-ink">Отчет по курьерам</h1>
          <p className="mt-1 text-sm text-muted">
            Период, суммы доставки, заказы и разрез по типам оплаты.
          </p>
        </div>
        <Button
          variant="secondary"
          onClick={() => void reportQuery.refetch()}
          icon={<RefreshCw className="h-4 w-4" />}
        >
          Обновить
        </Button>
      </div>

      <section className="rounded-lg border border-line bg-white p-4 shadow-sm">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-end">
          <div className="flex gap-2">
            <Button variant="secondary" onClick={() => applyPreset('today')}>
              Сегодня
            </Button>
            <Button variant="secondary" onClick={() => applyPreset('yesterday')}>
              Вчера
            </Button>
          </div>
          <DateField
            label="Начало"
            value={startDate}
            onChange={(date) => setStartDate(startOfDay(date))}
          />
          <DateField
            label="Конец"
            value={endDate}
            onChange={(date) => setEndDate(endOfDay(date))}
          />
        </div>
      </section>

      {reportQuery.isLoading ? <LoadingState label="Загрузка отчета" /> : null}

      {reportQuery.isError ? (
        <ErrorState
          message={reportQuery.error.message}
          onRetry={() => void reportQuery.refetch()}
        />
      ) : null}

      {!reportQuery.isLoading && !reportQuery.isError ? (
        <>
          <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <SummaryTile label="Доставлено" value={summary.totalDeliveredOrders} />
            <SummaryTile label="С курьером" value={summary.ordersWithCourier} />
            <SummaryTile label="Без курьера" value={summary.ordersWithoutCourier} />
            <SummaryTile
              label="Сумма доставки"
              value={<MoneyValue value={summary.totalDeliveryRevenue} />}
            />
          </section>

          {grouped.length ? (
            <section className="overflow-hidden rounded-lg border border-line bg-white shadow-sm">
              <div className="border-b border-line px-4 py-3">
                <h2 className="text-base font-semibold text-ink">Группировка по курьерам</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-line text-sm">
                  <thead className="bg-slate-50 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                    <tr>
                      <th className="px-4 py-3">Курьер</th>
                      <th className="px-4 py-3">Заказы</th>
                      <th className="px-4 py-3">Доставка</th>
                      <th className="px-4 py-3">Сумма заказов</th>
                      <th className="px-4 py-3">Без доставки</th>
                      <th className="px-4 py-3">Типы оплаты</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-line">
                    {grouped.map((courier) => (
                      <tr key={courier.courierId} className="align-top">
                        <td className="px-4 py-3 font-semibold text-ink">{courier.name}</td>
                        <td className="px-4 py-3">{courier.orders}</td>
                        <td className="px-4 py-3"><MoneyValue value={courier.deliveryRevenue} /></td>
                        <td className="px-4 py-3"><MoneyValue value={courier.totalOrderSum} /></td>
                        <td className="px-4 py-3">
                          <MoneyValue value={courier.orderSumWithoutDelivery} />
                        </td>
                        <td className="min-w-72 px-4 py-3">
                          <div className="flex flex-wrap gap-2">
                            {courier.paymentTypes.map((type) => (
                              <span
                                key={`${courier.courierId}-${type.name}`}
                                className="rounded-lg bg-slate-100 px-2 py-1 text-xs text-slate-700"
                              >
                                {safeText(type.name)}: {toNumber(type.orders)} /{' '}
                                <MoneyValue
                                  value={
                                    type.totalOrderSum ??
                                    type.total_order_sum ??
                                    type.total_amount ??
                                    type.amount
                                  }
                                />
                              </span>
                            ))}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </section>
          ) : (
            <EmptyState
              title="Нет данных за период"
              message="Выберите другой период или обновите отчет."
              icon={<CalendarDays className="h-6 w-6" />}
            />
          )}
        </>
      ) : null}
    </div>
  );
}

function DateField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: Date;
  onChange: (date: Date) => void;
}) {
  return (
    <label className="block text-sm font-semibold text-ink">
      {label}
      <input
        type="date"
        value={formatDateInput(value)}
        onChange={(event) => onChange(new Date(`${event.target.value}T12:00:00`))}
        className="mt-2 block min-h-10 rounded-lg border border-line px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
      />
    </label>
  );
}

function SummaryTile({ label, value }: { label: string; value: number | JSX.Element }) {
  return (
    <div className="rounded-lg border border-line bg-white p-4 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-wide text-muted">{label}</p>
      <p className="mt-2 text-2xl font-bold text-ink">{value}</p>
    </div>
  );
}

function groupByCourier(data?: CourierReportData): CourierBucket[] {
  const orders = Array.isArray(data?.orders) ? data.orders : [];
  const buckets = new Map<string, CourierBucket & { paymentMap: Map<string, PaymentTypeSummary> }>();

  for (const order of orders) {
    const courier = order.courier;
    const courierId = courier?.courier_id ?? courier?.id ?? -1;
    const key = String(courierId);
    const deliveryRevenue = toNumber(order.delivery_price);
    const totalOrderSum = toNumber(order.total_sum);
    const orderSumWithoutDelivery = Math.max(totalOrderSum - deliveryRevenue, 0);
    const paymentName = safeText(order.payment_type?.name, 'Не указан');

    const bucket =
      buckets.get(key) ??
      {
        courierId: key,
        name: courier ? safeText(courier.name ?? courier.login, 'Курьер') : 'Без курьера',
        orders: 0,
        deliveryRevenue: 0,
        totalOrderSum: 0,
        orderSumWithoutDelivery: 0,
        paymentTypes: [],
        paymentMap: new Map<string, PaymentTypeSummary>(),
      };

    bucket.orders += 1;
    bucket.deliveryRevenue += deliveryRevenue;
    bucket.totalOrderSum += totalOrderSum;
    bucket.orderSumWithoutDelivery += orderSumWithoutDelivery;

    const payment = bucket.paymentMap.get(paymentName) ?? {
      name: paymentName,
      orders: 0,
      deliveryRevenue: 0,
      totalOrderSum: 0,
      orderSumWithoutDelivery: 0,
    };

    payment.orders = toNumber(payment.orders) + 1;
    payment.deliveryRevenue = toNumber(payment.deliveryRevenue) + deliveryRevenue;
    payment.totalOrderSum = toNumber(payment.totalOrderSum) + totalOrderSum;
    payment.orderSumWithoutDelivery =
      toNumber(payment.orderSumWithoutDelivery) + orderSumWithoutDelivery;
    bucket.paymentMap.set(paymentName, payment);
    buckets.set(key, bucket);
  }

  return Array.from(buckets.values())
    .map(({ paymentMap, ...bucket }) => ({
      ...bucket,
      paymentTypes: Array.from(paymentMap.values()),
    }))
    .sort((a, b) => b.deliveryRevenue - a.deliveryRevenue);
}

function makeSummary(data: CourierReportData | undefined, grouped: CourierBucket[]) {
  const summary = data?.summary;
  const totalOrders = grouped.reduce((sum, courier) => sum + courier.orders, 0);
  const withoutCourier = grouped.find((courier) => courier.courierId === '-1')?.orders ?? 0;

  return {
    totalDeliveredOrders: toNumber(summary?.total_delivered_orders, totalOrders),
    ordersWithCourier: toNumber(summary?.orders_with_courier, totalOrders - withoutCourier),
    ordersWithoutCourier: toNumber(summary?.orders_without_courier, withoutCourier),
    totalDeliveryRevenue: toNumber(
      summary?.total_delivery_revenue,
      grouped.reduce((sum, courier) => sum + courier.deliveryRevenue, 0),
    ),
  };
}

function startOfDay(date: Date) {
  const result = new Date(date);
  result.setHours(0, 0, 0, 0);
  return result;
}

function endOfDay(date: Date) {
  const result = new Date(date);
  result.setHours(23, 59, 59, 999);
  return result;
}

function makeDayRange(date: Date) {
  return {
    start: startOfDay(date),
    end: endOfDay(date),
  };
}
