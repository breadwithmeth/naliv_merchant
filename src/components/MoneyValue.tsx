import { formatMoney } from '../lib/format';

export function MoneyValue({ value }: { value: unknown }) {
  return <span className="tabular-nums">{formatMoney(value)}</span>;
}
