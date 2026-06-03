import { CheckCircle2, Info, X, XCircle } from 'lucide-react';
import { clsx } from 'clsx';
import { useToastStore, type ToastType } from '../store/toasts';

const icons: Record<ToastType, typeof CheckCircle2> = {
  success: CheckCircle2,
  error: XCircle,
  info: Info,
};

const tones: Record<ToastType, string> = {
  success: 'border-emerald-100 text-emerald-700',
  error: 'border-red-100 text-red-700',
  info: 'border-sky-100 text-sky-700',
};

export function ToastViewport() {
  const { toasts, dismissToast } = useToastStore();

  return (
    <div className="fixed right-4 top-4 z-[70] flex w-[calc(100vw-2rem)] max-w-sm flex-col gap-3">
      {toasts.map((toast) => {
        const Icon = icons[toast.type];
        return (
          <div
            key={toast.id}
            className={clsx(
              'rounded-lg border bg-white p-4 shadow-soft',
              tones[toast.type],
            )}
          >
            <div className="flex gap-3">
              <Icon className="mt-0.5 h-5 w-5 shrink-0" />
              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold text-ink">{toast.title}</p>
                {toast.message ? (
                  <p className="mt-1 text-sm text-muted">{toast.message}</p>
                ) : null}
              </div>
              <button
                className="rounded p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-700"
                type="button"
                aria-label="Закрыть"
                onClick={() => dismissToast(toast.id)}
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>
        );
      })}
    </div>
  );
}
