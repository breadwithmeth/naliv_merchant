import { useEffect, useState } from 'react';
import { toNumber } from '../lib/format';
import type { OrderItem } from '../types/api';
import { Button } from './Button';
import { Dialog } from './Dialog';

export function QuantityEditDialog({
  item,
  open,
  busy,
  onSave,
  onClose,
}: {
  item: OrderItem | null;
  open: boolean;
  busy?: boolean;
  onSave: (amount: number) => void;
  onClose: () => void;
}) {
  const currentAmount = toNumber(item?.amount);
  const [amount, setAmount] = useState(currentAmount || 1);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setAmount(currentAmount || 1);
    setError(null);
  }, [currentAmount, open]);

  const submit = () => {
    if (amount <= 0) {
      setError('Количество должно быть больше 0');
      return;
    }

    if (amount > currentAmount) {
      setError('Количество не может быть больше текущего');
      return;
    }

    onSave(amount);
  };

  return (
    <Dialog
      open={open && Boolean(item)}
      title="Изменить количество"
      onClose={onClose}
      footer={
        <>
          <Button variant="secondary" onClick={onClose} disabled={busy}>
            Закрыть
          </Button>
          <Button onClick={submit} disabled={busy}>
            {busy ? 'Сохранение' : 'Сохранить'}
          </Button>
        </>
      }
    >
      <div className="space-y-4">
        <div>
          <p className="text-sm font-semibold text-ink">{item?.name || 'Товар'}</p>
          <p className="mt-1 text-sm text-muted">Текущее количество: {currentAmount}</p>
        </div>
        <label className="block text-sm font-medium text-ink" htmlFor="amount">
          Новое количество
        </label>
        <input
          id="amount"
          type="number"
          min="0.01"
          step="0.01"
          value={amount}
          onChange={(event) => setAmount(Number(event.target.value))}
          className="w-full rounded-lg border border-line px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
        />
        {error ? <p className="text-sm text-red-600">{error}</p> : null}
      </div>
    </Dialog>
  );
}
