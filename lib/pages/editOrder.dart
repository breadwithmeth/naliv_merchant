import 'package:flutter/material.dart';
import 'package:naliv_merchant/api.dart';
import 'package:naliv_merchant/pages/activeOrders.dart';
import 'package:naliv_merchant/pages/changeAmount.dart';
import 'package:naliv_merchant/pages/replaceItem.dart';

class EditOrderPage extends StatefulWidget {
  const EditOrderPage({super.key, required this.order_id, required this.order});
  final String order_id;
  final Map order;
  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: Padding(
            padding: EdgeInsets.all(30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Column(
                    children: [
                      Row(
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
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                double.parse(widget.order["delivery_price"])
                                        .toInt()
                                        .toString() ??
                                    "",
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
                                style: TextStyle(fontSize: 24),
                              )
                            ],
                          )),
                          Flexible(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                double.parse(orderDetails["sum"])
                                        .toInt()
                                        .toString() ??
                                    "",
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 24),
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
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        onPressed: () {},
                        child: Text("Заказ готов")),
                  ],
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
                      decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(width: 2))),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
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
                                        child:
                                            Image.network(items[index]["img"]),
                                      );
                                    },
                                  )),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  items[index]["name"],
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24),
                                ),
                              ),
                              Expanded(
                                  flex: 3,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        items[index]["amount"].toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 24),
                                      ),
                                    ],
                                  )),
                              Expanded(
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
                                                  actionsAlignment:
                                                      MainAxisAlignment.center,
                                                  content: Container(
                                                      child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Flexible(
                                                        child: Image.network(
                                                            items[index]
                                                                ["img"]),
                                                      ),
                                                      Flexible(
                                                          child: Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 5,
                                                            child: Text(
                                                              items[index]
                                                                  ["name"],
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 24),
                                                            ),
                                                          ),
                                                          Expanded(
                                                              flex: 3,
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  Text(
                                                                    items[index]
                                                                            [
                                                                            "amount"]
                                                                        .toString(),
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w700,
                                                                        fontSize:
                                                                            24),
                                                                  ),
                                                                ],
                                                              )),
                                                        ],
                                                      )),
                                                      Flexible(
                                                          child: Row(
                                                        children: [
                                                          Expanded(
                                                            flex: 5,
                                                            child: Text(
                                                              items[index]
                                                                  ["code"],
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 16),
                                                            ),
                                                          ),
                                                        ],
                                                      )),
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            flex: 3,
                                                            child: items[index][
                                                                        "by_weight"] ==
                                                                    0
                                                                ? Container()
                                                                : ElevatedButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pushReplacement(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                        builder:
                                                                            (context) {
                                                                          return ChangeAmountPage(
                                                                            item:
                                                                                items[index],
                                                                            order:
                                                                                widget.order,
                                                                            order_id:
                                                                                widget.order_id,
                                                                          );
                                                                        },
                                                                      ));
                                                                    },
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Text(
                                                                            "Изменить количество")
                                                                      ],
                                                                    )),
                                                          ),
                                                          Spacer(),
                                                          Flexible(
                                                              flex: 3,
                                                              child:
                                                                  ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pushReplacement(
                                                                            context,
                                                                            MaterialPageRoute(
                                                                          builder:
                                                                              (context) {
                                                                            return ReplaceItemPage(
                                                                              item: items[index],
                                                                              order: widget.order,
                                                                              order_id: widget.order_id,
                                                                            );
                                                                          },
                                                                        ));
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                            "Заменить",
                                                                          )
                                                                        ],
                                                                      )))
                                                        ],
                                                      ),
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
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20),
                                    ),
                                    Icon(Icons.close),
                                    Text(
                                      options[index]["name"],
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 20),
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
            child: Flexible(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      orderReady(widget.order_id);
                    },
                    child: Text("Заказ готов")),
              ],
            )),
          )
        ],
      )),
    );
  }
}
