import { useQuery } from '@tanstack/react-query';
import { AlertTriangle, RefreshCw } from 'lucide-react';
import { useParams, useSearchParams } from 'react-router-dom';
import { getCourierShiftDetail } from '../api/couriers';
import { Button } from '../components/Button';
import { DateTimeValue } from '../components/DateTimeValue';
import { EmptyState } from '../components/EmptyState';
import { ErrorState } from '../components/ErrorState';
import { LoadingState } from '../components/LoadingState';
import { MoneyValue } from '../components/MoneyValue';
import { StatusBadge } from '../components/StatusBadge';
import { buildAddressText, safeText, toInt, toNumber } from '../lib/format';
import { queryKeys } from '../lib/query';
import type { CourierReportOrder, PaymentTypeSummary } from '../types/api';

export function CourierShiftDetailPage() {
  const { shiftId } = useParams();
  const [searchParams] = useSearchParams();
  const courierId = searchParams.get('courier_id') ?? '';

  const shiftQuery = useQuery({
    queryKey: queryKeys.courierShift(shiftId ?? '', courierId),
    queryFn: () => getCourierShiftDetail({ shiftId: shiftId!, courierId }),
    enabled: Boolean(shiftId && courierId),
  });

  if (!courierId) {
    return (
      <EmptyState
        title="Не указан courier_id"
        message="Для загрузки смены backend требует ID курьера."
        icon={<AlertTriangle className="h-6 w-6" />}
      />
    );
  }

  if (shiftQuery.isLoading) return <LoadingState label="Загрузка смены" />;

  if (shiftQuery.isError) {
    return (
      <ErrorState
        message={shiftQuery.error.message}
        onRetry={() => void shiftQuery.refetch()}
      />
    );
  }

  const shift = shiftQuery.data;
  if (!shift) return <EmptyState title="Смена не найдена" />;

  const paymentTypes = shift.payment_types ?? [];
  const orders = shift.orders ?? [];

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-ink">
            Смена #{String(shift.shift_id ?? shift.id ?? shiftId)}
          </h1>
          <p className="mt-1 text-sm text-muted">
            Курьер: {safeText(shift.courier?.name ?? shift.courier?.login, `ID ${courierId}`)}
          </p>
        </div>
        <Button
          variant="secondary"
          onClick={() => void shiftQuery.refetch()}
          icon={<RefreshCw className="h-4 w-4" />}
        >
          Обновить
        </Button>
      </div>

      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <Metric label="Начало" value={<DateTimeValue value={shift.started_at} />} />
        <Metric label="Окончание" value={<DateTimeValue value={shift.ended_at} />} />
        <Metric label="Заказы" value={toNumber(shift.totals?.orders_count ?? shift.orders_count)} />
        <Metric
          label="Сумма"
          value={<MoneyValue value={shift.totals?.total_amount ?? shift.total_amount} />}
        />
      </section>

      <section className="rounded-lg border border-line bg-white p-4 shadow-sm">
        <h2 className="text-base font-semibold text-ink">Типы оплаты</h2>
        {paymentTypes.length ? (
          <div className="mt-3 grid gap-2 md:grid-cols-2 xl:grid-cols-3">
            {paymentTypes.map((type) => (
              <PaymentTypeBlock key={safeText(type.name)} type={type} />
            ))}
          </div>
        ) : (
          <p className="mt-3 text-sm text-muted">Backend не передал разрез по оплате.</p>
        )}
      </section>

      <section className="overflow-hidden rounded-lg border border-line bg-white shadow-sm">
        <div className="border-b border-line px-4 py-3">
          <h2 className="text-base font-semibold text-ink">Заказы смены</h2>
        </div>
        {orders.length ? (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-line text-sm">
              <thead className="bg-slate-50 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-4 py-3">ID</th>
                  <th className="px-4 py-3">Статус</th>
                  <th className="px-4 py-3">Адрес</th>
                  <th className="px-4 py-3">Тип оплаты</th>
                  <th className="px-4 py-3">Сумма</th>
                  <th className="px-4 py-3">Создан</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {orders.map((order) => (
                  <OrderRow key={String(order.order_id)} order={order} />
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="px-4 py-5 text-sm text-muted">Заказы не переданы backend.</p>
        )}
      </section>
    </div>
  );
}

function Metric({ label, value }: { label: string; value: JSX.Element | number }) {
  return (
    <div className="rounded-lg border border-line bg-white p-4 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-wide text-muted">{label}</p>
      <p className="mt-2 text-lg font-bold text-ink">{value}</p>
    </div>
  );
}

function PaymentTypeBlock({ type }: { type: PaymentTypeSummary }) {
  return (
    <div className="rounded-lg bg-slate-50 px-3 py-2 text-sm">
      <p className="font-semibold text-ink">{safeText(type.name)}</p>
      <div className="mt-2 space-y-1 text-muted">
        <p>Заказы: {toNumber(type.orders)}</p>
        <p>
          Сумма:{' '}
          <MoneyValue
            value={type.total_amount ?? type.totalOrderSum ?? type.total_order_sum ?? type.amount}
          />
        </p>
      </div>
    </div>
  );
}

function OrderRow({ order }: { order: CourierReportOrder }) {
  const status = toInt(order.current_status?.status, -1);
  const canceled = [5, 50, 51, 52, 53, 54].includes(status);

  return (
    <tr className={canceled ? 'bg-red-50/60 align-top' : 'align-top'}>
      <td className="px-4 py-3 font-semibold text-ink">#{safeText(order.order_id, '-')}</td>
      <td className="px-4 py-3">
        <StatusBadge status={status} label={order.current_status?.status_name} />
      </td>
      <td className="min-w-72 px-4 py-3">{buildAddressText(order.delivery_address)}</td>
      <td className="px-4 py-3">{safeText(order.payment_type?.name, 'Не указан')}</td>
      <td className="px-4 py-3"><MoneyValue value={order.total_sum} /></td>
      <td className="px-4 py-3"><DateTimeValue value={order.order_created} /></td>
    </tr>
  );
}
