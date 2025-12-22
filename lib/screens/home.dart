import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:connectivity_plus/connectivity_plus.dart';







class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin,WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const platform = MethodChannel('app.settings.channel');


  String name = '', surname = '', email = '', score = '0';
  String team1 = '', team2 = '', team3 = '', team4 = '';
  String rez1 = '', rez2 = '', rez3 = '', rez4 = '';
  bool hasSubmitted = false;

  final tip1Ctrl = TextEditingController();
  final tip2Ctrl = TextEditingController();
  final tip3Ctrl = TextEditingController();
  final tip4Ctrl = TextEditingController();

  int startTime = 0, globalEndTime = 0, scoreCalcEndTime = 0;
  Duration remaining = Duration.zero;
  Timer? timer;
  String phaseText = '';

  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;


  String inviteCode = '';
  bool _canWatchAd = false;
  Timer? _adCooldownTimer;
  int _nextAdTime = 0;
  String _adCountdownText = "";
  Timer? _countdownTimer;


  bool _adConsumedThisSession = false;




  // 🔔 Lokalna obavijest (za Ad cooldown)
  final FlutterLocalNotificationsPlugin _localNoti =
  FlutterLocalNotificationsPlugin();


  late StreamSubscription<List<ConnectivityResult>> _connSub;
  StreamSubscription<DocumentSnapshot>? _roundSub;

  bool _roundHandledForThisCycle = false;
  bool _tipsClearedForThisRound = false;
  late AnimationController _animController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _pulseAnim;





  @override
  void initState() {
    super.initState();
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasInternet = results.any(
            (r) => r == ConnectivityResult.mobile || r == ConnectivityResult.wifi,
      );

      if (!hasInternet && mounted) {
        _showNoInternetDialog();
      }
    });

    WidgetsBinding.instance.addObserver(this);
    MobileAds.instance.initialize();

    requestNotificationPermission();
    tz.initializeTimeZones();
    _initializeLocalNotifications();



    _loadUser();
    _loadMatchAndTimer();
    _initAds();

   // _adCooldownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
     // _checkAdAvailability();
   // });


    _loadBanner();
    _loadRewarded();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnim = Tween<double>(begin: 1, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animController.forward();

  }

  @override
  void dispose() {

    _connSub.cancel();
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _roundSub?.cancel();
    timer?.cancel();
    _adCooldownTimer?.cancel();
    _countdownTimer?.cancel();



    for (var c in [tip1Ctrl, tip2Ctrl, tip3Ctrl, tip4Ctrl]) {
      c.dispose();
    }


    _animController.dispose();
    _pulseController.dispose();

    super.dispose();

  }






  // 🔹 Učitavanje korisnika i tipova
  Future<void> _loadUser() async {
    final u = _auth.currentUser;
    if (u == null) return;
    final doc = await _firestore.collection('users').doc(u.uid).get();
    if (doc.exists) {
      setState(() {
        name = doc['ime'] ?? '';
        surname = doc['prezime'] ?? '';
        email = u.email ?? '';
        score = doc['score'] ?? '0';

        hasSubmitted = doc.data()?['tip1'] != null &&
            doc.data()?['tip2'] != null &&
            doc.data()?['tip3'] != null &&
            doc.data()?['tip4'] != null;



        tip1Ctrl.text = doc.data()?['tip1']?.toString() ?? '';
        tip2Ctrl.text = doc.data()?['tip2']?.toString() ?? '';
        tip3Ctrl.text = doc.data()?['tip3']?.toString() ?? '';
        tip4Ctrl.text = doc.data()?['tip4']?.toString() ?? '';






        final now = DateTime.now().millisecondsSinceEpoch;
        _nextAdTime = doc.data()?['nextAdTime'] ?? 0;
        _canWatchAd = now >= _nextAdTime;

        if (!_canWatchAd && _nextAdTime > 0) {
          _startCountdown();
        }


        if (!_canWatchAd && _nextAdTime > 0) {
          _startCountdown();
        }

      });

      inviteCode = doc['inviteCode'] ?? _auth.currentUser!.uid.substring(0, 6);
    }
  }

  // 🔹 Učitavanje utakmica i tajmera
  Future<void> _loadMatchAndTimer() async {
    final ref = _firestore.collection('timovi').doc('aktivni');
    final doc = await ref.get();
    if (!doc.exists) return;

    setState(() {
      team1 = doc['team1'] ?? '';
      team2 = doc['team2'] ?? '';
      team3 = doc['team3'] ?? '';
      team4 = doc['team4'] ?? '';
      rez1 = doc['stvarnirezultat1'] ?? '';
      rez2 = doc['stvarnirezultat2'] ?? '';
      rez3 = doc['stvarnirezultat3'] ?? '';
      rez4 = doc['stvarnirezultat4'] ?? '';
      startTime = (doc['startTimeMillis'] ?? 0).toInt();
      globalEndTime = (doc['globalEndTimeMillis'] ?? 0).toInt();
      scoreCalcEndTime = (doc['scoreCalcEndTimeMillis'] ?? 0).toInt();
      _roundHandledForThisCycle = false;
    });

    _updatePhase();
    _startTimer();

    // 🔹 Listener za promjene (automatski refresh)
    _roundSub?.cancel();
    _roundSub = ref.snapshots().listen((snap) async {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>?;

      setState(() {
        rez1 = (data?['stvarnirezultat1'] ?? '') as String;
        rez2 = (data?['stvarnirezultat2'] ?? '') as String;
        rez3 = (data?['stvarnirezultat3'] ?? '') as String;
        rez4 = (data?['stvarnirezultat4'] ?? '') as String;
        startTime = (data?['startTimeMillis'] ?? startTime).toInt();
        globalEndTime = (data?['globalEndTimeMillis'] ?? globalEndTime).toInt();
        scoreCalcEndTime =
            (data?['scoreCalcEndTimeMillis'] ?? scoreCalcEndTime).toInt();
      });


      _updatePhase();

      if (data?['startTimeMillis'] != null) {
        _loadUser();
        setState(() {
          hasSubmitted = false;
          tip1Ctrl.clear();
          tip2Ctrl.clear();
          tip3Ctrl.clear();
          tip4Ctrl.clear();
        });
      }
    });
  }

  void _startTimer() {
    if (startTime <= 0 || globalEndTime <= 0 || scoreCalcEndTime <= 0) {
      Future.delayed(const Duration(milliseconds: 300), _startTimer);
      return;
    }
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _updatePhase());
  }

  // 🔹 Glavna fazna logika
  void _updatePhase() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    String newPhase;
    int targetTime;

    if (now < startTime) {
      newPhase = "Round starts in";
      targetTime = startTime;
    } else if (now < globalEndTime) {
      newPhase = "Enrollment time left";
      targetTime = globalEndTime;
    } else if (now < scoreCalcEndTime) {
      newPhase = "Results coming in";
      targetTime = scoreCalcEndTime;



      // ✅ kopiranje kad završi Results coming in
      if (!_roundHandledForThisCycle && now >= scoreCalcEndTime - 1000) {
        _roundHandledForThisCycle = true;

      }
    } else {
      newPhase = "Round over";
      targetTime = now;
    }

    final diff =
    Duration(milliseconds: (targetTime - now).clamp(0, 999999999));
    setState(() {
      phaseText = newPhase;
      remaining = diff;
    });
  }




  Future<void> _checkAdAvailability() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final nextAdTime = doc.data()?['nextAdTime'] ?? 0;

    final canWatch = now >= nextAdTime;

    if (canWatch && !_canWatchAd) {
      setState(() {
        _canWatchAd = true;
      });

      // osiguraj da je reklama učitana
      if (_rewardedAd == null) {
        _loadRewarded();
      }
    }
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-6791458589312613/2944332927'
          : 'ca-app-pub-6791458589312613/7308197301',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          setState(() {});
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  void _showRewarded() {
    if (_rewardedAd == null) return;
    if (_adConsumedThisSession) return;

    _adConsumedThisSession = true;

    setState(() {
      _canWatchAd = false;
      _adCountdownText = "";
    });

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (_, __) async {
        await _addPoints(2);
        await _startAdCooldown(); // 🔥 Firebase zapis
      },
    );
  }


  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6791458589312613/3522917422',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }
  void requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Dozvola: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      _showNotificationSettingsDialog();
    }
  }
  Future<void> _showNotificationSettingsDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Enable notifications"),
        content: const Text(
          "Notifications are required for updates, reminders and rewards.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await platform.invokeMethod('openNotificationSettings');
            },
            child: const Text("Open settings"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Later"),
          ),
        ],
      ),
    );
  }

  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings android =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _localNoti.initialize(settings);



  }









  // 🔹 Slanje tipova
  Future<void> _submitTips() async {
    if ([tip1Ctrl, tip2Ctrl, tip3Ctrl, tip4Ctrl]
        .any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all 4 entries')),
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= globalEndTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment period is over')),
      );
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'tip1': tip1Ctrl.text.trim(),
      'tip2': tip2Ctrl.text.trim(),
      'tip3': tip3Ctrl.text.trim(),
      'tip4': tip4Ctrl.text.trim(),
    });
    setState(() => hasSubmitted = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Predictions submitted!')));
  }








  // === Reklame, internet, referral ===


  void _initAds() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-6791458589312613/3522917422'
          : 'ca-app-pub-6791458589312613/3240411048',
      size: AdSize.banner, // 🔥 MANJI I LJEPŠI BANNER
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();


  }



  Future<void> _addPoints(int pts) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _firestore.collection('users').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) return;
    final current = int.tryParse(snap['score'] ?? '0') ?? 0;
    final newScore = current + pts;
    await ref.update({'score': newScore.toString()});
    setState(() => score = newScore.toString());
  }

  Future<void> _startAdCooldown() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final now = DateTime.now();
    final next = now.add(const Duration(hours: 8));

    await _firestore.collection('users').doc(uid).update({
      'nextAdTime': next.millisecondsSinceEpoch,
    });

    await _scheduleAdAvailableNotification(next);
    print("🔥 Ad cooldown started. Next ad at: ${next.millisecondsSinceEpoch}");
  }

  Future<void> _scheduleAdAvailableNotification(DateTime time) async {
    const androidDetails = AndroidNotificationDetails(
      'ad_channel',
      'Ad Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNoti.zonedSchedule(
      999, // ID
      'Ad is available again!',
      'Watch the ad and earn +2 points.',
      tz.TZDateTime.from(time, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }


  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("No Internet Connection"),
        content:
        const Text("Internet connection is required to use DoublePick."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
  }
  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = _nextAdTime - now;

      if (diff <= 0) {
        _countdownTimer?.cancel();
        setState(() {
          _canWatchAd = true;
          _adCountdownText = "";
        });

        if (_rewardedAd == null) {
          _loadRewarded();
        }


        return;
      }

      final duration = Duration(milliseconds: diff);
      final h = duration.inHours.toString().padLeft(2, '0');
      final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
      final s = (duration.inSeconds % 60).toString().padLeft(2, '0');

      setState(() {
        _adCountdownText = "Next ad reward in $h:$m:$s";
      });
    });
  }



  void _shareReferral() async {
    final u = _auth.currentUser;
    if (u == null) return;
    final link = "https://play.google.com/store/apps/details?id=com.doublepick&referrer=${u.uid}}";
    await Share.share("🎯 Join DoublePick and earn points!\n$link");
  }


  @override
  Widget build(BuildContext context) {
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);

    return Scaffold(
      backgroundColor: const Color(0xFF00150A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00150A),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'DoublePick',
          style: TextStyle(
            color: Color(0xFFEFFF8A),
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
          ),
        ],
      ),

      body: Column(
        children: [

          // ===== SCROLLABLE CONTENT =====
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // HEADER
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: _headerCard(context),
                  ),

                  const SizedBox(height: 20),

                  // PHASE + TIMER CARD
                  Card(
                    elevation: 4,
                    shadowColor: const Color(0xFF44FF96).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF022D12),
                            Color(0xFF011F0A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            phaseText.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              letterSpacing: 1,
                              color: Color(0xFF44FF96),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${h.toString().padLeft(2, '0')}:"
                                "${m.toString().padLeft(2, '0')}:"
                                "${s.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              color: Color(0xFFEFFF8A),
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== MATCH CARDS WITH INPUTS =====
                  _matchCard(team1, team2, rez1, rez2, tip1Ctrl, tip2Ctrl),
                  const SizedBox(height: 8),
                  _matchCard(team3, team4, rez3, rez4, tip3Ctrl, tip4Ctrl),

                  const SizedBox(height: 16),

                  // SEND RESULTS BUTTON
                  if (!hasSubmitted && phaseText == "Enrollment time left")
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF44FF96),
                              Color(0xFFEFFF8A),
                            ],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _submitTips,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.send_rounded, color: Colors.black),
                              SizedBox(width: 10),
                              Text(
                                "SEND RESULTS",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // REWARDED AD BUTTON
                  if (_canWatchAd && _rewardedAd != null)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _showRewarded,
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text("Watch ad for +2 points"),
                      ),
                    )
                  else if (!_canWatchAd && _adCountdownText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _adCountdownText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )

                ],
              ),
            ),
          ),

          // ===== FOOTER =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF011F0A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Invite code: $inviteCode",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF44FF96),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: inviteCode),
                        );
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text("Invite code copied!"),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text(
                        "Copy",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Share.share(
                          "Join DoublePick! Your invite code is: $inviteCode",
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text(
                        "Share",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // ===== BANNER AD =====
      bottomNavigationBar: _bannerAd == null
          ? null
          : SafeArea(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF5E179), // svjetlija pozadina
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== USER ROW =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 2),
                      color: Colors.black, // unutrašnjost kruga crna
                    ),
                    child: const Icon(Icons.person, size: 20, color: Colors.green), // ikona u zelenoj boji
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$name $surname",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00150A),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _shareReferral,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22E58B),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.share, color: Colors.black, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===== EMAIL =====
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 14, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF00150A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ===== SCORE =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF44FF96), Color(0x6764E8FC)], // zel.-žuti gradijent
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.black, size: 18),
                const SizedBox(width: 6),
                Text(
                  "Score: $score",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.black, height: 1), // horizontalna linija

          const SizedBox(height: 6),
          // ===== MENU LINKS =====
          _menuTile(context, "Standings Global", Icons.public, '/standings', textColor: Colors.black),
          _menuTile(context, "Standings Round", Icons.emoji_events, '/roundStandings', textColor: Colors.black),
          _menuTile(context, "Rules of the game", Icons.rule, '/rules', textColor: Colors.black),
          _menuTile(context, "Reset password", Icons.lock_reset, '/reset', danger: true, textColor: Colors.red),
          if (email == "salihlihic998@gmail.com")
            _menuTile(
              context,
              "Admin panel",
              Icons.admin_panel_settings,
              '/admin',
              danger: true,
              textColor: Colors.red,
            ),
        ],
      ),
    );
  }

// ===== MODIFIKOVANI MENU TILE =====
  Widget _menuTile(
      BuildContext context,
      String title,
      IconData icon,
      String route, {
        bool danger = false,
        Color textColor = Colors.black,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: danger
              ? Colors.red.withOpacity(0.15)
              : Colors.lightBlue.withOpacity(0.2), // svjetlo plava pozadina
          border: Border.all(
            color: danger ? Colors.redAccent : Colors.blueAccent.withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: danger ? Colors.redAccent : Colors.blueAccent,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: danger ? Colors.redAccent : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget _matchCard(
      String homeTeam,
      String awayTeam,
      String homeResult,
      String awayResult,
      TextEditingController homeCtrl,
      TextEditingController awayCtrl,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFB8FF5C), Color(0xFFB8FF5C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.85),
        ),
        child: Column(
          children: [
            // ===== TEAM NAMES + RESULT =====
            Row(
              children: [
                Expanded(
                  child: Text(
                    homeTeam, // 🔥 TAČNO KAKO JE U FIREBASE
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  "$homeResult : $awayResult", // ❌ NEMA KAPSULE
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Expanded(
                  child: Text(
                    awayTeam, // 🔥 TAČNO KAKO JE U FIREBASE
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ===== INPUT SCORE =====
            if (!hasSubmitted && phaseText == "Enrollment time left")
              Row(
                children: [
                  _scoreInput(homeCtrl),
                  const SizedBox(width: 14),
                  _scoreInput(awayCtrl),
                ],
              )

    else
    Container(
    width: 140, // malo manja širina da ne zauzima cijeli red
    height: 50,
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    gradient: const LinearGradient(
    colors: [Color(0xFF22E58B), Color(0xFFB8FF5C)],
    ),
    boxShadow: [
    BoxShadow(
    color: const Color(0xFF22E58B).withOpacity(0.45),
    blurRadius: 16,
    spreadRadius: 1,
    offset: const Offset(0, 6),
    ),
    ],
    ),
    child: Container(
    margin: const EdgeInsets.all(2.2),
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    color: Colors.white.withOpacity(0.85),
    ),
    child: Center(
    child: Text(
    "Your pick: " +
    ((homeCtrl.text.isEmpty && awayCtrl.text.isEmpty)
    ? "No results"
        : "${homeCtrl.text}-${awayCtrl.text}"),
    style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Color(0xFF00150A),
    ),
    textAlign: TextAlign.center,
    ),
    ),
    ),
    ),



          ],
        ),
      ),
    );
  }



  Widget _scoreInput(TextEditingController ctrl) {
    return Expanded(
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF22E58B), Color(0xFFB8FF5C)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22E58B).withOpacity(0.45),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2.2), // okvir efekat
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: TextField(
            controller: ctrl,
            maxLength: 1, // ✅ SAMO JEDNA CIFRA
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00150A),
            ),
            decoration: const InputDecoration(
              counterText: "",
              hintText: "enter score",
              hintStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF22E58B),
                letterSpacing: 1,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }



  void _logout() async {
  await FirebaseAuth.instance.signOut();
  if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }




}

