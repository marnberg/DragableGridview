import 'package:dragablegridview_flutter/dragablegridview_flutter.dart';
import 'package:dragablegridview_flutter/dragablegridviewbin.dart';
import 'package:flutter/material.dart';

class DragAbleGridViewDemo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new DragAbleGridViewDemoState();
  }
}

class DragAbleGridViewDemoState extends State<DragAbleGridViewDemo> {
  List<ItemBin> itemBins = List();
  String actionTxtEdit = "Edit";
  String actionTxtComplete = "Done";
  String actionTxt;
  var editSwitchController = EditSwitchController();

  @override
  void initState() {
    super.initState();
    actionTxt = actionTxtEdit;

    for (int i = 0; i < 1000; i++) {
      itemBins.add(ItemBin(i.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = 5.0;

    final columns = 1;
    final itemHeight = width / columns;
    final itemWidth = itemHeight; // - spacing * (columns - 1);

    return new Scaffold(
      appBar: new AppBar(
        title: new Text("GridView"),
        actions: <Widget>[
          new Center(
              child: new GestureDetector(
            child: new Container(
              child: new Text(
                actionTxt,
                style: TextStyle(fontSize: 19.0),
              ),
              margin: EdgeInsets.only(right: 12),
            ),
            onTap: () {
              editSwitchController.editStateChanged();
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
        editSwitchController: editSwitchController,
        /******************************new parameter*********************************/
        animationDuration: 300, //milliseconds
        /******************************new parameter*********************************/
        child: (int position) {
          return Container(
            height: itemHeight,
            width: itemWidth,
            padding: EdgeInsets.all(2.0),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(new Radius.circular(3.0)),
                  border: Border.all(color: Colors.black87),
                  color: itemBins[position].dragAble
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
    return 'ItemBin{data: $data, dragPointX: $dragPointX, dragPointY: $dragPointY, lastTimePositionX: $lastTimePositionX, lastTimePositionY: $lastTimePositionY, containerKey: $containerKey, isLongPress: $isLongPress, dragAble: $dragAble}';
  }
}
