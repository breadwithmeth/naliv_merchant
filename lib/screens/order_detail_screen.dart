import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderDetails? _orderDetails;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _barcodeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final details =
          await ApiService.getOrderDetails(widget.orderId.toString());

      setState(() {
        _orderDetails = details;
        _isLoading = false;
        if (details == null) {
          _error = 'Не удалось загрузить детали заказа';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка загрузки: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заказ #${widget.orderId}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderDetails,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOrderActions(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Future<void> _startBarcodeScan() async {
    try {
      final res = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SimpleBarcodeScannerPage(),
        ),
      );
      final String? barcode = res is String ? res : null;
      if (barcode == null || barcode.isEmpty) return;
      setState(() => _barcodeCtrl.text = barcode);
      _findItemByBarcodeAndEdit(barcode);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сканирования: $e')),
      );
    }
  }

  void _onManualBarcodeSubmit() {
    final code = _barcodeCtrl.text.trim();
    if (code.isEmpty) return;
    _findItemByBarcodeAndEdit(code);
  }

  void _findItemByBarcodeAndEdit(String barcode) {
    if (_orderDetails == null) return;
    final items = _orderDetails!.order.items;
    OrderItem? match;
    final scanned = barcode.trim();
    for (final it in items) {
      final bc = (it.barcode ?? '').trim();
      if (bc.isNotEmpty && bc == scanned) {
        match = it;
        break;
      }
      if (it.name.trim() == scanned) {
        match = it;
        break;
      }
    }
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Товар со штрихкодом "$barcode" не найден')),
      );
      return;
    }
    _showEditAmountDialog(match);
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.orange,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrderDetails,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_orderDetails == null) {
      return const Center(
        child: Text('Заказ не найден'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScannerBar(),
          const SizedBox(height: 12),

          // Статус заказа
          _buildStatusSection(),
          const SizedBox(height: 24),

          // Информация о клиенте
          _buildClientSection(),
          const SizedBox(height: 24),

          // Информация о доставке
          if (_orderDetails!.order.deliveryAddress != null) ...[
            _buildDeliverySection(),
            const SizedBox(height: 24),
          ],

          // Товары в заказе
          _buildItemsSection(),
          const SizedBox(height: 24),

          // Финансовая информация
          _buildFinancialSection(),
          const SizedBox(height: 24),

          // История статусов
          _buildStatusHistorySection(),
          const SizedBox(height: 32),

          // Кнопки действий
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildScannerBar() {
    final canEdit = _orderDetails?.order.currentStatus.status == 1;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Сканер штрихкодов',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (!canEdit)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Только просмотр',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _startBarcodeScan,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Сканировать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _barcodeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Введите или вставьте штрихкод',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _onManualBarcodeSubmit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Найти товар',
                  onPressed: _onManualBarcodeSubmit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final status = _orderDetails!.order.currentStatus;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статус заказа',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusIndicator(status.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.statusName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(status.timestamp),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(int status) {
    Color color;
    IconData icon;

    switch (status) {
      case 0:
        color = Colors.grey;
        icon = Icons.fiber_new;
        break;
      case 1:
        color = Colors.blue;
        icon = Icons.schedule;
        break;
      case 2:
        color = Colors.orange;
        icon = Icons.inventory;
        break;
      case 3:
        color = Colors.purple;
        icon = Icons.local_shipping;
        break;
      case 4:
        color = Colors.green;
        icon = Icons.done_all;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildClientSection() {
    final user = _orderDetails!.order.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Клиент',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ID: ${user.userId}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () {
                    // Действие для звонка
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    final address = _orderDetails!.order.deliveryAddress!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Доставка',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.address,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (address.details?.apartment?.isNotEmpty == true)
                        Text(
                          'Кв. ${address.details!.apartment}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      if (address.details?.entrance?.isNotEmpty == true)
                        Text(
                          'Подъезд ${address.details!.entrance}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      if (address.details?.floor?.isNotEmpty == true)
                        Text(
                          'Этаж ${address.details!.floor}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      if (address.details?.comment?.isNotEmpty == true)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            address.details!.comment!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: () {
                    // Открыть карту
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    final items = _orderDetails!.order.items;
    final canEdit = _orderDetails!.order.currentStatus.status == 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Товары (${items.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!canEdit)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Редактирование недоступно',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildItemCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.img != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.img!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.barcode ?? 'Штрихкод не указан',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${item.amount} ${item.unit} × ${item.price} ₸',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          tooltip: 'Сканировать для этого товара',
                          onPressed: _startBarcodeScan,
                        ),
                        if (_orderDetails!.order.currentStatus.status == 1)
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showEditAmountDialog(item),
                            tooltip: 'Изменить количество',
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.edit,
                                size: 20, color: Colors.grey),
                            onPressed: null,
                            tooltip:
                                'Редактирование недоступно для данного статуса заказа',
                          ),
                      ],
                    ),
                    Text(
                      'Итого: ${item.totalCost.toStringAsFixed(2)} ₸',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.options.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Опции:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...item.options.map((option) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '• ${option.name} (+${option.selectedPrice} ₸)',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialSection() {
    final cost = _orderDetails!.order.costSummary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Финансы',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                'Стоимость товаров', '${cost.itemsTotal.toStringAsFixed(2)} ₸'),
            if (cost.deliveryPrice > 0)
              _buildInfoRow('Доставка', '${cost.deliveryPrice} ₸'),
            if (cost.serviceFee > 0)
              _buildInfoRow('Сервисный сбор', '${cost.serviceFee} ₸'),
            if (cost.bonusUsed > 0)
              _buildInfoRow('Использовано бонусов', '${cost.bonusUsed} ₸',
                  valueColor: Colors.green),
            const Divider(),
            _buildInfoRow(
              'Итого к оплате',
              '${cost.totalSum.toStringAsFixed(2)} ₸',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistorySection() {
    final history = _orderDetails!.order.statusHistory;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История статусов',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...history.map((status) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildStatusIndicator(status.status),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.statusName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDate(status.timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.orange : (valueColor ?? Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final currentStatus = _orderDetails!.order.currentStatus.status;

    return Column(
      children: [
        // Кнопки для изменения статуса в зависимости от текущего статуса
        if (currentStatus == 0) // Новый заказ
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(1),
                  icon: const Icon(Icons.check),
                  label: const Text('Принять заказ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRejectDialog(),
                  icon: const Icon(Icons.close),
                  label: const Text('Отклонить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          )
        else if (currentStatus == 1) // Принят магазином
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(2),
              icon: const Icon(Icons.inventory),
              label: const Text('Начать сборку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else if (currentStatus == 2) // Сборка
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(3),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Передать в доставку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else if (currentStatus == 3) // Готовится/Доставляется
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(4),
              icon: const Icon(Icons.done_all),
              label: const Text('Заказ доставлен'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else if (currentStatus == 4) // Доставлен
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Заказ завершен',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Кнопка связи с клиентом - всегда доступна
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Связаться с клиентом
            },
            icon: const Icon(Icons.phone),
            label: const Text('Связаться с клиентом'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showOrderActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать заказ'),
              onTap: () {
                Navigator.pop(context);
                // Действие редактирования
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Печать заказа'),
              onTap: () {
                Navigator.pop(context);
                // Действие печати
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                // Действие поделиться
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAmountDialog(OrderItem item) {
    // Проверяем статус заказа
    if (_orderDetails!.order.currentStatus.status != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Редактирование количества доступно только для новых заказов'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController controller = TextEditingController(
      text: item.amount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить количество'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Текущее количество: ${item.amount} ${item.unit}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Новое количество (${item.unit})',
                border: const OutlineInputBorder(),
                suffixText: item.unit,
                helperText: 'Количество не может превышать текущее',
                helperStyle: const TextStyle(color: Colors.orange),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAmount = double.tryParse(controller.text);
              if (newAmount == null || newAmount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Введите корректное количество'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newAmount > item.amount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Количество не может превышать текущее (${item.amount} ${item.unit})'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _updateItemAmount(item, newAmount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateItemAmount(OrderItem item, double newAmount) async {
    try {
      final success = await ApiService.updateOrderItemAmount(
        orderId: widget.orderId.toString(),
        itemRelationId: item.relationId,
        amount: newAmount,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Количество товара обновлено'),
            backgroundColor: Colors.green,
          ),
        );
        // Перезагружаем данные заказа
        _loadOrderDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при обновлении количества'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    // Безопасное форматирование даты без DateFormat
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Обновление статуса заказа
  Future<void> _updateOrderStatus(int newStatus) async {
    try {
      final success = await ApiService.updateOrderStatus(
        widget.orderId.toString(),
        newStatus,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Статус заказа обновлен'),
            backgroundColor: Colors.green,
          ),
        );
        // Перезагружаем данные заказа
        _loadOrderDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при обновлении статуса'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Диалог отклонения заказа
  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить заказ'),
        content: const Text(
          'Вы уверены, что хотите отклонить этот заказ? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Здесь можно добавить специальный статус для отклоненных заказов
              // Пока используем статус -1 или специальный статус для отклонения
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Функция отклонения заказа будет добавлена позже'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }
}
