import 'package:flutter/material.dart';

class OrderTipsScreen extends StatelessWidget {
  const OrderTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подсказки по заказу'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TipCard(
            icon: Icons.timeline,
            title: 'Статусы по шагам',
            text:
                'Рекомендуемый порядок: Принят -> Просмотрен -> Собирается -> Готов к выдаче -> Передан курьеру.',
          ),
          _TipCard(
            icon: Icons.qr_code_scanner,
            title: 'Сканер и количество',
            text:
                'Проверяйте штрихкоды при сборке и сразу корректируйте количество. Перед переводом статуса убедитесь, что количество всех товаров заполнено.',
          ),
          _TipCard(
            icon: Icons.delivery_dining,
            title: 'Передача курьеру',
            text:
                'Перед сменой статуса на "Передан курьеру" сверяйте адрес доставки и наличие контакта клиента.',
          ),
          _TipCard(
            icon: Icons.map_outlined,
            title: 'Геолокация',
            text:
                'На карте: красный маркер - курьер, синий - адрес доставки, оранжевый - бизнес. Если курьер не назначен, уточните назначение в диспетчерской.',
          ),
          _TipCard(
            icon: Icons.support_agent,
            title: 'Если есть проблемы',
            text:
                'При сбоях со скидками или оплатой откройте карточку заказа, обновите данные и передайте номер заказа в поддержку.',
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.orange),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
