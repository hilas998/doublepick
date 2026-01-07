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
import 'screens/invite_code.dart';
import 'screens/LeagueScreenGlobal.dart';
import 'screens/LeagueLeaderboardScreen.dart';




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

  // 🔹 Registracija background handlera
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await MobileAds.instance.initialize();

  // 🔹 Detekcija kliknutih notifikacija kad je app ZATVOREN
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  RemoteMessage? initialMessage = await messaging.getInitialMessage();

  runApp(MyApp(initialMessage: initialMessage));
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
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
      print("Current user: ${FirebaseAuth.instance.currentUser?.email}");
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image(
          image: AssetImage('assets/images/logo_firme.png'),
          width: 200,
        ),
      ),
    );
  }
}
