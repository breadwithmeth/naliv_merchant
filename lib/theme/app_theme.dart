import 'package:flutter/cupertino.dart';

/// Цветовая схема приложения, основанная на Material Theme
class AppColors {
  // Основные цвета из Material Theme
  static const Color primary = CupertinoColors.activeOrange;
  static const Color secondary = CupertinoColors.activeBlue;
  static const Color success = CupertinoColors.activeGreen;
  static const Color danger = CupertinoColors.destructiveRed;
  static const Color warning = CupertinoColors.systemYellow;

  // Цвета фона
  static const Color background = CupertinoColors.white;
  static const Color surface = CupertinoColors.systemGrey6;
  static const Color scaffold = CupertinoColors.white;

  // Цвета текста
  static const Color textPrimary = CupertinoColors.black;
  static const Color textSecondary = CupertinoColors.systemGrey;
  static const Color textLabel = CupertinoColors.secondaryLabel;

  // Цвета для навигации
  static const Color navigationBar = CupertinoColors.activeOrange;
  static const Color navigationText = CupertinoColors.white;

  // Цвета для кнопок
  static const Color buttonPrimary = CupertinoColors.activeOrange;
  static const Color buttonSecondary = CupertinoColors.systemGrey;
  static const Color buttonSuccess = CupertinoColors.activeGreen;
  static const Color buttonDanger = CupertinoColors.destructiveRed;

  // Цвета для границ
  static const Color border = CupertinoColors.systemGrey4;
  static const Color borderError = CupertinoColors.destructiveRed;

  // Цвета для статусов заказов (как в оригинальном коде)
  static const Color orderNew = CupertinoColors.activeGreen;
  static const Color orderAccepted = CupertinoColors.activeBlue;
  static const Color orderReady = CupertinoColors.systemYellow;
  static const Color orderDelivered = CupertinoColors.destructiveRed;
  static const Color orderUnpaid = CupertinoColors.destructiveRed;
}

/// Размеры и отступы
class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double borderRadius = 8.0;
  static const double borderRadiusLarge = 12.0;

  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 80.0;
}

/// Стили текста
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textLabel,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}
