import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Barcode,
  Building2,
  CalendarClock,
  CreditCard,
  MapPin,
  Navigation,
  RefreshCw,
  Search,
  Truck,
  User,
} from 'lucide-react';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import {
  cancelOrder,
  getOrderDetails,
  updateOrderItemAmount,
  updateOrderStatus,
} from '../api/orders';
import { BarcodeScannerDialog } from '../components/BarcodeScannerDialog';
import { Button } from '../components/Button';
import { CancelOrderDialog } from '../components/CancelOrderDialog';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { DateTimeValue } from '../components/DateTimeValue';
import { EmptyState } from '../components/EmptyState';
import { ErrorState } from '../components/ErrorState';
import { LoadingState } from '../components/LoadingState';
import { MoneyValue } from '../components/MoneyValue';
import { OrderItemsTable } from '../components/OrderItemsTable';
import { QuantityEditDialog } from '../components/QuantityEditDialog';
import { StatusBadge } from '../components/StatusBadge';
import {
  buildAddressText,
  formatDateTime,
  safeText,
  toInt,
  toNumber,
} from '../lib/format';
import { queryKeys } from '../lib/query';
import { canCancelOrder, getNextAction, isPaymentBlockedStatus } from '../lib/statuses';
import { useToastStore } from '../store/toasts';
import type { OrderItem } from '../types/api';

export function OrderDetailPage() {
  const { orderId } = useParams();
  const queryClient = useQueryClient();
  const showToast = useToastStore((state) => state.showToast);
  const [manualBarcode, setManualBarcode] = useState('');
  const [scannerOpen, setScannerOpen] = useState(false);
  const [quantityItem, setQuantityItem] = useState<OrderItem | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [cancelOpen, setCancelOpen] = useState(false);
  const autoSeenRef = useRef<string | null>(null);

  const detailsQuery = useQuery({
    queryKey: queryKeys.order(orderId ?? ''),
    queryFn: () => getOrderDetails(orderId!),
    enabled: Boolean(orderId),
    refetchInterval: 5_000,
  });

  const order = detailsQuery.data?.order;
  const business = detailsQuery.data?.business;
  const status = toInt(order?.current_status?.status, -1);
  const items = useMemo(() => order?.items ?? [], [order?.items]);
  const canEditAmount = status === 1 || status === 11;
  const nextAction = getNextAction(status);
  const processingBlocked = status !== 0 && isPaymentBlockedStatus(status);

  const invalidateOrder = () => {
    if (orderId) {
      void queryClient.invalidateQueries({ queryKey: queryKeys.order(orderId) });
      void queryClient.invalidateQueries({ queryKey: ['orders'] });
    }
  };

  const statusMutation = useMutation({
    mutationFn: (transitionPath: string) => updateOrderStatus(orderId!, transitionPath),
    onSuccess: () => {
      showToast({ type: 'success', title: 'Статус заказа обновлен' });
      invalidateOrder();
      setConfirmOpen(false);
    },
    onError: (error) => {
      showToast({
        type: 'error',
        title: 'Не удалось обновить статус',
        message: error.message,
      });
    },
  });

  const quantityMutation = useMutation({
    mutationFn: (params: { item: OrderItem; amount: number }) =>
      updateOrderItemAmount({
        orderId: orderId!,
        itemRelationId: params.item.relation_id!,
        amount: params.amount,
      }),
    onSuccess: () => {
      showToast({ type: 'success', title: 'Количество обновлено' });
      setQuantityItem(null);
      invalidateOrder();
    },
    onError: (error) => {
      showToast({
        type: 'error',
        title: 'Не удалось изменить количество',
        message: error.message,
      });
    },
  });

  const cancelMutation = useMutation({
    mutationFn: (cancelStatus: number) => cancelOrder(orderId!, cancelStatus),
    onSuccess: () => {
      showToast({ type: 'success', title: 'Заказ отменен' });
      setCancelOpen(false);
      invalidateOrder();
    },
    onError: (error) => {
      showToast({
        type: 'error',
        title: 'Не удалось отменить заказ',
        message: error.message,
      });
    },
  });

  useEffect(() => {
    if (!orderId || status !== 1 || autoSeenRef.current === orderId) return;

    autoSeenRef.current = orderId;
    void updateOrderStatus(orderId, 'seen')
      .then(() => queryClient.invalidateQueries({ queryKey: queryKeys.order(orderId) }))
      .catch(() => undefined);
  }, [orderId, queryClient, status]);

  const openQuantityEditor = useCallback(
    (item: OrderItem) => {
      if (!canEditAmount) {
        showToast({
          type: 'error',
          title: 'Количество сейчас нельзя изменить',
          message: 'Изменение доступно только при статусах “Принят” или “Просмотрен”.',
        });
        return;
      }

      setQuantityItem(item);
    },
    [canEditAmount, showToast],
  );

  const findItemByBarcode = useCallback(
    (code: string) => {
      const trimmed = code.trim();
      if (!trimmed) return;

      const item = items.find((candidate) => {
        const barcodes = (candidate.barcode ?? '')
          .split(',')
          .map((value) => value.trim())
          .filter(Boolean);
        return barcodes.includes(trimmed) || candidate.name?.trim() === trimmed;
      });

      if (!item) {
        showToast({
          type: 'error',
          title: 'Товар не найден',
          message: `Штрихкод ${trimmed} отсутствует в заказе.`,
        });
        return;
      }

      setScannerOpen(false);
      openQuantityEditor(item);
    },
    [items, openQuantityEditor, showToast],
  );

  const handleStatusConfirm = () => {
    if (!nextAction) return;

    if (processingBlocked) {
      showToast({
        type: 'error',
        title: 'Заказ заблокирован для обработки',
        message: 'Проверьте оплату или текущий статус заказа.',
      });
      setConfirmOpen(false);
      return;
    }

    if (status === 12 && nextAction.nextStatus === 2) {
      const statusTime = order?.current_status?.timestamp
        ? new Date(order.current_status.timestamp)
        : null;
      const allowedAt = statusTime
        ? new Date(statusTime.getTime() + 60_000)
        : null;

      if (allowedAt && Date.now() < allowedAt.getTime()) {
        showToast({
          type: 'info',
          title: 'Слишком рано',
          message: `Статус “Готов к выдаче” доступен после ${formatDateTime(allowedAt)}.`,
        });
        setConfirmOpen(false);
        return;
      }
    }

    statusMutation.mutate(nextAction.transitionPath);
  };

  if (detailsQuery.isLoading) return <LoadingState label="Загрузка заказа" />;

  if (detailsQuery.isError) {
    return (
      <ErrorState
        message={detailsQuery.error.message}
        onRetry={() => void detailsQuery.refetch()}
      />
    );
  }

  if (!order) {
    return <EmptyState title="Заказ не найден" message="Backend вернул пустые данные." />;
  }

  const canCancel = canCancelOrder(status);
  const costSummary = order.cost_summary;

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <div className="flex flex-wrap items-center gap-3">
            <h1 className="text-2xl font-bold text-ink">
              Заказ #{toInt(order.order_id)}
            </h1>
            <StatusBadge status={status} label={order.current_status?.status_name} />
          </div>
          <p className="mt-1 text-sm text-muted">
            Создан: <DateTimeValue value={order.created_at ?? order.log_timestamp} />
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button
            variant="secondary"
            onClick={() => void detailsQuery.refetch()}
            icon={<RefreshCw className="h-4 w-4" />}
          >
            Обновить
          </Button>
          <Link to={`/orders/${orderId}/locations`}>
            <Button variant="secondary" icon={<Navigation className="h-4 w-4" />}>
              Курьер на карте
            </Button>
          </Link>
          {nextAction ? (
            <Button onClick={() => setConfirmOpen(true)} disabled={statusMutation.isPending}>
              {nextAction.label}
            </Button>
          ) : null}
          {canCancel ? (
            <Button variant="danger" onClick={() => setCancelOpen(true)}>
              Отменить
            </Button>
          ) : null}
        </div>
      </div>

      {processingBlocked ? (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
          Заказ недоступен для обработки из-за текущего платежного или ошибочного
          статуса.
        </div>
      ) : null}

      <section className="grid gap-4 lg:grid-cols-3">
        <InfoPanel
          title="Клиент и доставка"
          rows={[
            { icon: User, label: 'Клиент', value: safeText(order.user?.name) },
            {
              icon: Truck,
              label: 'Курьер',
              value: order.courier
                ? safeText(order.courier.name || order.courier.login)
                : 'Не назначен',
            },
            {
              icon: MapPin,
              label: 'Адрес',
              value: buildAddressText(order.delivery_address),
            },
            {
              icon: CalendarClock,
              label: 'Дата доставки',
              value: formatDateTime(order.delivery_date),
            },
          ]}
        />
        <InfoPanel
          title="Оплата и сумма"
          rows={[
            {
              icon: CreditCard,
              label: 'Тип оплаты',
              value: safeText(order.payment_type?.name, 'Не указан'),
            },
            {
              icon: Building2,
              label: 'Магазин',
              value: safeText(business?.name, 'Не указан'),
            },
            {
              icon: MapPin,
              label: 'Адрес магазина',
              value: safeText(business?.address, 'Не указан'),
            },
          ]}
        />
        <div className="rounded-lg border border-line bg-white p-4 shadow-sm">
          <h2 className="text-base font-semibold text-ink">Финансовая сводка</h2>
          <dl className="mt-3 space-y-2 text-sm">
            <MoneyRow label="Товары" value={costSummary?.items_total ?? order.cost} />
            <MoneyRow label="Доставка" value={costSummary?.delivery_price ?? order.delivery_price} />
            <MoneyRow label="Сервисный сбор" value={costSummary?.service_fee ?? order.service_fee} />
            <MoneyRow label="Бонусы" value={costSummary?.bonus_used ?? order.bonus} />
            <div className="border-t border-line pt-2">
              <MoneyRow
                label="Итого"
                value={costSummary?.total_sum ?? order.total_cost ?? order.total_sum}
                strong
              />
            </div>
          </dl>
        </div>
      </section>

      {order.delivery_address?.details?.comment || order.extra ? (
        <section className="rounded-lg border border-line bg-white p-4 shadow-sm">
          <h2 className="text-base font-semibold text-ink">Комментарии</h2>
          <div className="mt-3 space-y-2 text-sm text-slate-700">
            {order.extra ? <p>К заказу: {order.extra}</p> : null}
            {order.delivery_address?.details?.comment ? (
              <p>К адресу: {order.delivery_address.details.comment}</p>
            ) : null}
          </div>
        </section>
      ) : null}

      <section className="rounded-lg border border-line bg-white p-4 shadow-sm">
        <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
          <div>
            <h2 className="text-base font-semibold text-ink">Поиск по штрихкоду</h2>
            <p className="mt-1 text-sm text-muted">
              Поддерживается CSV-строка штрихкодов и точное совпадение названия товара.
            </p>
          </div>
          <div className="flex w-full flex-col gap-2 sm:flex-row md:w-auto">
            <input
              value={manualBarcode}
              onChange={(event) => setManualBarcode(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') {
                  findItemByBarcode(manualBarcode);
                  setManualBarcode('');
                }
              }}
              className="min-h-10 rounded-lg border border-line px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
              placeholder="Введите штрихкод"
            />
            <Button
              variant="secondary"
              onClick={() => {
                findItemByBarcode(manualBarcode);
                setManualBarcode('');
              }}
              icon={<Search className="h-4 w-4" />}
            >
              Найти
            </Button>
            <Button
              onClick={() => setScannerOpen(true)}
              icon={<Barcode className="h-4 w-4" />}
            >
              Сканер
            </Button>
          </div>
        </div>
      </section>

      <OrderItemsTable items={items} canEdit={canEditAmount} onEdit={openQuantityEditor} />

      <section className="rounded-lg border border-line bg-white p-4 shadow-sm">
        <h2 className="text-base font-semibold text-ink">История статусов</h2>
        <div className="mt-4 space-y-3">
          {(order.status_history ?? []).map((entry, index) => (
            <div
              key={`${entry.status_id ?? entry.status}-${entry.timestamp}-${index}`}
              className="flex flex-col gap-1 rounded-lg bg-slate-50 px-3 py-2 sm:flex-row sm:items-center sm:justify-between"
            >
              <StatusBadge status={toInt(entry.status, -1)} label={entry.status_name} />
              <span className="text-sm text-muted">
                <DateTimeValue value={entry.timestamp} />
              </span>
            </div>
          ))}
          {!order.status_history?.length ? (
            <p className="text-sm text-muted">История статусов не передана backend.</p>
          ) : null}
        </div>
      </section>

      <ConfirmDialog
        open={confirmOpen}
        title="Изменить статус заказа"
        message={`Выполнить действие “${nextAction?.label ?? ''}”?`}
        confirmLabel={nextAction?.label}
        busy={statusMutation.isPending}
        onClose={() => setConfirmOpen(false)}
        onConfirm={handleStatusConfirm}
      />

      <CancelOrderDialog
        open={cancelOpen}
        busy={cancelMutation.isPending}
        onClose={() => setCancelOpen(false)}
        onCancel={(cancelStatus) => cancelMutation.mutate(cancelStatus)}
      />

      <QuantityEditDialog
        open={Boolean(quantityItem)}
        item={quantityItem}
        busy={quantityMutation.isPending}
        onClose={() => setQuantityItem(null)}
        onSave={(amount) => {
          if (quantityItem) quantityMutation.mutate({ item: quantityItem, amount });
        }}
      />

      <BarcodeScannerDialog
        open={scannerOpen}
        onClose={() => setScannerOpen(false)}
        onScan={findItemByBarcode}
      />
    </div>
  );
}

type InfoRow = {
  icon: typeof User;
  label: string;
  value: string;
};

function InfoPanel({ title, rows }: { title: string; rows: InfoRow[] }) {
  return (
    <div className="rounded-lg border border-line bg-white p-4 shadow-sm">
      <h2 className="text-base font-semibold text-ink">{title}</h2>
      <div className="mt-3 space-y-3">
        {rows.map((row) => {
          const Icon = row.icon;
          return (
            <div key={row.label} className="flex gap-3 text-sm">
              <Icon className="mt-0.5 h-4 w-4 shrink-0 text-brand-600" />
              <div className="min-w-0">
                <p className="text-xs font-semibold uppercase tracking-wide text-muted">
                  {row.label}
                </p>
                <p className="mt-0.5 break-words text-ink">{row.value}</p>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function MoneyRow({
  label,
  value,
  strong,
}: {
  label: string;
  value: unknown;
  strong?: boolean;
}) {
  return (
    <div className="flex items-center justify-between gap-3">
      <dt className={strong ? 'font-semibold text-ink' : 'text-muted'}>{label}</dt>
      <dd className={strong ? 'font-bold text-ink' : 'text-ink'}>
        <MoneyValue value={toNumber(value)} />
      </dd>
    </div>
  );
}
