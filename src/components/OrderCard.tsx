import { CalendarClock, CreditCard, MapPin, MessageSquare, User } from 'lucide-react';
import type { OrderSummary } from '../types/api';
import { buildAddressText, formatDateTime, formatMoney, safeText, toInt } from '../lib/format';
import { StatusBadge } from './StatusBadge';

export function OrderCard({
  order,
  onOpen,
}: {
  order: OrderSummary;
  onOpen: () => void;
}) {
  const status = order.current_status?.status ?? null;
  const total = order.total_cost ?? order.total_sum ?? order.cost;

  return (
    <button
      type="button"
      onClick={onOpen}
      className="w-full rounded-lg border border-line bg-white p-4 text-left shadow-sm transition hover:border-brand-200 hover:shadow-soft focus:outline-none focus:ring-2 focus:ring-brand-500 focus:ring-offset-2"
    >
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="text-lg font-bold text-ink">Заказ #{toInt(order.order_id)}</h2>
            <StatusBadge status={status} label={order.current_status?.status_name} />
          </div>
          <div className="mt-3 grid gap-2 text-sm text-slate-600 md:grid-cols-2">
            <span className="flex min-w-0 items-center gap-2">
              <User className="h-4 w-4 shrink-0 text-slate-400" />
              <span className="truncate">{safeText(order.user?.name)}</span>
            </span>
            <span className="flex min-w-0 items-center gap-2">
              <CalendarClock className="h-4 w-4 shrink-0 text-slate-400" />
              <span>{formatDateTime(order.delivery_date)}</span>
            </span>
            <span className="flex min-w-0 items-center gap-2 md:col-span-2">
              <MapPin className="h-4 w-4 shrink-0 text-slate-400" />
              <span className="truncate">{buildAddressText(order.delivery_address)}</span>
            </span>
          </div>
        </div>
        <div className="shrink-0 text-left sm:text-right">
          <p className="text-lg font-bold text-ink">{formatMoney(total)}</p>
          <p className="mt-1 flex items-center gap-2 text-sm text-muted sm:justify-end">
            <CreditCard className="h-4 w-4" />
            {safeText(order.payment_type?.name, 'Оплата не указана')}
          </p>
        </div>
      </div>

      {order.extra ? (
        <div className="mt-3 flex gap-2 rounded-lg bg-brand-50 px-3 py-2 text-sm text-brand-700">
          <MessageSquare className="mt-0.5 h-4 w-4 shrink-0" />
          <span className="line-clamp-2">{order.extra}</span>
        </div>
      ) : null}
    </button>
  );
}
