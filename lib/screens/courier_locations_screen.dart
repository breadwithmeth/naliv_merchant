import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class CourierLocationsScreen extends StatefulWidget {
  final String? orderId;

  const CourierLocationsScreen({
    super.key,
    this.orderId,
  });

  @override
  State<CourierLocationsScreen> createState() => _CourierLocationsScreenState();
}

class _CourierLocationsScreenState extends State<CourierLocationsScreen> {
  static const Color _pageBg = Colors.white;
  static const Color _surface = Colors.white;
  static const Color _ink = Color(0xFF1F2A37);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _brand = Color(0xFF1E5AA8);

  final MapController _mapController = MapController();
  Timer? _pollingTimer;
  bool _isRequestInFlight = false;
  bool _loading = false;
  String? _error;
  List<CourierLocationPoint> _locations = [];
  DateTime? _lastUpdatedAt;
  String? _businessName;
  String? _businessAddress;
  String? _deliveryAddress;
  LatLng? _businessPoint;
  LatLng? _deliveryPoint;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted || _isRequestInFlight) return;

      // Poll only when this page is currently visible to the user.
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (!isCurrentRoute) return;

      _loadLocations(showLoading: false);
    });
  }

  Future<void> _loadLocations({bool showLoading = true}) async {
    if (_isRequestInFlight) return;
    _isRequestInFlight = true;

    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    final futures = <Future<dynamic>>[
      ApiService.getCourierLocations(orderId: widget.orderId),
      if (widget.orderId != null)
        ApiService.getOrderDetails(widget.orderId!).catchError((_) => null),
    ];

    try {
      final responses = await Future.wait(futures);
      final result = responses.first as CourierLocationsResult;
      final orderDetails =
          responses.length > 1 ? responses[1] as OrderDetails? : null;

      if (!mounted) return;

      setState(() {
        _locations = result.locations;
        _loading = false;
        _lastUpdatedAt = DateTime.now();

        _businessName = orderDetails?.business.name;
        _businessAddress = orderDetails?.business.address;
        _deliveryAddress =
            _buildDeliveryAddressText(orderDetails?.order.deliveryAddress);

        final businessCoordinates = orderDetails?.business.coordinates;
        _businessPoint = (businessCoordinates != null &&
                (businessCoordinates.lat != 0 || businessCoordinates.lon != 0))
            ? LatLng(businessCoordinates.lat, businessCoordinates.lon)
            : null;

        final deliveryCoordinates =
            orderDetails?.order.deliveryAddress?.coordinates;
        _deliveryPoint = (deliveryCoordinates != null &&
                (deliveryCoordinates.lat != 0 || deliveryCoordinates.lon != 0))
            ? LatLng(deliveryCoordinates.lat, deliveryCoordinates.lon)
            : null;

        if (result.isCourierNotAssigned) {
          _error = result.errorMessage ?? 'У заказа не назначен курьер';
        } else if (!result.success && _locations.isEmpty) {
          _error =
              result.errorMessage ?? 'Не удалось получить локации курьеров';
        } else if (_locations.isEmpty) {
          _error = 'Список локаций пуст';
        }
      });

      _fitMapToAllPoints();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_locations.isEmpty) {
          _error = 'Не удалось обновить геолокацию';
        }
      });
    } finally {
      _isRequestInFlight = false;
    }
  }

  String _fmtDateTime(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} ${two(dateTime.hour)}:${two(dateTime.minute)}';
  }

  String? _buildDeliveryAddressText(DeliveryAddress? deliveryAddress) {
    if (deliveryAddress == null) return null;

    final extras = <String>[];
    final details = deliveryAddress.details;
    if (details?.apartment?.isNotEmpty == true) {
      extras.add('кв. ${details!.apartment}');
    }
    if (details?.entrance?.isNotEmpty == true) {
      extras.add('подъезд ${details!.entrance}');
    }
    if (details?.floor?.isNotEmpty == true) {
      extras.add('этаж ${details!.floor}');
    }

    if (extras.isEmpty) return deliveryAddress.address;
    return '${deliveryAddress.address} (${extras.join(', ')})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: Text(
          widget.orderId == null
              ? 'Локации курьеров'
              : 'Курьер по заказу #${widget.orderId}',
        ),
        backgroundColor: _surface,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadLocations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLocations,
        child: _buildBody(),
      ),
    );
  }

  void _fitMapToAllPoints() {
    final points = <LatLng>[
      ..._locations.map((e) => LatLng(e.lat, e.lon)),
      if (_deliveryPoint != null) _deliveryPoint!,
      if (_businessPoint != null) _businessPoint!,
    ];

    if (points.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (points.length == 1) {
        _mapController.move(points.first, 15);
        return;
      }

      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
        ),
      );
    });
  }

  Widget _buildBody() {
    if (_loading && _locations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _brand),
      );
    }

    if (_error != null && _locations.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Icon(Icons.location_off, size: 64, color: _muted),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              style: const TextStyle(color: _muted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _loadLocations,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
              ),
              child: const Text('Повторить'),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: _locations.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildHeaderInfo(),
              ),
              _buildOrderMetaCard(),
              if (_locations.isNotEmpty) _buildMapCard(),
            ],
          );
        }

        final location = _locations[index - 1];
        final courierName =
            location.courierName ?? location.courierLogin ?? 'Курьер';

        return Card(
          elevation: 1,
          color: _surface,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _brand.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delivery_dining, color: _brand),
            ),
            title: Text(
              courierName,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (location.courierId != null)
                  Text(
                    'ID: ${location.courierId}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                Text(
                  'Координаты: ${location.lat.toStringAsFixed(6)}, ${location.lon.toStringAsFixed(6)}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                if (location.updatedAt != null &&
                    location.updatedAt!.isNotEmpty)
                  Text(
                    'Обновлено: ${location.updatedAt}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderInfo() {
    final updatedText = _lastUpdatedAt == null
        ? 'Данные загружаются'
        : 'Обновлено: ${_fmtDateTime(_lastUpdatedAt!)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: _brand, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              updatedText,
              style: const TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _brand.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_locations.length} курьер(ов)',
              style: const TextStyle(
                color: _brand,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderMetaCard() {
    final rows = <Widget>[];

    if (_businessName != null && _businessName!.isNotEmpty) {
      rows.add(_buildMetaRow('Бизнес', _businessName!));
    }
    if (_businessAddress != null && _businessAddress!.isNotEmpty) {
      rows.add(_buildMetaRow('Адрес бизнеса', _businessAddress!));
    }
    if (_deliveryAddress != null && _deliveryAddress!.isNotEmpty) {
      rows.add(_buildMetaRow('Адрес доставки', _deliveryAddress!));
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      color: _surface,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }

  Widget _buildMetaRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _ink,
                decoration: TextDecoration.none,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: _muted,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
        softWrap: true,
      ),
    );
  }

  Widget _buildMapCard() {
    final allPoints = <LatLng>[
      ..._locations.map((e) => LatLng(e.lat, e.lon)),
      if (_deliveryPoint != null) _deliveryPoint!,
      if (_businessPoint != null) _businessPoint!,
    ];

    final first = allPoints.first;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(first.latitude, first.longitude),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.maps.2gis.com/tiles?x={x}&y={y}&z={z}',
                  subdomains: const ['tile0', 'tile1', 'tile2', 'tile3'],
                  tileProvider: CancellableNetworkTileProvider(),
                ),
                MarkerLayer(
                  markers: [
                    ..._locations.map(
                      (loc) => Marker(
                        point: LatLng(loc.lat, loc.lon),
                        width: 86,
                        height: 30,
                        child: _buildTextMarker(
                          label: 'Курьер',
                          color: Colors.red,
                        ),
                      ),
                    ),
                    if (_deliveryPoint != null)
                      Marker(
                        point: _deliveryPoint!,
                        width: 96,
                        height: 30,
                        child: _buildTextMarker(
                          label: 'Доставка',
                          color: Colors.blue,
                        ),
                      ),
                    if (_businessPoint != null)
                      Marker(
                        point: _businessPoint!,
                        width: 86,
                        height: 30,
                        child: _buildTextMarker(
                          label: 'Бизнес',
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Material(
                color: _surface,
                elevation: 1,
                borderRadius: BorderRadius.circular(20),
                child: IconButton(
                  tooltip: 'Показать все точки',
                  icon: const Icon(Icons.center_focus_strong, color: _ink),
                  onPressed: _fitMapToAllPoints,
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: _buildMapLegend(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendRow(color: Colors.red, label: 'Курьер'),
          _LegendRow(color: Colors.blue, label: 'Доставка'),
          _LegendRow(color: Colors.orange, label: 'Бизнес'),
        ],
      ),
    );
  }

  Widget _buildTextMarker({required String label, required Color color}) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
