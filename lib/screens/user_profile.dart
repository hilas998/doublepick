import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  final String uid;
  const UserProfileScreen({super.key, required this.uid});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int? selectedRound;
  List<Map<String, dynamic>> roundsList = [];
  String? selectedLeagueKey;
  String? selectedLeagueRound;

  List<String> userLeagues = [];
  List<String> leagueRounds = [];
  Map<String, dynamic>? leagueRoundData;


  @override
  void initState() {
    super.initState();
    _loadRounds();
  }
  //Future<void> _loadUserLeagues(Map<String, dynamic> userData) async {
    //final leaguesMap = Map<String, dynamic>.from(userData['leagues'] ?? {});
   // setState(() {
   //  userLeagues = leaguesMap.keys.toList();
   // if (userLeagues.isNotEmpty) {
    //   selectedLeagueKey = userLeagues.first;
    // }
   // });
//
   // if (selectedLeagueKey != null) {
     // await _loadLeagueRounds(selectedLeagueKey!);
   // }
 // }
Future<void> _loadUserLeagues(Map<String, dynamic> userData) async {
  final leaguesMap = Map<String, dynamic>.from(userData['leagues'] ?? {});

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    setState(() {
      userLeagues = leaguesMap.keys.toList();
      if (userLeagues.isNotEmpty) {
        selectedLeagueKey = userLeagues.first;
      }
    });
  });

  if (selectedLeagueKey != null) {
     await _loadLeagueRounds(selectedLeagueKey!);
     }
}
  Future<void> _loadLeagueRounds(String leagueKey) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('${leagueKey}tip1')
        .get();

    setState(() {
      leagueRounds = snap.docs.map((d) => d.id).toList();
      if (leagueRounds.isNotEmpty) {
        selectedLeagueRound = leagueRounds.first;
      }
    });

    if (selectedLeagueRound != null) {
      await _loadLeagueRoundData(leagueKey, selectedLeagueRound!);
    }
  }




  Future<void> _loadLeagueRoundData(String leagueKey, String roundId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('${leagueKey}tip1')
        .doc(roundId)
        .get();

    final raw = Map<String, dynamic>.from(doc.data() ?? {});

    // ⛔ filtriraj prazne / neodigrane mečeve
    final filtered = <String, dynamic>{};

    raw.forEach((key, value) {
      final m = Map<String, dynamic>.from(value);

      if (
      m['home'] != -1 &&
          m['away'] != -1 &&
          m['homeTeam'] != null &&
          m['awayTeam'] != null &&
          m['homeTeam'].toString().isNotEmpty &&
          m['awayTeam'].toString().isNotEmpty
      ) {
        filtered[key] = m;
      }
    });

    setState(() {
      leagueRoundData = filtered;
    });
  }


  Future<void> _loadRounds() async {
    final db = FirebaseFirestore.instance;
    final roundsSnap = await db.collection('rounds').orderBy('roundNumber').get();
    List<Map<String, dynamic>> list = roundsSnap.docs.map((doc) => doc.data()).toList().cast<Map<String, dynamic>>();

    setState(() {
      roundsList = list;
      if (list.isNotEmpty) selectedRound = list.last['roundNumber'];
    });
  }

  Future<Map<String, dynamic>?> _getUser() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Map<String, dynamic>? _getUserRoundData(int roundNumber) {
    final round = roundsList.firstWhere((r) => r['roundNumber'] == roundNumber, orElse: () => {});
    if (round.isEmpty) return null;
    final users = List<Map<String, dynamic>>.from(round['users']);
    final userData = users.firstWhere((u) => u['uid'] == widget.uid, orElse: () => {});
    if (userData.isEmpty) return null;
    return {
      'roundNumber': roundNumber,
      'timovi': round['timovi'],
      'stvarniRezultati': round['stvarniRezultati'],
      'userData': userData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00150A),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUser(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF66)));
          final u = snap.data;
          if (u == null) return const Center(child: Text("User not found", style: TextStyle(color: Colors.white)));

          return AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF44FF96), size: 26),
                    ),
                    const Spacer(),
                    const Text(
                      "DoublePick",
                      style: TextStyle(fontSize: 26, color: Color(0xFFEFFF8A), fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _profileCard(u),

                        const SizedBox(height: 24),

                        // STARA HISTORIJA (2 MEČA – daily rounds)
                        _roundHistory(),


                        const SizedBox(height: 32),

                        // NOVA HISTORIJA (LIGE → RUNDE → MEČEVI)
                        _leagueHistory(u),
                      ],
                    ),

                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  Widget _profileCard(dynamic u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFE9FFB1), Color(0xFFDFFF8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== PROFILE HEADER =====
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00FF88), Color(0xFF00994C)],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.black,
                        child: const Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "${u['ime'] ?? ''} ${u['prezime'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ===== EMAIL =====
                _infoLine(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: u["email"] ?? "N/A",
                  color: Colors.blueAccent,
                  labelFontSize: 12,
                  valueFontSize: 15,
                ),

                // ===== TOTAL SCORE =====
                _infoLine(
                  icon: Icons.star_rate_rounded,
                  label: "Total Score",
                  value: "${u['score'] ?? '0'}",
                  color: Colors.amber,
                  glow: true,
                ),

                const SizedBox(height: 16),
                _divider(),

                const SizedBox(height: 12),
                const Text(
                  "Recent Predictions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // ===== MATCH CARDS (modern style) =====
                _matchCard("Match 1", u['tip1'] ?? "-", u['tip2'] ?? "-"),
                const SizedBox(height: 12),
                _matchCard("Match 2", u['tip3'] ?? "-", u['tip4'] ?? "-"),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _matchCard(String matchTitle, dynamic home, dynamic away) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xBAFFFFFF), Color(0x99E0FFE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.6), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Naziv meča, npr. "Match 1"
          Text(
            matchTitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),

          // Rezultat / korisnikov tip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF22E58B), Color(0xFFB8FF5C)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22E58B).withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              "$home : $away",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF00150A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leagueHistory(Map<String, dynamic> userData) {
    if (userLeagues.isEmpty) {
      _loadUserLeagues(userData);
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "League History",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF44FF96),
          ),
        ),
        const SizedBox(height: 12),

        /// LEAGUE DROPDOWN
        DropdownButton<String>(
          value: selectedLeagueKey,
          dropdownColor: const Color(0xFF112309),
          alignment: Alignment.centerLeft,
          onChanged: (val) async {
            setState(() {
              selectedLeagueKey = val;
              leagueRounds.clear();
              leagueRoundData = null;
            });
            await _loadLeagueRounds(val!);
          },
          items: userLeagues.map((l) {
            return DropdownMenuItem(
              value: l,
              child: Text(l.toUpperCase(), style: const TextStyle(color: Colors.yellow)),
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        /// ROUND DROPDOWN
        if (leagueRounds.isNotEmpty)
          DropdownButton<String>(
            value: selectedLeagueRound,
            dropdownColor: const Color(0xFF112309),
            alignment: Alignment.centerLeft, // lijevo poravnanje
            onChanged: (val) async {
              if (val == null) return;
              setState(() => selectedLeagueRound = val);
              if (selectedLeagueKey != null) {
                await _loadLeagueRoundData(selectedLeagueKey!, val);
              }
            },
            items: leagueRounds.map((r) {
              final roundNumber = r.replaceAll(RegExp(r'[^0-9]'), ''); // izvadi broj iz stringa
              return DropdownMenuItem<String>(
                value: r,
                child: Text("Round $roundNumber", style: const TextStyle(color: Colors.yellow)),
              );
            }).toList(),
          ),


        const SizedBox(height: 12),

        if (leagueRoundData != null)
          ...leagueRoundData!.entries.map((e) {
            final m = Map<String, dynamic>.from(e.value);
            return Card(
              child: ListTile(
                title: Text("${m['homeTeam']} vs ${m['awayTeam']}"),
                subtitle: Text("Your tip: ${m['home']} : ${m['away']}"),
                trailing: Text("Result: ${m['resHome']} : ${m['resAway']}"),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _roundHistory() {
    if (roundsList.isEmpty) return const Text("No rounds played yet", style: TextStyle(color: Colors.white));

    final selectedData = selectedRound != null ? _getUserRoundData(selectedRound!) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Round History", style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900,  color: Color(0xFF44FF96))),
        const SizedBox(height: 12),
        DropdownButton<int>(
          value: selectedRound, // varijabla koja drži trenutno odabrano kolo
          dropdownColor: const Color(0xFF112309),
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                selectedRound = newValue;
              });
            }
          },
          items: roundsList.map<DropdownMenuItem<int>>((r) {
            final num = r['roundNumber'] as int; // cast u int
            return DropdownMenuItem<int>(
              value: num,
              child: Text("Round $num", style: const TextStyle(color: Colors.yellow)),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),
        if (selectedData != null) ...[
          _roundCard(
            teams: selectedData['timovi'],
            results: selectedData['stvarniRezultati'],
            userData: selectedData['userData'],
          ),
        ] else
          const Text("No data for this round", style: TextStyle(color: Colors.yellow)),
      ],
    );
  }

  Widget _roundCard({required Map<String, dynamic> teams, required Map<String, dynamic> results, required Map<String, dynamic> userData}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Round ${userData['roundNumber'] ?? ''}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Meč 1
          _scoreboardRow(
            teamHome: teams['team1'] ?? "-",
            teamAway: teams['team2'] ?? "-",
            resultHome: results['r1'] ?? "-",
            resultAway: results['r2'] ?? "-",
            tipHome: userData['tip1'] ?? "-",
            tipAway: userData['tip2'] ?? "-",
            points: userData['m1'] ?? 0,
          ),

          const SizedBox(height: 8),

          // Meč 2
          _scoreboardRow(
            teamHome: teams['team3'] ?? "-",
            teamAway: teams['team4'] ?? "-",
            resultHome: results['r3'] ?? "-",
            resultAway: results['r4'] ?? "-",
            tipHome: userData['tip3'] ?? "-",
            tipAway: userData['tip4'] ?? "-",
            points: userData['m2'] ?? 0,
          ),


          const Divider(height: 18, color: Colors.black87),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("Total: ${userData['total'] ?? 0} pts", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreboardRow({
    required dynamic teamHome,
    required dynamic teamAway,
    required dynamic resultHome,
    required dynamic resultAway,
    required dynamic tipHome,
    required dynamic tipAway,
    required int points,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lijevi dio: timovi + stvarni rezultat
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$teamHome vs $teamAway", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Score: $resultHome:$resultAway"),
            ],
          ),
        ),

        // Desni dio: tip + bodovi
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Your Tip: $tipHome:$tipAway"),
              Text("$points pts", style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }


  Widget _roundMatchRow({
    required dynamic teamHome,
    required dynamic teamAway,
    required dynamic resultHome,
    required dynamic resultAway,
    required dynamic tipHome,
    required dynamic tipAway,
    required int points,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text("$teamHome - $teamAway", style: const TextStyle(fontWeight: FontWeight.bold))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("Score: $resultHome:$resultAway"),
            Text("Your Tip: $tipHome:$tipAway"),
            Text("$points points", style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _profileHeader(dynamic u) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF00FF88), Color(0xFF00994C)]),
          ),
          child: const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.black,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text("${u['ime'] ?? ''} ${u['prezime'] ?? ''}",
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Colors.black)),
        ),
      ],
    );
  }

  Widget _infoLine({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool glow = false,
    double labelFontSize = 14,
    double valueFontSize = 17,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 28, color: color, shadows: glow ? [Shadow(color: color.withOpacity(0.7), blurRadius: 12)] : []),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: labelFontSize, color: Colors.black)),
                Text(
                  value,
                  style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.w600, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      height: 1.3,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.withOpacity(0), Colors.green.withOpacity(0.7), Colors.green.withOpacity(0)]),
      ),
    );
  }



}
