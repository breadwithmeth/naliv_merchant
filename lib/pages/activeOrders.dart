import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:naliv_merchant/api.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:naliv_merchant/main.dart';
import 'package:naliv_merchant/pages/editOrder.dart';
import 'package:naliv_merchant/pages/orderPage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:naliv_merchant/pages/stopListPage.dart';

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
    super.initState();
    _getActiveOrders();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      debugPrint(timer.tick.toString());
      _getActiveOrders();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text(
          "Заказы",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text("Меню"),
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                actions: [
                  CupertinoActionSheetAction(
                    child: Text("Стоп-лист"),
                    onPressed: () {
                      Navigator.push(context, CupertinoPageRoute(
                        builder: (context) {
                          return StopListPage();
                        },
                      ));
                    },
                  ),
                  CupertinoActionSheetAction(
                    isDestructiveAction: true,
                    child: Text("Выйти"),
                    onPressed: () {
                      logout();
                      Navigator.pushReplacement(context, CupertinoPageRoute(
                        builder: (context) {
                          return Main();
                        },
                      ));
                    },
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  child: Text("Отмена"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
        ),
      ),
      child: CustomScrollView(
        slivers: [
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
            CupertinoIcons.circle_fill,
            color: CupertinoColors.destructiveRed,
          ),
          Text("Не оплачен")
        ],
      ));
    } else if (string == "0") {
      return Container(
          child: Row(
        children: [
          Icon(
            CupertinoIcons.circle_fill,
            color: CupertinoColors.activeGreen,
          ),
          Text("Новый заказ")
        ],
      ));
    } else if (string == "1") {
      return Container(
          child: Row(
        children: [
          Icon(
            CupertinoIcons.circle_fill,
            color: CupertinoColors.activeBlue,
          ),
          Text("Заказ принят мерчантом")
        ],
      ));
    } else if (string == "2") {
      return Container(
          child: Row(
        children: [
          Icon(
            CupertinoIcons.circle_fill,
            color: CupertinoColors.systemYellow,
          ),
          Text("Заказ собран")
        ],
      ));
    } else if (string == "3") {
      return Container(
          child: Row(
        children: [
          Icon(
            CupertinoIcons.circle_fill,
            color: CupertinoColors.destructiveRed,
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
              color: CupertinoColors.black.withOpacity(0.12),
              offset: Offset(1, 1),
              blurRadius: 5,
            )
          ],
          color: CupertinoColors.white,
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.order["address"] ?? "Самовывоз",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.order["order_id"].toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 36,
                    color: isAccepted
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.activeOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            child: CupertinoPageScaffold(
              child: OrderPage(
                order_id: widget.order["order_id"].toString(),
                scrollController: ScrollController(),
              ),
            ),
          ),
        );
      },
    );
  }
}
