import 'package:flutter/material.dart';

class MonthlyNav {
  static void navReplace(BuildContext context, Widget screen) {
    final st = Scaffold.maybeOf(context);
    if (st != null && st.isDrawerOpen) {
      Navigator.of(context).pop(); // close drawer
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
