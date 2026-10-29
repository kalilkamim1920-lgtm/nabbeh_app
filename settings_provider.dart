import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/misc_models.dart';
import '../../data/models/rule_model.dart';
import '../../domain/repositories/nabbeh_repository.dart';

/// يدير الإعدادات: الصلاحيات، الخصوصية، التطبيقات المراقبة، القواعد
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._repo);
  final NabbehRepository _repo;

  StreamSubscription<Map<String, dynamic>>? _sub;
  GlobalSettings? global;
  List<AppSettingItem> apps = [];
  List<RuleItem> rules = [];
  bool notificationAccess = false;
  bool calendarAccess = false;
  bool loading = true;

  void init() {
    _sub = _repo.eventStream.listen((event) {
      // تطبيق جديد ظهر أثناء العمل يحتاج إضافته لقائمة التطبيقات
      if (event['type'] == 'new_notification' || event['type'] == 'deleted') {
        refresh();
      }
    });
    refresh();
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        _repo.getGlobalSettings(),
        _repo.getAppSettings(),
        _repo.getRules(),
        _repo.isNotificationAccessGranted(),
        _repo.isCalendarAccessGranted(),
      ]);
      global = results[0] as GlobalSettings;
      apps = results[1] as List<AppSettingItem>;
      rules = results[2] as List<RuleItem>;
      notificationAccess = results[3] as bool;
      calendarAccess = results[4] as bool;
    } catch (_) {
      // نتجاهل الأخطاء هنا لأن الشاشة تعرض الحالات الفارغة بأمان
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ===== الخصوصية العامة =====
  Future<void> setMasterEnabled(bool v) async {
    await _repo.setGlobalSetting('masterEnabled', v);
    await refresh();
  }

  Future<void> setAutoApplyRules(bool v) async {
    await _repo.setGlobalSetting('autoApplyRules', v);
    await refresh();
  }

  Future<void> setCurrency(String code) async {
    await _repo.setGlobalSetting('currency', code);
    await refresh();
  }

  // ===== التطبيقات =====
  Future<void> setAppEnabled(String packageName, bool v) async {
    await _repo.setAppEnabled(packageName, enabled: v);
    await refresh();
  }

  // ===== القواعد =====
  Future<void> addRule({
    required String appFilter,
    required String keyword,
    required String actionType,
  }) async {
    await _repo.addRule(appFilter: appFilter, keyword: keyword, actionType: actionType);
    await refresh();
  }

  Future<void> toggleRule(int id, bool v) async {
    await _repo.toggleRule(id, enabled: v);
    await refresh();
  }

  Future<void> deleteRule(int id) async {
    await _repo.deleteRule(id);
    await refresh();
  }

  // ===== الصلاحيات =====
  Future<void> openNotificationAccess() async {
    await _repo.openNotificationAccessSettings();
    // ننتظر قليلاً حتى يعود المستخدم من إعدادات النظام
    await Future.delayed(const Duration(seconds: 2));
    await refresh();
  }

  Future<void> requestCalendarPermissions() async {
    await _repo.requestCalendarPermissions();
    await refresh();
  }

  // ===== منطقة الخطر =====
  Future<void> deleteAllData() async {
    await _repo.deleteAllData();
    await refresh();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
