import 'package:flutter/material.dart';

import '../../../app/app_services.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/widgets/page_layout.dart';
import '../../game/data/local_chess_rules.dart';
import '../../game/domain/game_rules.dart';
import '../../game/presentation/board_view_state.dart';
import '../../game/presentation/widgets/board_materials.dart';
import '../../game/presentation/widgets/chess_board.dart';
import '../domain/board_appearance.dart';

Future<void> showBoardAppearance(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .90,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tahtanı seç',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const BoardAppearanceControls(),
            ],
          ),
        ),
      ),
    );

class BoardAppearanceButton extends StatelessWidget {
  const BoardAppearanceButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('board-appearance'),
    tooltip: 'Tahta görünümü',
    onPressed: () => showBoardAppearance(context),
    icon: const Icon(Icons.palette_outlined),
  );
}

class BoardAppearanceControls extends StatelessWidget {
  const BoardAppearanceControls({super.key});
  static final _preview = _PreviewState();
  @override
  Widget build(BuildContext context) {
    final preferences = AppScope.of(context).boardAppearance;
    Future<void> change({
      BoardViewMode? view,
      BoardStyle? board,
      PieceStyle? pieces,
      BoardCamera? camera,
      PieceShape? shape,
    }) async {
      try {
        await preferences.update(
          view: view,
          board: board,
          pieces: pieces,
          camera: camera,
          shape: shape,
        );
      } catch (_) {
        if (context.mounted) {
          showNotice(
            context,
            'Tahta tercihi kaydedilemedi. Yeniden deneyebilirsin.',
          );
        }
      }
    }

    final langCode = AppScope.of(context).language.current.code;

    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) {
        final value = preferences.value;
        final board = BoardMaterial.of(value.board);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(AppStrings.get('board_view_title', langCode)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in {
                  BoardViewMode.flat: AppStrings.get('board_view_flat', langCode),
                  BoardViewMode.overhead: AppStrings.get('board_view_overhead', langCode),
                  BoardViewMode.table3d: AppStrings.get('board_view_table3d', langCode),
                  BoardViewMode.wizard3d: AppStrings.get('board_view_wizard3d', langCode),
                }.entries)
                  ChoiceChip(
                    key: ValueKey('view-${entry.key.name}'),
                    label: Text(entry.value),
                    selected: value.view == entry.key,
                    onSelected: (_) => change(view: entry.key),
                  ),
              ],
            ),
            if (value.view == BoardViewMode.table3d) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.get('camera_angle', langCode),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in {
                    BoardCamera.low: AppStrings.get('camera_low', langCode),
                    BoardCamera.balanced: AppStrings.get('camera_balanced', langCode),
                    BoardCamera.high: AppStrings.get('camera_high', langCode),
                  }.entries)
                    ChoiceChip(
                      key: ValueKey('camera-${entry.key.name}'),
                      label: Text(entry.value),
                      selected: value.camera == entry.key,
                      onSelected: (_) => change(camera: entry.key),
                    ),
                ],
              ),
            ],
            if (value.view == BoardViewMode.table3d) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.get('piece_model', langCode),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in {
                    PieceShape.classic: AppStrings.get('piece_classic', langCode),
                    PieceShape.carved: AppStrings.get('piece_carved', langCode),
                  }.entries)
                    ChoiceChip(
                      key: ValueKey('shape-${entry.key.name}'),
                      label: Text(entry.value),
                      selected: value.shape == entry.key,
                      onSelected: (_) => change(shape: entry.key),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ChessBoard(
                    key: const ValueKey('appearance-preview'),
                    controller: _preview,
                    appearance: value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(board.name, style: Theme.of(context).textTheme.titleMedium),
            Text(board.description),
            const SizedBox(height: 4),
            SectionTitle(AppStrings.get('classic_boards', langCode)),
            _boards(
              context,
              BoardStyle.values.where((s) => !BoardMaterial.of(s).playful),
              value,
              (style) => change(
                board: style,
                pieces: BoardMaterial.of(style).recommendedPieces,
              ),
            ),
            const SizedBox(height: 4),
            SectionTitle(AppStrings.get('playful_boards', langCode)),
            Text(AppStrings.get('playful_boards_desc', langCode)),
            const SizedBox(height: 12),
            _boards(
              context,
              BoardStyle.values.where((s) => BoardMaterial.of(s).playful),
              value,
              (style) => change(
                board: style,
                pieces: BoardMaterial.of(style).recommendedPieces,
              ),
            ),
            const SizedBox(height: 4),
            SectionTitle(AppStrings.get('piece_set', langCode)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final style in PieceStyle.values)
                  ChoiceChip(
                    key: ValueKey('pieces-${style.name}'),
                    avatar: _TeamColors(material: PieceMaterial.of(style)),
                    label: Text(PieceMaterial.of(style).name),
                    selected: value.pieces == style,
                    onSelected: (_) => change(pieces: style),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.get('board_colors_hint', langCode),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              key: const ValueKey('appearance-reset'),
              onPressed: () => change(
                view: const BoardAppearance().view,
                board: const BoardAppearance().board,
                pieces: const BoardAppearance().pieces,
                camera: const BoardAppearance().camera,
                shape: const BoardAppearance().shape,
              ),
              icon: const Icon(Icons.restore),
              label: Text(AppStrings.get('reset_classic', langCode)),
            ),
          ],
        );
      },
    );
  }

  Widget _boards(
    BuildContext context,
    Iterable<BoardStyle> styles,
    BoardAppearance value,
    ValueChanged<BoardStyle> select,
  ) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final style in styles)
          SizedBox(
            width: constraints.maxWidth < 280
                ? constraints.maxWidth
                : (constraints.maxWidth - 10) / 2,
            child: Semantics(
              selected: value.board == style,
              button: true,
              child: Material(
                color: value.board == style
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: value.board == style
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: InkWell(
                  key: ValueKey('board-${style.name}'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => select(style),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 40,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _BoardSwatch(BoardMaterial.of(style)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          BoardMaterial.of(style).name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _TeamColors extends StatelessWidget {
  const _TeamColors({required this.material});
  final PieceMaterial material;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 24,
    height: 20,
    child: Stack(
      children: [
        Positioned(left: 0, top: 2, child: _dot(material.white)),
        Positioned(right: 0, bottom: 2, child: _dot(material.black)),
      ],
    ),
  );
  Widget _dot(Color color) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black.withValues(alpha: .18)),
    ),
  );
}

class _BoardSwatch extends CustomPainter {
  const _BoardSwatch(this.material);
  final BoardMaterial material;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      Paint()..color = material.frame,
    );
    final rect = Rect.fromLTWH(5, 5, size.width - 10, size.height - 10);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)));
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 8; c++) {
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left + c * rect.width / 8,
            rect.top + r * rect.height / 4,
            rect.width / 8 + .2,
            rect.height / 4 + .2,
          ),
          Paint()..color = (r + c).isEven ? material.light : material.dark,
        );
      }
    }
    canvas.restore();
    final pieces = PieceMaterial.of(material.recommendedPieces);
    for (final entry in [
      (pieces.white, size.width * .37),
      (pieces.black, size.width * .63),
    ]) {
      canvas.drawCircle(
        Offset(entry.$2, size.height * .53),
        9,
        Paint()
          ..color = Colors.black.withValues(alpha: .16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(
        Offset(entry.$2, size.height * .48),
        8,
        Paint()
          ..shader =
              RadialGradient(
                center: const Alignment(-.4, -.4),
                colors: [Color.lerp(entry.$1, Colors.white, .3)!, entry.$1],
              ).createShader(
                Rect.fromCircle(
                  center: Offset(entry.$2, size.height * .48),
                  radius: 8,
                ),
              ),
      );
    }
  }

  @override
  bool shouldRepaint(_BoardSwatch old) => old.material != material;
}

class _PreviewState implements BoardViewState {
  _PreviewState() {
    for (final move in [
      ('e2', 'e4'),
      ('e7', 'e5'),
      ('g1', 'f3'),
      ('b8', 'c6'),
      ('f1', 'c4'),
      ('f8', 'c5'),
    ]) {
      rules.move(move.$1, move.$2);
    }
  }
  @override
  final GameRules rules = LocalChessRules();
  @override
  bool get flipped => false;
  @override
  String? get selected => null;
  @override
  String? get lastFrom => null;
  @override
  String? get lastTo => null;
  @override
  List<String> get targets => const [];
}
