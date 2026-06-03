import { AlertTriangle } from 'lucide-react';
import { Button } from './Button';

export function ErrorState({
  title = 'Не удалось загрузить данные',
  message,
  onRetry,
}: {
  title?: string;
  message?: string;
  onRetry?: () => void;
}) {
  return (
    <div className="flex min-h-56 items-center justify-center px-4">
      <div className="w-full max-w-md rounded-lg border border-red-100 bg-white p-6 text-center shadow-soft">
        <AlertTriangle className="mx-auto h-10 w-10 text-red-500" />
        <h2 className="mt-3 text-lg font-semibold text-ink">{title}</h2>
        {message ? <p className="mt-2 text-sm text-muted">{message}</p> : null}
        {onRetry ? (
          <Button className="mt-4" onClick={onRetry}>
            Повторить
          </Button>
        ) : null}
      </div>
    </div>
  );
}
