import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naliv_merchant/api.dart';
import 'package:naliv_merchant/pages/activeOrders.dart';
import 'package:naliv_merchant/pages/editOrder.dart';

class ChangeAmountPage extends StatefulWidget {
  const ChangeAmountPage({super.key, required this.item, required this.order_id, required this.order});
  final Map item;
  final String order_id;
  final Map order;
  @override
  State<ChangeAmountPage> createState() => _ChangeAmountPageState();
}

class _ChangeAmountPageState extends State<ChangeAmountPage> {
  double amount = 0;
  double _currentAmount = 0;
  bool isButtonActive = true;
  TextEditingController _amount = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      amount = widget.item["amount"];
      _amount.text = amount.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            flex: 3,
            child: Image.network(widget.item["img"]),
          ),
          Flexible(
              child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  widget.item["name"],
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24),
                ),
              ),
              Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.item["amount"].toString(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24),
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
                  widget.item["code"],
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          )),
          Flexible(
              child: Card(
                  margin: EdgeInsets.all(10),
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Flexible(
                          child: Text(
                            "Количество",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                          ),
                        ),
                        Spacer(),
                        Flexible(
                            flex: 3,
                            child: Container(
                              child: TextField(
                                onChanged: (String value) {
                                  print('Changed');
                                  double x;
                                  if (double.parse(value) <= amount && double.parse(value) >= amount * 0.3) {
                                    setState(() {
                                      isButtonActive = true;
                                    });
                                  } else {
                                    setState(() {
                                      isButtonActive = false;
                                    });
                                  }
                                  // try {
                                  //   x = double.parse(value);
                                  // } catch (error) {
                                  //   x = amount;
                                  // }
                                  // if (x < amount / 2) {
                                  //   x = amount / 2;
                                  //   _amount.text = x.toString();
                                  // } else if (x > amount) {
                                  //   x = amount;
                                  //   _amount.text = x.toString();
                                  // }
                                  // _amount.value = TextEditingValue(
                                  //     text: x.toString(),
                                  //     selection: TextSelection.fromPosition(
                                  //       TextPosition(
                                  //           offset: _amount
                                  //               .value.selection.baseOffset),
                                  //     ));
                                },
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]+[,.]{0,1}[0-9]*')),
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) => newValue.copyWith(
                                      text: newValue.text.replaceAll(',', '.'),
                                    ),
                                  ),
                                ],
                                controller: _amount,
                              ),
                            ))
                      ],
                    ),
                  ))),
          Flexible(
              child: ElevatedButton(
                  onPressed: isButtonActive
                      ? () {
                          changeAmount(widget.item["relation_id"], _amount.text).then((v) {
                            Navigator.pushReplacement(context, MaterialPageRoute(
                              builder: (context) {
                                return EditOrderPage(order_id: widget.order_id, order: widget.order);
                              },
                            ));
                          });
                        }
                      : null,
                  child: Text("Готово")))
        ],
      )),
    );
  }
}
