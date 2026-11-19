# Tam alan satranç simgesi — seçenek 05

Kullanıcı isteği: içeriğe uygun, uygulama listesinde alanın yarısını kullanıyormuş gibi küçük görünmeyen simge. Krem mermer at, küçük altın bant ve tam alan turkuaz zemin; Zeka Parkuru görsel ailesi korunur. Yerleşik ImageGen ile iki işlem: yeni kompozisyon ve aynı taşın gerçek alpha ile arka plan çıkarımı. Eski ikon dosyaları korunur.

`05-full-chess.png`: ana görsel. `05-full-chess-512.png`: mağaza önizlemesi. `05-full-chess-foreground.png`: Android alpha katmanı. `05-launcher-preview.png`: yuvarlak/kare ve 48px arayüz simülasyonu; gerçek telefon ekran görüntüsü değildir.

Android'de `ic_launcher_studio_v2` manifest simgesidir; 26+ arka/ön katman ve 33+ tek renk katmanı hazırlanır. Geçmiş seçenek 04 yerine büyük tek at kullanıldı. Play Console görseli bu işlemde yüklenmez.

## Görsel üretim istemi

Use case: precise-object-edit / stylized-concept.
Asset type: finished full-bleed square launcher icon for the premium friendly Turkish chess app Satranç Platformu.
Input image: the provided ivory-knight and jade-rook illustration is the material and sculpting reference. Preserve its warm ivory marble, silky jade/turquoise, subtle gold details and believable soft 3D studio lighting, but redesign the composition for a MUCH STRONGER phone-app icon.
Primary request: produce ONE finished opaque square icon with a LARGE, immediately recognizable ivory Staunton chess knight dominating the frame, and a jade-turquoise background filling every pixel to all four edges. It must look substantial beside other app icons, never like a tiny object occupying half the icon.
Composition: one complete stout chess knight, almost frontal with a slight three-quarter angle facing left. The beautifully rounded carved horse head, arched neck and circular chess-piece base are large and unified. Top of ear at about 7% of canvas height, bottom of round base at about 92%; overall height about 85%. The head/neck broaden to about 74% width at the middle, and the base is about 65% width at its upper edge, tapering to a narrower ellipse at the bottom. Center the visual mass. Keep the ears near the upper center, muzzle in the central-left and base centered so a circular or rounded-square launcher mask keeps the important silhouette. Generous sculptural forms, very crisp recognizability at 48 pixels. No second piece, no stand or floating pedestal. The chess-piece base sits directly on the backdrop.
Scene/backdrop: seamless opaque SATIN JADE TURQUOISE near #168F82 covering the WHOLE square, no white mat, no frame, no pre-rounded corners, no external padding or transparent margins. Very restrained tonal falloff is fine, but edges must all stay jade turquoise. A faint soft contact shadow beneath the base, within the icon, makes it tangible.
Materials: warm ivory/cream stone, very restrained delicate marble grain, rounded friendly edges exactly like the reference's Zeka Parkuru family of 3D objects. One tiny muted amber-gold band around the base. Soft premium physical lighting from upper left, gentle highlights, no neon or glow. Clean restful but lively contrast.
Constraints: original polished app-icon artwork only, square 1:1. The knight is the icon itself and fills most of the visible canvas. NO inset icon tile, NO badge, NO medallion, NO thick border, NO white border, NO small centered scene, NO phone mockup, NO contact sheet, NO words, letters or ZP text, NO watermark, NO extra chess pieces, NO plants, NO platform, NO large board, NO excessive metallic shine. Keep every important part of the one piece visible and avoid cropping its ears or base.

## Ön katman için son düzenleme istemi

Use case: background-extraction.
Input image: the attached full-bleed jade-turquoise chess knight app icon. This is the edit target.
Create the matching Android adaptive-icon foreground layer by removing ONLY the jade background. Preserve the EXACT same complete ivory marble Staunton knight, its tiny gold collar, the exact shape, position, scale, soft lighting, colors, texture and all edges. Do not redesign or recompose any part of the piece. Keep the same square canvas and the existing 7%-92% tall dominant knight layout. Make the background genuinely transparent (alpha), all the way to the canvas edges. Keep the carved head, ear, mane, neck and entire circular base intact. Retain only a very subtle tight semi-transparent contact shadow just under the base; remove any large diffuse background shadows. One transparent PNG artwork, no checkerboard drawn in, no floor, no matte, no frame, no words, no new objects. Main knight unchanged; background removal only.

