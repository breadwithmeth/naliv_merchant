export const STATUS_NAMES: Record<number, string> = {
  0: 'Новый заказ',
  1: 'Принят магазином',
  11: 'Просмотрен',
  12: 'Собирается',
  2: 'Готов к выдаче',
  21: 'Передан курьеру',
  3: 'Доставляется',
  31: 'Курьер рядом',
  4: 'Доставлен',
  5: 'Отменен',
  50: 'Отменен пользователем',
  51: 'Отменен магазином',
  52: 'Отменен: нет в наличии',
  53: 'Отменен: клиент младше 21 года',
  54: 'Отменен: клиент отказался',
  6: 'Ошибка платежа',
  60: 'Ожидает оплаты',
  61: 'Оплата в обработке',
  66: 'Не оплачен',
  67: 'Платеж отклонен',
  68: 'Системная ошибка оплаты',
  7: 'Возврат начат',
  71: 'Возврат завершен',
};

export const STATUS_TRANSITIONS: Record<number, string> = {
  1: 'accepted',
  11: 'seen',
  12: 'collecting',
  2: 'ready',
  21: 'handed-to-courier',
};

export const CANCEL_REASONS = [
  { status: 5, label: 'Другая причина' },
  { status: 50, label: 'Отменен пользователем' },
  { status: 51, label: 'Отменен магазином' },
  { status: 52, label: 'Нет в наличии' },
  { status: 53, label: 'Клиент младше 21 года' },
  { status: 54, label: 'Клиент отказался' },
];

export function getStatusName(status?: number | null, fallback?: string | null) {
  if (typeof status !== 'number') return fallback || 'Статус не указан';
  return fallback || STATUS_NAMES[status] || 'Статус не указан';
}

export function isPaymentBlockedStatus(status?: number | null) {
  return status === 0 || status === 66 || status === 6 || status === 67 || status === 68;
}

export function canCancelOrder(status?: number | null) {
  if (typeof status !== 'number') return false;
  return ![4, 5, 50, 51, 52, 53, 54, 66, 7, 71, 6, 67, 68].includes(status);
}

export function getNextAction(status?: number | null) {
  switch (status) {
    case 0:
      return { label: 'Принять заказ', nextStatus: 1, transitionPath: 'accepted' };
    case 1:
    case 11:
      return { label: 'Начать сборку', nextStatus: 12, transitionPath: 'collecting' };
    case 12:
      return { label: 'Готов к выдаче', nextStatus: 2, transitionPath: 'ready' };
    case 2:
      return {
        label: 'Передать курьеру',
        nextStatus: 21,
        transitionPath: 'handed-to-courier',
      };
    default:
      return null;
  }
}

export function getStatusTone(status?: number | null) {
  if ([5, 50, 51, 52, 53, 54, 6, 67, 68].includes(status ?? -1)) return 'danger';
  if ([4, 21, 3, 31].includes(status ?? -1)) return 'success';
  if ([12, 2].includes(status ?? -1)) return 'warning';
  if ([0, 66, 60, 61].includes(status ?? -1)) return 'neutral';
  return 'info';
}
