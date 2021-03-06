import 'dart:async';

import 'package:dragablegridview_flutter/dragablegridviewbin.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef CreateChild = Widget Function(int position);
typedef EditChangeListener();

class DragAbleGridView<T extends DragAbleGridViewBin> extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final List<T> itemBins;
  final Size containerSize;

  final int crossAxisCount;

  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  final DragAbleGridViewController controller;
  final ValueChanged<List<T>> onReorder;
  final void Function(int) onSelectionChanged;
  final void Function(int) onDragStarted;

  final int animationDuration;
  final bool requireEditToReorder;
  final ScrollPhysics scrollPhysics;


  DragAbleGridView({
    Key key,
    @required this.itemBuilder,
    @required this.itemBins,
    this.crossAxisCount: 4,
    this.childAspectRatio: 1.0,
    this.mainAxisSpacing: 0.0,
    this.crossAxisSpacing: 0.0,
    this.controller,
    this.animationDuration: 300,
    this.requireEditToReorder: false,
    this.onReorder,
    this.onSelectionChanged,
    this.onDragStarted,
    this.containerSize,
    this.scrollPhysics = const ScrollPhysics()
  })  : assert(
          itemBuilder != null,
          itemBins != null,
        ),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _DragAbleGridViewState<T>();
  }
}

class _DragAbleGridViewState<T extends DragAbleGridViewBin>
    extends State<DragAbleGridView> with SingleTickerProviderStateMixin {
  final dragContainerKey = GlobalKey<_PlaceholderItemState>();

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

  bool isRemoveItem = false;
  Future _future;

  bool isSelecting = false;
  Set<int> selectedPositions = Set();

  @override
  void initState() {
    super.initState();

    widget.controller?._dragAbleGridViewState = this;
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
    selectedPositions.clear();
    setState(() {});
  }

  List<T> _itemBins() {
    if (itemPositions?.length != widget.itemBins.length) {
      itemPositions = List();
      for (int i = 0; i < widget.itemBins.length; i++) {
        itemPositions.add(i);
      }
      selectedPositions.clear();
    }
    return widget.itemBins;
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
          offsetBin = _itemBins()[childWidgetPosition];

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
          offsetBin = _itemBins()[childWidgetPosition];

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
          offsetBin = _itemBins()[childWidgetPosition];
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
          offsetBin = _itemBins()[childWidgetPosition];
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
    if (widget.containerSize != null) {
      screenWidth = widget.containerSize.width;
      screenHeight = widget.containerSize.height;
    } else {
      Size screenSize = MediaQuery.of(context).size;
      screenWidth = screenSize.width;
      screenHeight = screenSize.height;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GridView.builder(
            physics: widget.scrollPhysics,
            scrollDirection: Axis.vertical,
            controller: scrollController,
            itemCount: _itemBins().length,
            gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.crossAxisCount,
                childAspectRatio: widget.childAspectRatio,
                crossAxisSpacing: widget.crossAxisSpacing,
                mainAxisSpacing: widget.mainAxisSpacing),
            itemBuilder: (BuildContext contexts, int index) {
              return GestureDetector(
                onTap: isSelecting
                    ? () {
                        setState(() {
                          _itemBins()[index].isSelected =
                              !_itemBins()[index].isSelected;
                          if (_itemBins()[index].isSelected) {
                            selectedPositions.add(index);
                          } else {
                            selectedPositions.remove(index);
                          }
                        });
                        if (widget.onSelectionChanged != null) {
                          widget.onSelectionChanged(index);
                        }
                      }
                    : null,
                onLongPressStart: (details) {
                  if (!widget.requireEditToReorder || isSelecting) {
                    _onLongPressDragStart(index, details);
                  }
                },
                onLongPressMoveUpdate: (details) {
                  if (!widget.requireEditToReorder || isSelecting) {
                    _onLongPressDragUpdate(index, details);
                  }
                },
                onLongPressUp: () {
                  if (!widget.requireEditToReorder || isSelecting) {
                    _onLongPressDragUp(index);
                    dragContainerKey.currentState.clearItem();
                  }
                },
                key: _itemBins()[index].containerKey,
                child: Container(
                  alignment: Alignment.center,
                  child: OverflowBox(
                      maxWidth: screenWidth,
                      maxHeight: screenHeight,
                      alignment: Alignment.center,
                      child: new Center(
                        child: new Container(
                          key: _itemBins()[index].containerKeyChild,
                          transform: new Matrix4.translationValues(
                              _itemBins()[index].dragPointX,
                              _itemBins()[index].dragPointY,
                              0.0),
                          child: _itemBins()[index].isDraging
                              ? null
                              : widget.itemBuilder(context, index),
                        ),
                      )),
                ),
              );
            }),
        PlaceholderItem<T>(
          key: dragContainerKey,
          itemBins: _itemBins(),
          itemBuilder: widget.itemBuilder,
        )
      ],
    );
  }

  void _onLongPressDragUp(int index) {
    if (_itemBins().length < 2) {
      return;
    }

    if (index >= _itemBins().length) {
      fallbackReset();
      return;
    }
    T pressItemBin = _itemBins()[index];

    // pressItemBin.isLongPress = false;
    if (!pressItemBin.isDraging) {
      pressItemBin.dragPointY = 0.0;
      pressItemBin.dragPointX = 0.0;
    } else {
      onPanEndEvent(index);
    }
  }

  void _onLongPressDragStart(int index, LongPressStartDetails detail) {
    if (index >= _itemBins().length || _itemBins().length < 2) {
      return;
    }
    if (widget.onDragStarted != null) {
      widget.onDragStarted(index);
    }

    T pressItemBin = _itemBins()[index];

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

    endPosition = index;

    setState(() {
      _itemBins()[index].isDraging = true;
      startPosition = index;
    });
  }

  void _onLongPressDragUpdate(
      int index, LongPressMoveUpdateDetails updateDetail) {
    if (_itemBins().length < 2) {
      return;
    }

    if (index >= _itemBins().length) {
      fallbackReset();
      return;
    }

    T pressItemBin = _itemBins()[index];

    pressItemBin.dragPointY = updateDetail.offsetFromOrigin.dy;
    pressItemBin.dragPointX = updateDetail.offsetFromOrigin.dx;

    if (shuffleAnimationController.isAnimating) {
      return;
    }
    _shuffleBins(index, pressItemBin.dragPointX, pressItemBin.dragPointY);

    setState(() {});
  }

  void _shuffleBins(int index, double dragPointX, double dragPointY) async {
    if (index >= _itemBins().length) {
      fallbackReset();
      return;
    }

    double xBlankPlace = blankSpaceHorizontal * 2 + widget.crossAxisSpacing;
    double yBlankPlace = blankSpaceVertical * 2 + widget.mainAxisSpacing;

    int y = geyYTransferItemCount(index, yBlankPlace, dragPointY);
    int x = geyXTransferItemCount(index, xBlankPlace, dragPointX);

    if (endPosition != x + y &&
        !shuffleAnimationController.isAnimating &&
        x + y < _itemBins().length &&
        x + y >= 0 &&
        _itemBins()[index].isDraging) {
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
    _itemBins()[index].isDraging = false;
    if (shuffleAnimationController.isAnimating) {
      await _future;
    }
    setState(() {
      List<T> itemBi = List();
      T bin;
      for (int i = 0; i < itemPositions.length; i++) {
        if (_itemBins().length > itemPositions[i]) {
          bin = _itemBins()[itemPositions[i]];
          bin.dragPointX = 0.0;
          bin.dragPointY = 0.0;
          bin.lastTimePositionX = 0.0;
          bin.lastTimePositionY = 0.0;
          itemBi.add(bin);
        }
      }
      widget.itemBins.clear();
      widget.itemBins.addAll(itemBi);
      _initItemPositions();
      if (widget.onReorder != null) {
        widget.onReorder(widget.itemBins);
      }
    });
  }

  void fallbackReset() async {
    if (shuffleAnimationController.isAnimating) {
      await _future;
    }
    if (!mounted) {
      return;
    }

    dragContainerKey.currentState?.clearItem();
    _initItemPositions();
    _itemBins();
    selectedPositions.clear();

    setState(() {
      List<T> itemBi = List();
      T bin;
      for (int i = 0; i < itemPositions.length; i++) {
        bin = _itemBins()[itemPositions[i]];
        bin.dragPointX = 0.0;
        bin.dragPointY = 0.0;
        bin.lastTimePositionX = 0.0;
        bin.lastTimePositionY = 0.0;
        itemBi.add(bin);
        if (bin.isSelected == true) {
          selectedPositions.add(itemPositions[i]);
        }
      }
      widget.itemBins.clear();
      widget.itemBins.addAll(itemBi);
    });
    if (widget.onSelectionChanged != null) {
      widget.onSelectionChanged(null);
    }
  }
}

class DragAbleGridViewController {
  _DragAbleGridViewState _dragAbleGridViewState;

  bool persistentSelection;
  DragAbleGridViewController({this.persistentSelection: false});

  void setSelectedMode(bool selected) {
    _dragAbleGridViewState?.isSelecting = selected;

    if (!persistentSelection && !selected) {
      _dragAbleGridViewState.selectedPositions.forEach((index) {
        _dragAbleGridViewState._itemBins()[index].isSelected = false;
      });
      _dragAbleGridViewState.selectedPositions.clear();
    } else {
      _dragAbleGridViewState.selectedPositions.forEach((index) {
        _dragAbleGridViewState._itemBins()[index].isSelected = selected;
      });
    }
  }

  bool getSelectedMode() {
    return _dragAbleGridViewState?.isSelecting ?? false;
  }

  Set<int> getSelected() {
    return _dragAbleGridViewState?.selectedPositions;
  }

  void refreshItemsPositions() {
    _dragAbleGridViewState?.fallbackReset();
  }

  void onReorder() {}
}

class PlaceholderItem<T extends DragAbleGridViewBin> extends StatefulWidget {
  final List<T> itemBins;
  final IndexedWidgetBuilder itemBuilder;

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
    if (_item == null || _item >= widget.itemBins.length) {
      return Container();
    }
    final bin = widget.itemBins[_item];
    if (bin == null) {
      return Container();
    }
    return Container(
      transform: new Matrix4.translationValues(
          bin.startPositionX + bin.dragPointX,
          bin.startPositionY + bin.dragPointY,
          0.0),
      child: widget.itemBuilder(context, _item),
    );
  }
}
