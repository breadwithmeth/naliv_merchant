import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Заказ #${order.orderId}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOrderActions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус заказа
            _buildStatusSection(),
            const SizedBox(height: 24),

            // Информация о клиенте
            _buildClientSection(),
            const SizedBox(height: 24),

            // Информация о доставке
            if (order.deliveryAddress != null) ...[
              _buildDeliverySection(),
              const SizedBox(height: 24),
            ],

            // Информация о заказе
            _buildOrderInfoSection(),
            const SizedBox(height: 24),

            // Финансовая информация
            _buildFinancialSection(),
            const SizedBox(height: 32),

            // Кнопки действий
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
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
                _buildStatusIndicator(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.currentStatus.statusName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(order.currentStatus.timestamp),
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

  Widget _buildStatusIndicator() {
    Color color;
    IconData icon;

    switch (order.currentStatus.status) {
      case 1:
        color = Colors.blue;
        icon = Icons.schedule;
        break;
      case 2:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 3:
        color = Colors.orange;
        icon = Icons.local_shipping;
        break;
      case 4:
        color = Colors.purple;
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
                        order.user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'ID: ${order.user.userId}',
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
    if (order.deliveryAddress == null) return const SizedBox.shrink();

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
                        order.deliveryAddress!.address,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (order.deliveryAddress!.details?.apartment != null)
                        Text(
                          'Кв. ${order.deliveryAddress!.details!.apartment}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      if (order.deliveryAddress!.details?.entrance != null)
                        Text(
                          'Подъезд ${order.deliveryAddress!.details!.entrance}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      if (order.deliveryAddress!.details?.floor != null)
                        Text(
                          'Этаж ${order.deliveryAddress!.details!.floor}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      if (order.deliveryAddress!.details?.comment != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.deliveryAddress!.details!.comment!,
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

  Widget _buildOrderInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о заказе',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('UUID заказа', order.orderUuid),
            _buildInfoRow('Тип доставки',
                order.deliveryType == 'delivery' ? 'Доставка' : 'Самовывоз'),
            _buildInfoRow(
                'Способ оплаты', order.paymentType?.name ?? 'Не указан'),
            _buildInfoRow('Количество товаров', '${order.itemsCount} шт.'),
            _buildInfoRow(
                'Время доставки',
                order.deliveryDate != null
                    ? _formatDate(order.deliveryDate!)
                    : 'Дата не указана'),
            _buildInfoRow('Время создания', _formatDate(order.logTimestamp)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSection() {
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
            _buildInfoRow('Стоимость товаров', '${order.cost} ₸'),
            if (order.deliveryPrice > 0)
              _buildInfoRow('Доставка', '${order.deliveryPrice} ₸'),
            if (order.serviceFee > 0)
              _buildInfoRow('Сервисный сбор', '${order.serviceFee} ₸'),
            if (order.bonus > 0)
              _buildInfoRow('Бонусы', '${order.bonus} ₸',
                  valueColor: Colors.green),
            const Divider(),
            _buildInfoRow(
              'Итого к оплате',
              '${order.totalCost} ₸',
              isTotal: true,
            ),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Принять заказ
                },
                icon: const Icon(Icons.check),
                label: const Text('Принять'),
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
                onPressed: () {
                  // Отклонить заказ
                },
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
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Связаться с клиентом
            },
            icon: const Icon(Icons.phone),
            label: const Text('Связаться с клиентом'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
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

  String _formatDate(DateTime date) {
    // Безопасное форматирование даты без DateFormat
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
