import 'package:flutter/material.dart';
import '../../modules/village/models/village_model.dart';
import '../../modules/village/views/village_center_screen.dart';
import '../../modules/profile/views/player_profile_screen.dart';

enum MainContentType {
  village,
  custom,
}

class MainContentController extends ChangeNotifier {
  Widget? _currentContent;
  MainContentType? _currentType;

  Widget? get currentContent => _currentContent;
  MainContentType? get currentType => _currentType;

  void showVillageCenter(VillageModel village) {
    _currentContent = VillageCenterScreen(villageId: village.id);
    _currentType = MainContentType.village;
    notifyListeners();
  }

  void setCustomContent(Widget widget) {
    _currentContent = widget;
    _currentType = MainContentType.custom;
    notifyListeners();
  }

  void setPlayerProfileScreen(String userId) {
    _currentContent = PlayerProfileScreen(userId: userId);
    _currentType = MainContentType.custom;
    notifyListeners();
  }

  void reset() {
    _currentContent = null;
    _currentType = null;
    notifyListeners();
  }
}
