import { useQuery } from '@tanstack/react-query';
import { Inbox, RefreshCw } from 'lucide-react';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getOrders } from '../api/orders';
import { Button } from '../components/Button';
import { EmptyState } from '../components/EmptyState';
import { ErrorState } from '../components/ErrorState';
import { LoadingState } from '../components/LoadingState';
import { OrderCard } from '../components/OrderCard';
import { queryKeys } from '../lib/query';

const ORDERS_LIMIT = 10;

export function OrdersPage() {
  const [page, setPage] = useState(1);
  const navigate = useNavigate();

  const ordersQuery = useQuery({
    queryKey: queryKeys.orders(page),
    queryFn: () =>
      getOrders({
        page,
        limit: ORDERS_LIMIT,
        dateFrom: '2024-01-01',
      }),
    refetchInterval: 30_000,
  });

  const orders = ordersQuery.data?.orders ?? [];
  const pagination = ordersQuery.data?.pagination;

  return (
    <div className="space-y-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-ink">Заказы</h1>
          <p className="mt-1 text-sm text-muted">
            Автообновление каждые 30 секунд. Показываются актуальные заказы магазина.
          </p>
        </div>
        <Button
          variant="secondary"
          onClick={() => void ordersQuery.refetch()}
          disabled={ordersQuery.isFetching}
          icon={<RefreshCw className="h-4 w-4" />}
        >
          Обновить
        </Button>
      </div>

      {ordersQuery.isLoading ? <LoadingState label="Загрузка заказов" /> : null}

      {ordersQuery.isError ? (
        <ErrorState
          message={ordersQuery.error.message}
          onRetry={() => void ordersQuery.refetch()}
        />
      ) : null}

      {!ordersQuery.isLoading && !ordersQuery.isError && !orders.length ? (
        <EmptyState
          title="Заказов нет"
          message="Когда появятся новые заказы, они будут здесь."
          icon={<Inbox className="h-6 w-6" />}
        />
      ) : null}

      {orders.length ? (
        <div className="space-y-3">
          {orders.map((order) => (
            <OrderCard
              key={order.order_id ?? order.order_uuid}
              order={order}
              onOpen={() => navigate(`/orders/${order.order_id}`)}
            />
          ))}
        </div>
      ) : null}

      {pagination ? (
        <div className="flex items-center justify-between rounded-lg border border-line bg-white px-4 py-3 text-sm">
          <span className="text-muted">
            Страница {pagination.page ?? page}
            {pagination.totalPages ? ` из ${pagination.totalPages}` : ''}
          </span>
          <div className="flex gap-2">
            <Button
              variant="secondary"
              disabled={!pagination.hasPrev || page <= 1}
              onClick={() => setPage((value) => Math.max(1, value - 1))}
            >
              Назад
            </Button>
            <Button
              variant="secondary"
              disabled={!pagination.hasNext}
              onClick={() => setPage((value) => value + 1)}
            >
              Далее
            </Button>
          </div>
        </div>
      ) : null}
    </div>
  );
}
