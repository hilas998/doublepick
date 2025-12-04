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
      backgroundColor: const Color(0xFF022904),
        appBar: AppBar(
          backgroundColor: const Color(0xFF022904),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2ECC71)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'DoublePick',
            style: TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              color: const Color(0xFFFFF59D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Text(
                      "Rules of the Game",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "1️⃣ Predict the correct score for both matches.\n\n"
                          "2️⃣ Correct result (e.g. 2:1 exact) gives 15 points.\n\n"
                          "3️⃣ Correct outcome (win/draw/loss) gives 5 points.\n\n"
                          "4️⃣ If both matches have correct scores, you get +15 bonus points.\n\n"
                          "5️⃣ Each day you can watch one ad to get +2 bonus points.\n\n"
                          "6️⃣ The leaderboard updates automatically after results are posted.\n\n"
                          "7️⃣ Each player can create only one league.\n\n"
                          "8️⃣ The app is intended for fun and entertainment only, not for any form of gambling.\n\n",
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),

                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

          ],
        ),
      ),
      bottomNavigationBar:  null



    );
  }

}
