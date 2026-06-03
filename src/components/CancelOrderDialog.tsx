import { useState } from 'react';
import { CANCEL_REASONS } from '../lib/statuses';
import { Button } from './Button';
import { Dialog } from './Dialog';

export function CancelOrderDialog({
  open,
  busy,
  onCancel,
  onClose,
}: {
  open: boolean;
  busy?: boolean;
  onCancel: (status: number) => void;
  onClose: () => void;
}) {
  const [status, setStatus] = useState(51);

  return (
    <Dialog
      open={open}
      title="Отмена заказа"
      onClose={onClose}
      footer={
        <>
          <Button variant="secondary" onClick={onClose} disabled={busy}>
            Закрыть
          </Button>
          <Button variant="danger" onClick={() => onCancel(status)} disabled={busy}>
            {busy ? 'Отмена' : 'Отменить заказ'}
          </Button>
        </>
      }
    >
      <label className="block text-sm font-medium text-ink" htmlFor="cancel-reason">
        Причина
      </label>
      <select
        id="cancel-reason"
        value={status}
        onChange={(event) => setStatus(Number(event.target.value))}
        className="mt-2 w-full rounded-lg border border-line bg-white px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-2 focus:ring-brand-100"
      >
        {CANCEL_REASONS.map((reason) => (
          <option key={reason.status} value={reason.status}>
            {reason.label}
          </option>
        ))}
      </select>
    </Dialog>
  );
}
