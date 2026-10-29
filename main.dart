import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/service_locator.dart';
import 'presentation/providers/budget_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/notifications_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/tasks_provider.dart';
import 'presentation/screens/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تحميل رموز تنسيق التواريخ العربية
  await initializeDateFormatting('ar');
  runApp(const NabbehApp());
}

/// نبّه — يحوّل إشعارات هاتفك إلى مهام ومواعيد ومصاريف
/// المعالجة كلها على الجهاز: لا سحابة، لا إنترنت، لا تتبع
class NabbehApp extends StatelessWidget {
  const NabbehApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ServiceLocator.repo;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider(repo)..init()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(repo)..init()),
        ChangeNotifierProvider(create: (_) => TasksProvider(repo)..init()),
        ChangeNotifierProvider(create: (_) => BudgetProvider(repo)..init()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(repo)..init()),
      ],
      child: MaterialApp(
        title: 'نبّه',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const MainScaffold(),
      ),
    );
  }
}
