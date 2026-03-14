import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/token_manager.dart';

class ApiService {
  //static const String baseUrl = 'https://njt25.naliv.kz';
  static const String baseUrl = 'http://localhost:3009';

  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Получение списка заказов
  static Future<Map<String, dynamic>?> getOrders({
    int page = 1,
    int limit = 10,
    String? dateFrom,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (dateFrom != null) 'date_from': dateFrom,
      };

      final uri = Uri.parse('$baseUrl/api/business/orders')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        print(response.body);
        return json.decode(response.body);
      } else {
        print('Failed to load orders: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching orders: $e');
      return null;
    }
  }

  /// Получение деталей заказа
  static Future<OrderDetails?> getOrderDetails(String orderId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/business/orders/$orderId');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        if (data['success'] == true && data['data'] != null) {
          return OrderDetails.fromJson(data['data']);
        }
        return null;
      } else {
        print('Failed to load order details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching order details: $e');
      return null;
    }
  }

  /// Обновление статуса заказа
  static Future<bool> updateOrderStatus(String orderId, int status) async {
    final transitionPath = _statusTransitionPath(status);
    if (transitionPath == null) {
      // Для обратной совместимости: старый универсальный эндпоинт.
      return _updateOrderStatusLegacy(orderId, status);
    }

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
          '$baseUrl/api/businesses/orders/$orderId/status/$transitionPath');

      final response = await http.patch(uri, headers: headers);

      print('Response status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  /// Автоматическая отметка "Просмотрен" после статуса "Принят".
  static Future<bool> markOrderSeen(String orderId) async {
    return updateOrderStatus(orderId, 11);
  }

  static String? _statusTransitionPath(int status) {
    switch (status) {
      case 1:
        return 'accepted';
      case 11:
        return 'seen';
      case 12:
        return 'collecting';
      case 2:
        return 'ready';
      case 21:
        return 'handed-to-courier';
      default:
        return null;
    }
  }

  static Future<bool> _updateOrderStatusLegacy(
      String orderId, int status) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/business/orders/$orderId/status');

      final response = await http.patch(
        uri,
        headers: headers,
        body: json.encode({'status': status}),
      );

      print('Response status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  /// Изменение количества товара в заказе
  static Future<bool> updateOrderItemAmount({
    required String orderId,
    required int itemRelationId,
    required double amount,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(
          '$baseUrl/api/business/orders/$orderId/items/$itemRelationId');

      final response = await http.patch(
        uri,
        headers: headers,
        body: json.encode({'amount': amount}),
      );

      print('Response status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating order item amount: $e');
      return false;
    }
  }

  /// Отчет по курьерам за период
  static Future<dynamic> getCourierReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      String _fmt(DateTime d) {
        String two(int v) => v.toString().padLeft(2, '0');
        return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
      }

      final queryParams = {
        'start_date': _fmt(startDate),
        'end_date': _fmt(endDate),
      };
      final uri = Uri.parse('$baseUrl/api/businesses/reports/couriers')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? data; // возвращаем полезную часть или всё
      } else {
        print('Failed to load courier reports: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching courier reports: $e');
      return null;
    }
  }

  /// Локации курьеров
  static Future<CourierLocationsResult> getCourierLocations(
      {String? orderId}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl/api/businesses/couriers/locations')
          .replace(queryParameters: {
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
      });
      final response = await http.get(uri, headers: headers);
      print(response.body);

      final Map<String, dynamic>? payload =
          response.body.isNotEmpty ? json.decode(response.body) : null;

      if (payload == null) {
        return CourierLocationsResult(
          success: false,
          statusCode: response.statusCode,
          errorMessage: 'Пустой ответ сервера',
          locations: const [],
        );
      }

      // Сервер может вернуть success=false со statusCode=409, если курьер не назначен.
      if (payload['success'] == false) {
        final error = payload['error'];
        final errorMessage = error is Map
            ? (error['message']?.toString() ?? payload['message']?.toString())
            : payload['message']?.toString();
        final int? errorStatusCode = error is Map
            ? _toIntOrNull(error['statusCode'])
            : _toIntOrNull(payload['statusCode']);

        return CourierLocationsResult(
          success: false,
          statusCode: errorStatusCode ?? response.statusCode,
          errorMessage: errorMessage ?? 'Не удалось получить локации курьеров',
          locations: const [],
          raw: payload,
        );
      }

      final dynamic data = payload['data'] ?? payload;
      final locations = _extractCourierLocations(data);

      return CourierLocationsResult(
        success: true,
        statusCode: response.statusCode,
        message: payload['message']?.toString(),
        locations: locations,
        raw: payload,
      );
    } catch (e) {
      print('Error fetching courier locations: $e');
      return CourierLocationsResult(
        success: false,
        errorMessage: 'Ошибка загрузки: $e',
        locations: const [],
      );
    }
  }

  static int? _toIntOrNull(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static List<CourierLocationPoint> _extractCourierLocations(dynamic data) {
    final result = <CourierLocationPoint>[];

    // Новый контракт: data.couriers[].location.{lat,lon}
    if (data is Map && data['couriers'] is List) {
      for (final courier in data['couriers']) {
        if (courier is! Map) continue;

        final location = courier['location'];
        final lat = _toDoubleOrNull(
            location is Map ? location['lat'] : courier['latitude']);
        final lon = _toDoubleOrNull(
            location is Map ? location['lon'] : courier['longitude']);

        if (lat == null || lon == null) continue;

        result.add(
          CourierLocationPoint(
            courierId: _toIntOrNull(courier['courier_id'] ?? courier['id']),
            courierName: courier['name']?.toString(),
            courierLogin: courier['login']?.toString(),
            lat: lat,
            lon: lon,
            updatedAt: location is Map
                ? location['updated_at']?.toString()
                : courier['updated_at']?.toString(),
            raw: Map<String, dynamic>.from(courier),
          ),
        );
      }
      if (result.isNotEmpty) return result;
    }

    // Обратная совместимость со старыми/плоскими ответами.
    final candidates = <dynamic>[];
    if (data is List) {
      candidates.addAll(data);
    } else if (data is Map) {
      if (data['locations'] is List) candidates.addAll(data['locations']);
      if (data['items'] is List) candidates.addAll(data['items']);
      if (data['data'] is List) candidates.addAll(data['data']);
      candidates.add(data);
    }

    for (final item in candidates) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final lat = _toDoubleOrNull(map['latitude'] ?? map['lat']);
      final lon = _toDoubleOrNull(map['longitude'] ?? map['lon'] ?? map['lng']);
      if (lat == null || lon == null) continue;

      final courier = map['courier'];

      result.add(
        CourierLocationPoint(
          courierId: _toIntOrNull(map['courier_id'] ??
              map['id'] ??
              (courier is Map ? courier['id'] : null)),
          courierName: courier is Map
              ? courier['name']?.toString()
              : map['courier_name']?.toString(),
          courierLogin: courier is Map ? courier['login']?.toString() : null,
          lat: lat,
          lon: lon,
          updatedAt: map['updated_at']?.toString(),
          raw: map,
        ),
      );
    }

    return result;
  }
}

class CourierLocationsResult {
  final bool success;
  final int? statusCode;
  final String? message;
  final String? errorMessage;
  final List<CourierLocationPoint> locations;
  final Map<String, dynamic>? raw;

  const CourierLocationsResult({
    required this.success,
    required this.locations,
    this.statusCode,
    this.message,
    this.errorMessage,
    this.raw,
  });

  bool get isCourierNotAssigned => statusCode == 409;
}

class CourierLocationPoint {
  final int? courierId;
  final String? courierName;
  final String? courierLogin;
  final double lat;
  final double lon;
  final String? updatedAt;
  final Map<String, dynamic> raw;

  const CourierLocationPoint({
    required this.lat,
    required this.lon,
    required this.raw,
    this.courierId,
    this.courierName,
    this.courierLogin,
    this.updatedAt,
  });
}

class OrderStatusCatalog {
  static const Map<int, String> names = {
    0: 'Новый заказ',
    1: 'Принят магазином',
    11: 'Просмотрен',
    12: 'Собирается',
    2: 'Готов к выдаче',
    21: 'Передан курьеру',
    3: 'Доставляется',
    31: 'Курьер рядом',
    4: 'Доставлен',
    5: 'Отменен',
    50: 'Отменен пользователем',
    51: 'Отменен магазином',
    52: 'Отменен: нет в наличии',
    6: 'Ошибка платежа',
    60: 'Ожидает оплаты',
    61: 'Оплата в обработке',
    66: 'Не оплачен',
    7: 'Возврат начат',
    71: 'Возврат завершен',
  };

  static String resolve(int status) {
    return names[status] ?? 'Статус не указан';
  }
}

/// Модель заказа
class Order {
  final int orderId;
  final String orderUuid;
  final User user;
  final DeliveryAddress? deliveryAddress;
  final String deliveryType;
  final int deliveryPrice;
  final int cost;
  final int serviceFee;
  final int totalCost;
  final PaymentType? paymentType;
  final OrderStatus currentStatus;
  final int itemsCount;
  final DateTime? deliveryDate;
  final DateTime logTimestamp;
  final int bonus;
  final String? extra;

  Order({
    required this.orderId,
    required this.orderUuid,
    required this.user,
    this.deliveryAddress,
    required this.deliveryType,
    required this.deliveryPrice,
    required this.cost,
    required this.serviceFee,
    required this.totalCost,
    this.paymentType,
    required this.currentStatus,
    required this.itemsCount,
    this.deliveryDate,
    required this.logTimestamp,
    required this.bonus,
    this.extra,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'] ?? 0,
      orderUuid: json['order_uuid'] ?? '',
      user: User.fromJson(json['user']),
      deliveryAddress: json['delivery_address'] != null
          ? DeliveryAddress.fromJson(json['delivery_address'])
          : null,
      deliveryType: json['delivery_type'] ?? 'Не указан',
      deliveryPrice: json['delivery_price'] ?? 0,
      cost: (json['cost'] is String)
          ? double.tryParse(json['cost'])?.toInt() ?? 0
          : (json['cost'] ?? 0).toInt(),
      serviceFee: json['service_fee'] ?? 0,
      totalCost: (json['total_cost'] is String)
          ? double.tryParse(json['total_cost'])?.toInt() ?? 0
          : (json['total_cost'] ?? 0).toInt(),
      paymentType: json['payment_type'] != null
          ? PaymentType.fromJson(json['payment_type'])
          : null,
      currentStatus: OrderStatus.fromJson(json['current_status']),
      itemsCount: int.tryParse(json['items_count']?.toString() ?? '0') ?? 0,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.tryParse(json['delivery_date'])
          : null,
      logTimestamp:
          DateTime.tryParse(json['log_timestamp'] ?? '') ?? DateTime.now(),
      bonus: json['bonus'] ?? 0,
      extra: json['extra'],
    );
  }
}

class User {
  final int userId;
  final String name;

  User({required this.userId, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? 'Не указано',
    );
  }
}

class DeliveryAddress {
  final int addressId;
  final String name;
  final String address;
  final Coordinates coordinates;
  final AddressDetails? details;

  DeliveryAddress({
    required this.addressId,
    required this.name,
    required this.address,
    required this.coordinates,
    this.details,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      addressId: json['address_id'] ?? 0,
      name: json['name'] ?? 'Адрес не указан',
      address: json['address'] ?? 'Адрес не указан',
      coordinates: Coordinates.fromJson(json['coordinates'] ?? {}),
      details: json['details'] != null
          ? AddressDetails.fromJson(json['details'])
          : null,
    );
  }
}

class Coordinates {
  final double lat;
  final double lon;

  Coordinates({required this.lat, required this.lon});

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lon: (json['lon'] ?? 0.0).toDouble(),
    );
  }
}

class AddressDetails {
  final String? apartment;
  final String? entrance;
  final String? floor;
  final String? comment;

  AddressDetails({
    this.apartment,
    this.entrance,
    this.floor,
    this.comment,
  });

  factory AddressDetails.fromJson(Map<String, dynamic> json) {
    return AddressDetails(
      apartment: json['apartment'],
      entrance: json['entrance'],
      floor: json['floor'],
      comment: json['comment'],
    );
  }
}

class PaymentType {
  final int paymentTypeId;
  final String name;

  PaymentType({required this.paymentTypeId, required this.name});

  factory PaymentType.fromJson(Map<String, dynamic> json) {
    return PaymentType(
      paymentTypeId: json['payment_type_id'] ?? 0,
      name: json['name'] ?? 'Не указан',
    );
  }
}

class OrderStatus {
  final int status;
  final String statusName;
  final DateTime timestamp;
  final int isCanceled;

  OrderStatus({
    required this.status,
    required this.statusName,
    required this.timestamp,
    required this.isCanceled,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    final status = json['status'] ?? 0;
    return OrderStatus(
      status: status,
      statusName:
          json['status_name']?.toString() ?? OrderStatusCatalog.resolve(status),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isCanceled: json['isCanceled'] ?? 0,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
      hasNext: json['hasNext'],
      hasPrev: json['hasPrev'],
    );
  }
}

/// Детальная информация о заказе
class OrderDetails {
  final OrderDetail order;
  final Business business;

  OrderDetails({
    required this.order,
    required this.business,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      order: OrderDetail.fromJson(json['order']),
      business: Business.fromJson(json['business']),
    );
  }
}

class OrderDetail {
  final int orderId;
  final String orderUuid;
  final User user;
  final DeliveryAddress? deliveryAddress;
  final String deliveryType;
  final DateTime? deliveryDate;
  final PaymentType? paymentType;
  final OrderStatus currentStatus;
  final List<StatusHistory> statusHistory;
  final List<OrderItem> items;
  final double itemsCount;
  final CostSummary costSummary;
  final String? extra;
  final DateTime createdAt;
  final int bonus;

  OrderDetail({
    required this.orderId,
    required this.orderUuid,
    required this.user,
    this.deliveryAddress,
    required this.deliveryType,
    this.deliveryDate,
    this.paymentType,
    required this.currentStatus,
    required this.statusHistory,
    required this.items,
    required this.itemsCount,
    required this.costSummary,
    this.extra,
    required this.createdAt,
    required this.bonus,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      orderId: json['order_id'] ?? 0,
      orderUuid: json['order_uuid'] ?? '',
      user: User.fromJson(json['user']),
      deliveryAddress: json['delivery_address'] != null
          ? DeliveryAddress.fromJson(json['delivery_address'])
          : null,
      deliveryType: json['delivery_type'] ?? 'Не указан',
      deliveryDate: json['delivery_date'] != null
          ? DateTime.tryParse(json['delivery_date'])
          : null,
      paymentType: json['payment_type'] != null
          ? PaymentType.fromJson(json['payment_type'])
          : null,
      currentStatus: OrderStatus.fromJson(json['current_status']),
      statusHistory: (json['status_history'] as List?)
              ?.map((item) => StatusHistory.fromJson(item))
              .toList() ??
          [],
      items: (json['items'] as List?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      itemsCount: (json['items_count'] ?? 0.0).toDouble(),
      costSummary: CostSummary.fromJson(json['cost_summary']),
      extra: json['extra'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      bonus: json['bonus'] ?? 0,
    );
  }
}

class StatusHistory {
  final int statusId;
  final int status;
  final String statusName;
  final DateTime timestamp;
  final int isCanceled;

  StatusHistory({
    required this.statusId,
    required this.status,
    required this.statusName,
    required this.timestamp,
    required this.isCanceled,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    final status = json['status'] ?? 0;
    return StatusHistory(
      statusId: json['status_id'] ?? 0,
      status: status,
      statusName:
          json['status_name']?.toString() ?? OrderStatusCatalog.resolve(status),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isCanceled: json['isCanceled'] ?? 0,
    );
  }
}

class OrderItem {
  final int relationId;
  final int itemId;
  final String name;
  final String description;
  final String? img;
  final String? barcode; // Добавлено поле для штрихкода
  final double amount;
  final int price;
  final String unit;
  final int originalPrice;
  final double totalCost;
  final List<ItemOption> options;

  OrderItem({
    required this.relationId,
    required this.itemId,
    required this.name,
    required this.description,
    this.img,
    this.barcode,
    required this.amount,
    required this.price,
    required this.unit,
    required this.originalPrice,
    required this.totalCost,
    required this.options,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      relationId: json['relation_id'] ?? 0,
      itemId: json['item_id'] ?? 0,
      name: json['name'] ?? 'Неизвестный товар',
      description: json['description'] ?? '',
      img: json['img'],
      barcode: json['barcode'] ?? '', // Извлечение штрихкода
      amount: (json['amount'] ?? 0.0).toDouble(),
      price: json['price'] ?? 0,
      unit: json['unit'] ?? '',
      originalPrice: json['original_price'] ?? 0,
      totalCost: (json['total_cost'] ?? 0.0).toDouble(),
      options: (json['options'] as List?)
              ?.map((item) => ItemOption.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class ItemOption {
  final int optionId;
  final String optionName;
  final int itemId;
  final String name;
  final int price;
  final int selectedPrice;
  final int amount;

  ItemOption({
    required this.optionId,
    required this.optionName,
    required this.itemId,
    required this.name,
    required this.price,
    required this.selectedPrice,
    required this.amount,
  });

  factory ItemOption.fromJson(Map<String, dynamic> json) {
    return ItemOption(
      optionId: json['option_id'] ?? 0,
      optionName: json['option_name'] ?? '',
      itemId: json['item_id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      selectedPrice: json['selected_price'] ?? 0,
      amount: json['amount'] ?? 0,
    );
  }
}

class CostSummary {
  final double itemsTotal;
  final int deliveryPrice;
  final int serviceFee;
  final int bonusUsed;
  final double subtotal;
  final double totalSum;

  CostSummary({
    required this.itemsTotal,
    required this.deliveryPrice,
    required this.serviceFee,
    required this.bonusUsed,
    required this.subtotal,
    required this.totalSum,
  });

  factory CostSummary.fromJson(Map<String, dynamic> json) {
    return CostSummary(
      itemsTotal: (json['items_total'] ?? 0.0).toDouble(),
      deliveryPrice: json['delivery_price'] ?? 0,
      serviceFee: json['service_fee'] ?? 0,
      bonusUsed: json['bonus_used'] ?? 0,
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      totalSum: (json['total_sum'] ?? 0.0).toDouble(),
    );
  }
}

class Business {
  final int businessId;
  final String name;
  final String? address;
  final Coordinates? coordinates;

  Business({
    required this.businessId,
    required this.name,
    this.address,
    this.coordinates,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      businessId: json['business_id'] ?? 0,
      name: json['name'] ?? 'Неизвестно',
      address: json['address']?.toString(),
      coordinates: json['coordinates'] is Map
          ? Coordinates.fromJson(Map<String, dynamic>.from(json['coordinates']))
          : null,
    );
  }
}
