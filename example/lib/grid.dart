import 'dart:async';

import 'package:dragablegridview_flutter/dragablegridview_flutter.dart';
import 'package:dragablegridview_flutter/dragablegridviewbin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprung/sprung.dart';

class DragAbleGridViewDemo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new DragAbleGridViewDemoState();
  }
}

class DragAbleGridViewDemoState extends State<DragAbleGridViewDemo>
    with SingleTickerProviderStateMixin {
  static final String storeKey = 'itemIds';

  List<ItemBin> itemBins = List();
  final controller = DragAbleGridViewController(persistentSelection: false);
  bool isSelecting = false;
  bool hasSelection = false;
  Timer timer;

  Animation<double> _scaleAnimation;
  AnimationController _dragScaleController;

  @override
  void initState() {
    super.initState();

    _loadStoredData();

    _dragScaleController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
    timer = null;
    _dragScaleController.dispose();
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
      if (itemBins.length < 10) {
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
    for (int i = 0; i < 20; i++) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text("GridView"),
        leading: isSelecting
            ? IconButton(
                icon: Icon(Icons.delete),
                onPressed: hasSelection
                    ? () {
                        setState(() {
                          itemBins = itemBins
                              .where((item) => !item.isSelected)
                              .toList();
                          hasSelection = false;
                        });
                      }
                    : null,
              )
            : null,
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
            onTap: () async {
              setState(() {
                isSelecting = !isSelecting;
                hasSelection = (controller.getSelected()?.length ?? 0) > 0;
              });
              controller.setSelectedMode(isSelecting);
            },
          ))
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  itemBins.add(ItemBin(itemBins.length.toString()));
                  //controller.refreshItemsPositions();
                });
              },
            ),
          ),
          FloatingActionButton(
            backgroundColor: Colors.red,
            child: Icon(Icons.remove),
            onPressed: () {
              if (itemBins.isNotEmpty) {
                setState(() {
                  itemBins.removeLast();
                  //controller.refreshItemsPositions();
                });
              }
            },
          )
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
        onReorder: (items) {
          _saveDataToStore();
          _dragScaleController.reset();
        },
        onSelectionChanged: (index) {
          setState(() {
            final numberSelected = controller.getSelected()?.length ?? 0;

            hasSelection = numberSelected > 0;
          });
        },
        onDragStarted: (index) {
          HapticFeedback.lightImpact();
          _dragScaleController.forward();
        },
        itemBuilder: (BuildContext context, int position) {
          _scaleAnimation = Tween<double>(
            begin: 0.8,
            end: 1.05,
          ).animate(CurvedAnimation(
            parent: _dragScaleController,
            curve: Sprung(damped: Damped.under),
          ));

          final isDragging = itemBins[position].isDraging;

          final container = Container(
              height: itemHeight,
              width: itemHeight,
              padding: EdgeInsets.all(2.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(new Radius.circular(3.0)),
                    border: isDragging
                        ? Border.all(width: 3.0, color: Colors.red)
                        : Border.all(color: Colors.black87),
                    color: itemBins[position].isSelected
                        ? Colors.red
                        : Colors.blueGrey),
                padding: EdgeInsets.all(8.0),
                alignment: Alignment.center,
                child: Text(
                  itemBins[position].data,
                  style: TextStyle(fontSize: 16.0, color: Colors.white),
                ),
              ));

          return isDragging
              ? ScaleTransition(scale: _scaleAnimation, child: container)
              : container;
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
