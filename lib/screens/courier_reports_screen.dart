import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CourierReportsScreen extends StatefulWidget {
  const CourierReportsScreen({super.key});
  @override
  State<CourierReportsScreen> createState() => _CourierReportsScreenState();
}

class _CourierReportsScreenState extends State<CourierReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;
  dynamic _rawData; // полный data
  String? _error;

  List<Map<String, dynamic>> _couriers = []; // агрегировано по курьерам
  Map<String, dynamic>? _summary; // summary из ответа
  String _sortKey = 'deliveryRevenue';
  bool _sortAsc = false;

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate =
        isStart ? (_startDate ?? now) : (_endDate ?? _startDate ?? now);
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 1, 12, 31);

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null) return;

    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (timeOfDay == null) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    setState(() {
      if (isStart) {
        _startDate = selected;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _loadReport() async {
    if (_startDate == null || _endDate == null) {
      setState(() => _error = 'Выберите даты');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _rawData = null;
      _couriers.clear();
    });
    final data = await ApiService.getCourierReports(
      startDate: _startDate!,
      endDate: _endDate!,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data == null) {
        _error = 'Не удалось получить отчет';
      } else {
        _rawData = data;
        _parseCouriers();
      }
    });
  }

  void _parseCouriers() {
    _summary =
        (_rawData is Map) ? _rawData['summary'] as Map<String, dynamic>? : null;
    final orders = (_rawData is Map) ? _rawData['orders'] : null;
    final Map<int, Map<String, dynamic>> agg = {};
    final List<Map<String, dynamic>> unassignedOrders = [];
    if (orders is List) {
      for (final o in orders) {
        if (o is Map) {
          final courier = o['courier'];
          final deliveryPrice = _toNum(o['delivery_price']);
          final totalSum = _toNum(o['total_sum']);
          final orderId = o['order_id'];
          final created = o['order_created'];
          final address = o['delivery_address'];
          if (courier is Map) {
            final id = courier['courier_id'] ?? 0;
            final name = courier['name'] ?? courier['login'] ?? 'Курьер';
            final bucket = agg.putIfAbsent(
                id,
                () => {
                      'courierId': id,
                      'name': name,
                      'orders': 0,
                      'deliveryRevenue': 0.0,
                      'totalOrderSum': 0.0,
                      'ordersList': <Map<String, dynamic>>[],
                    });
            bucket['orders'] = (bucket['orders'] as int) + 1;
            bucket['deliveryRevenue'] =
                (bucket['deliveryRevenue'] as num) + deliveryPrice;
            bucket['totalOrderSum'] =
                (bucket['totalOrderSum'] as num) + totalSum;
            (bucket['ordersList'] as List).add({
              'order_id': orderId,
              'delivery_price': deliveryPrice,
              'total_sum': totalSum,
              'order_created': created,
              'delivery_address': address,
            });
          } else {
            unassignedOrders.add(o.cast<String, dynamic>());
          }
        }
      }
    }
    _couriers = agg.values.map((e) => e).toList();
    if (unassignedOrders.isNotEmpty) {
      _couriers.add({
        'courierId': -1,
        'name': 'Без курьера',
        'orders': unassignedOrders.length,
        'deliveryRevenue': unassignedOrders.fold<num>(
            0, (p, o) => p + _toNum(o['delivery_price'])),
        'totalOrderSum':
            unassignedOrders.fold<num>(0, (p, o) => p + _toNum(o['total_sum'])),
        'ordersList': unassignedOrders,
      });
    }
    _applySort();
  }

  num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  void _applySort() {
    _couriers.sort((a, b) {
      final av = a[_sortKey] as num? ?? 0;
      final bv = b[_sortKey] as num? ?? 0;
      final cmp = av.compareTo(bv);
      return _sortAsc ? cmp : -cmp;
    });
  }

  void _changeSort(String key) {
    setState(() {
      if (_sortKey == key) {
        _sortAsc = !_sortAsc;
      } else {
        _sortKey = key;
        _sortAsc = key == 'name' ? true : false;
      }
      _applySort();
    });
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Не выбрана';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  String _formatNum(num? v) {
    v ??= 0;
    final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
    // простая группировка по 3
    final parts = s.split('.');
    final intPart = parts[0];
    final buff = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      buff.write(intPart[i]);
      final posFromEnd = intPart.length - i - 1;
      if (posFromEnd > 0 && posFromEnd % 3 == 0) buff.write(' ');
    }
    return parts.length == 2 && parts[1] != '00'
        ? '${buff.toString()}.${parts[1]}'
        : buff.toString();
  }

  num get _totalOrders =>
      _couriers.fold(0, (p, c) => p + (c['orders'] as num? ?? 0));
  num get _totalDeliveryRevenue =>
      _couriers.fold(0, (p, c) => p + (c['deliveryRevenue'] as num? ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отчет по курьерам'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _periodSelectors(),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_couriers.isNotEmpty) _summaryBar(),
            const SizedBox(height: 8),
            _headerBar(),
            const Divider(height: 1),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _periodSelectors() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _DateButton(
          label: 'Начало: ${_fmt(_startDate)}',
          onTap: () => _pickDateTime(isStart: true),
        ),
        _DateButton(
          label: 'Конец: ${_fmt(_endDate)}',
          onTap: () => _pickDateTime(isStart: false),
        ),
        ElevatedButton.icon(
          onPressed: _loading ? null : _loadReport,
          icon: const Icon(Icons.assessment),
          label: const Text('Получить'),
        ),
      ],
    );
  }

  Widget _summaryBar() {
    final delivered = _summary?['total_delivered_orders'] ?? _totalOrders;
    final withCourier = _summary?['orders_with_courier'];
    final withoutCourier = _summary?['orders_without_courier'];
    final totalDeliveryRevenue = _summary?['total_delivery_revenue'];
    return Card(
      color: Colors.orange.withOpacity(.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _summaryItem(Icons.local_shipping, 'Доставлено',
                _formatNum(_toNum(delivered))),
            if (withCourier != null)
              _summaryItem(
                  Icons.person, 'С курьером', _formatNum(_toNum(withCourier))),
            if (withoutCourier != null)
              _summaryItem(Icons.person_off, 'Без курьера',
                  _formatNum(_toNum(withoutCourier))),
            _summaryItem(
                Icons.payments,
                'Дост. выручка',
                _formatNum(_toNum(totalDeliveryRevenue) == 0
                    ? _totalDeliveryRevenue
                    : _toNum(totalDeliveryRevenue))),
            if (_totalOrders > 0)
              _summaryItem(Icons.bar_chart, 'Avg доставка',
                  _formatNum(_totalDeliveryRevenue / _totalOrders)),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.orange),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _headerBar() {
    if (_couriers.isEmpty) return const SizedBox();
    TextStyle h = const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    Widget sortBtn(String key, String label) {
      final active = _sortKey == key;
      return InkWell(
        onTap: () => _changeSort(key),
        child: Row(children: [
          Text(label,
              style:
                  h.copyWith(color: active ? Colors.orange : Colors.black87)),
          if (active)
            Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14, color: Colors.orange),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(children: [
        const SizedBox(
            width: 40,
            child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 4, child: sortBtn('name', 'Курьер')),
        Expanded(
            flex: 2,
            child: Align(
                alignment: Alignment.centerRight,
                child: sortBtn('orders', 'Заказы'))),
        Expanded(
            flex: 3,
            child: Align(
                alignment: Alignment.centerRight,
                child: sortBtn('deliveryRevenue', 'Дост. выручка'))),
        const SizedBox(width: 36),
      ]),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_rawData == null)
      return const Center(child: Text('Выберите период и нажмите "Получить"'));
    if (_couriers.isEmpty) return const Center(child: Text('Нет данных'));

    return ListView.separated(
      itemCount: _couriers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final c = _couriers[index];
        final avg = (c['orders'] as num) > 0
            ? (c['deliveryRevenue'] as num) / (c['orders'] as num)
            : 0;
        return InkWell(
          onTap: () => _showCourierOrders(c),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(children: [
              SizedBox(
                width: 40,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orange.withOpacity(.15),
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['name']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(children: [
                        _miniChip(Icons.receipt_long,
                            _formatNum(c['orders'] as num?)),
                        const SizedBox(width: 6),
                        _miniChip(Icons.payments,
                            _formatNum(c['deliveryRevenue'] as num?)),
                      ]),
                    ]),
              ),
              Expanded(
                flex: 2,
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(_formatNum(c['orders'] as num?),
                        style: const TextStyle(fontWeight: FontWeight.w500))),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatNum(c['deliveryRevenue'] as num?),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Text('avg ${_formatNum(avg)}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ]),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.list_alt,
                      size: 20, color: Colors.orange),
                  onPressed: () => _showCourierOrders(c),
                  tooltip: 'Заказы'),
            ]),
          ),
        );
      },
    );
  }

  void _showCourierOrders(Map<String, dynamic> courier) {
    final orders = (courier['ordersList'] as List?) ?? [];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(courier['name']?.toString() ?? '',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: orders.length,
                itemBuilder: (context, i) {
                  final o = orders[i] as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text('Заказ #${o['order_id']}'),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (o['order_created'] != null)
                              Text(o['order_created'].toString(),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            if (o['delivery_address'] != null)
                              Text(o['delivery_address'].toString(),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                          ]),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_formatNum(_toNum(o['delivery_price'])),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          if (_toNum(o['total_sum']) > 0)
                            Text('Σ ${_formatNum(_toNum(o['total_sum']))}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String text, {Color? color}) {
    final c = color ?? Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 3),
          Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: c)),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.date_range),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

// Старый _CourierReportTile удален, функционал заменен новым списком.
