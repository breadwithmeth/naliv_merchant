import { useQuery } from '@tanstack/react-query';
import { RefreshCw, Route } from 'lucide-react';
import { FormEvent, useState } from 'react';
import { Link } from 'react-router-dom';
import { getCourierShifts } from '../api/couriers';
import { Button } from '../components/Button';
import { DateTimeValue } from '../components/DateTimeValue';
import { EmptyState } from '../components/EmptyState';
import { ErrorState } from '../components/ErrorState';
import { LoadingState } from '../components/LoadingState';
import { MoneyValue } from '../components/MoneyValue';
import { safeText, toNumber } from '../lib/format';
import { queryKeys } from '../lib/query';
import type { CourierShift } from '../types/api';

export function CourierShiftsPage() {
  const [inputCourierId, setInputCourierId] = useState('');
  const [courierId, setCourierId] = useState<string | undefined>();

  const shiftsQuery = useQuery({
    queryKey: queryKeys.courierShifts(courierId),
    queryFn: () => getCourierShifts(courierId),
  });

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setCourierId(inputCourierId.trim() || undefined);
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-ink">Смены курьеров</h1>
          <p className="mt-1 text-sm text-muted">
            Список смен по всем курьерам или по конкретному ID.
          </p>
        </div>
        <Button
          variant="secondary"
          onClick={() => void shiftsQuery.refetch()}
          icon={<RefreshCw className="h-4 w-4" />}
        >
          Обновить
        </Button>
      </div>

      <form
        onSubmit={submit}
        className="flex flex-col gap-2 rounded-lg border border-line bg-white p-4 shadow-sm sm:flex-row sm:items-end"
      >
        <label className="block flex-1 text-sm font-semibold text-ink">
          ID курьера
          <input
            value={inputCourierId}
            onChange={(event) => setInputCourierId(event.target.value)}
            className="mt-2 w-full rounded-lg border border-line px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
            placeholder="Оставьте пустым для всех"
          />
        </label>
        <Button type="submit">Показать</Button>
      </form>

      {shiftsQuery.isLoading ? <LoadingState label="Загрузка смен" /> : null}

      {shiftsQuery.isError ? (
        <ErrorState
          message={shiftsQuery.error.message}
          onRetry={() => void shiftsQuery.refetch()}
        />
      ) : null}

      {!shiftsQuery.isLoading && !shiftsQuery.isError && !shiftsQuery.data?.length ? (
        <EmptyState
          title="Смены не найдены"
          message="Backend вернул пустой список смен."
          icon={<Route className="h-6 w-6" />}
        />
      ) : null}

      {shiftsQuery.data?.length ? (
        <section className="overflow-hidden rounded-lg border border-line bg-white shadow-sm">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-line text-sm">
              <thead className="bg-slate-50 text-left text-xs font-semibold uppercase tracking-wide text-muted">
                <tr>
                  <th className="px-4 py-3">Курьер</th>
                  <th className="px-4 py-3">Начало</th>
                  <th className="px-4 py-3">Окончание</th>
                  <th className="px-4 py-3">Статус</th>
                  <th className="px-4 py-3">Заказы</th>
                  <th className="px-4 py-3">Сумма</th>
                  <th className="px-4 py-3 text-right">Детали</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {shiftsQuery.data.map((shift) => (
                  <ShiftRow key={getShiftId(shift)} shift={shift} />
                ))}
              </tbody>
            </table>
          </div>
        </section>
      ) : null}
    </div>
  );
}

function ShiftRow({ shift }: { shift: CourierShift }) {
  const shiftId = getShiftId(shift);
  const courierId = shift.courier_id ?? shift.courier?.courier_id ?? shift.courier?.id;
  const detailUrl = `/couriers/shifts/${shiftId}?courier_id=${courierId ?? ''}`;

  return (
    <tr className="align-middle">
      <td className="px-4 py-3 font-semibold text-ink">
        {safeText(shift.courier?.name ?? shift.courier?.login, 'Курьер')}
      </td>
      <td className="px-4 py-3"><DateTimeValue value={shift.started_at} /></td>
      <td className="px-4 py-3"><DateTimeValue value={shift.ended_at} /></td>
      <td className="px-4 py-3">{safeText(shift.status, 'Не указан')}</td>
      <td className="px-4 py-3">{toNumber(shift.orders_count ?? shift.totals?.orders_count)}</td>
      <td className="px-4 py-3">
        <MoneyValue value={shift.total_amount ?? shift.totals?.total_amount} />
      </td>
      <td className="px-4 py-3 text-right">
        <Link to={detailUrl}>
          <Button variant="secondary" className="min-h-9 px-3 py-1.5">
            Открыть
          </Button>
        </Link>
      </td>
    </tr>
  );
}

function getShiftId(shift: CourierShift) {
  return String(shift.shift_id ?? shift.id ?? '');
}
