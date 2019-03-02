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
    final spacing = 10.0;

    final columns = 4;
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
              changeActionState();
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
        isOpenDragAble: true,
        animationDuration: 300, //milliseconds
        longPressDuration: 800, //milliseconds
        /******************************new parameter*********************************/

        // deleteIcon: Container(
        //     decoration: BoxDecoration(
        //       color: Colors.red,
        //       shape: BoxShape.circle,
        //     ),
        //     child: Icon(Icons
        //         .close)), //Image.asset("images/close.png", width: 15.0, height: 15.0),
        child: (int position) {
          return Container(
            height: itemHeight,
            width: itemWidth,

            padding: EdgeInsets.fromLTRB(8.0, 5.0, 8.0, 5.0),
            decoration: new BoxDecoration(
              borderRadius: BorderRadius.all(new Radius.circular(3.0)),
              border: new Border.all(color: Colors.black87),
              color: itemBins[position].dragAble ? Colors.red : Colors.blueGrey
            ),
            //Because this layout and the delete_Icon are in the same Stack, setting marginTop and marginRight will make the icon in the proper position.
            margin: EdgeInsets.only(top: 6.0, right: 6.0),
            child: Text(
              itemBins[position].data,
              style: new TextStyle(fontSize: 16.0, color: Colors.white),
            ),
          );
        },
        editChangeListener: () {
          changeActionState();
        },
      ),
    );
  }

  void changeActionState() {
    if (actionTxt == actionTxtEdit) {
      setState(() {
        actionTxt = actionTxtComplete;
      });
    } else {
      setState(() {
        actionTxt = actionTxtEdit;
      });
    }
  }
}

class ItemBin extends DragAbleGridViewBin {
  ItemBin(this.data);

  String data;

  @override
  String toString() {
    return 'ItemBin{data: $data, dragPointX: $dragPointX, dragPointY: $dragPointY, lastTimePositionX: $lastTimePositionX, lastTimePositionY: $lastTimePositionY, containerKey: $containerKey, containerKeyChild: $containerKeyChild, isLongPress: $isLongPress, dragAble: $dragAble}';
  }
}
