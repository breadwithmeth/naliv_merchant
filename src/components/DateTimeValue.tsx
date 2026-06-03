import { formatDateTime } from '../lib/format';

export function DateTimeValue({ value }: { value?: string | Date | null }) {
  return <span>{formatDateTime(value)}</span>;
}
