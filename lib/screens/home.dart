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



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

 // BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  bool isRewardReady = false;
  bool canWatchAd = true;
  DateTime? nextAvailable;

  // 🔔 Lokalna obavijest (za Ad cooldown)
  final FlutterLocalNotificationsPlugin _localNoti =
  FlutterLocalNotificationsPlugin();


  late StreamSubscription<List<ConnectivityResult>> _connSub;
  StreamSubscription<DocumentSnapshot>? _roundSub;

  bool _roundHandledForThisCycle = false;
  bool _tipsClearedForThisRound = false;





  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    _initializeLocalNotifications();
    _loadUser();
    _loadMatchAndTimer();
    //_initAds();
    _checkCooldown();
    _initConnectivityWatch();
    _checkReferralLink();

    Timer.periodic(const Duration(minutes: 3), (_) {
      if (mounted && canWatchAd && !isRewardReady) {
        _loadRewarded();
      }
    });

  }

  @override
  void dispose() {
    _connSub.cancel();
    //_bannerAd?.dispose();
    _rewardedAd?.dispose();
    _roundSub?.cancel();
    timer?.cancel();
    for (var c in [tip1Ctrl, tip2Ctrl, tip3Ctrl, tip4Ctrl]) {
      c.dispose();
    }
    super.dispose();
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


  Future<void> _showAdAvailableNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ad_channel',               // kanal ID
      'Ad Notifications',         // ime kanala
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notifDetails =
    NotificationDetails(android: androidDetails);

    await _localNoti.show(
      0,
      'Ad is available again!',           // 🔔 NASLOV
      'Watch the ad and earn +2 points.', // 📌 TEKST
      notifDetails,
    );
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
        hasSubmitted = doc.data()!.containsKey('tip1');
        tip1Ctrl.text = doc.data()?['tip1']?.toString() ?? '';
        tip2Ctrl.text = doc.data()?['tip2']?.toString() ?? '';
        tip3Ctrl.text = doc.data()?['tip3']?.toString() ?? '';
        tip4Ctrl.text = doc.data()?['tip4']?.toString() ?? '';
      });
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

      await _applyResultsIfAvailableOnce();
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
      _applyResultsIfAvailableOnce();

      // 🔥 Ovdje brišemo tipove čim prođe scoreCalcEndTime
      if (now >= scoreCalcEndTime && !_tipsClearedForThisRound) {
        _tipsClearedForThisRound = true;
        await _clearUserTips();
      }

      // ✅ kopiranje kad završi Results coming in
      if (!_roundHandledForThisCycle && now >= scoreCalcEndTime - 1000) {
        _roundHandledForThisCycle = true;
        await _startNewRound();
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

  // 🔹 Provjera i bodovanje
  String get _roundId =>
      "${startTime.toString()}-${globalEndTime.toString()}-${scoreCalcEndTime.toString()}";

  bool _isAllResultsFilled() =>
      rez1.isNotEmpty && rez2.isNotEmpty && rez3.isNotEmpty && rez4.isNotEmpty;

  Future<void> _applyResultsIfAvailableOnce() async {
    if (!_isAllResultsFilled()) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;
    final markerKey = "scored_$_roundId";
    if (userDoc.data()!.containsKey(markerKey) && userDoc[markerKey] == true) return;

    final t1 = (userDoc.data()?['tip1'] ?? '').toString();
    final t2 = (userDoc.data()?['tip2'] ?? '').toString();
    final t3 = (userDoc.data()?['tip3'] ?? '').toString();
    final t4 = (userDoc.data()?['tip4'] ?? '').toString();
    if (t1.isEmpty || t2.isEmpty || t3.isEmpty || t4.isEmpty) {
      await userRef.update({markerKey: true});
      return;
    }

    int? tip1 = int.tryParse(t1);
    int? tip2 = int.tryParse(t2);
    int? tip3 = int.tryParse(t3);
    int? tip4 = int.tryParse(t4);
    int? r1 = int.tryParse(rez1);
    int? r2 = int.tryParse(rez2);
    int? r3 = int.tryParse(rez3);
    int? r4 = int.tryParse(rez4);
    if ([tip1, tip2, tip3, tip4, r1, r2, r3, r4].contains(null)) return;

    int points = 0;
    bool exact1 = _isExact(tip1!, tip2!, r1!, r2!);
    bool exact2 = _isExact(tip3!, tip4!, r3!, r4!);
    bool outcome1 = _sameOutcome(tip1, tip2, r1, r2);
    bool outcome2 = _sameOutcome(tip3, tip4, r3, r4);

    if (exact1) points += 15;
    else if (outcome1) points += 5;
    if (exact2) points += 15;
    else if (outcome2) points += 5;
    if (exact1 && exact2) points += 15;

    final currentScore = int.tryParse(userDoc.data()?['score'] ?? '0') ?? 0;
    final newScore = currentScore + points;
    await userRef.update({'score': newScore.toString(), markerKey: true});
    setState(() => score = newScore.toString());
  }

  bool _isExact(int a, int b, int x, int y) => (a == x && b == y);
  bool _sameOutcome(int a, int b, int x, int y) {
    int sign(int d) => d > 0 ? 1 : (d < 0 ? -1 : 0);
    return sign(a - b) == sign(x - y);
  }

  // 🔹 Kopiranje nove runde
  Future<void> _startNewRound() async {
    final nextDoc = await _firestore.collection('timovi').doc('sljedece').get();
    if (!nextDoc.exists) return;
    final data = nextDoc.data();
    if (data == null || data.isEmpty) return;

    await _firestore.collection('timovi').doc('aktivni').set(data);

    final users = await _firestore.collection('users').get();
    for (var doc in users.docs) {
      await doc.reference.update({
        'tip1': FieldValue.delete(),
        'tip2': FieldValue.delete(),
        'tip3': FieldValue.delete(),
        'tip4': FieldValue.delete(),
      });
    }
  }


  Future<void> _clearUserTips() async {
    final users = await _firestore.collection('users').get();

    for (var doc in users.docs) {
      await doc.reference.update({
        'tip1': FieldValue.delete(),
        'tip2': FieldValue.delete(),
        'tip3': FieldValue.delete(),
        'tip4': FieldValue.delete(),
      });
    }

    // reset local state for UI
    setState(() {
      hasSubmitted = false;
      tip1Ctrl.clear();
      tip2Ctrl.clear();
      tip3Ctrl.clear();
      tip4Ctrl.clear();
    });
  }


  // === Reklame, internet, referral ===
  /*void _initAds() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-6791458589312613/3522917422'
          : 'ca-app-pub-6791458589312613/3240411048',
        size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    )..load();

    _loadRewarded();
  }
*/




  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-6791458589312613/2944332927' // 🟢 Android rewarded ID
          : 'ca-app-pub-6791458589312613/7308197301', // 🟣 iOS rewarded ID
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            isRewardReady = true;
          });
        },
        onAdFailedToLoad: (_) => setState(() => isRewardReady = false),
      ),
    );
  }

  void _showRewarded() {
    if (_rewardedAd == null) return;
    _rewardedAd!.show(onUserEarnedReward: (_, __) {
      _addPoints(2);
      _startCooldown();
    });
    setState(() => _rewardedAd = null);
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

  Future<void> _startCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final next = DateTime.now().add(const Duration(hours: 24));
    await prefs.setString('nextAdTime', next.toIso8601String());
    setState(() {
      canWatchAd = false;
      nextAvailable = next;
    });
    Future.delayed(next.difference(DateTime.now()), () {
      setState(() => canWatchAd = true);
      _loadRewarded();

      // 🔥 OVDJE DOLAZI NOTIFIKACIJA!
      _showAdAvailableNotification();
    });
  }

  Future<void> _checkCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('nextAdTime');
    if (str == null) {
      setState(() => canWatchAd = true);
      return;
    }
    final next = DateTime.tryParse(str);
    if (next == null || DateTime.now().isAfter(next)) {
      setState(() => canWatchAd = true);
    } else {
      setState(() {
        canWatchAd = false;
        nextAvailable = next;
      });
    }
  }

  void _initConnectivityWatch() {
    _connSub = Connectivity().onConnectivityChanged.listen((resList) async {
      final res = resList.isNotEmpty ? resList.first : ConnectivityResult.none;
      if (res == ConnectivityResult.none) {
        _showNoInternetDialog();
      }
    });
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

  void _checkReferralLink() async {
    final uri = Uri.base;
    final ref = uri.queryParameters['ref'];
    if (ref != null && ref.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('referral_uid', ref);
    }
  }

  void _shareReferral() async {
    final u = _auth.currentUser;
    if (u == null) return;
    final link = "https://doublepick.web.app/invite.html?ref=${u.uid}";
    await Share.share("🎯 Join DoublePick and earn points!\n$link");
  }

  // === UI ===
  @override
  Widget build(BuildContext context) {
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);

    return Scaffold(
      backgroundColor: const Color(0xFF022904),
      appBar: AppBar(
        title: const Text(
          'DoublePick',
          style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF022904),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(context),
            const SizedBox(height: 16),
            Text(phaseText,
                style: const TextStyle(color: Colors.white, fontSize: 22)),
            Text(
              "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}",
              style: const TextStyle(
                  color: Colors.yellow,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _matchCard(team1, team2, rez1, rez2, tip1Ctrl, tip2Ctrl),
            const SizedBox(height: 8),
            _matchCard(team3, team4, rez3, rez4, tip3Ctrl, tip4Ctrl),
            const SizedBox(height: 16),
            if (!hasSubmitted && phaseText == "Enrollment time left")
              ElevatedButton(
                onPressed: _submitTips,
                child: const Text("Send Results"),
              ),
            const SizedBox(height: 12),
            if (canWatchAd)
              ElevatedButton.icon(
                onPressed: isRewardReady ? _showRewarded : null,
                icon: const Icon(Icons.play_circle_fill),
                label: const Text("Watch ad for +2 points"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent.shade700),
              )
            else
              Text(
                "Next ad available at:\n${nextAvailable?.toLocal().toString().split('.')[0] ?? ''}",
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
      bottomNavigationBar:  null

    );
  }



  Widget _headerCard(BuildContext context) => Card(
    color: const Color(0xFFFFF59D),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Ime + share dugme
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.black54, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    "$name $surname",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              IconButton(
                onPressed: _shareReferral,
                icon: const Icon(Icons.share, color: Colors.black),
              ),
            ],
          ),

          const SizedBox(height: 2),   // ⬅️ email vrlo blizu imenu

          // Email
          Row(
            children: [
              const Icon(Icons.email, color: Colors.black54, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),   // ⬅️ veći razmak email → score

          // Score
          Row(
            children: [
              const Icon(Icons.star, color: Colors.deepPurple, size: 22),
              const SizedBox(width: 6),
              Text(
                "My score: $score",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.black54),
          ),

          // Standings / Rules / Reset
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => Navigator.pushNamed(context, '/standings'),
                child: const Text(
                  "Standings",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 3),

              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => Navigator.pushNamed(context, '/rules'),
                child: const Text(
                  "Rules of the game",
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 3),

              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => Navigator.pushNamed(context, '/reset'),
                child: const Text(
                  "Reset password",
                  style: TextStyle(
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    ),
  );


  // 🔹 Match card prikaz
  Widget _matchCard(String t1, String t2, String r1, String r2,
      TextEditingController c1, TextEditingController c2) {
    return Card(
      color: Colors.green.shade400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(t1,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text("$r1 : $r2",
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            Text(t2,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          if (phaseText == "Enrollment time left" && !hasSubmitted)
            Row(children: [
              Expanded(
                child: TextField(
                  controller: c1,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Home"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: c2,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Away"),
                ),
              ),
            ])
          else if (hasSubmitted &&
              (phaseText == "Enrollment time left" ||
                  phaseText == "Results coming in"))
            Text("Your pick: ${c1.text}:${c2.text}",
                style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ]),
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }
}
