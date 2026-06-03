import { Button } from './Button';
import { Dialog } from './Dialog';

export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = 'Подтвердить',
  busy,
  onConfirm,
  onClose,
}: {
  open: boolean;
  title: string;
  message: string;
  confirmLabel?: string;
  busy?: boolean;
  onConfirm: () => void;
  onClose: () => void;
}) {
  return (
    <Dialog
      open={open}
      title={title}
      onClose={onClose}
      footer={
        <>
          <Button variant="secondary" onClick={onClose} disabled={busy}>
            Отмена
          </Button>
          <Button onClick={onConfirm} disabled={busy}>
            {busy ? 'Выполняется' : confirmLabel}
          </Button>
        </>
      }
    >
      <p className="text-sm leading-6 text-slate-700">{message}</p>
    </Dialog>
  );
}
