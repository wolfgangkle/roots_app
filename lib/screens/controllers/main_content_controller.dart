import 'package:flutter/material.dart';
import '../../modules/village/models/village_model.dart';
import '../../modules/village/views/village_center_screen.dart';

enum MainContentType {
  village,
  custom,
}

class MainContentController extends ChangeNotifier {
  Widget? _currentContent;
  MainContentType? _currentType;

  Widget? get currentContent => _currentContent;
  MainContentType? get currentType => _currentType;

  /// Shows the village center screen in the middle column
  void showVillageCenter(VillageModel village) {
    _currentContent = VillageCenterScreen(village: village);
    _currentType = MainContentType.village;
    notifyListeners();
  }

  /// Manually set any widget as center content
  void setCustomContent(Widget widget) {
    _currentContent = widget;
    _currentType = MainContentType.custom;
    notifyListeners();
  }

  /// Clears current view (e.g. reset to home message)
  void reset() {
    _currentContent = null;
    _currentType = null;
    notifyListeners();
  }
}
