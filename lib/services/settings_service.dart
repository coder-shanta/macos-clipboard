import 'package:shared_preferences/shared_preferences.dart';

const defaultMenuBarItemCount = 5;
const minMenuBarItemCount = 1;
const maxMenuBarItemCount = 15;

class SettingsService {
  static const _menuBarItemCountKey = 'menu_bar_item_count';

  Future<int> getMenuBarItemCount() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_menuBarItemCountKey) ?? defaultMenuBarItemCount;
    return value.clamp(minMenuBarItemCount, maxMenuBarItemCount);
  }

  Future<void> setMenuBarItemCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _menuBarItemCountKey,
      count.clamp(minMenuBarItemCount, maxMenuBarItemCount),
    );
  }
}
