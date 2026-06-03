import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CourierShiftDetailScreen extends StatefulWidget {
  final int courierId;
  final String shiftId;

  const CourierShiftDetailScreen(
      {super.key, required this.courierId, required this.shiftId});

  @override
  State<CourierShiftDetailScreen> createState() =>
      _CourierShiftDetailScreenState();
}

class _CourierShiftDetailScreenState extends State<CourierShiftDetailScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.getCourierShiftDetail(
      shiftId: widget.shiftId,
      courierId: widget.courierId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res == null) {
        _error = 'Не удалось получить данные смены';
      } else if (res is Map) {
        _data = Map<String, dynamic>.from(res);
      } else {
        _error = 'Неправильный формат ответа сервера';
      }
    });
  }

  String _fmtDate(String? s) {
    if (s == null) return '-';
    try {
      final d = DateTime.parse(s);
      String two(int v) => v.toString().padLeft(2, '0');
      return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shift = (_data != null) ? _data!['shift'] : null;
    final totals = (_data != null) ? _data!['totals'] ?? {} : {};
    final paymentTypes = (_data != null && _data!['payment_types'] is List)
        ? _data!['payment_types'] as List
        : [];
    final orders = (_data != null && _data!['orders'] is List)
        ? _data!['orders'] as List
        : [];

    return Scaffold(
      appBar: AppBar(title: const Text('Деталь смены')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (shift != null) ...[
              Text('Смена ${shift['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  'Период: ${_fmtDate((_data?['period'] ?? {})['start_date']?.toString())} — ${_fmtDate((_data?['period'] ?? {})['end_date']?.toString())}'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Заказы: ${totals['orders_count'] ?? 0}'),
                      Text('Сумма: ${totals['total_amount'] ?? 0}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (paymentTypes.isNotEmpty) ...[
                const Text('Типы оплат',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...paymentTypes.map((pt) {
                  final p = pt is Map ? Map<String, dynamic>.from(pt) : {};
                  return ListTile(
                    dense: true,
                    title: Text(p['payment_type_name']?.toString() ?? '—'),
                    subtitle: Text(
                        'Итого: ${p['total_amount'] ?? 0} — Отменено: ${p['canceled'] ?? 0}'),
                  );
                }).toList(),
                const SizedBox(height: 12),
              ],
              const Text('Заказы',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final o = orders[idx] is Map
                        ? Map<String, dynamic>.from(orders[idx])
                        : {};
                    return ListTile(
                      title: Text(
                          'Заказ ${o['order_id'] ?? ''} • ${o['payment_type_name'] ?? ''}'),
                      subtitle: Text(
                          'Сумма: ${o['amount_total'] ?? o['amount'] ?? 0} • Доставка: ${o['delivery_cost'] ?? 0} • Fee: ${o['delivery_service_fee'] ?? 0}'),
                      trailing: o['is_canceled'] == true
                          ? const Icon(Icons.cancel, color: Colors.red)
                          : null,
                    );
                  },
                ),
              ),
            ] else if (!_loading)
              const Expanded(
                  child: Center(child: Text('Данные смены отсутствуют'))),
          ],
        ),
      ),
    );
  }
}
