import type { ReactNode } from 'react';

export function EmptyState({
  title,
  message,
  icon,
}: {
  title: string;
  message?: string;
  icon?: ReactNode;
}) {
  return (
    <div className="flex min-h-56 items-center justify-center px-4">
      <div className="w-full max-w-md rounded-lg border border-line bg-white p-6 text-center shadow-soft">
        <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-slate-100 text-slate-500">
          {icon}
        </div>
        <h2 className="mt-3 text-lg font-semibold text-ink">{title}</h2>
        {message ? <p className="mt-2 text-sm text-muted">{message}</p> : null}
      </div>
    </div>
  );
}
