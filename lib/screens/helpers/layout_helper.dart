enum ScreenSizeCategory {
  small,   // mobile
  medium,  // 3-column
  large,   // 4-column
}

class LayoutHelper {
  static ScreenSizeCategory getSizeCategory(double screenWidth) {
    if (screenWidth < 1024) return ScreenSizeCategory.small;
    if (screenWidth < 1600) return ScreenSizeCategory.medium;
    return ScreenSizeCategory.large;
  }
}
