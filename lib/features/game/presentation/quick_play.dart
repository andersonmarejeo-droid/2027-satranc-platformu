import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/widgets/page_layout.dart';
import '../domain/game_result.dart';
import '../domain/saved_game.dart';
import 'quick_play_controller.dart';

Future<void> startQuickPlay(BuildContext context) async {
  final services = AppScope.of(context),
      choice = services.quickPlay?.value ?? const QuickPlayChoice();
  try {
    if (choice.mode != QuickPlayMode.online) {
      final draft = services.gameDraft.draft;
      if (draft != null && draft.game.result == GameResult.unfinished) {
        context.push('/game?resume=1');
        return;
      }
      if (draft != null && draft.game.moves.isNotEmpty) {
        await services.gameHistory.save(draft.game);
      }
      if (draft != null || services.gameDraft.hasError) {
        await services.gameDraft.clear();
      }
    }
    final route =
        choice.mode == QuickPlayMode.computer &&
            choice.side == PlayerSideChoice.random &&
            !Random().nextBool()
        ? '${choice.route}&playerColor=black'
        : choice.route;
    if (context.mounted) context.push(route);
  } catch (_) {
    if (context.mounted) {
      showNotice(context, 'Oyun açılamadı. Oyna ekranından yeniden dene.');
    }
  }
}
