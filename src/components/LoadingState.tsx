export function LoadingState({ label = 'Загрузка данных' }: { label?: string }) {
  return (
    <div className="flex min-h-56 items-center justify-center">
      <div className="flex items-center gap-3 rounded-lg border border-line bg-white px-4 py-3 text-sm text-muted shadow-soft">
        <span className="h-4 w-4 animate-spin rounded-full border-2 border-brand-600 border-t-transparent" />
        {label}
      </div>
    </div>
  );
}
