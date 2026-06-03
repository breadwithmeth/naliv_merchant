import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'courier_shift_detail_screen.dart';

class CourierShiftsScreen extends StatefulWidget {
  final int? courierId;

  const CourierShiftsScreen({super.key, this.courierId});

  @override
  State<CourierShiftsScreen> createState() => _CourierShiftsScreenState();
}

class _CourierShiftsScreenState extends State<CourierShiftsScreen> {
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
    final res = await ApiService.getCourierShifts(courierId: widget.courierId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res == null) {
        _error = 'Не удалось получить смены';
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
    final shifts = (_data != null && _data!['shifts'] is List)
        ? _data!['shifts'] as List
        : [];

    return Scaffold(
      appBar: AppBar(title: const Text('Смены курьеров')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (shifts.isEmpty && !_loading && _error == null)
              const Expanded(child: Center(child: Text('Смен не найдено'))),
            if (shifts.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: shifts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = shifts[idx] is Map
                        ? Map<String, dynamic>.from(shifts[idx])
                        : {};
                    final courier = item['courier'] is Map
                        ? Map<String, dynamic>.from(item['courier'])
                        : <String, dynamic>{};
                    final shift = item['shift'] ?? {};
                    final totals = item['totals'] ?? {};
                    final start = shift['started_at']?.toString();
                    final end = shift['ended_at']?.toString();
                    final status = shift['status']?.toString() ?? '';
                    final ordersCount = totals['orders_count'] ?? 0;
                    final totalAmount = totals['total_amount'] ?? 0;
                    final courierId = int.tryParse(
                            (courier['courier_id'] ?? '').toString()) ??
                        widget.courierId ??
                        0;
                    final courierName = courier['name']?.toString() ??
                        courier['login']?.toString() ??
                        'Курьер';

                    return ListTile(
                      title:
                          Text('$courierName • ${_fmtDate(start)} — ${_fmtDate(end)}'),
                      subtitle: Text(
                          'Статус: $status • Заказы: $ordersCount • Сумма: $totalAmount'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: courierId <= 0 || (shift['id']?.toString().isEmpty ?? true)
                          ? null
                          : () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CourierShiftDetailScreen(
                            courierId: courierId,
                            shiftId: shift['id']?.toString() ?? '',
                          ),
                        ));
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Детальная страница находится в `courier_shift_detail_screen.dart`.
