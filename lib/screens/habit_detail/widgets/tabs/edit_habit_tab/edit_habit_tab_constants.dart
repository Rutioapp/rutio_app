import 'package:flutter/material.dart';

const Color editHabitCream = Color(0xFFF5EDE0);
const Color editHabitCamel = Color(0xFFB8895A);
const Color editHabitDark = Color(0xFF3D2010);
const Color editHabitSage = Color(0xFF7A9E7E);

extension EditHabitColorOpacity on Color {
  Color withOpacitySafe(double value) => withValues(alpha: value);
}
