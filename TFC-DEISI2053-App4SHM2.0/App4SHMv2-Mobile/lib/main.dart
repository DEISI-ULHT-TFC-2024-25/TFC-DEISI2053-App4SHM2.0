import 'dart:io';

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:app4shm/pages/about_page.dart';
import 'package:app4shm/pages/damage_detection_page.dart';
import 'package:app4shm/pages/join_structure_page.dart';
import 'package:app4shm/pages/login_page.dart';
import 'package:app4shm/pages/network_master_page.dart';
import 'package:app4shm/pages/network_slave_page.dart';
import 'package:app4shm/pages/power_spectrum_network_page.dart';
import 'package:app4shm/pages/power_spectrum_page.dart';
import 'package:app4shm/pages/time_series_master_page.dart';
import 'package:app4shm/pages/time_series_page.dart';
import 'package:app4shm/pages/time_series_slave_page.dart';
import 'package:app4shm/providers/app_provider.dart';
import 'package:app4shm/services/network_service.dart';
import 'package:app4shm/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app4shm/pages/structures_page.dart';
import 'package:app4shm/pages/welcome_page.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:page_transition/page_transition.dart';
import 'package:app4shm/pages/cable_force_page.dart';
import 'package:upgrader/upgrader.dart';

import 'models/user.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

Future main() async {
  const bool isProduction = kReleaseMode;
  if (isProduction) {
    await dotenv.load(fileName: 'assets/env/.env-prod');
  } else if (Platform.isAndroid) {
    await dotenv.load(fileName: "assets/env/.env.android-dev");
  } else if (Platform.isIOS) {
    await dotenv.load(fileName: "assets/env/.env.ios-dev");
  }
  SharedPreferences prefs = await SharedPreferences.getInstance();

  Brightness brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
  bool darkModeOn = brightness == Brightness.dark;

  WidgetsFlutterBinding.ensureInitialized();

  Mixpanel mixpanel = await Mixpanel.init("29eaa8bb55046edc4c0f8c268423139d",
      trackAutomaticEvents: true);

  if (kReleaseMode) {
    await SentryFlutter.init((options) {
      options.dsn = 'https://c68cf4b46d19c47de26cfb25f9947962@o4506772785332224.ingest.us.sentry.io/4507000997937152';
    }, appRunner: () async => runApp(await buildChangeNotifierProvider(darkModeOn, prefs, mixpanel)));
  } else {
    runApp(await buildChangeNotifierProvider(darkModeOn, prefs, mixpanel));


  }
}

Widget _wrapWithUpgradeAlert(Widget child) {
  final dialogStyle =
  kIsWeb || defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.macOS
      ? UpgradeDialogStyle.material
      : UpgradeDialogStyle.cupertino;

  // final upgrader = Upgrader(
  //   debugLogging: true,
  //   debugDisplayAlways: false,
  // );

  return UpgradeAlert(
    // upgrader: upgrader,
    dialogStyle: dialogStyle,
    navigatorKey: _rootNavigatorKey,
    child: child,
  );
}

Future<MultiProvider> buildChangeNotifierProvider(
    bool darkModeOn, SharedPreferences prefs, Mixpanel mixpanel) async {

  return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        Provider.value(value: mixpanel),
        Provider<NetworkService>(create: (_) => NetworkService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // phone in dark mode ? darkTheme : lightTheme
        theme: darkModeOn ? await darkTheme() : await lightTheme(),
        navigatorKey: _rootNavigatorKey,
        home: Builder(
          builder: (context) {
            if (prefs.getString('userid') != null) {
              Provider.of<AppProvider>(context, listen: false).setUser(User(prefs.getString('userid')!));
            }

            return AnimatedSplashScreen(
              splash: 'assets/splash.png',
              nextScreen: _wrapWithUpgradeAlert(prefs.getString('token') == null ? const LoginPage() : const StructuresPage()),
              pageTransitionType: PageTransitionType.rightToLeftWithFade,
              backgroundColor: const Color(0xFF01DEA0),
              splashIconSize: double.infinity,
            );
          },
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/structures': (context) => const StructuresPage(),
          '/welcome': (context) => const WelcomePage(),
          '/timeseries': (context) => const TimeSeriesPage(),
          '/powerSpec': (context) => const PowerSpectrumPage(),
          '/result': (context) => const DamageDetectionPage(),
          '/about': (context) => const AboutPage(),
          '/timeSeriesMasterNetwork': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map;
            return TimeSeriesMasterNetwork(
              networkId: args['networkId'],
              selectedLocation: args['selectedLocation'],
            );
          },
          '/timeSeriesSlaveNetwork': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map;
            return TimeSeriesSlaveNetwork(
              networkId: args['networkId'],
              selectedLocation: args['selectedLocation'],
            );
          },
          '/joinStructure': (context) => const JoinStructurePage(),
          '/cableforce': (context) => const CableForcePage(),
          '/networkMaster': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map;
            return NetworkMasterPage(networkId: args['networkId'], structure: args['structure'],);
          },
          '/networkSlave': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map;
            return NetworkSlavePage(networkId: args['networkId']);
          },
          '/powerSpectrumNetwork': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map;
            return PowerSpectrumNetworkPage(networkId: args['networkId']);
          },
        },
      ));
}
