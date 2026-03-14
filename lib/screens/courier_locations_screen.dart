import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  }

  Future<void> _loadLocations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result =
        await ApiService.getCourierLocations(orderId: widget.orderId);
    final orderDetails = widget.orderId == null
        ? null
        : await ApiService.getOrderDetails(widget.orderId!);

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
        _error = result.errorMessage ?? 'Не удалось получить локации курьеров';
      } else if (_locations.isEmpty) {
        _error = 'Список локаций пуст';
      }
    });
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
      appBar: AppBar(
        title: Text(
          widget.orderId == null
              ? 'Локации курьеров'
              : 'Курьер по заказу #${widget.orderId}',
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
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

  Widget _buildBody() {
    if (_loading && _locations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _locations.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          const Center(
            child: Icon(Icons.location_off, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _loadLocations,
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
                child: Text(
                  _lastUpdatedAt == null
                      ? (widget.orderId == null
                          ? 'Локации курьеров'
                          : 'Локация курьера для заказа #${widget.orderId}')
                      : 'Обновлено: ${_fmtDateTime(_lastUpdatedAt!)}',
                  style: const TextStyle(color: Colors.grey),
                ),
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.delivery_dining, color: Colors.white),
            ),
            title: Text(courierName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (location.courierId != null)
                  Text('ID: ${location.courierId}'),
                Text(
                    'Координаты: ${location.lat.toStringAsFixed(6)}, ${location.lon.toStringAsFixed(6)}'),
                if (location.updatedAt != null &&
                    location.updatedAt!.isNotEmpty)
                  Text('Обновлено: ${location.updatedAt}'),
              ],
            ),
          ),
        );
      },
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
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
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(first.latitude, first.longitude),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'naliv.merchant',
            ),
            MarkerLayer(
              markers: [
                ..._locations.map(
                  (loc) => Marker(
                    point: LatLng(loc.lat, loc.lon),
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 42,
                    ),
                  ),
                ),
                if (_deliveryPoint != null)
                  Marker(
                    point: _deliveryPoint!,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.home,
                      color: Colors.blue,
                      size: 36,
                    ),
                  ),
                if (_businessPoint != null)
                  Marker(
                    point: _businessPoint!,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.store,
                      color: Colors.orange,
                      size: 34,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
