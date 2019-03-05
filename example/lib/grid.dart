import 'dart:async';

import 'package:dragablegridview_flutter/dragablegridview_flutter.dart';
import 'package:dragablegridview_flutter/dragablegridviewbin.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DragAbleGridViewDemo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new DragAbleGridViewDemoState();
  }
}

class DragAbleGridViewDemoState extends State<DragAbleGridViewDemo> {
  static final String storeKey = 'itemIds';

  List<ItemBin> itemBins = List();
  final controller = DragAbleGridViewController(persistentSelection: false);
  bool isSelecting = false;
  Timer timer;

  @override
  void initState() {
    super.initState();

    _loadStoredData();

    addOrRemoveItem();
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    timer = null;
  }

  void _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();

    itemBins.clear();
    final items = prefs.getStringList(storeKey) ?? _defaultData();
    items.forEach((item) {
      itemBins.add(ItemBin(item));
    });
    controller.refreshItemsPositions();
  }

  void addOrRemoveItem() {
    timer?.cancel();

    setState(() {
      if (itemBins.length < 20) {
        itemBins.add(ItemBin(itemBins.length.toString()));
      } else {
        itemBins.removeLast();
      }
    });

    _saveDataToStore();

    timer = Timer(Duration(seconds: 10), () {
      addOrRemoveItem();
    });
  }

  void _saveDataToStore() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> storeList = itemBins.map((item) => item.data).toList();
    prefs.setStringList(storeKey, storeList);
    controller.refreshItemsPositions();
  }

  List<String> _defaultData() {
    List<String> _defaultItems = List();
    for (int i = 0; i < 4; i++) {
      _defaultItems.add(i.toString());
    }
    return _defaultItems;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = 5.0;

    final columns = 3;
    final itemHeight = width / columns;
    final itemWidth = itemHeight; // - spacing * (columns - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text("GridView"),
        actions: <Widget>[
          Center(
              child: GestureDetector(
            child: Container(
              child: Text(
                isSelecting ? 'Done' : 'Select',
                style: TextStyle(fontSize: 19.0),
              ),
              margin: EdgeInsets.only(right: 12),
            ),
            onTap: () {
              setState(() {
                isSelecting = !isSelecting;
              });
              controller.setSelectedMode(isSelecting);
            },
          ))
        ],
      ),
      body: DragAbleGridView(
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1,
        crossAxisCount: columns,
        itemBins: itemBins,
        controller: controller,
        animationDuration: 100, //milliseconds
        onReorder: () {
          print('==========');
          itemBins.forEach((item) {
            print('Item ${item.data}');
          });

          _saveDataToStore();
        },
        itemBuilder: (BuildContext context, int position) {
          return Container(
            height: itemHeight,
            width: itemWidth,
            padding: EdgeInsets.all(2.0),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(new Radius.circular(3.0)),
                  border: Border.all(color: Colors.black87),
                  color: itemBins[position].isSelected
                      ? Colors.red
                      : Colors.blueGrey),
              padding: EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(
                itemBins[position].data,
                style: TextStyle(fontSize: 16.0, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ItemBin extends DragAbleGridViewBin {
  ItemBin(this.data);

  String data;

  @override
  String toString() {
    return 'ItemBin{data: $data, dragPointX: $dragPointX, dragPointY: $dragPointY, lastTimePositionX: $lastTimePositionX, lastTimePositionY: $lastTimePositionY, containerKey: $containerKey, isDraging: $isDraging}';
  }
}
