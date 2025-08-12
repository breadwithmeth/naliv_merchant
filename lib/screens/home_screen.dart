import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/token_manager.dart';
import '../services/api_service.dart';
import '../widgets/order_card.dart';
import '../screens/order_detail_screen.dart';
import 'login_screen.dart';
import 'courier_reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _currentToken;
  List<Order> _orders = [];
  bool _isLoadingOrders = false;
  String? _errorMessage;
  int _currentPage = 1;
  Timer? _refreshTimer; // таймер автообновления

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadOrders();
    _startAutoRefresh(); // запуск автообновления
  }

  Future<void> _loadToken() async {
    final token = await TokenManager.getToken();
    setState(() {
      _currentToken = token;
    });
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoadingOrders = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getOrders(
        page: _currentPage,
        limit: 10,
        dateFrom: '2024-01-01',
      );

      if (response != null && response['success'] == true) {
        final ordersData = response['data']['orders'] as List;

        setState(() {
          _orders =
              ordersData.map((orderJson) => Order.fromJson(orderJson)).toList();
          _isLoadingOrders = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Не удалось загрузить заказы';
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки: $e';
        _isLoadingOrders = false;
      });
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _loadOrders();
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content:
            const Text('Вы уверены, что хотите выйти? Токен будет удален.'),
        actions: [
          TextButton(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Выйти'),
            onPressed: () async {
              await TokenManager.removeToken();
              if (mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказы'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.insert_chart_outlined),
            tooltip: 'Отчет курьеры',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CourierReportsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTokenDialog();
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.info, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingOrders && _orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет заказов',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Заказы будут отображаться здесь',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _orders.length + (_isLoadingOrders ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _orders.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return OrderCard(
          order: _orders[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  OrderDetailScreen(orderId: _orders[index].orderId),
            ),
          ).then((_) => _loadOrders()), // обновить список после возврата
        );
      },
    );
  }

  void _showTokenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о токене'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Текущий токен:'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentToken ?? 'Токен не найден',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: _loadToken,
            child: const Text('Обновить'),
          ),
        ],
      ),
    );
  }
}
