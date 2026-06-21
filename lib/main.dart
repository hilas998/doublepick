import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// tvoji ekrani
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/rules.dart';
import 'screens/standings.dart';
import 'screens/forgot_password.dart';
import 'screens/round_standings.dart';
import 'screens/admin.dart';
import 'screens/user_profile.dart';
import 'screens/favorites_screen.dart';
import 'screens/AdminLeague.dart';
import 'screens/LeagueDetail.dart';
import 'screens/MyLeagues.dart';
import 'screens/BonusGameScreenAdmin.dart';
import 'screens/LeagueScreenGlobal.dart';
import 'screens/LaguesGameScreenAdmin.dart';
import 'screens/Teamupisadmin.dart';
import 'screens/UpisTeamSezona.dart';




// 🔹 GLOBAL KEY za navigaciju izvan widgeta
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔹 Handler za background poruke
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background poruka: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("========== APP START ==========");

  print("1 - Widgets initialized");
  // 🔹 Registracija background handlera
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await MobileAds.instance.initialize();

  // 🔹 Detekcija kliknutih notifikacija kad je app ZATVOREN
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  RemoteMessage? initialMessage = await messaging.getInitialMessage();

  runApp(MyApp(initialMessage: initialMessage));



  try {
    await Firebase.initializeApp();
    print("2 - Firebase initialized");
  } catch (e, s) {
    print("FIREBASE ERROR:");
    print(e);
    print(s);
    rethrow;
  }

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);
  print("3 - Background handler registered");

  try {
    await MobileAds.instance.initialize();
    print("4 - Mobile Ads initialized");
  } catch (e, s) {
    print("ADMOB ERROR:");
    print(e);
    print(s);
  }


}

class MyApp extends StatelessWidget {
  final RemoteMessage? initialMessage;

  const MyApp({super.key, this.initialMessage});

  @override
  Widget build(BuildContext context) {
    // 🔹 Ako je app pokrenut klikom na notifikaciju → otvori HOME
    if (initialMessage != null) {
      // mora delay jer navigatorKey nije odmah spreman
      Future.delayed(const Duration(milliseconds: 300), () {
        navigatorKey.currentState?.pushNamed('/home');
      });
    }

    // 🔹 Listener kad je app u pozadini pa se klikne na notifikaciju
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigatorKey.currentState?.pushNamed('/home');
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'DoublePick',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/standings': (context) => const StandingsScreen(),
        '/rules': (context) => const RulesScreen(),
        '/reset': (context) => const ForgotPasswordScreen(),
        '/roundStandings': (context) => const RoundStandingsScreen(),
        '/admin': (context) => const AdminScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/myLeagues' : (context) => const MyLeaguesScreen(),
        '/leagueDetail' : (context) => const LeagueDetailScreen(),
        '/adminLeague' : (context) => const AdminLeagueScreen(),
        '/bonusGameAdmin': (context) => const BonusGameScreen(),
        '/leaguesAdmin': (context) => const LaguesGameScreen(),
        '/leaguesAdminTeam':(context)=> const Teamupisadmin(),
        '/upisTimovaSezone':(context)=> const UpisTeamSezona(),



          '/profile': (context) {
          final uid = ModalRoute.of(context)!.settings.arguments as String;
          return UserProfileScreen(uid: uid);

    },

             '/invite_code': (context) {
    return const Scaffold(
    body: Center(child: Text("Invalid route")),
             );
    },


      },
    );
  }
}

// 🔹 Splash ekran
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    print("Splash init");
  }

  Future<void> _checkLoginStatus() async {
    print("Checking login...");

    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    print("Current user object: $user");

    if (!mounted) {
      print("Widget disposed");
      return;
    }

    if (user != null) {
      print("Navigating to HOME");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print("Navigating to LOGIN");
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
  @override
  Widget build(BuildContext context) {
    print("Splash build");

    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: Text(
          "LOADING",
          style: TextStyle(fontSize: 30, color: Colors.black),
        ),
      ),
    );
  }
}
