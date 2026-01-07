import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6791458589312613/3522917422',
      size: AdSize.banner, // 🔥 MANJI BANNER
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose(); // sprječava crash
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    //_bannerAd?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00150A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF011F0A),
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
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 40 * (1 - value)),
              child: child,
            ),
          );
        },

        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE9FFB1),
                      Color(0xFFDFFF8E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: const [
                      Text(
                        "🎯 Rules of the Game",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 18),

                      Text(

                      "1️⃣ Predict the correct score for both matches.\n\n"

                      "2️⃣ Special bonus matches:\n\n"

                      "   Correct exact score → 20 points\n\n"
                      "   Correct outcome (win/draw/loss) → 7 points\n\n"

                  "3️⃣ Other leagues:\n\n"

                  "   Correct exact score → 10 points\n\n"

                  "   Correct outcome (win/draw/loss) → 2 points\n\n"

                "4️⃣ Bonus for both matches correct in special bonus round: +15 points\n\n"

                "5️⃣ Each day you can watch one ad to get 10 bonus points.\n\n"

                "6️⃣ Each league has its own leaderboard, but all points count towards the global score.\n\n"

                "7️⃣ The leaderboard updates automatically after results are posted.\n\n"

                "8️⃣ Each player can create only one league.\n\n"

                  "9️⃣ The app is intended for fun and entertainment only.\n\n",
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.6,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),

      bottomNavigationBar: null,
    );
  }

}
