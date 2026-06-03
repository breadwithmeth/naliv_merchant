import { Edit3 } from 'lucide-react';
import { BASE_URL } from '../api/client';
import { formatMoney, safeText, toNumber } from '../lib/format';
import type { OrderItem } from '../types/api';
import { Button } from './Button';

function resolveImage(src?: string | null) {
  if (!src) return null;
  if (src.startsWith('http')) return src;
  if (src.startsWith('/')) return `${BASE_URL}${src}`;
  return src;
}

export function OrderItemsTable({
  items,
  canEdit,
  onEdit,
}: {
  items: OrderItem[];
  canEdit: boolean;
  onEdit: (item: OrderItem) => void;
}) {
  return (
    <div className="overflow-hidden rounded-lg border border-line bg-white">
      <div className="border-b border-line px-4 py-3">
        <h2 className="text-base font-semibold text-ink">Товары</h2>
      </div>
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-line text-sm">
          <thead className="bg-slate-50 text-left text-xs font-semibold uppercase tracking-wide text-muted">
            <tr>
              <th className="px-4 py-3">Товар</th>
              <th className="px-4 py-3">Штрихкоды</th>
              <th className="px-4 py-3">Количество</th>
              <th className="px-4 py-3">Цена</th>
              <th className="px-4 py-3">Итог</th>
              <th className="px-4 py-3 text-right">Действия</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-line">
            {items.map((item) => {
              const image = resolveImage(item.img);
              const relationId = item.relation_id ?? item.item_id ?? item.name;

              return (
                <tr key={String(relationId)} className="align-top">
                  <td className="min-w-72 px-4 py-3">
                    <div className="flex gap-3">
                      <div className="flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden rounded-lg bg-slate-100">
                        {image ? (
                          <img
                            src={image}
                            alt=""
                            className="h-full w-full object-cover"
                            loading="lazy"
                          />
                        ) : (
                          <span className="text-xs text-muted">Нет фото</span>
                        )}
                      </div>
                      <div className="min-w-0">
                        <p className="font-semibold text-ink">{safeText(item.name, 'Товар')}</p>
                        {item.description ? (
                          <p className="mt-1 line-clamp-2 text-xs text-muted">
                            {item.description}
                          </p>
                        ) : null}
                        {item.options?.length ? (
                          <div className="mt-2 flex flex-wrap gap-1">
                            {item.options.map((option) => (
                              <span
                                key={`${option.option_id}-${option.name}`}
                                className="rounded bg-slate-100 px-2 py-1 text-xs text-slate-600"
                              >
                                {safeText(option.option_name || option.name)}
                              </span>
                            ))}
                          </div>
                        ) : null}
                      </div>
                    </div>
                  </td>
                  <td className="max-w-56 px-4 py-3 text-muted">
                    <span className="break-words">{safeText(item.barcode, '-')}</span>
                  </td>
                  <td className="px-4 py-3 font-semibold text-ink">
                    {toNumber(item.amount)} {item.unit || ''}
                  </td>
                  <td className="px-4 py-3">{formatMoney(item.price)}</td>
                  <td className="px-4 py-3 font-semibold">{formatMoney(item.total_cost)}</td>
                  <td className="px-4 py-3 text-right">
                    <Button
                      variant="secondary"
                      className="min-h-9 px-3 py-1.5"
                      disabled={!canEdit}
                      onClick={() => onEdit(item)}
                      icon={<Edit3 className="h-4 w-4" />}
                    >
                      Изменить
                    </Button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
