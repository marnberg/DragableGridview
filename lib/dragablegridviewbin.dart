import 'package:flutter/material.dart';

class DragAbleGridViewBin {
  double startPositionX=0.0;
  double startPositionY=0.0;
  double dragPointX=0.0;
  double dragPointY=0.0;
  double lastTimePositionX=0.0;
  double lastTimePositionY=0.0;
  GlobalKey containerKey= GlobalKey();
  GlobalKey containerKeyChild= GlobalKey();
  bool isLongPress=false;
  bool dragAble=false;
  ///是否隐藏，默认不隐藏
  bool offstage=false;
}
