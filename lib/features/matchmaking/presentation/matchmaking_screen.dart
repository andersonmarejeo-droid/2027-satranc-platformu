import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routing/menu_back.dart';

import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/widgets/page_layout.dart';
import '../../../core/widgets/online_consent.dart';
import '../../game/domain/time_control.dart';
import '../../game/domain/computer_difficulty.dart';
import '../domain/matchmaking_repository.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({
    super.key,
    required this.timeControl,
    this.autostart = false,
    this.botFallbackDelay = const Duration(seconds: 15),
  });

  final TimeControl timeControl;
  final bool autostart;
  final Duration botFallbackDelay;

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  MatchmakingRepository? _repository;
  StreamSubscription<MatchTicket>? _updates;
  MatchTicket? _ticket;
  String? _error;
  bool _busy = false;
  bool _started = false;
  bool _botFallbackVisible = false;
  String? _openedMatch;
  Timer? _expiry, _botFallbackTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _repository = AppScope.of(context).matchmaking;
    if (widget.autostart && !_started && _repository != null) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _join();
      });
    }
  }

  @override
  void dispose() {
    _updates?.cancel();
    _expiry?.cancel();
    _botFallbackTimer?.cancel();
    final ticket = _ticket;
    if (ticket?.status == QueueStatus.searching) {
      final repository = _repository;
      if (repository != null) {
        unawaited(_cancelOnExit(repository, ticket!.id));
      }
    }
    super.dispose();
  }

  Future<void> _cancelOnExit(
    MatchmakingRepository repository,
    String ticketId,
  ) async {
    try {
      await repository.cancel(ticketId);
    } catch (_) {
      // The route is closing; the server's ticket expiry is the fallback.
    }
  }

  Future<void> _join() async {
    final repository = _repository;
    if (repository == null) return;
    if (!await ensureOnlineConsent(context) || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _botFallbackVisible = false;
    });
    try {
      final ticket = await repository.join(widget.timeControl);
      if (!mounted) return;
      setState(() => _ticket = ticket);
      _openMatched(ticket);
      if (ticket.status == QueueStatus.searching) {
        _watch(repository, ticket.id);
        _startBotFallbackTimer();
      }
      if (ticket.status == QueueStatus.searching) {
        _expiry?.cancel();
        _expiry = Timer(const Duration(minutes: 5), () async {
          if (!mounted || _ticket?.status != QueueStatus.searching) return;
          try {
            await repository.cancel(ticket.id);
          } catch (_) {}
          if (mounted && _ticket?.status == QueueStatus.searching) {
            await _updates?.cancel();
            setState(
              () => _ticket = MatchTicket(ticket.id, QueueStatus.expired),
            );
          }
        });
      }
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Sıraya katılınamadı. Yeniden deneyebilirsin.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _watch(MatchmakingRepository repository, String ticketId) {
    _updates?.cancel();
    _updates = repository
        .watch(ticketId)
        .listen(
          (ticket) {
            if (mounted) {
              setState(() {
                _ticket = ticket;
                if (ticket.status != QueueStatus.searching) {
                  _botFallbackVisible = false;
                }
              });
            }
            _openMatched(ticket);
          },
          onError: (Object error) {
            if (!mounted) return;
            setState(() {
              _error = error is ApiFailure
                  ? error.message
                  : 'Eşleşme durumu alınamadı. Bağlantını kontrol et.';
            });
          },
        );
  }

  void _openMatched(MatchTicket ticket) {
    final id = ticket.matchId;
    if (!widget.autostart || id == null || id == _openedMatch) return;
    _openedMatch = id;
    _expiry?.cancel();
    _botFallbackTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.replace('/online-match/${Uri.encodeComponent(id)}');
    });
  }

  Future<void> _cancel() async {
    final repository = _repository;
    final ticket = _ticket;
    if (repository == null || ticket == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    await _updates?.cancel();
    _botFallbackTimer?.cancel();
    try {
      await repository.cancel(ticket.id);
      if (mounted) {
        setState(() => _ticket = MatchTicket(ticket.id, QueueStatus.cancelled));
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failure.message);
        _watch(repository, ticket.id);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Sıra iptal edilemedi. Yeniden deneyebilirsin.',
        );
        _watch(repository, ticket.id);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _startBotFallbackTimer() {
    _botFallbackTimer?.cancel();
    if (widget.botFallbackDelay <= Duration.zero) {
      _botFallbackVisible = true;
      return;
    }
    _botFallbackTimer = Timer(widget.botFallbackDelay, () {
      if (!mounted || _ticket?.status != QueueStatus.searching) return;
      setState(() => _botFallbackVisible = true);
    });
  }

  Future<void> _playBotFallback() async {
    final repository = _repository;
    final ticket = _ticket;
    if (repository == null || ticket?.status != QueueStatus.searching) return;
    final draftStore = AppScope.of(context).gameDraft;
    if (draftStore.draft != null || draftStore.hasError) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bilgisayar maçına geçilsin mi?'),
          content: const Text(
            'Cihazında devam eden yerel bir oyun var. Yeni bilgisayar maçı açılırsa bu oyunun yerini alır; kaydedilmiş maçların korunur.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yeni maç'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      try {
        await draftStore.clear();
      } catch (_) {
        if (mounted) {
          setState(() => _error = 'Yerel oyun korunamadı; yeni maç açılmadı.');
        }
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    _botFallbackTimer?.cancel();
    await _updates?.cancel();
    try {
      await repository.cancel(ticket!.id);
      if (!mounted || _ticket?.status != QueueStatus.searching) return;
      final difficulty =
          AppScope.of(context).quickPlay?.value.difficulty ??
          ComputerDifficulty.medium;
      context.replace(
        '/game?minutes=${widget.timeControl.minutes}&increment=${widget.timeControl.incrementSeconds}&clock=on&opponent=computer&difficulty=${difficulty.name}&fallback=1',
      );
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Arama kapatılamadı. Gerçek rakip araması sürdürülüyor.',
        );
        _watch(repository, ticket!.id);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _statusMessage => switch (_ticket?.status) {
    QueueStatus.searching => 'Uygun rakip aranıyor…',
    QueueStatus.matched => 'Rakip bulundu.',
    QueueStatus.cancelled => 'Eşleşme araması iptal edildi.',
    QueueStatus.expired => 'Eşleşme biletinin süresi doldu.',
    QueueStatus.idle || null => 'Eşleşme için hazır.',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const MenuBackButton(),
      title: const Text('Rakip ara'),
    ),
    body: PageLayout(
      eyebrow: 'Çevrim içi eşleşme',
      title: 'Bir rakip bulalım.',
      subtitle: widget.timeControl.description,
      children: [
        if (_repository == null)
          const SurfaceCard(
            child: Text(
              'Canlı eşleşme için çevrim içi hesap ve oyun sunucusu bağlantısı gerekir. Şimdilik yerel pratik ve davet denemesi kullanılabilir.',
            ),
          )
        else ...[
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_ticket?.status == QueueStatus.searching) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      const Icon(Icons.public_outlined),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (_ticket?.matchId case final matchId?) ...[
                  const SizedBox(height: 12),
                  Text('Maç numarası: $matchId'),
                  const SizedBox(height: 8),
                  const Text(
                    'Maç iki oyuncunun telefonunda aynı hamle geçmişinden açılır. Sıralamaya katılan doğrulanmış hesaplar, iki uygulamada doğrulanan sonuçlardan topluluk puanı kazanır.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/online-match/${Uri.encodeComponent(matchId)}',
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Maçı aç'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_botFallbackVisible &&
              _ticket?.status == QueueStatus.searching) ...[
            const SizedBox(height: 12),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.smart_toy_outlined),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Gerçek rakip henüz bulunamadı.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'İstersen beklemeyi sürdürebilir veya bilgisayara karşı hemen başlayabilirsin. Bu maç çevrim içi sıralamaya eklenmez.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        key: const ValueKey('play-bot-fallback'),
                        onPressed: _busy ? null : _playBotFallback,
                        icon: const Icon(Icons.smart_toy_outlined),
                        label: const Text('Bilgisayara karşı başla'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('keep-searching'),
                        onPressed: _busy
                            ? null
                            : () => setState(() => _botFallbackVisible = false),
                        child: const Text('Beklemeye devam et'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (_error case final message?) ...[
            const SizedBox(height: 12),
            SurfaceCard(
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy
                  ? null
                  : _ticket?.status == QueueStatus.searching
                  ? _cancel
                  : _ticket?.status == QueueStatus.matched
                  ? null
                  : _ticket == null
                  ? _join
                  : () => setState(() {
                      _ticket = null;
                      _error = null;
                    }),
              icon: Icon(
                _ticket?.status == QueueStatus.searching
                    ? Icons.close
                    : _ticket == null
                    ? Icons.search_rounded
                    : Icons.refresh_rounded,
              ),
              label: Text(
                _ticket?.status == QueueStatus.searching
                    ? 'Aramayı iptal et'
                    : _ticket == null
                    ? 'Rakip ara'
                    : _ticket?.status == QueueStatus.matched
                    ? 'Maç tahtası bekleniyor'
                    : 'Yeni arama',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Arama, oturum açmış oyuncuların sunucu kuyruğunda yürür. Uygulamadan çıkarken bekleyen arama iptal edilir.',
          ),
        ],
      ],
    ),
  );
}
