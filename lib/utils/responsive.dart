import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;
  Responsive(this.context);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  bool get isPhone => width < 600;
  bool get isTablet => width >= 800 && width <= 1340;
  bool get isLargeScreen => width > 1024;

  double get contentMaxWidth {
    if (isLargeScreen) return 480;
    if (isTablet) return 420;
    return width;
  }

  double get scannerHeight {
    if (isPhone) return height * 0.32;
    return height * 0.40;
  }

  double get horizontalPadding => isPhone ? 16 : 32;
  double get baseFontScale => isPhone ? 1.0 : 1.1;
}