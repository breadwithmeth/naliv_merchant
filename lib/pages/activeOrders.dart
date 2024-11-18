import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naliv_merchant/NotificationController.dart';
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

  Future<void> _getActiveOrders() async {
    await getActiveOrders().then((v) {
      setState(() {
        if (v != null) {
          orders = v["orders"];
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
    return CustomScrollView(
      slivers: [
        SliverOffstage(
          offstage: _isMenuOpen,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 100,
                ),
                ElevatedButton(
                    onPressed: () {
                      logout();
                      Navigator.pushReplacement(context, MaterialPageRoute(
                        builder: (context) {
                          return Main();
                        },
                      ));
                    },
                    child: Text("Выйти"))
              ],
            ),
          ),
        ),
        SliverAppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Text(
            "Заказы",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          leading: IconButton(
              onPressed: () {
                if (_isMenuOpen) {
                  setState(() {
                    _isMenuOpen = false;
                  });
                } else {
                  setState(() {
                    _isMenuOpen = true;
                  });
                }
              },
              icon: Icon(Icons.menu)),
          actions: [
            ElevatedButton(
                onPressed: () {
                  NotificationController.createNewNotification();
                },
                child: Text("data"))
          ],
        ),
        SliverFillRemaining(
            child: SingleChildScrollView(
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
        )),
      ],
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
          Text("ne oplachen")
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
      items = widget.order["items"];
    });
    setState(() {
      if (widget.order["ready_at"] != null) {
        isReady = true;
      }
      if (widget.order["accepted_at"] == null) {
        isNew = true;
      } else {
        isAccepted = true;
      }
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
        onTap: () {
          if (!isReady) {
            if (isNew) {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) {
                  return OrderPage(
                    order_id: widget.order["order_id"].toString(),
                    order: widget.order,
                  );
                },
              ));
            }
            if (isAccepted) {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) {
                  return EditOrderPage(
                    order_id: widget.order["order_id"].toString(),
                    order: widget.order,
                  );
                },
              ));
            }
          }
        },
        child: Card(
                color: const Color.fromARGB(255, 240, 213, 213),
                child: ExpansionTile(
                  collapsedBackgroundColor: Colors.black,
                  backgroundColor: Colors.black,
                  title: GestureDetector(
                    child: Row(
                      children: [
                        Icon(isReady ? Icons.done : Icons.circle),
                        Text(
                          widget.order["order_uuid"],
                          style: TextStyle(
                              color: isAccepted ? Colors.green : Colors.yellow),
                        )
                      ],
                    ),
                    onTap: () {
                      if (!isReady) {
                        if (isNew) {
                          Navigator.pushReplacement(context, MaterialPageRoute(
                            builder: (context) {
                              return OrderPage(
                                order_id: widget.order["order_id"].toString(),
                                order: widget.order,
                              );
                            },
                          ));
                        }
                        if (isAccepted) {
                          Navigator.pushReplacement(context, MaterialPageRoute(
                            builder: (context) {
                              return EditOrderPage(
                                order_id: widget.order["order_id"].toString(),
                                order: widget.order,
                              );
                            },
                          ));
                        }
                      }
                    },
                  ),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      primary: false,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.all(10),
                          color: Colors.grey.shade900,
                          child: Row(
                            children: [
                              Flexible(
                                  child: Container(
                                margin: EdgeInsets.all(10),
                                child: items[index]["img"] != null
                                    ? Image.network(items[index]["img"])
                                    : Container(),
                              )),
                              Flexible(
                                  flex: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!isReady) {
                                        if (isNew) {
                                          Navigator.pushReplacement(context,
                                              MaterialPageRoute(
                                            builder: (context) {
                                              return OrderPage(
                                                order_id: widget
                                                    .order["order_id"]
                                                    .toString(),
                                                order: widget.order,
                                              );
                                            },
                                          ));
                                        }
                                        if (isAccepted) {
                                          Navigator.pushReplacement(context,
                                              MaterialPageRoute(
                                            builder: (context) {
                                              return EditOrderPage(
                                                order_id:
                                                    widget.order["order_id"],
                                                order: widget.order,
                                              );
                                            },
                                          ));
                                        }
                                      }
                                    },
                                    child: Text(
                                      items[index]["name"],
                                      softWrap: true,
                                      overflow: TextOverflow.fade,
                                    ),
                                  ))
                            ],
                          ),
                        );
                      },
                    )
                  ],
                  // subtitle: getOrderStatusFormat(widget.order["order_status"]),
                ))
            .animate(
              controller: _animationCtrl,
              autoPlay: isNew,
              onPlay: (controller) {
                controller.repeat(reverse: true);
              },
            )
            .shimmer(curve: Curves.decelerate, duration: Durations.long4));
  }
}
