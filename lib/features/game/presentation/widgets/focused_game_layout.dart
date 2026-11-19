import 'package:flutter/material.dart';

/// Tahtanın hem dikeyde hem yatayda maksimum alana oturmasını sağlayan modern Esports düzeni.
class FocusedGameLayout extends StatelessWidget {
  const FocusedGameLayout({
    super.key,
    required this.board,
    required this.topPlayer,
    required this.bottomPlayer,
    required this.status,
    required this.controls,
    this.landscapeHeader,
    this.landscapeAd,
  });

  final Widget board, topPlayer, bottomPlayer, status, controls;
  final Widget? landscapeHeader;
  final Widget? landscapeAd;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // YATAY MOD (LANDSCAPE)
      // Tahta sol tarafta ekran yüksekliğinin tamamını kaplayarak devasa boyuta ulaşır.
      // Sağ tarafta ise geniş panel içinde oyuncu bilgileri, kontroller ve reklam yer alır.
      if (constraints.maxWidth > constraints.maxHeight * 1.15) {
        // Tahtanın sağ paneli aşırı daraltmasını önlemek için maksimum %64 genişlik sınırı
        final maxBoardWidth = constraints.maxWidth * 0.64;
        final boardDimension = constraints.maxHeight > maxBoardWidth ? maxBoardWidth : constraints.maxHeight;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SOL: Tam boyuta oturan devasa satranç tahtası
              Center(
                child: SizedBox(
                  width: boardDimension,
                  height: boardDimension,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: board,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. SAĞ: Ferah ve geniş kontrol & bilgi paneli
              Expanded(
                child: LayoutBuilder(
                  builder: (context, sideConstraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: sideConstraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ?landscapeHeader,
                            topPlayer,
                            bottomPlayer,
                            if (status is! SizedBox) status,
                            controls,
                            ?landscapeAd,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }

      // DİKEY MOD (PORTRAIT)
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: topPlayer,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Center(child: board),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: bottomPlayer,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: controls,
            ),
            const SizedBox(height: 6),
          ],
        ),
      );
    },
  );
}
