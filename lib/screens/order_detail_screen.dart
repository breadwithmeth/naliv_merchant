import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'courier_locations_screen.dart';
import 'discount_help_screen.dart';
import 'order_tips_screen.dart';

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
  final FocusNode _barcodeFocusNode = FocusNode();
  bool _showLiveScanner = false;
  final MobileScannerController _scannerController = MobileScannerController();
  final Map<int, double> _originalAmounts =
      {}; // relationId -> исходное количество
  final Map<int, double> _updatedAmounts =
      {}; // relationId -> обновленное количество
  final Set<int> _confirmedItems = {}; // relationId подтвержденных
  bool _autoSeenAttempted = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
    _barcodeFocusNode.addListener(() {
      if (_barcodeFocusNode.hasFocus) {
        // Прячем виртуальную клавиатуру, оставляя фокус для аппаратного ввода
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _barcodeFocusNode.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      OrderDetails? details =
          await ApiService.getOrderDetails(widget.orderId.toString());

      // Принятый заказ автоматически помечаем как "Просмотрен" при первом открытии.
      if (details != null &&
          details.order.currentStatus.status == 1 &&
          !_autoSeenAttempted) {
        _autoSeenAttempted = true;
        final seenMarked =
            await ApiService.markOrderSeen(widget.orderId.toString());
        if (seenMarked) {
          details =
              await ApiService.getOrderDetails(widget.orderId.toString()) ??
                  details;
        }
      }

      setState(() {
        _orderDetails = details;
        _isLoading = false;
        if (details == null) {
          _error = 'Не удалось загрузить детали заказа';
        }
        if (details != null) {
          for (final item in details.order.items) {
            _originalAmounts.putIfAbsent(item.relationId, () => item.amount);
          }
          // чистим удалённые
          final ids = details.order.items.map((e) => e.relationId).toSet();
          _originalAmounts.removeWhere((k, v) => !ids.contains(k));
          _updatedAmounts.removeWhere((k, v) => !ids.contains(k));
          _confirmedItems.removeWhere((k) => !ids.contains(k));
          // восстанавливаем подтверждение для уже изменённых ранее товаров
          for (final item in details.order.items) {
            if (_updatedAmounts.containsKey(item.relationId)) {
              _confirmedItems.add(item.relationId);
            }
          }
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
    setState(() => _showLiveScanner = true);
  }

  void _onManualBarcodeSubmit() {
    final code = _barcodeCtrl.text.trim();
    if (code.isEmpty) return;
    _findItemByBarcodeAndEdit(code);
    // очищаем поле после обработки
    _barcodeCtrl.clear();
  }

  void _findItemByBarcodeAndEdit(String barcode) {
    if (_orderDetails == null) return;
    final items = _orderDetails!.order.items;
    OrderItem? match;
    final scanned = barcode.trim();
    for (final it in items) {
      // barcode может приходить как CSV: "code1,code2,code3"
      final raw = it.barcode ?? '';
      final barcodes = raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();

      if (barcodes.contains(scanned)) {
        match = it;
        break;
      }
      // на всякий случай оставим поиск по названию
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

  bool _hasIncompleteAmounts() {
    final items = _orderDetails?.order.items;
    if (items == null || items.isEmpty) return true;
    for (final it in items) {
      if (it.amount <= 0) return true;
    }
    return false;
  }

  bool _isErrorStatus(int status) {
    return status == 6 || status == 67 || status == 68;
  }

  bool _isOrderBlockedByStatus(int status) {
    return status == 0 || status == 66 || _isErrorStatus(status);
  }

  List<int> _statusFlow() {
    return const [
      0,
      1,
      11,
      12,
      2,
      21,
      3,
      31,
      4,
      5,
      50,
      51,
      52,
      6,
      60,
      61,
      66,
      67,
      68,
      7,
      71,
    ];
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.blue;
      case 11:
        return Colors.indigo;
      case 12:
        return Colors.orange;
      case 2:
        return Colors.orange;
      case 21:
        return Colors.deepOrange;
      case 3:
        return Colors.purple;
      case 31:
        return Colors.teal;
      case 4:
        return Colors.green;
      case 5:
      case 50:
      case 51:
      case 52:
        return Colors.red;
      case 6:
      case 68:
        return Colors.deepPurple;
      case 60:
      case 61:
        return Colors.amber;
      case 66:
      case 67:
        return Colors.redAccent;
      case 7:
      case 71:
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderSummaryHeader() {
    final currentStatus = _orderDetails!.order.currentStatus;
    final total = _orderDetails!.order.costSummary.totalSum;
    final itemsCount = _orderDetails!.order.items.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Заказ #${widget.orderId}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(currentStatus.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    currentStatus.statusName,
                    style: TextStyle(
                      color: _statusColor(currentStatus.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip(
                    Icons.shopping_bag_outlined, '$itemsCount тов.'),
                _buildQuickChip(
                    Icons.payments_outlined, '${total.toStringAsFixed(0)} ₸'),
                _buildQuickChip(
                    Icons.schedule, _formatDate(currentStatus.timestamp)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgress(int currentStatus) {
    final flow = _statusFlow();
    final currentIndex = flow.indexOf(currentStatus);

    if (currentIndex < 0) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(flow.length, (index) {
          final status = flow[index];
          final isDone = index < currentIndex;
          final isCurrent = index == currentIndex;
          final color =
              isCurrent || isDone ? _statusColor(status) : Colors.grey.shade300;

          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      size: isDone ? 16 : 10,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 72,
                    child: Text(
                      OrderStatusCatalog.resolve(status),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrent ? color : Colors.grey.shade600,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (index != flow.length - 1)
                Container(
                  width: 20,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 24),
                  color: index < currentIndex
                      ? _statusColor(flow[index + 1])
                      : Colors.grey.shade300,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    final size = MediaQuery.of(context).size;
    final isSmall =
        size.width < 380 || size.height < 700; // эвристика маленького экрана
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
      padding: EdgeInsets.all(isSmall ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummaryHeader(),
          SizedBox(height: isSmall ? 8 : 12),

          _buildScannerBar(),
          SizedBox(height: isSmall ? 8 : 12),

          // Товары в заказе
          _buildItemsSection(),
          const SizedBox(height: 12),
          // Кнопка помощи со скидками (под списком товаров)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderTipsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.lightbulb_outline, color: Colors.orange),
              label: const Text(
                'Подсказки по обработке заказа',
                style: TextStyle(color: Colors.orange),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DiscountHelpScreen(orderId: widget.orderId.toString()),
                  ),
                );
              },
              icon: const Icon(Icons.help_outline, color: Colors.orange),
              label: const Text(
                'Помогите, у меня не работают скидки!',
                style: TextStyle(color: Colors.orange),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(height: isSmall ? 16 : 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourierLocationsScreen(
                      orderId: widget.orderId.toString(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.my_location, color: Colors.orange),
              label: const Text(
                'Геолокация курьера',
                style: TextStyle(color: Colors.orange),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(height: isSmall ? 16 : 24),

          // Статус заказа
          _buildStatusSection(),
          SizedBox(height: isSmall ? 16 : 24),

          // Финансовая информация
          _buildFinancialSection(),
          SizedBox(height: isSmall ? 16 : 24),
          _buildExtraSection(),
          SizedBox(height: isSmall ? 16 : 24),

          // Информация о клиенте
          _buildClientSection(),
          SizedBox(height: isSmall ? 16 : 24),

          // Информация о доставке
          if (_orderDetails!.order.deliveryAddress != null) ...[
            _buildDeliverySection(),
            SizedBox(height: isSmall ? 16 : 24),
          ],

          // История статусов
          _buildStatusHistorySection(),
          SizedBox(height: isSmall ? 20 : 32),

          // Кнопки действий
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildScannerBar() {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 380 || size.height < 700;
    final status = _orderDetails?.order.currentStatus.status;
    final canEdit = status != null &&
        !_isOrderBlockedByStatus(status) &&
        (status == 1 || status == 11);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.orange),
                SizedBox(width: isSmall ? 6 : 8),
                Text(
                  'Сканер штрихкодов',
                  style: TextStyle(
                    fontSize: isSmall ? 14 : 16,
                    fontWeight: FontWeight.w600,
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
                    child: const Text('Только просмотр',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
              ],
            ),
            SizedBox(height: isSmall ? 6 : 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeCtrl,
                    focusNode: _barcodeFocusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Штрихкод',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: isSmall ? 6 : 8),
                    ),
                    onTap: () =>
                        SystemChannels.textInput.invokeMethod('TextInput.hide'),
                    onSubmitted: (_) => _onManualBarcodeSubmit(),
                  ),
                ),
                SizedBox(width: isSmall ? 4 : 6),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _onManualBarcodeSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[50],
                      foregroundColor: Colors.black54,
                      padding:
                          EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10),
                    ),
                    child: const Icon(Icons.search, size: 18),
                  ),
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
    final isSmall = MediaQuery.of(context).size.width < 380 ||
        MediaQuery.of(context).size.height < 700;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статус заказа',
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmall ? 8 : 12),
            Row(
              children: [
                _buildStatusIndicator(status.status),
                SizedBox(width: isSmall ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.statusName,
                        style: TextStyle(
                          fontSize: isSmall ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(status.timestamp),
                        style: TextStyle(
                          fontSize: isSmall ? 12 : 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusProgress(status.status),
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
      case 11:
        color = Colors.indigo;
        icon = Icons.visibility;
        break;
      case 12:
        color = Colors.orange;
        icon = Icons.inventory_2;
        break;
      case 2:
        color = Colors.orange;
        icon = Icons.inventory;
        break;
      case 21:
        color = Colors.deepOrange;
        icon = Icons.local_shipping;
        break;
      case 3:
        color = Colors.purple;
        icon = Icons.local_shipping;
        break;
      case 31:
        color = Colors.teal;
        icon = Icons.near_me;
        break;
      case 4:
        color = Colors.green;
        icon = Icons.done_all;
        break;
      case 5:
      case 50:
      case 51:
      case 52:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 6:
      case 68:
        color = Colors.deepPurple;
        icon = Icons.error_outline;
        break;
      case 60:
      case 61:
        color = Colors.amber;
        icon = Icons.payments;
        break;
      case 66:
      case 67:
        color = Colors.redAccent;
        icon = Icons.money_off;
        break;
      case 7:
      case 71:
        color = Colors.blueGrey;
        icon = Icons.replay;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    final isSmall = MediaQuery.of(context).size.width < 380 ||
        MediaQuery.of(context).size.height < 700;
    return Container(
      width: isSmall ? 40 : 48,
      height: isSmall ? 40 : 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: isSmall ? 20 : 24,
      ),
    );
  }

  Widget _buildClientSection() {
    final user = _orderDetails!.order.user;
    final isSmall = MediaQuery.of(context).size.width < 380 ||
        MediaQuery.of(context).size.height < 700;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Клиент',
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmall ? 8 : 12),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: isSmall ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: isSmall ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ID: ${user.userId}',
                        style: TextStyle(
                          fontSize: isSmall ? 12 : 14,
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
    final isSmall = MediaQuery.of(context).size.width < 380 ||
        MediaQuery.of(context).size.height < 700;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Доставка',
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmall ? 8 : 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.orange),
                SizedBox(width: isSmall ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.address,
                        style: TextStyle(
                          fontSize: isSmall ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (address.details?.apartment?.isNotEmpty == true)
                        Text(
                          'Кв. ${address.details!.apartment}',
                          style: TextStyle(
                            fontSize: isSmall ? 12 : 14,
                            color: Colors.grey,
                          ),
                        ),
                      if (address.details?.entrance?.isNotEmpty == true)
                        Text(
                          'Подъезд ${address.details!.entrance}',
                          style: TextStyle(
                            fontSize: isSmall ? 12 : 14,
                            color: Colors.grey,
                          ),
                        ),
                      if (address.details?.floor?.isNotEmpty == true)
                        Text(
                          'Этаж ${address.details!.floor}',
                          style: TextStyle(
                            fontSize: isSmall ? 12 : 14,
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
                            style: TextStyle(
                              fontSize: isSmall ? 12 : 14,
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
    final status = _orderDetails!.order.currentStatus.status;
    final canEdit =
        !_isOrderBlockedByStatus(status) && (status == 1 || status == 11);
    final isSmall = MediaQuery.of(context).size.width < 380 ||
        MediaQuery.of(context).size.height < 700;
    final remaining = items.where((it) => it.amount <= 0).length;
    final sortedItems = [
      ...items.where((it) => it.amount <= 0),
      ...items.where((it) => it.amount > 0),
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Товары (${items.length})',
                    style: TextStyle(
                      fontSize: isSmall ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!canEdit)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Редакт. недоступно',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_hasIncompleteAmounts())
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orangeAccent),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Укажите количество для всех товаров (не может быть 0) перед изменением статуса. Осталось: $remaining',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: isSmall ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ...sortedItems.map((item) => _buildItemCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(OrderItem item) {
    final isSmall = MediaQuery.of(context).size.width < 380 ||
        MediaQuery.of(context).size.height < 700;
    final original = _originalAmounts[item.relationId];
    final confirmed = _confirmedItems.contains(item.relationId);
    final changed = original != null && original != item.amount;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isSmall ? 10 : 12),
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
                    width: isSmall ? 48 : 60,
                    height: isSmall ? 48 : 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: isSmall ? 48 : 60,
                        height: isSmall ? 48 : 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              SizedBox(width: isSmall ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.barcode ?? 'Штрихкод не указан',
                      style: TextStyle(
                        fontSize: isSmall ? 9 : 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.amount} ${item.unit} × ${item.price} ₸',
                            style: TextStyle(
                              fontSize: isSmall ? 12 : 14,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          tooltip: 'Сканировать для этого товара',
                          onPressed: _startBarcodeScan,
                        ),
                        if (!_isOrderBlockedByStatus(
                                _orderDetails!.order.currentStatus.status) &&
                            (_orderDetails!.order.currentStatus.status == 1 ||
                                _orderDetails!.order.currentStatus.status ==
                                    11))
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showEditAmountDialog(item),
                            tooltip: 'Изменить количество',
                          )
                        else
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.edit,
                                size: 18, color: Colors.grey),
                            onPressed: null,
                            tooltip:
                                'Редактирование недоступно для данного статуса заказа',
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (original != null)
                          Text(
                            'Исходное: ${original.toStringAsFixed(2)} ${item.unit}',
                            style: TextStyle(
                              fontSize: isSmall ? 10 : 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        Text(
                          'Текущее: ${item.amount.toStringAsFixed(2)} ${item.unit}' +
                              (changed ? ' (изменено)' : ''),
                          style: TextStyle(
                            fontSize: isSmall ? 11 : 13,
                            fontWeight:
                                changed ? FontWeight.w600 : FontWeight.w400,
                            color:
                                changed ? Colors.orange[800] : Colors.black87,
                          ),
                        ),
                        Text(
                          'Итого: ${item.totalCost.toStringAsFixed(2)} ₸',
                          style: TextStyle(
                            fontSize: isSmall ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        if (!confirmed)
                          Text(
                            'Не подтверждено',
                            style: TextStyle(
                              fontSize: isSmall ? 10 : 11,
                              color: Colors.red[400],
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (changed)
                          Text(
                            'Подтверждено',
                            style: TextStyle(
                              fontSize: isSmall ? 10 : 11,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.options.isNotEmpty) ...[
            SizedBox(height: isSmall ? 6 : 8),
            Text(
              'Опции:',
              style: TextStyle(
                fontSize: isSmall ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            ...item.options.map((option) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    '• ${option.name} (+${option.selectedPrice} ₸)',
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 14,
                      color: Colors.grey,
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialSection() {
    final cost = _orderDetails!.order.costSummary;
    final isSmall = MediaQuery.of(context).size.width < 380 ||
        MediaQuery.of(context).size.height < 700;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Финансы',
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(_orderDetails?.order.paymentType?.name ?? '')
              ],
            ),
            SizedBox(height: isSmall ? 8 : 12),
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

  Widget _buildExtraSection() {
    final isSmall = MediaQuery.of(context).size.width < 380 ||
        MediaQuery.of(context).size.height < 700;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Комментарии и дополнительные сведения',
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmall ? 8 : 12),
            Text(
              _orderDetails!.order.extra ?? 'Нет дополнительных сведений',
              style: TextStyle(
                fontSize: isSmall ? 12 : 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHistorySection() {
    final history = _orderDetails!.order.statusHistory;
    final isSmall = MediaQuery.of(context).size.width < 380 ||
        MediaQuery.of(context).size.height < 700;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'История статусов',
              style: TextStyle(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isSmall ? 8 : 12),
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
                      SizedBox(width: isSmall ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.statusName,
                              style: TextStyle(
                                fontSize: isSmall ? 12 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatDate(status.timestamp),
                              style: TextStyle(
                                fontSize: isSmall ? 11 : 12,
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
    final isSmall = MediaQuery.of(context).size.width < 380 ||
        MediaQuery.of(context).size.height < 700;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? (isSmall ? 14 : 16) : (isSmall ? 12 : 14),
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? (isSmall ? 14 : 16) : (isSmall ? 12 : 14),
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
    final blocked = _hasIncompleteAmounts();
    final isLocked = _isOrderBlockedByStatus(currentStatus);

    return Column(
      children: [
        if (isLocked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Заказ заблокирован для обработки в текущем статусе',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Кнопки для изменения статуса в зависимости от текущего статуса
        if (currentStatus == 0) // Новый заказ (авто -> Просмотрен)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (blocked || isLocked)
                      ? null
                      : () => _updateOrderStatus(1),
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
        else if (currentStatus == 1 ||
            currentStatus == 11) // Принят / Просмотрен
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (blocked || isLocked) ? null : () => _updateOrderStatus(12),
              icon: const Icon(Icons.inventory),
              label: const Text('Начать сборку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else if (currentStatus == 12) // Сборка
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (blocked || isLocked) ? null : () => _updateOrderStatus(2),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Готов к выдаче'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else if (currentStatus == 2) // Готов
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (blocked || isLocked) ? null : () => _updateOrderStatus(21),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Передать курьеру'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else if (currentStatus == 21)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepOrange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.deepOrange[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.local_shipping, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text(
                  'Заказ передан курьеру',
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
    if (_isOrderBlockedByStatus(_orderDetails!.order.currentStatus.status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ заблокирован в текущем статусе'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Проверяем статус заказа
    if (_orderDetails!.order.currentStatus.status != 1 &&
        _orderDetails!.order.currentStatus.status != 11) {
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
              keyboardType: TextInputType.none,
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
        setState(() {
          _updatedAmounts[item.relationId] = newAmount;
          _confirmedItems
              .add(item.relationId); // автоподтверждение при изменении
        });
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
    if (_isOrderBlockedByStatus(_orderDetails!.order.currentStatus.status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заказ заблокирован для смены статуса'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_hasIncompleteAmounts()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала заполните количество для всех товаров'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
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
