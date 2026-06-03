import { Html5QrcodeScanner } from 'html5-qrcode';
import { useEffect, useMemo } from 'react';
import { Dialog } from './Dialog';

export function BarcodeScannerDialog({
  open,
  onClose,
  onScan,
}: {
  open: boolean;
  onClose: () => void;
  onScan: (code: string) => void;
}) {
  const readerId = useMemo(
    () => `barcode-reader-${Math.random().toString(36).slice(2)}`,
    [],
  );

  useEffect(() => {
    if (!open) return;

    const scanner = new Html5QrcodeScanner(
      readerId,
      {
        fps: 10,
        qrbox: { width: 260, height: 160 },
        rememberLastUsedCamera: true,
        supportedScanTypes: [],
      },
      false,
    );

    scanner.render(
      (decodedText) => {
        onScan(decodedText);
      },
      () => undefined,
    );

    return () => {
      void scanner.clear().catch(() => undefined);
    };
  }, [onScan, open, readerId]);

  return (
    <Dialog open={open} title="Сканер штрихкода" onClose={onClose}>
      <div className="space-y-3">
        <div id={readerId} className="overflow-hidden rounded-lg border border-line" />
        <p className="text-sm text-muted">
          Наведите камеру на штрихкод товара. После распознавания откроется изменение
          количества.
        </p>
      </div>
    </Dialog>
  );
}
