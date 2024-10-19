import 'package:flutter/material.dart';
import 'package:naliv_merchant/api.dart';
import 'package:naliv_merchant/pages/activeOrders.dart';

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
        items = v["items"];
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
                            backgroundColor: Colors.blueAccent),
                        onPressed: () {},
                        child: Text("Принять заказ")),
                  ],
                ))
              ],
            ),
          )),
          SliverFillRemaining(
              child: Card(
            margin: EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                primary: false,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(width: 2))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            items[index]["name"],
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 24),
                          ),
                        ),
                        Expanded(
                            child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              items[index]["amount"],
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 24),
                            ),
                          ],
                        )),
                      ],
                    ),
                  );
                },
              ),
            ),
          )),
        ],
      )),
    );
  }
}
