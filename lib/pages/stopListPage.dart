import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:naliv_merchant/api.dart';

class StopListPage extends StatefulWidget {
  const StopListPage({super.key});

  @override
  State<StopListPage> createState() => _StopListPageState();
}

class _StopListPageState extends State<StopListPage> {
  late Timer _timer;
  List<Map<dynamic, dynamic>> items = [];
  List<Map<dynamic, dynamic>> stopListItems = [];
  TextEditingController _search = TextEditingController();

  _getItems() {
    getItems().then((v) {
      if (v != null && v["items"] != null) {
        setState(() {
          items = (v["items"] as List)
              .map((item) => Map<dynamic, dynamic>.from(item as Map))
              .toList();
        });
      }
    });
  }

  _getStopListItems() {
    getItemStopList().then((v) {
      if (v != null) {
        setState(() {
          stopListItems = (v as List)
              .map((item) => Map<dynamic, dynamic>.from(item as Map))
              .toList();
        });
      }
    });
  }

  String convertToLocalTime(String utcTimeStr) {
    DateTime utcTime =
        DateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS").parseUtc(utcTimeStr);
    DateTime localTime = utcTime.toLocal();
    return DateFormat("yyyy-MM-dd HH:mm:ss").format(localTime);
  }

  @override
  void initState() {
    super.initState();
    _getStopListItems();
    _timer = Timer.periodic(new Duration(seconds: 10), (timer) {
      debugPrint(timer.tick.toString());
      _getStopListItems();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Стоп-лист"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.add),
          onPressed: () {
            _getItems();
            showCupertinoModalPopup(
              context: context,
              builder: (context) => _SearchModalContent(
                items: items,
                onItemSelected: (item) {
                  addItemStopList(
                    item["item_id"].toString(),
                    item["hours"], // используем выбранное количество часов
                  ).then((_) {
                    _getStopListItems();
                    Navigator.pop(context);
                  });
                },
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: ListView.separated(
          itemCount: stopListItems.length,
          separatorBuilder: (context, index) => Container(height: 1),
          itemBuilder: (context, index) {
            return CupertinoListTile(
              title: Text(stopListItems[index]["name"]),
              subtitle: Text(
                convertToLocalTime(stopListItems[index]["end_at"]),
                style: TextStyle(color: CupertinoColors.secondaryLabel),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchModalContent extends StatefulWidget {
  final List items;
  final Function(Map) onItemSelected;

  const _SearchModalContent({
    required this.items,
    required this.onItemSelected,
  });

  @override
  State<_SearchModalContent> createState() => _SearchModalContentState();
}

class _SearchModalContentState extends State<_SearchModalContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List _filterItems() {
    if (_searchText.isEmpty) {
      return widget.items;
    }

    final String searchLower = _searchText.toLowerCase();

    return widget.items.where((item) {
      final String name = (item["name"] ?? "").toString().toLowerCase();
      final String code = (item["code"] ?? "").toString().toLowerCase();

      // Быстрая проверка на точное совпадение
      if (name.contains(searchLower) || code.contains(searchLower)) {
        return true;
      }

      // Поиск по отдельным словам
      final List<String> searchWords =
          searchLower.split(' ').where((word) => word.isNotEmpty).toList();

      return searchWords
          .every((word) => name.contains(word) || code.contains(word));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filterItems();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: "Поиск по названию или коду",
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),
          if (filteredItems.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  "Ничего не найдено",
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: filteredItems.length,
                separatorBuilder: (context, index) => Container(height: 1),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return CupertinoListTile(
                    title: Text(item["name"] ?? ""),
                    subtitle: Text(
                      item["code"] ?? "",
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel,
                        fontSize: 13,
                      ),
                    ),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(CupertinoIcons.add),
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) =>
                              CupertinoActionSheet(
                            title: Text('На какое время убрать позицию?'),
                            actions: <CupertinoActionSheetAction>[
                              CupertinoActionSheetAction(
                                child: Text('1 час'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget
                                      .onItemSelected({...item, 'hours': '1'});
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: Text('3 часа'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget
                                      .onItemSelected({...item, 'hours': '3'});
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: Text('12 часов'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget
                                      .onItemSelected({...item, 'hours': '12'});
                                },
                              ),
                              CupertinoActionSheetAction(
                                child: Text('24 часа'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget
                                      .onItemSelected({...item, 'hours': '24'});
                                },
                              ),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              child: Text('Отмена'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
