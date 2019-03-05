import 'dart:async';

import 'package:dragablegridview_flutter/dragablegridviewbin.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef CreateChild = Widget Function(int position);
typedef EditChangeListener();

class DragAbleGridView<T extends DragAbleGridViewBin> extends StatefulWidget {
  final CreateChild child;
  final List<T> itemBins;

  final int crossAxisCount;

  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  final EditSwitchController editSwitchController;

  final int animationDuration;

  final Widget deleteIcon;

  DragAbleGridView({
    @required this.child,
    @required this.itemBins,
    this.crossAxisCount: 4,
    this.childAspectRatio: 1.0,
    this.mainAxisSpacing: 0.0,
    this.crossAxisSpacing: 0.0,
    this.editSwitchController,
    this.animationDuration: 300,
    this.deleteIcon,
  }) : assert(child != null, itemBins != null,);

  @override
  State<StatefulWidget> createState() {
    return new DragAbleGridViewState<T>();
  }
}

class DragAbleGridViewState<T extends DragAbleGridViewBin>
    extends State<DragAbleGridView> with SingleTickerProviderStateMixin {
  final _userScrollable = const ScrollPhysics();
  final dragContainerKey = GlobalKey<_PlaceholderItemState>();

  var scrollPhysics;

  final scrollController = ScrollController();

  double screenWidth;
  double screenHeight;

  List<int> itemPositions;

  double itemWidth;
  double itemHeight;
  double itemWidthChild;
  double itemHeightChild;

  double blankSpaceHorizontal;
  double blankSpaceVertical;

  Animation<double> animation;
  AnimationController shuffleAnimationController;
  int startPosition;
  int endPosition;
  bool isRest = false;

  Timer timer;
  bool isRemoveItem = false;
  Future _future;

  @override
  void initState() {
    super.initState();
    scrollPhysics = _userScrollable;

    widget.editSwitchController.dragAbleGridViewState = this;
    shuffleAnimationController = AnimationController(
        duration: Duration(milliseconds: widget.animationDuration),
        vsync: this);
    animation = Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(
          curve: Curves.easeIn,
        ))
        .animate(shuffleAnimationController)
          ..addListener(_shuffleAnimation);
    animation.addStatusListener(_shuffleStatusListner);
    _initItemPositions();
  }

  void _initItemPositions() {
    itemPositions = List();
    for (int i = 0; i < widget.itemBins.length; i++) {
      itemPositions.add(i);
    }
  }

  void _shuffleStatusListner(animationStatus) {
    if (animationStatus == AnimationStatus.completed) {
      setState(() {});
      isRest = true;
      shuffleAnimationController.reset();
      isRest = false;

      if (isRemoveItem) {
        isRemoveItem = false;
        itemPositions.removeAt(startPosition);
        onPanEndEvent(startPosition);
      } else {
        int dragPosition = itemPositions[startPosition];
        itemPositions.removeAt(startPosition);
        itemPositions.insert(endPosition, dragPosition);

        startPosition = endPosition;
      }
    } else if (animationStatus == AnimationStatus.forward) {}
  }

  void _shuffleAnimation() {
    T offsetBin;
    int childWidgetPosition;

    if (isRest) {
      if (startPosition > endPosition) {
        for (int i = endPosition; i < startPosition; i++) {
          childWidgetPosition = itemPositions[i];
          offsetBin = widget.itemBins[childWidgetPosition];

          if ((i + 1) % widget.crossAxisCount == 0) {
            offsetBin.lastTimePositionX =
                -(screenWidth - itemWidth) * 1 + offsetBin.lastTimePositionX;
            offsetBin.lastTimePositionY =
                (itemHeight + widget.mainAxisSpacing) * 1 +
                    offsetBin.lastTimePositionY;
          } else {
            offsetBin.lastTimePositionX =
                (itemWidth + widget.crossAxisSpacing) * 1 +
                    offsetBin.lastTimePositionX;
          }
        }
      } else {
        for (int i = startPosition + 1; i <= endPosition; i++) {
          childWidgetPosition = itemPositions[i];
          offsetBin = widget.itemBins[childWidgetPosition];

          if (i % widget.crossAxisCount == 0) {
            offsetBin.lastTimePositionX =
                (screenWidth - itemWidth) * 1 + offsetBin.lastTimePositionX;
            offsetBin.lastTimePositionY =
                -(itemHeight + widget.mainAxisSpacing) * 1 +
                    offsetBin.lastTimePositionY;
          } else {
            offsetBin.lastTimePositionX =
                -(itemWidth + widget.crossAxisSpacing) * 1 +
                    offsetBin.lastTimePositionX;
          }
        }
      }
      return;
    }

    setState(() {
      if (startPosition > endPosition) {
        for (int i = endPosition; i < startPosition; i++) {
          childWidgetPosition = itemPositions[i];
          offsetBin = widget.itemBins[childWidgetPosition];
          if ((i + 1) % widget.crossAxisCount == 0) {
            offsetBin.dragPointX =
                -(screenWidth - itemWidth) * animation.value +
                    offsetBin.lastTimePositionX;
            offsetBin.dragPointY =
                (itemHeight + widget.mainAxisSpacing) * animation.value +
                    offsetBin.lastTimePositionY;
          } else {
            offsetBin.dragPointX =
                (itemWidth + widget.crossAxisSpacing) * animation.value +
                    offsetBin.lastTimePositionX;
          }
        }
      } else {
        for (int i = startPosition + 1; i <= endPosition; i++) {
          childWidgetPosition = itemPositions[i];
          offsetBin = widget.itemBins[childWidgetPosition];
          if (i % widget.crossAxisCount == 0) {
            offsetBin.dragPointX = (screenWidth - itemWidth) * animation.value +
                offsetBin.lastTimePositionX;
            offsetBin.dragPointY =
                -(itemHeight + widget.mainAxisSpacing) * animation.value +
                    offsetBin.lastTimePositionY;
          } else {
            offsetBin.dragPointX =
                -(itemWidth + widget.crossAxisSpacing) * animation.value +
                    offsetBin.lastTimePositionX;
          }
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Size screenSize = MediaQuery.of(context).size;
    screenWidth = screenSize.width;
    screenHeight = screenSize.height;
  }

  @override
  Widget build(BuildContext context) {
    return new NotificationListener(
        onNotification: (onNotifications) {},
        child: Stack(
          children: <Widget>[
            GridView.builder(
                physics: scrollPhysics,
                scrollDirection: Axis.vertical,
                controller: scrollController,
                itemCount: widget.itemBins.length,
                gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.crossAxisCount,
                    childAspectRatio: widget.childAspectRatio,
                    crossAxisSpacing: widget.crossAxisSpacing,
                    mainAxisSpacing: widget.mainAxisSpacing),
                itemBuilder: (BuildContext contexts, int index) {
                  return GestureDetector(
                    onLongPressDragStart: (details) {
                      _onLongDownEvent(index, details);
                    },
                    onLongPressDragUpdate: (details) {
                      _onLongPressDragUpdate(index, details);
                    },
                    onLongPressDragUp: (details) {
                      _onLongPressDragUp(index);
                      dragContainerKey.currentState.clearItem();
                    },
                    key: widget.itemBins[index].containerKey,
                    child: Container(
                      alignment: Alignment.center,
                      child: OverflowBox(
                          maxWidth: screenWidth,
                          maxHeight: screenHeight,
                          alignment: Alignment.center,
                          child: new Center(
                            child: new Container(
                              key: widget.itemBins[index].containerKeyChild,
                              transform: new Matrix4.translationValues(
                                  widget.itemBins[index].dragPointX,
                                  widget.itemBins[index].dragPointY,
                                  0.0),
                              child: widget.itemBins[index].isLongPress
                                  ? null
                                  : widget.child(index),
                            ),
                          )),
                    ),
                  );
                }),
            PlaceholderItem<T>(
              key: dragContainerKey,
              itemBins: widget.itemBins,
              itemBuilder: widget.child,
            )
          ],
        ));
  }

  void _onLongPressDragUp(int index) {
    T pressItemBin = widget.itemBins[index];

    pressItemBin.isLongPress = false;
    if (!pressItemBin.dragAble) {
      pressItemBin.dragPointY = 0.0;
      pressItemBin.dragPointX = 0.0;
    } else {
      onPanEndEvent(index);
    }
  }

  void _onLongDownEvent(int index, GestureLongPressDragStartDetails detail) {
    T pressItemBin = widget.itemBins[index];

    dragContainerKey.currentState.setItem(index);

    final RenderBox box =
        pressItemBin.containerKey.currentContext.findRenderObject();

    itemWidth = box.paintBounds.size.width;
    itemHeight = box.paintBounds.size.height;

    itemWidthChild = pressItemBin.containerKeyChild.currentContext
        .findRenderObject()
        .paintBounds
        .size
        .width;
    itemHeightChild = pressItemBin.containerKeyChild.currentContext
        .findRenderObject()
        .paintBounds
        .size
        .height;

    blankSpaceHorizontal = (itemWidth - itemWidthChild) / 2;
    blankSpaceVertical = (itemHeight - itemHeightChild) / 2;

    final position =
        box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
    pressItemBin.startPositionX = position.dx + blankSpaceHorizontal;
    pressItemBin.startPositionY = position.dy + blankSpaceVertical;

    pressItemBin.isLongPress = true;

    endPosition = index;

    setState(() {
      widget.itemBins[index].dragAble = true;
      startPosition = index;
    });
  }

  void _onLongPressDragUpdate(
      int index, GestureLongPressDragUpdateDetails updateDetail) {
    T pressItemBin = widget.itemBins[index];

    pressItemBin.dragPointY = updateDetail.offsetFromOrigin.dy;
    pressItemBin.dragPointX = updateDetail.offsetFromOrigin.dx;

    if (timer != null && timer.isActive) {
      timer.cancel();
    }

    if (shuffleAnimationController.isAnimating) {
      return;
    }
    timer = Timer(Duration(milliseconds: 30), () {
      _shuffleBins(index, pressItemBin.dragPointX, pressItemBin.dragPointY);
    });

    setState(() {});
  }

  void _shuffleBins(int index, double dragPointX, double dragPointY) async {
    double xBlankPlace = blankSpaceHorizontal * 2 + widget.crossAxisSpacing;
    double yBlankPlace = blankSpaceVertical * 2 + widget.mainAxisSpacing;

    int y = geyYTransferItemCount(index, yBlankPlace, dragPointY);
    int x = geyXTransferItemCount(index, xBlankPlace, dragPointX);

    if (endPosition != x + y &&
        !shuffleAnimationController.isAnimating &&
        x + y < widget.itemBins.length &&
        x + y >= 0 &&
        widget.itemBins[index].dragAble) {
      endPosition = x + y;
      _future = shuffleAnimationController.forward();
    }
  }

  int geyXTransferItemCount(int index, double xBlankPlace, double dragPointX) {
    if (dragPointX.abs() > xBlankPlace) {
      if (dragPointX > 0) {
        return checkXAxleRight(index, xBlankPlace, dragPointX);
      } else {
        return checkXAxleLeft(index, xBlankPlace, dragPointX);
      }
    } else {
      return 0;
    }
  }

  int checkXAxleRight(int index, double xBlankPlace, double dragPointX) {
    double aSection = xBlankPlace + itemWidthChild;
    double rightTransferDistance = dragPointX.abs() + itemWidthChild;
    double rightBorder = rightTransferDistance % aSection;
    double leftBorder = dragPointX.abs() % aSection;

    if (rightBorder < itemWidthChild && leftBorder < itemWidthChild) {
      if (itemWidthChild - leftBorder > rightBorder) {
        return (dragPointX.abs() / aSection).floor();
      } else {
        return (rightTransferDistance / aSection).floor();
      }
    } else if (rightBorder > itemWidthChild && leftBorder < itemWidthChild) {
      return (dragPointX.abs() / aSection).floor();
    } else if (rightBorder < itemWidthChild && leftBorder > itemWidthChild) {
      return (rightTransferDistance / aSection).floor();
    } else {
      return 0;
    }
  }

  int checkXAxleLeft(int index, double xBlankPlace, double dragPointX) {
    double aSection = xBlankPlace + itemWidthChild;
    double leftTransferDistance = dragPointX.abs() + itemWidthChild;
    double leftBorder = leftTransferDistance % aSection;
    double rightBorder = dragPointX.abs() % aSection;

    if (rightBorder < itemWidthChild && leftBorder < itemWidthChild) {
      if (itemWidthChild - rightBorder > leftBorder) {
        return -(dragPointX.abs() / aSection).floor();
      } else {
        return -(leftTransferDistance / aSection).floor();
      }
    } else if (rightBorder > itemWidthChild && leftBorder < itemWidthChild) {
      return -(leftTransferDistance / aSection).floor();
    } else if (rightBorder < itemWidthChild && leftBorder > itemWidthChild) {
      return -(dragPointX.abs() / aSection).floor();
    } else {
      return 0;
    }
  }


  int geyYTransferItemCount(int index, double yBlankPlace, double dragPointY) {
    if (dragPointY.abs() > yBlankPlace) {
      if (dragPointY > 0) {
        return checkYAxleBelow(index, yBlankPlace, dragPointY);
      } else {
        return checkYAxleAbove(index, yBlankPlace, dragPointY);
      }
    } else {
      return index;
    }
  }

  int checkYAxleAbove(int index, double yBlankPlace, double dragPointY) {
    double aSection = yBlankPlace + itemHeightChild;
    double topTransferDistance = dragPointY.abs() + itemHeightChild;
    double topBorder = (topTransferDistance) % aSection;
    double bottomBorder = dragPointY.abs() % aSection;

    if (topBorder < itemHeightChild && bottomBorder < itemHeightChild) {
      if (itemHeightChild - bottomBorder > topBorder) {
        return index -
            (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
      } else {
        return index -
            (topTransferDistance / aSection).floor() * widget.crossAxisCount;
      }
    } else if (topBorder > itemHeightChild && bottomBorder < itemHeightChild) {
      return index -
          (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
    } else if (topBorder < itemHeightChild && bottomBorder > itemHeightChild) {
      return index -
          (topTransferDistance / aSection).floor() * widget.crossAxisCount;
    } else {
      return index;
    }
  }

  int checkYAxleBelow(int index, double yBlankPlace, double dragPointY) {
    double aSection = yBlankPlace + itemHeightChild;
    double bottomTransferDistance = dragPointY.abs() + itemHeightChild;
    double bottomBorder = bottomTransferDistance % aSection;
    double topBorder = dragPointY.abs() % aSection;

    if (bottomBorder < itemHeightChild && topBorder < itemHeightChild) {
      if (itemHeightChild - topBorder > bottomBorder) {
        return index +
            (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
      } else {
        return index +
            (bottomTransferDistance / aSection).floor() * widget.crossAxisCount;
      }
    } else if (topBorder > itemHeightChild && bottomBorder < itemHeightChild) {
      return index +
          (bottomTransferDistance / aSection).floor() * widget.crossAxisCount;
    } else if (topBorder < itemHeightChild && bottomBorder > itemHeightChild) {
      return index +
          (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
    } else {
      return index;
    }
  }

  void onPanEndEvent(index) async {
    widget.itemBins[index].dragAble = false;
    if (shuffleAnimationController.isAnimating) {
      await _future;
    }
    setState(() {
      scrollPhysics = _userScrollable;

      List<T> itemBi = List();
      T bin;
      for (int i = 0; i < itemPositions.length; i++) {
        bin = widget.itemBins[itemPositions[i]];
        bin.dragPointX = 0.0;
        bin.dragPointY = 0.0;
        bin.lastTimePositionX = 0.0;
        bin.lastTimePositionY = 0.0;
        itemBi.add(bin);
      }
      widget.itemBins.clear();
      widget.itemBins.addAll(itemBi);
      _initItemPositions();
    });
  }


}

class EditSwitchController {
  DragAbleGridViewState dragAbleGridViewState;

  void editStateChanged() {
  }
}

class PlaceholderItem<T extends DragAbleGridViewBin> extends StatefulWidget {
  final List<T> itemBins;
  final CreateChild itemBuilder;

  PlaceholderItem({Key key, this.itemBins, this.itemBuilder}) : super(key: key);

  _PlaceholderItemState createState() => _PlaceholderItemState();
}

class _PlaceholderItemState extends State<PlaceholderItem> {
  int _item;

  setItem(int index) {
    setState(() {
      _item = index;
    });
  }

  clearItem() {
    setState(() {
      _item = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_item == null) {
      return Container();
    }
    final bin = widget.itemBins[_item];

    return Container(
      transform: new Matrix4.translationValues(
          bin.startPositionX + bin.dragPointX,
          bin.startPositionY + bin.dragPointY,
          0.0),
      child: widget.itemBuilder(_item),
    );
  }
}
