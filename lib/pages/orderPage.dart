import 'dart:async';
import 'package:flutter/cupertino.dart';
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
  late Timer _timer;

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
    final textStyle = TextStyle(fontSize: 17);
    switch (string) {
      case "66":
        return Text("Не оплачен", style: textStyle);
      case "0":
        return Text("Новый заказ", style: textStyle);
      case "1":
        return Text("Заказ отправлен в систему учета", style: textStyle);
      case "2":
        return Text("Заказ собран", style: textStyle);
      case "3":
        return Text("Заказ в пути", style: textStyle);
      default:
        return Container();
    }
  }

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
    super.initState();
    _getOrder();
    _timer = Timer.periodic(new Duration(seconds: 5), (timer) {
      debugPrint(timer.tick.toString());
      _getOrder();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Заказ ${widget.order_id}'),
      ),
      child: SafeArea(
        child: ListView(
          controller: widget.scrollController,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getOrderStatusFormat(
                    (order?["order"]["order_status"] ?? "").toString(),
                  ),
                  SizedBox(height: 8),
                  Text(
                    order?["order"]["address"] ?? "",
                    style: TextStyle(color: CupertinoColors.secondaryLabel),
                  ),
                ],
              ),
            ),
            order == null
                ? Center(child: CupertinoActivityIndicator())
                : _buildOrderItems(),
            if (orderEditable)
              Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoButton.filled(
                  onPressed: () {
                    orderReady(widget.order_id).then((_) {
                      Navigator.pop(context);
                    });
                  },
                  child: Text("Завершить редактирование"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: order_items.length,
      separatorBuilder: (context, index) => Container(),
      itemBuilder: (context, index) {
        return Slidable(
          enabled: orderEditable,
          startActionPane: ActionPane(
            motion: DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => ReplaceItemDialog(
                      order_item: order_items[index],
                    ),
                  ).then((_) => _getOrder());
                },
                backgroundColor: CupertinoColors.systemRed,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.repeat,
                label: 'Заменить',
              ),
              SlidableAction(
                onPressed: (_) {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => ChangeAmountDialog(
                      order_item: order_items[index],
                    ),
                  ).then((_) => _getOrder());
                },
                backgroundColor: CupertinoColors.activeBlue,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.pencil,
                label: 'Изменить',
              ),
            ],
          ),
          child: _buildOrderItemTile(index),
        );
      },
    );
  }

  Widget _buildOrderItemTile(int index) {
    final item = order_items[index];
    return CupertinoListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          item["img"] ?? "/",
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(item["name"]),
      subtitle: Text("${item["amount"]} шт"),
      trailing: Text(
        "${item["price"]} ₽",
        style: TextStyle(color: CupertinoColors.secondaryLabel),
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
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    amount = widget.order_item["amount"];
    _textController.text = amount.toString();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Изменить количество'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Отмена'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                widget.order_item["name"],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoTextField(
                controller: _textController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      amount = double.tryParse(value) ?? amount;
                    });
                  }
                },
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8),
                ),
                placeholder: "Введите количество",
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoButton.filled(
                onPressed: () {
                  if (amount < (widget.order_item["amount"] as num) &&
                      amount > 0) {
                    changeAmount(
                      widget.order_item["relation_id"],
                      amount.toString(),
                    ).then((_) => Navigator.pop(context));
                  } else {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text("Ошибка"),
                        content: Text("Введите корректное количество"),
                        actions: [
                          CupertinoDialogAction(
                            child: Text("OK"),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text("Подтвердить"),
              ),
            ),
          ],
        ),
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
    super.initState();
    _getReplacements();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Замена товара'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Отмена'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: ListView.separated(
          itemCount: replacementItems.length,
          separatorBuilder: (context, index) => Container(),
          itemBuilder: (context, index) {
            final item = replacementItems[index];
            return CupertinoListTile(
              title: Text(item["name"]),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  replaceItem(
                    widget.order_item["relation_id"].toString(),
                    item["item_id"].toString(),
                  ).then((_) => Navigator.pop(context));
                },
                child: Text("Выбрать"),
              ),
            );
          },
        ),
      ),
    );
  }
}
