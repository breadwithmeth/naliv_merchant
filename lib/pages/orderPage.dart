import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naliv_merchant/api.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:input_quantity/input_quantity.dart';

class OrderPage extends StatefulWidget {
  const OrderPage(
      {super.key, required this.order_id, required this.scrollController});
  final String order_id;
  final ScrollController scrollController;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  Map? order;
  List order_items = [];
  bool isOrderReady = false;
  bool orderEditable = false;
  _getOrder() async {
    await getOrderDetails(widget.order_id).then((value) {
      print(value);
      setState(() {
        order = value;
        order_items = value["order"]["items"];
      });
      checkOrderEditable();
    });
  }

  Widget getOrderStatusFormat(String string) {
    if (string == "66") {
      return Text("Не оплачен");
    } else if (string == "0") {
      return Text(
        "Новый заказ",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      );
    } else if (string == "1") {
      return Text(
        "Заказ отправлен в систему учета",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      );
    } else if (string == "2") {
      return Text(
        "Заказ собран",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      );
    } else if (string == "3") {
      return Text(
        "Заказ в пути",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      );
    } else {
      return Container();
    }
  }

  late Timer _timer;

  checkOrderEditable() {
    if (order?["order"]["editable"]) {
      setState(() {
        isOrderReady = false;
        orderEditable = true;
      });
    } else {
      setState(() {
        print("d332211");
        isOrderReady = true;
        orderEditable = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getOrder();
    _timer = Timer.periodic(new Duration(seconds: 5), (timer) {
      debugPrint(timer.tick.toString());
      _getOrder();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        controller: widget.scrollController,
        physics: ClampingScrollPhysics(),
        children: [
          Text(order.toString()),
          Container(
            padding: EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: getOrderStatusFormat(
                      (order?["order"]["order_status"] ?? null).toString()),
                ),
                // Flexible(
                //     flex: 1,
                //     child: Container(
                //       child: ElevatedButton(
                //           onPressed: () {
                //             orderReady(widget.order_id).then((v) {
                //               Navigator.pop(context);
                //             });
                //           },
                //           child: Text("Закончить редактирование")),
                //     ))
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(15),
            child: Text(
              order?["order"]["address"] ?? "",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          order == null
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Container(
                  child: ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    primary: false,
                    shrinkWrap: true,
                    itemCount: order_items.length,
                    itemBuilder: (context, index) {
                      List option_items = order_items[index]["items"] ?? [];
                      return Slidable(
                          enabled: orderEditable,
                          closeOnScroll: true,
                          startActionPane: ActionPane(
                            // A motion is a widget used to control how the pane animates.
                            motion: DrawerMotion(),

                            // A pane can dismiss the Slidable.

                            // All actions are defined in the children parameter.
                            children: [
                              Flexible(
                                  child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    backgroundColor: Colors.white,
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    context: context,
                                    builder: (context) {
                                      return ReplaceItemDialog(
                                        order_item: order_items[index],
                                      );
                                    },
                                  ).then((onValue) {
                                    _getOrder();
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(30)),
                                      boxShadow: [
                                        BoxShadow(
                                            offset: Offset(2, 2),
                                            blurRadius: 5,
                                            color: Colors.black12)
                                      ],
                                      color: Colors.redAccent),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.find_replace,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                      Text(
                                        "Заменить",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24),
                                      )
                                    ],
                                  ),
                                ),
                              )),
                              Flexible(
                                  child: GestureDetector(
                                onTap: () {
                                  showModalBottomSheet(
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    context: context,
                                    builder: (context) {
                                      return ChangeAmountDialog(
                                        order_item: order_items[index],
                                      );
                                    },
                                  ).then((onValue) {
                                    _getOrder();
                                  });
                                },
                                child: Container(
                                  margin: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(30)),
                                      boxShadow: [
                                        BoxShadow(
                                            offset: Offset(2, 2),
                                            blurRadius: 5,
                                            color: Colors.black12)
                                      ],
                                      color: Colors.blueAccent),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                      Text(
                                        "Изменить количество",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24),
                                      )
                                    ],
                                  ),
                                ),
                              )),
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.all(15),
                            margin: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12,
                                      offset: Offset(1, 1),
                                      blurRadius: 5)
                                ],
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15))),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                    child: Container(
                                  margin: EdgeInsets.all(10),
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 5,
                                            color: Colors.black12)
                                      ],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(15))),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Image.network(
                                      order_items[index]["img"] ?? "/",
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )),
                                Flexible(
                                    flex: 5,
                                    child: Container(
                                      alignment: Alignment.topLeft,
                                      margin: EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    order_items[index]["amount"]
                                                        .toString(),
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 24),
                                                  ),
                                                  Icon(Icons.close),
                                                  Text(
                                                    order_items[index]["name"],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        fontSize: 24),
                                                  ),
                                                ],
                                              ),
                                              IconButton(
                                                  onPressed: () {},
                                                  icon: Icon(Icons.edit))
                                            ],
                                          ),
                                          ListView.builder(
                                            primary: false,
                                            shrinkWrap: true,
                                            itemCount: option_items.length,
                                            itemBuilder: (context, index2) {
                                              return Row(
                                                children: [
                                                  Text(
                                                    option_items[index2]
                                                            ["amount"]
                                                        .toString(),
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20),
                                                  ),
                                                  Icon(
                                                    Icons.close,
                                                    size: 16,
                                                  ),
                                                  Text(
                                                    option_items[index2]
                                                        ["name"],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20),
                                                  ),
                                                ],
                                              );
                                            },
                                          )
                                        ],
                                      ),
                                    ))
                              ],
                            ),
                          ));
                    },
                  ),
                ),
          orderEditable
              ? ElevatedButton(
                  onPressed: () {
                    orderReady(widget.order_id).then((v) {
                      Navigator.pop(context);
                    });
                  },
                  child: Text("Закончить редактирование"))
              : Container(),
        ],
      ),
    );
  }
}

class ChangeAmountDialog extends StatefulWidget {
  const ChangeAmountDialog({super.key, required this.order_item});
  final Map order_item;
  @override
  State<ChangeAmountDialog> createState() => _ChangeAmountDialogState();
}

class _ChangeAmountDialogState extends State<ChangeAmountDialog> {
  num amount = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InputQty(
            decoration: QtyDecorationProps(
              plusBtn: Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(500)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          offset: Offset(2, 2),
                          blurRadius: 5,
                          color: Colors.black26)
                    ]),
                child: Icon(
                  Icons.add,
                  color: Colors.blueAccent,
                  size: 36,
                ),
              ),
              minusBtn: Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(500)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          offset: Offset(2, 2),
                          blurRadius: 5,
                          color: Colors.black26)
                    ]),
                child: Icon(
                  Icons.remove,
                  color: Colors.blueAccent,
                  size: 36,
                ),
              ),
              width: 20,
              borderShape: BorderShapeBtn.none,
              btnColor: Colors.blueAccent,
              fillColor: Colors.white,
              isBordered: false,
            ),
            qtyFormProps: QtyFormProps(
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              cursorColor: Colors.red,
              enableTyping: true,
            ),
            maxVal: widget.order_item["amount"],
            initVal: widget.order_item["amount"],
            minVal: 0,
            steps: 1,
            onQtyChanged: (val) {
              setState(() {
                amount = val;
              });
              print(amount);
            },
          ),
          Row(
            children: [
              Text(
                widget.order_item["amount"].toString(),
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
              ),
              Icon(Icons.close),
              Text(
                widget.order_item["name"],
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
              ),
            ],
          ),
          // TextField(
          //   controller: amount,
          //   decoration: InputDecoration(
          //       border:
          //           OutlineInputBorder()),
          //   keyboardType:
          //       TextInputType.number,
          //   inputFormatters: <TextInputFormatter>[
          //     FilteringTextInputFormatter
          //         .allow(RegExp(
          //             r'^\d*\.?\d*$'))
          //   ], // O
          // ),
          ElevatedButton(
              onPressed: () {
                if (amount >= (widget.order_item["amount"] as num)) {
                  print(amount);
                  SnackBar(content: Text("Ты что не так делаешь"));
                }

                changeAmount(
                        widget.order_item["relation_id"], amount.toString())
                    .then((v) {});
                Navigator.pop(context);
              },
              child: Text("Подтвердить")),
          SizedBox(
            height: 200,
          )
        ],
      ),
    );
  }
}

class ReplaceItemDialog extends StatefulWidget {
  const ReplaceItemDialog({super.key, required this.order_item});
  final Map order_item;

  @override
  State<ReplaceItemDialog> createState() => _ReplaceItemDialogState();
}

class _ReplaceItemDialogState extends State<ReplaceItemDialog> {
  List replacementItems = [];
  _getReplacements() {
    getReplacementItems(widget.order_item["relation_id"].toString())
        .then((value) {
      setState(() {
        replacementItems = value ?? [];
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getReplacements();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      child: ListView.builder(
        itemCount: replacementItems.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.all(10),
            child: GestureDetector(
              child: Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          offset: Offset(2, 2),
                          blurRadius: 3,
                          color: Colors.black26)
                    ]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(replacementItems[index]["name"]),
                    TextButton(
                        onPressed: () {
                          replaceItem(
                                  widget.order_item["relation_id"].toString(),
                                  replacementItems[index]["item_id"].toString())
                              .then((v) {
                            Navigator.pop(context);
                          });
                        },
                        child: Text("Выбрать"))
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
