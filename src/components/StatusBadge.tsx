import { clsx } from 'clsx';
import { getStatusName, getStatusTone } from '../lib/statuses';

const tones = {
  danger: 'bg-red-50 text-red-700 ring-red-100',
  success: 'bg-emerald-50 text-emerald-700 ring-emerald-100',
  warning: 'bg-amber-50 text-amber-700 ring-amber-100',
  neutral: 'bg-slate-100 text-slate-700 ring-slate-200',
  info: 'bg-sky-50 text-sky-700 ring-sky-100',
};

export function StatusBadge({
  status,
  label,
}: {
  status?: number | null;
  label?: string | null;
}) {
  return (
    <span
      className={clsx(
        'inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold ring-1',
        tones[getStatusTone(status)],
      )}
    >
      {getStatusName(status, label)}
    </span>
  );
}
