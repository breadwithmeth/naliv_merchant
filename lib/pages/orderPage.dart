import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naliv_merchant/api.dart';
import 'package:naliv_merchant/pages/activeOrders.dart';
import 'package:naliv_merchant/pages/editOrder.dart';
import '../globals.dart' as globals;

class OrderPage extends StatefulWidget {
  const OrderPage({super.key, required this.order_id, required this.order});
  final String order_id;
  final Map order;
  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List items = [];
  Map orderDetails = {};
  Future<void> _getOrder() async {
    await getOrderDetails(widget.order_id).then((v) {
      print(v);
      setState(() {
        orderDetails = v;
        items = v["items"]["items"];
      });
    });
  }

  late Timer _timer;

  late int _start;

  int currentTime = 1;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      _start = widget.order["created_at"];
    });
    _getOrder();
    startTimer();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        setState(() {
          currentTime = _start + 600 - (DateTime.now().toUtc().millisecondsSinceEpoch / 1000).toInt();
        });
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: CustomScrollView(
        shrinkWrap: true,
        primary: false,
        slivers: [
          SliverToBoxAdapter(
              child: Padding(
            padding: EdgeInsets.all(30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                Flexible(
                  child: Text(
                    "Заказ",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                ),
                Flexible(
                    child: GestureDetector(
                  child: Text(
                    "Назад",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                  onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(
                      builder: (context) {
                        return ActiveOrders();
                      },
                    ));
                  },
                ))
              ],
            ),
          )),
          SliverToBoxAdapter(
              child: Padding(
            padding: EdgeInsets.all(30),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 3,
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Flexible(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Доставка",
                                style: TextStyle(fontSize: 24),
                              )
                            ],
                          )),
                          Flexible(
                              child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                widget.order["delivery_price"].toString() ?? "",
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 24),
                              )
                            ],
                          ))
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Сумма",
                                style: TextStyle(fontSize: 12),
                              )
                            ],
                          )),
                          Flexible(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                orderDetails["sum"] == null
                                    ? "999999"
                                    : orderDetails["sum"].toString(),
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12),
                              )
                            ],
                          ))
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [Text(globals.formattedTime(timeInSecond: currentTime))],
                ))
              ],
            ),
          )),
          SliverToBoxAdapter(
              child: Card(
            margin: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                primary: false,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  List options = items[index]["options"] ?? [];
                  return Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(width: 2))),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Flexible(
                                  flex: 2,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Container(
                                        margin: EdgeInsets.all(5),
                                        clipBehavior:
                                            Clip.antiAliasWithSaveLayer,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20))),
                                        width: constraints.maxWidth,
                                        height: constraints.maxWidth,
                                        child: items[index]["img"] != null
                                            ? Image.network(items[index]["img"])
                                            : Container(),
                                      );
                                    },
                                  )),
                              Flexible(
                                flex: 5,
                                child: Text(
                                  items[index]["name"],
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
                                ),
                              ),
                              Flexible(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        items[index]["amount"].toString(),
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24),
                                      ),
                                    ],
                                  )),
                              Flexible(
                                  child: options.length != 0
                                      ? Container()
                                      : IconButton(
                                          iconSize: 36,
                                          onPressed: () {
                                            showAdaptiveDialog(
                                              barrierDismissible: true,
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  alignment: Alignment.center,
                                                  actionsAlignment: MainAxisAlignment.center,
                                                  content: Container(
                                                      child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      items[index]["img"] != null
                                                          ? Flexible(
                                                              child: Image.network(items[index]["img"]),
                                                            )
                                                          : SizedBox(),
                                                      Flexible(
                                                          child: Row(
                                                        children: [
                                                          Flexible(
                                                            flex: 5,
                                                            child: Text(
                                                              items[index]["name"],
                                                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 24),
                                                            ),
                                                          ),
                                                          Flexible(
                                                              flex: 3,
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.end,
                                                                children: [
                                                                  Text(
                                                                    items[index]["amount"].toString(),
                                                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 24),
                                                                  ),
                                                                ],
                                                              )),
                                                        ],
                                                      )),
                                                      Flexible(
                                                          child: Row(
                                                        children: [
                                                          Flexible(
                                                            flex: 5,
                                                            child: Text(
                                                              items[index]["code"],
                                                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
                                                            ),
                                                          ),
                                                        ],
                                                      )),
                                                    ],
                                                  )),
                                                  actions: [],
                                                );
                                              },
                                            );
                                          },
                                          icon: Icon(Icons.more_vert))),
                            ],
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            primary: false,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Row(
                                  children: [
                                    Text(
                                      options[index]["amount"].toString(),
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                                    ),
                                    Icon(Icons.close),
                                    Text(
                                      options[index]["name"],
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                                    )
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ));
                },
              ),
            ),
          )),
          SliverToBoxAdapter(
            child: Container(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    onPressed: () {
                      acceptOrder(widget.order_id).then((v) {
                        Navigator.pushReplacement(context, MaterialPageRoute(
                          builder: (context) {
                            return EditOrderPage(
                                order_id: widget.order_id.toString(),
                                order: widget.order);
                          },
                        ));
                      });
                    },
                    child: Text("Принять заказ")),
              ],
            )),
          )
        ],
      )),
    );
  }
}
