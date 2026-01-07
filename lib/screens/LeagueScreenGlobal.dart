import 'dart:async';
import 'package:doublepick/screens/LeagueLeaderboardScreen.dart' hide LeagueLeaderboardScreen;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LeagueLeaderboardScreen.dart';






class LeagueScreenGlobal extends StatefulWidget {
  final String leagueId;
  final String leagueName;

  const LeagueScreenGlobal({
    super.key,
    required this.leagueId,
    required this.leagueName,
  });

  @override
  State<LeagueScreenGlobal> createState() => _LeagueScreenGlobalState();
}

class _LeagueScreenGlobalState extends State<LeagueScreenGlobal> {
  final _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  Map<String, Map<String, dynamic>> unsentTips = {};
  bool unsentLoaded = false;


  List<Map<String, dynamic>> matches = [];
  bool loading = true;

  int startTime = 0;
  int globalEndTime = 0;
  int scoreCalcEndTime = 0;
  bool hasSubmitted = false;

  Duration remaining = Duration.zero;
  Timer? timer;
  String phaseText = "";
  late final String leagueKey;

  @override
  void initState() {
    super.initState();
    leagueKey = widget.leagueName.toLowerCase().replaceAll(' ', '');
    _loadLeague().then((_) => _loadUserTips());
  }




  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // --------------------------------------------------
  Future<void> _loadLeague() async {
    try {
      final doc = await _firestore.collection('leagues2').doc(widget.leagueId).get();
      if (!doc.exists) {
        print("Document ${widget.leagueId} does not exist!");
        return;
      }

      final data = doc.data();
      if (data == null) {
        print("Document data is null!");
        return;
      }

      print("Firebase data: $data"); // <<< ovo će ti pokazati sve polja

      startTime = (data['startTimeMillis'] ?? 0).toInt();
      globalEndTime = (data['globalEndTimeMillis'] ?? 0).toInt();
      scoreCalcEndTime = (data['scoreCalcEndTimeMillis'] ?? 0).toInt();

      final rawMatches = Map<String, dynamic>.from(data['matches'] ?? {});
      print("Matches: $rawMatches");

      matches = rawMatches.entries.map((e) {
        final m = Map<String, dynamic>.from(e.value);
        return {
          'matchId': e.key,
          'home': m['home'] ?? '',
          'away': m['away'] ?? '',
          'resHome': (m['resHome'] ?? -1).toInt(),
          'resAway': (m['resAway'] ?? -1).toInt(),
          'homeCtrl': TextEditingController(text: (m['resHome'] ?? -1) >= 0 ? m['resHome'].toString() : ''),
          'awayCtrl': TextEditingController(text: (m['resAway'] ?? -1) >= 0 ? m['resAway'].toString() : ''),
        };
      }).where((m) => m['home'].toString().isNotEmpty && m['away'].toString().isNotEmpty).toList();

      loading = false;
      _updatePhase();
      _startTimer();
      setState(() {});
    } catch (e, st) {
      print("Error loading league: $e");
      print(st);
    }
  }


  // --------------------------------------------------

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updatePhase();
    });
  }


  void _submitTips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user logged in!");
      return;
    }

    final uid = user.uid;
    final leagueDoc = await _firestore
        .collection('leagues2')
        .doc(widget.leagueName.toLowerCase().replaceAll(' ', ''))
        .get();

    final int currentRound = leagueDoc.data()?['currentRound'] ?? 1;


    try {
      // Mapiranje korisničkih tipova
      Map<String, Map<String, dynamic>> userTips = {};
      for (var m in matches) {
        final homeText = m['homeCtrl'].text.trim();
        final awayText = m['awayCtrl'].text.trim();


        // Ako nema unosa, preskoči
        if (homeText.isEmpty && awayText.isEmpty) continue;



        userTips[m['matchId']] = {
          'homeTeam': m['home'],  // <- koristimo polje koje zapravo postoji
          'awayTeam': m['away'],  // <- koristimo polje koje zapravo postoji
          'tipHome': homeText.isEmpty ? -1 : int.tryParse(homeText) ?? -1,
          'tipAway': awayText.isEmpty ? -1 : int.tryParse(awayText) ?? -1,
        };



      }


      if (userTips.isEmpty) {
        print("No tips entered!");
        return;
      }

      // Sprema u Firestore pod users/{uid}/englishtip1 (ili naziv lige)


      // Drugi collection - unsent / backup
      final backupCollectionName = "${widget.leagueName.toLowerCase().replaceAll(' ', '')}unsenttip";

      await _firestore
          .collection('users')
          .doc(uid)
          .collection(backupCollectionName)
          .doc('round1')
          .set({
        'matches': userTips,
        'savedAt': FieldValue.serverTimestamp(),
      });



      setState(() {
        hasSubmitted = true; // blokira unos
      });
    } catch (e) {
      print("Error saving tips: $e");
    }
  }


  void _updatePhase() {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now < startTime) {
      phaseText = "Round starts in";
      remaining = Duration(milliseconds: startTime - now);
    } else if (now < globalEndTime) {
      phaseText = "Enrollment time left";
      remaining = Duration(milliseconds: globalEndTime - now);
    } else if (now < scoreCalcEndTime) {
      phaseText = "Results incoming";
      remaining = Duration(milliseconds: scoreCalcEndTime - now);
    } else {
      phaseText = "Round finished";
      remaining = Duration.zero;
    }

    setState(() {});
  }


  Future<void> _loadUserTips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final backupCollectionName = "${widget.leagueName.toLowerCase().replaceAll(' ', '')}unsenttip";

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection(backupCollectionName)
          .doc('round1')
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      hasSubmitted = true; // korisnik je već poslao tipove

      // Uzmi sve mečeve iz Firestore i spremi u mapu
      final matchesData = Map<String, dynamic>.from(data['matches'] ?? {});
      unsentTips = matchesData.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
      unsentLoaded = true;

      // Opcionalno: popuni controllere da vidiš u inputima
      for (var m in matches) {
        final matchData = unsentTips[m['matchId']];
        if (matchData != null) {
          m['homeCtrl'].text = matchData['tipHome'] != -1 ? matchData['tipHome'].toString() : '';
          m['awayCtrl'].text = matchData['tipAway'] != -1 ? matchData['tipAway'].toString() : '';
        }
      }

      setState(() {});
    } catch (e) {
      print("Error loading user tips: $e");
    }
  }



  Future<void> _saveLeagueStandings() async {
    final db = FirebaseFirestore.instance;

    List<Map<String, dynamic>> standings = [];

    // Uzmi sve korisnike
    final usersSnap = await db.collection('users').get();

    for (var doc in usersSnap.docs) {
      final data = doc.data();

      // Provjeri da li korisnik ima ligu
      final leagues = Map<String, dynamic>.from(data['leagues'] ?? {});
      final leagueData = leagues[widget.leagueName.toLowerCase().replaceAll(' ', '')];

      // Ako nema, dodaj sa total 0 umjesto da preskačemo
      final total = leagueData != null ? (leagueData['total'] ?? 0) : 0;

      standings.add({
        'uid': doc.id,
        'ime': data['ime'] ?? '',
        'prezime': data['prezime'] ?? '',
        'total': total,
      });
    }

    // Sort descending po bodovima
    standings.sort((a, b) => b['total'].compareTo(a['total']));

    // Spremi pod nazivom lige
    await db
        .collection('leagueStandings')
        .doc(widget.leagueName.toLowerCase().replaceAll(' ', ''))
        .set({'users': standings});

    print("League ${widget.leagueName} standings saved!");
  }


  Future<void> _calculateRound(BuildContext context) async {
    final db = FirebaseFirestore.instance;
    final leagueKey = widget.leagueName.toLowerCase().replaceAll(' ', '');

    final leagueDoc = await db.collection('leagues2').doc(widget.leagueId).get();
    if (!leagueDoc.exists) return;

    final matchesData = Map<String, dynamic>.from(leagueDoc.data()!['matches'] ?? {});

    final realMatches = matchesData.entries.map((e) {
      final m = Map<String, dynamic>.from(e.value);
      return {
        'matchId': e.key,
        'resHome': (m['resHome'] ?? -1).toInt(),
        'resAway': (m['resAway'] ?? -1).toInt(),
        'homeTeam': m['home'] ?? '',
        'awayTeam': m['away'] ?? '',
      };
    }).toList();

    final usersSnap = await db.collection('users').get();

    for (var doc in usersSnap.docs) {
      final d = doc.data();

      final unsentColName = '${leagueKey}unsenttip';
      final tipColName = '${leagueKey}tip1';
      final unsentColRef = doc.reference.collection(unsentColName);
      final tipColRef = doc.reference.collection(tipColName);


      // --- Odredi broj runde ---
      final existingRounds = await tipColRef.get();
      final roundNumber = existingRounds.docs.length + 1; // npr. round1, round2 ...
      final roundDocId = 'round$roundNumber';

      // --- Uzmi korisničke tipove iz unsent collection ---
      final unsentDocSnap = await unsentColRef.doc('round1').get();
      if (!unsentDocSnap.exists) continue; // ako korisnik nema tipove, preskoči

      final unsentData = Map<String, dynamic>.from(unsentDocSnap.data()?['matches'] ?? {});

      // --- Kreiraj mapu za novu rundu ---
      final Map<String, dynamic> newRoundData = {};

      int roundScore = 0;

      for (var match in realMatches) {
        final matchId = match['matchId'];

        // Uzmi postojeći tip korisnika ako postoji
       // final tipDocSnap = await tipColRef.doc('round1').get(); // možemo uvijek gledati runde od 1
       // final oldTip = tipDocSnap.exists
        //    ? Map<String, dynamic>.from(tipDocSnap.data()![matchId] ?? {})
        //    : {};

        final tip = Map<String, dynamic>.from(unsentData[matchId] ?? {});

        final hT = tip['tipHome'] ?? -1;
        final aT = tip['tipAway'] ?? -1;

        final hR = match['resHome'];
        final aR = match['resAway'];

        if (hT != -1 && aT != -1 && hR != -1 && aR != -1) {
          if (hT == hR && aT == aR) roundScore += 10;
          else if (_sameOutcome(hT, aT, hR, aR)) roundScore += 2;
        }

        // Dodajemo sve u novi dokument
        newRoundData[matchId] = {
          'home': hT,
          'away': aT,
          'resHome': hR,
          'resAway': aR,
          'homeTeam': match['homeTeam'],
          'awayTeam': match['awayTeam'],
        };
      }

      // --- Spremi novu rundu ---
      await tipColRef.doc(roundDocId).set(newRoundData);

      // --- Update globalnog score ---
      int global = 0;
      final rawScore = d['score'];
      if (rawScore != null) {
        if (rawScore is String) global = int.tryParse(rawScore) ?? 0;
        else if (rawScore is int) global = rawScore;
      }

      final leagues = Map<String, dynamic>.from(d['leagues'] ?? {});
      final leagueData = Map<String, dynamic>.from(leagues[leagueKey] ?? {});
      final oldTotal = leagueData['total'] ?? 0;

      await doc.reference.update({
        'score': (global + roundScore).toString(),
        'leagues.$leagueKey.total': oldTotal + roundScore,
      });
    }

    await _saveLeagueStandings();
  }


  bool _sameOutcome(int a, int b, int x, int y) {
      int sign(int d) => d > 0 ? 1 : (d < 0 ? -1 : 0);
      return sign(a - b) == sign(x - y);
    }




    bool _isAdmin(User? user) {
    if (user == null) return false;
    return user.email == "salihlihic998@gmail.com";
  }


  Future<void> _resetRound() async {
    final db = FirebaseFirestore.instance;
    final leagueKey = widget.leagueName.toLowerCase().replaceAll(' ', '');
    final leagueDocRef = db.collection('leagues2').doc(widget.leagueId);
    final leagueSnap = await leagueDocRef.get();
    if (!leagueSnap.exists) return;

    final data = Map<String, dynamic>.from(leagueSnap.data()!);
    final matches = Map<String, dynamic>.from(data['matches'] ?? {});

    final Map<String, dynamic> resetMatches = {};
    matches.forEach((matchId, value) {
      resetMatches[matchId] = {
        'home': "",       // prazno polje
        'away': "",       // prazno polje
        'resHome': -1,    // reset rezultata
        'resAway': -1,    // reset rezultata
      };
    });

    // --- Uzmi sve korisnike ---
    final usersSnap = await db.collection('users').get();

    for (var userDoc in usersSnap.docs) {
      final userRef = userDoc.reference;

      final backupColName = '${leagueKey}unsenttip';

      // Dobavi sve dokumente u kolekciji unsenttip za ovog korisnika
      final backupDocs = await userRef.collection(backupColName).get();

      for (var doc in backupDocs.docs) {
        await doc.reference.delete(); // briše dokument
      }
    }



    await leagueDocRef.update({'matches': resetMatches});
  }

  Future<void> _resetSeason() async {
    final db = FirebaseFirestore.instance;
    final leagueKey = widget.leagueName.toLowerCase().replaceAll(' ', ''); // npr. "englishleague"

    final usersSnap = await db.collection('users').get();

    for (var userDoc in usersSnap.docs) {
      final data = userDoc.data();

      // Reset score samo u ligi
      final leagues = Map<String, dynamic>.from(data['leagues'] ?? {});
      if (leagues.containsKey(leagueKey)) {
        leagues[leagueKey]['total'] = 0;
      }

      await userDoc.reference.update({'leagues': leagues});

      // Obriši sve runde iz tip1 kolekcije
      final tipColName = '${leagueKey}tip1';
      final tipColRef = userDoc.reference.collection(tipColName);

      final tipDocs = await tipColRef.get();
      for (var doc in tipDocs.docs) {
        await doc.reference.delete();
      }
    }

    print("Season reset for league $leagueKey completed!");
  }



  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);

    return Scaffold(
      backgroundColor: const Color(0xFF00150A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00150A),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF44FF96)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DoublePick',
          style: TextStyle(
            color: Color(0xFFEFFF8A),
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ===== LEAGUE NAME =====
          Text(
            widget.leagueName.toUpperCase(),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFFEFFF8A),
              shadows: [
                Shadow(color: Colors.yellow, blurRadius: 12),
              ],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

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

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeagueLeaderboardScreen(
                    leagueName: widget.leagueName,
                    leagueId: widget.leagueId,
                  ),
                ),
              );
            },
            child: const Text(
              "Standings league",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),



          // ===== MATCH LIST =====
          Expanded(
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (_, i) {
                final m = matches[i];

                // Preskoči prazne utakmice
                if ((m['home'] as String).isEmpty && (m['away'] as String).isEmpty) {
                  return const SizedBox.shrink();
                }

                return _matchCard(
                  m['matchId'],
                  m['home'],
                  m['away'],
                  m['resHome'] != null && m['resHome'] >= 0 ? m['resHome'].toString() : "0",
                  m['resAway'] != null && m['resAway'] >= 0 ? m['resAway'].toString() : "0",
                  m['homeCtrl'],
                  m['awayCtrl'],

                );
              },
            ),
          ),


          // ===== SEND RESULTS BUTTON =====
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


          if (_isAdmin(user))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _calculateRound(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    ),
                    child: const Text(
                      "CALCULATE ROUND",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // razmak između dugmadi
                  ElevatedButton(
                    onPressed: () async {
                      await _resetRound(); // funkcija koju ćemo napraviti
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    ),
                    child: const Text(
                      "RESET ROUND",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: () async {
                      await _resetSeason();
                      // Opcionalno: refresh UI nakon reset
                      setState(() {
                        hasSubmitted = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                    ),
                    child: const Text(
                      "RESET SEASON",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }


  Widget _matchCard(
      String matchId,
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
                width: 140,
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
                          ((unsentLoaded && unsentTips[matchId] != null)
                              ? "${unsentTips[matchId]!['tipHome']}-${unsentTips[matchId]!['tipAway']}"
                              : "No results"),
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






}
