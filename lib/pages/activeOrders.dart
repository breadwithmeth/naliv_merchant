import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naliv_merchant/api.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:naliv_merchant/main.dart';
import 'package:naliv_merchant/pages/editOrder.dart';
import 'package:naliv_merchant/pages/orderPage.dart';
import 'package:audioplayers/audioplayers.dart';

class ActiveOrders extends StatefulWidget {
  const ActiveOrders({super.key});

  @override
  State<ActiveOrders> createState() => _ActiveOrdersState();
}

class _ActiveOrdersState extends State<ActiveOrders> {
  List orders = [];
  bool isNew = false;
  bool isAccepted = false;

  Future<void> _getActiveOrders() async {
    await getActiveOrders().then((v) {
      setState(() {
        if (v != null) {
          orders = v ?? [];
        }
      });
    });
  }

  late Timer _timer;
  late AudioPlayer player = AudioPlayer();
  bool _isMenuOpen = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _getActiveOrders();
    _timer = Timer.periodic(new Duration(seconds: 10), (timer) {
      debugPrint(timer.tick.toString());
      _getActiveOrders();
    });
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   await player.setSource(AssetSource('ambient_c_motion.mp3'));
    //   await player.resume();
    // });
  }

  @override
  void dispose() {
    _timer.cancel();
    player.dispose();

    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: () {
                logout();
                Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (context) {
                    return Main();
                  },
                ));
              },
              child: Text("Выйти"),
            )
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: true,
            centerTitle: false,
            title: Text(
              "Заказы",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    // NotificationController.createNewNotification();
                  },
                  child: Text("data"))
            ],
          ),
          SliverToBoxAdapter(
            child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return OrderTile(
                  order: orders[index],
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class OrderTile extends StatefulWidget {
  const OrderTile({super.key, this.order});
  final order;
  @override
  State<OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<OrderTile> with TickerProviderStateMixin {
  late AnimationController _animationCtrl;
  Widget getOrderStatusFormat(String string) {
    if (string == "66") {
      return Container(
          child: Row(
        children: [
          Icon(
            Icons.circle,
            color: Colors.red,
          ),
          Text("Не оплачен")
        ],
      ));
    } else if (string == "0") {
      return Container(
          child: Row(
        children: [
          Icon(
            Icons.circle,
            color: Colors.green,
          ),
          Text("Новый заказ")
        ],
      ));
    } else if (string == "1") {
      return Container(
          child: Row(
        children: [
          Icon(
            Icons.circle,
            color: Colors.blue,
          ),
          Text("Заказ принят мерчантом")
        ],
      ));
    } else if (string == "2") {
      return Container(
          child: Row(
        children: [
          Icon(
            Icons.circle,
            color: Colors.yellowAccent,
          ),
          Text("Заказ собран")
        ],
      ));
    } else if (string == "3") {
      return Container(
          child: Row(
        children: [
          Icon(
            Icons.circle,
            color: Colors.red,
          ),
          Text("Заказ забрал курьер")
        ],
      ));
    } else {
      return Container();
    }
  }

  bool isNew = false;

  bool isAccepted = false;

  bool isReady = false;

  List items = [];

  void initItems() {
    setState(() {
      // items = widget.order["items"];
    });
    setState(() {
      // if (widget.order["ready_at"] != null) {
      //   isReady = true;
      // }
      // if (widget.order["accepted_at"] == null) {
      //   isNew = true;
      // } else {
      //   isAccepted = true;
      // }
    });
  }

  @override
  void initState() {
    super.initState();
    initItems();
    _animationCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _animationCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
          margin: EdgeInsets.all(15),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, offset: Offset(1, 1), blurRadius: 5)
              ],
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(15),
              )),
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.order["address"] ?? "Самовывоз",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                // getOrderStatusFormat(widget.order["order_status"]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.order["order_id"].toString(),
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          color: isAccepted
                              ? Colors.green
                              : Colors.yellowAccent.shade700),
                    ),
                    // IconButton(onPressed: () {}, icon: Icon(Icons.open_in_new))
                  ],
                ),
              ],
            ),
          )),
      onTap: () {
        showModalBottomSheet(
          useSafeArea: true,
          showDragHandle: true,
          enableDrag: true,
          backgroundColor: Colors.white,
          isScrollControlled: true,
          constraints: BoxConstraints.tight(Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 1)),
          context: context,
          builder: (context) => DraggableScrollableSheet(
              expand: true,
              initialChildSize: 0.9,
              minChildSize: 0.9,
              maxChildSize: 1,
              builder: (context, scrollController) => OrderPage(
                    order_id: widget.order["order_id"].toString(),
                    scrollController: scrollController

                  )),
        );
      },
    );
  }
}
