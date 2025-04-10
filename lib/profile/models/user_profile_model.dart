// lib/modules/profile/models/user_profile_model.dart

import 'package:flutter/foundation.dart';

class UserProfileModel with ChangeNotifier {
  final String heroName;

  UserProfileModel({required this.heroName});
}
