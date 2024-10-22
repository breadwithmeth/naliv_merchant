import 'package:flutter/material.dart';
import 'package:naliv_merchant/api.dart';
import 'package:naliv_merchant/pages/editOrder.dart';

class ReplaceItemPage extends StatefulWidget {
  const ReplaceItemPage({super.key, required this.item, required this.order_id, required this.order});
  final Map item;
  final String order_id;
  final Map order;
  @override
  State<ReplaceItemPage> createState() => _ReplaceItemPageState();
}

class _ReplaceItemPageState extends State<ReplaceItemPage> {
  List items = [];

  void _getReplacementItems() {
    getReplacementItems(widget.item["relation_id"].toString()).then((v) {
      print(v);
      setState(() {
        items = v ?? [];
      });
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print(widget.item);
    _getReplacementItems();
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
                    "Замена",
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
                        return EditOrderPage(order_id: widget.order_id, order: widget.order);
                      },
                    ));
                  },
                ))
              ],
            ),
          )),
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Заменить?"),
                          actions: [
                            ElevatedButton(
                                onPressed: () {
                                  replaceItem(widget.item["relation_id"].toString(), items[index]["item_id"]).then((v) {
                                    Navigator.pushReplacement(context, MaterialPageRoute(
                                      builder: (context) {
                                        return EditOrderPage(order_id: widget.order_id, order: widget.order);
                                      },
                                    ));
                                  });
                                },
                                child: Text("Да")),
                            ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("Нет"))
                          ],
                        );
                      },
                    );
                  },
                  title: Text(items[index]["name"]),
                  subtitle: Row(
                    children: [Text("Цена: "), Text(items[index]["price"])],
                  ),
                  trailing: Image.network(items[index]["img"]),
                ),
              );
            },
          )
        ],
      )),
    );
  }
}
