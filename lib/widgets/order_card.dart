import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок заказа
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Заказ #${order.orderId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(order.currentStatus),
                ],
              ),
              const SizedBox(height: 8),

              // Информация о клиенте
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    order.user.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Адрес доставки
              if (order.deliveryAddress != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.deliveryAddress!.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Время доставки
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    order.deliveryDate != null
                        ? _formatDate(order.deliveryDate!)
                        : 'Дата не указана',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Нижняя секция с суммой и количеством товаров
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           'Товаров: ${order.itemsCount}',
              //           style: const TextStyle(
              //             fontSize: 14,
              //             color: Colors.grey,
              //           ),
              //         ),
              //         Text(
              //           order.paymentType?.name ?? 'Способ оплаты не указан',
              //           style: const TextStyle(
              //             fontSize: 12,
              //             color: Colors.grey,
              //           ),
              //         ),
              //       ],
              //     ),
              //     Column(
              //       crossAxisAlignment: CrossAxisAlignment.end,
              //       children: [
              //         Text(
              //           '${order.totalCost} ₸',
              //           style: const TextStyle(
              //             fontSize: 18,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.orange,
              //           ),
              //         ),
              //         if (order.deliveryPrice > 0)
              //           Text(
              //             'Доставка: ${order.deliveryPrice} ₸',
              //             style: const TextStyle(
              //               fontSize: 12,
              //               color: Colors.grey,
              //             ),
              //           ),
              //       ],
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status.status) {
      case 1:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        break;
      case 2:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        break;
      case 3:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        break;
      case 4:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade700;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.statusName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Безопасное форматирование даты без DateFormat
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
