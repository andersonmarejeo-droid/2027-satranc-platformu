import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../../../settings/domain/board_appearance.dart';

class BoardMaterial {
  const BoardMaterial(
    this.name,
    this.description,
    this.light,
    this.dark,
    this.frame,
    this.recommendedPieces, {
    this.texture,
    this.playful = false,
  });
  final String name, description;
  final Color light, dark, frame;
  final String? texture;
  final PieceStyle recommendedPieces;
  final bool playful;
  static BoardMaterial of(BoardStyle style) => all[style]!;
  static const all = {
    BoardStyle.blackWhite: BoardMaterial(
      'Siyah & Beyaz',
      'Net kareler, mat siyah ve temiz beyaz',
      Color(0xFFFFFFFF),
      Color(0xFF20252B),
      Color(0xFF47515B),
      PieceStyle.blackWhite,
    ),
    BoardStyle.walnut: BoardMaterial(
      'Ceviz & Fildişi',
      'Sıcak ceviz, mat fildişi',
      Color(0xFFE8DCC3),
      Color(0xFF927557),
      Color(0xFF69503B),
      PieceStyle.classic,
      texture: 'assets/textures/wood-walnut-v1.png',
    ),
    BoardStyle.oak: BoardMaterial(
      'Doğal Meşe',
      'Açık meşe ve koyu ahşap',
      Color(0xFFEFDEB9),
      Color(0xFF81674E),
      Color(0xFFB39165),
      PieceStyle.classic,
      texture: 'assets/textures/wood-walnut-v1.png',
    ),
    BoardStyle.marble: BoardMaterial(
      'Carrara Mermer',
      'İnce damarlar, sakin taş yüzey',
      Color(0xFFF2F0EB),
      Color(0xFF68767A),
      Color(0xFFD3D5D2),
      PieceStyle.porcelain,
      texture: 'assets/textures/marble-carrara-v1.png',
    ),
    BoardStyle.slate: BoardMaterial(
      'Antrasit & Pirinç',
      'Mat taş ve sıcak metal',
      Color(0xFFC9CCCA),
      Color(0xFF536363),
      Color(0xFF384847),
      PieceStyle.bronze,
      texture: 'assets/textures/marble-carrara-v1.png',
    ),
    BoardStyle.artisanWalnut: BoardMaterial(
      'Usta Cevizi',
      'Gerçek ceviz dokusu, ince ahşap damarları',
      Color(0xFFE9D6B4),
      Color(0xFF87694E),
      Color(0xFF634C38),
      PieceStyle.classic,
      texture: 'assets/textures/natural_walnut_veneer-1k.jpg',
    ),
    BoardStyle.creamMarble: BoardMaterial(
      'Krem Mermer',
      'Gerçek taş dokusu, yumuşak krem tonları',
      Color(0xFFF2E9D5),
      Color(0xFF827E6B),
      Color(0xFFB9AB91),
      PieceStyle.porcelain,
      texture: 'assets/textures/marble_01-1k.jpg',
    ),
    BoardStyle.meadow: BoardMaterial(
      'Neşeli Bahçe',
      'Nane ve krem, renkli taşlar',
      Color(0xFFFFF2CD),
      Color(0xFF99C5A5),
      Color(0xFF71A18B),
      PieceStyle.berryMint,
      playful: true,
    ),
    BoardStyle.candy: BoardMaterial(
      'Şeker Bahçesi',
      'Kayısı ve gökyüzü mavisi',
      Color(0xFFFFDCC0),
      Color(0xFFA7CADD),
      Color(0xFFE8AD8B),
      PieceStyle.coralBlue,
      playful: true,
    ),
    BoardStyle.ocean: BoardMaterial(
      'Deniz Macerası',
      'Kum ve deniz renkleri',
      Color(0xFFF4E6C2),
      Color(0xFF8DBBBB),
      Color(0xFF5C8E9B),
      PieceStyle.coralBlue,
      playful: true,
    ),
    BoardStyle.lavender: BoardMaterial(
      'Masal Masası',
      'Lavanta, krem ve neşeli taşlar',
      Color(0xFFF8E7D7),
      Color(0xFFBEAFD0),
      Color(0xFF9A8BB4),
      PieceStyle.sunViolet,
      playful: true,
    ),
  };
}

class PieceMaterial {
  const PieceMaterial(
    this.name,
    this.white,
    this.black, {
    this.metallic = false,
  });
  final String name;
  final Color white, black;
  final bool metallic;
  Color team(bool isWhite) => isWhite ? white : black;
  static PieceMaterial of(PieceStyle style) => all[style]!;
  static const all = {
    PieceStyle.blackWhite: PieceMaterial(
      'Beyaz & Siyah',
      Color(0xFFFFFFFF),
      Color(0xFF101419),
    ),
    PieceStyle.classic: PieceMaterial(
      'Fildişi & Abanoz',
      Color(0xFFEADBBE),
      Color(0xFF354139),
    ),
    PieceStyle.porcelain: PieceMaterial(
      'Porselen & Lacivert',
      Color(0xFFF8F5EC),
      Color(0xFF283F56),
    ),
    PieceStyle.bronze: PieceMaterial(
      'Gümüş & Bronz',
      Color(0xFFD7DFDD),
      Color(0xFF976E42),
      metallic: true,
    ),
    PieceStyle.coralBlue: PieceMaterial(
      'Mercan & Mavi',
      Color(0xFFE87758),
      Color(0xFF326DA4),
    ),
    PieceStyle.berryMint: PieceMaterial(
      'Ahududu & Petrol',
      Color(0xFFBA5274),
      Color(0xFF247C74),
    ),
    PieceStyle.sunViolet: PieceMaterial(
      'Güneş & Mor',
      Color(0xFFE1AC38),
      Color(0xFF775A9E),
    ),
  };
}

/// Decoded once at modest resolution; shared by every board on this device.
class BoardTextures {
  static final _cache = <String, Future<ui.Image?>>{};
  static final _decoded = <String, ui.Image>{};
  static ui.Image? cached(String? path) => _decoded[path];
  static Future<ui.Image?> load(String path, {AssetBundle? bundle}) =>
      _cache.putIfAbsent(path, () async {
        try {
          final data = await (bundle ?? rootBundle).load(path);
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
            targetWidth: 512,
          );
          try {
            final image = (await codec.getNextFrame()).image;
            _decoded[path] = image;
            return image;
          } finally {
            codec.dispose();
          }
        } catch (_) {
          return null;
        }
      });
}
