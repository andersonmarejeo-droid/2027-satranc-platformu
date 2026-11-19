import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../board_view_state.dart';
import '../../../settings/domain/board_appearance.dart';

/// Yüksek kaliteli WebGL / Three.js tabanlı Wizard Chess 3D köprü bileşeni.
class WizardChess3DView extends StatefulWidget {
  const WizardChess3DView({
    super.key,
    required this.controller,
    required this.appearance,
    this.onSquareTap,
  });

  final BoardViewState controller;
  final BoardAppearance appearance;
  final ValueChanged<String>? onSquareTap;

  @override
  State<WizardChess3DView> createState() => _WizardChess3DViewState();
}

class _WizardChess3DViewState extends State<WizardChess3DView> {
  WebViewController? _webController;
  bool _ready = false;
  String _lastFen = '';

  @override
  void initState() {
    super.initState();
    _lastFen = widget.controller.rules.fen;
    if (WebViewPlatform.instance != null) {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              // Emniyet: Sayfa yüklendiğinde sceneReady mesajı gecikirse bile takılmayı önle
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted && !_ready) {
                  setState(() => _ready = true);
                  _syncPosition(initial: true);
                }
              });
            },
          ),
        )
        ..addJavaScriptChannel(
          'FlutterBridge',
          onMessageReceived: (message) {
            try {
              final data = jsonDecode(message.message) as Map<String, dynamic>;
              final event = data['event'] as String?;
              if (event == 'squareTapped') {
                final square = data['square'] as String?;
                if (square != null && widget.onSquareTap != null) {
                  HapticFeedback.selectionClick();
                  widget.onSquareTap!(square);
                }
              } else if (event == 'pieceCaptured') {
                HapticFeedback.heavyImpact();
              } else if (event == 'sceneReady') {
                setState(() => _ready = true);
                _syncPosition(initial: true);
              }
            } catch (_) {}
          },
        )
        ..loadFlutterAsset('assets/wizard_chess/index.html');
    }
  }

  @override
  void didUpdateWidget(WizardChess3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_ready || _webController == null) return;

    final nextFen = widget.controller.rules.fen;
    if (nextFen != _lastFen) {
      final from = widget.controller.lastFrom;
      final to = widget.controller.lastTo;
      if (from != null && to != null) {
        HapticFeedback.lightImpact();
        _webController!.runJavaScript(
          'if (window.playMove) window.playMove("$from", "$to");',
        );
      } else {
        _syncPosition();
      }
      _lastFen = nextFen;
    }

    if (widget.controller.selected != oldWidget.controller.selected ||
        widget.controller.targets != oldWidget.controller.targets) {
      final sel = widget.controller.selected ?? '';
      _webController!.runJavaScript(
        'if (window.selectSquare) window.selectSquare("$sel");',
      );
      final targetsJson = jsonEncode(widget.controller.targets.toList());
      _webController!.runJavaScript(
        'if (window.setLegalTargets) window.setLegalTargets($targetsJson);',
      );
    }

    if (widget.controller.flipped != oldWidget.controller.flipped) {
      _syncPosition();
    }
  }

  void _syncPosition({bool initial = false}) {
    if (_webController == null) return;
    final fen = widget.controller.rules.fen;
    final flipped = widget.controller.flipped;
    _webController!.runJavaScript(
      'if (window.loadPosition) window.loadPosition("$fen", $flipped);',
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final unbounded =
            !constraints.hasBoundedHeight || constraints.maxHeight.isInfinite;
        final content = ClipRRect(
          key: const ValueKey('wizard-chess-3d'),
          borderRadius: BorderRadius.zero,
          child: Stack(
            fit: unbounded ? StackFit.loose : StackFit.expand,
            children: [
              if (_webController != null)
                WebViewWidget(controller: _webController!)
              else
                Container(
                  color: const Color(0xFF0D0A08),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFD4AF37),
                      size: 48,
                    ),
                  ),
                ),
              if (!_ready && _webController != null)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                ),
            ],
          ),
        );
        if (unbounded) {
          return AspectRatio(
            aspectRatio: 1.0,
            child: content,
          );
        }
        return content;
      },
    );
  }
}
