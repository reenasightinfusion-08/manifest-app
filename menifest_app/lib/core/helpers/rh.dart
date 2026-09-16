import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RH {
  RH._();

  static double w(num width) => width.w;
  static double h(num height) => height.h;
  static double r(num radius) => radius.r;
  static double sp(num fontSize) => fontSize.sp;

  static Widget spaceY(num height) => height.verticalSpace;
  static Widget spaceX(num width) => width.horizontalSpace;
}
