import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_services.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/routing/menu_back.dart';
import '../../../core/widgets/online_consent.dart';
import '../../../core/widgets/page_layout.dart';
import '../../game/domain/time_control.dart';
import '../domain/challenge_invite.dart';
import '../domain/online_challenge_repository.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key, this.inviteId});
  final String? inviteId;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  TimeControl selectedTime = TimeControl.presets.first; // 10 dakika
  bool busy = false;
  bool initialized = false;
  ChallengeInvite? invite;
  String? error;
  StreamSubscription<String?>? _matchUpdates;
  bool _navigated = false;

  // En çok tercih edilen süreler
  static const List<TimeControl> popularPresets = [
    TimeControl(5, 0),
    TimeControl(10, 0),
    TimeControl(15, 0),
    TimeControl(30, 0),
  ];

  @override
  void dispose() {
    unawaited(_matchUpdates?.cancel());
    super.dispose();
  }

  void _openMatch(String id) {
    if (!mounted || _navigated) return;
    _navigated = true;
    context.push('/online-match/$id');
  }

  void _watchInvite(ChallengeInvite value) {
    final repo = AppScope.of(context).challenges;
    if (repo is! OnlineChallengeRepository) return;
    unawaited(_matchUpdates?.cancel());
    _navigated = false;
    _matchUpdates = repo.watchMatch(value.id).listen(
      (id) {
        if (id != null) _openMatch(id);
      },
      onError: (Object _) {
        if (mounted) {
          setState(() => error = 'Davet bağlantısı kesildi. Yeniden dene.');
        }
      },
    );
  }

  Future<void> _accept() async {
    final repo = AppScope.of(context).challenges;
    if (repo is! OnlineChallengeRepository || invite == null) return;
    setState(() => busy = true);
    try {
      _openMatch(await repo.accept(invite!.id));
    } catch (_) {
      if (mounted) {
        showNotice(
          context,
          'Davet kullanılmış, süresi dolmuş veya arkadaşının katılması bekleniyor.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      if (widget.inviteId != null) load();
    }
  }

  @override
  void didUpdateWidget(covariant ChallengeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inviteId != widget.inviteId && widget.inviteId != null) {
      load();
    }
  }

  Future<void> load() async {
    if (AppScope.of(context).challenges is OnlineChallengeRepository &&
        !await ensureOnlineConsent(context)) {
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    try {
      final loaded = await AppScope.of(context).challenges.find(
        widget.inviteId ?? invite!.id,
      );
      if (!mounted) return;
      setState(() {
        invite = loaded;
        error = loaded == null
            ? 'Bu davet bulunamadı.'
            : loaded.isExpired
            ? 'Bu davetin süresi dolmuş.'
            : null;
      });
      if (loaded != null && !loaded.isExpired) _watchInvite(loaded);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Davet okunamadı. Yeniden deneyebilirsin.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Daveti oluşturur ve WhatsApp paylaşımını açar
  Future<void> create() async {
    final repo = AppScope.of(context).challenges;
    if (repo is OnlineChallengeRepository &&
        !await ensureOnlineConsent(context)) {
      return;
    }
    if (!mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final created = await repo.create(selectedTime);
      if (mounted) {
        setState(() => invite = created);
        _watchInvite(created);
        // Otomatik olarak WhatsApp'ı aç
        unawaited(share());
      }
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Davet kaydedilemedi. Yeniden deneyebilirsin.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> copy() async {
    if (invite == null) return;
    try {
      await Clipboard.setData(
        ClipboardData(text: invite!.shareLink.toString()),
      );
      if (mounted) showNotice(context, 'Davet bağlantısı kopyalandı.');
    } catch (_) {
      if (mounted) showNotice(context, 'Bağlantı kopyalanamadı.');
    }
  }

  Future<void> share() async {
    if (invite == null) return;
    try {
      final opened = await AppScope.of(context).whatsApp.openComposer(invite!);
      if (!mounted) return;
      if (!opened) {
        showNotice(context, 'WhatsApp açılamadı. Bağlantı panoya kopyalandı.');
        await copy();
      }
    } catch (_) {}
  }

  void _showJoinDialog() {
    final linkController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.link_rounded, color: Color(0xFF0F7A4A)),
                  const SizedBox(width: 8),
                  Text(
                    'Davet Bağlantısıyla Katıl',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Davet linkini buraya yapıştır',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F7A4A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final value = linkController.text.trim();
                  final uri = Uri.tryParse(value);
                  final id = RegExp(r'^[a-f0-9]{40}$').hasMatch(value)
                      ? value
                      : uri?.host == 'satranc-platformu.web.app' &&
                                uri?.pathSegments.length == 2 &&
                                uri?.pathSegments.first == 'challenge'
                          ? uri!.pathSegments.last
                          : '';
                  if (RegExp(r'^[a-f0-9]{40}$').hasMatch(id)) {
                    Navigator.pop(ctx);
                    context.push('/challenge/$id');
                  } else {
                    showNotice(
                      ctx,
                      'Geçerli bir Satranç Platformu davet bağlantısı gir.',
                    );
                  }
                },
                child: const Text('Maça Katıl'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeChip(TimeControl time, {bool isPopular = false}) {
    final isSelected = selectedTime.minutes == time.minutes &&
        selectedTime.incrementSeconds == time.incrementSeconds;

    return ChoiceChip(
      key: ValueKey('challenge-time-${time.minutes}-${time.incrementSeconds}'),
      selected: isSelected,
      onSelected: (_) => setState(() => selectedTime = time),
      showCheckmark: true,
      checkmarkColor: const Color(0xFF0F7A4A),
      avatar: !isSelected
          ? const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF0F7A4A))
          : null,
      label: Text(
        time.incrementSeconds == 0
            ? (isPopular ? '${time.minutes} Dakika' : time.plainLabel)
            : '${time.minutes} dk + ${time.incrementSeconds}s',
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? const Color(0xFF0F7A4A) : null,
        ),
      ),
      selectedColor: const Color(0xFFD8F3DC),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF0F7A4A)
            : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        width: isSelected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challenges = AppScope.of(context).challenges;
    final isLocalDemo = challenges.isLocalDemo;

    return Scaffold(
      appBar: AppBar(
        leading: const MenuBackButton(),
        title: const Text('Meydan Oku'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HATA KARTI
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              error!,
                              style: TextStyle(color: Colors.red.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (widget.inviteId != null)
                      OutlinedButton.icon(
                        onPressed: load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Yeniden Dene'),
                      ),
                    const SizedBox(height: 14),
                  ],

                  // YÜKLENİYOR
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF25D366),
                        ),
                      ),
                    ),

                  // DURUM 1: Dışarıdan Davet Linkiyle Gelinmişse (Kabul Et Ekranı)
                  if (widget.inviteId != null && invite != null && !busy) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF163E2E), Color(0xFF28654B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.sports_esports_rounded,
                            size: 44,
                            color: Color(0xFFD8F3DC),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Satranç Meydan Okuması!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            invite!.timeControl.description,
                            style: const TextStyle(
                              color: Color(0xFFD8F3DC),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _accept,
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: const Text(
                                'Daveti Kabul Et ve Oyna',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: share,
                        icon: const Icon(Icons.chat_rounded, size: 20),
                        label: const Text('WhatsApp ile paylaş'),
                      ),
                    ),
                  ],

                  // DURUM 2: Davet Oluşturuldu, Arkadaşın Katılması Bekleniyor
                  if (invite != null && widget.inviteId == null && !busy) ...[
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F7A4A), Color(0xFF1E8E5A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F7A4A).withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.hourglass_top_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Davet Gönderildi!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Arkadaşının katılması bekleniyor...\nBağlantıya tıkladığı an tahtanız otomatik açılır.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '⏱️ Süre: ${invite!.timeControl.plainLabel}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: share,
                      icon: const Icon(Icons.chat_rounded, size: 20),
                      label: const Text(
                        'WhatsApp ile paylaş',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: const ValueKey('copy-invite'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: copy,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Bağlantıyı Kopyala'),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => invite = null),
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: const Text('Yeni bir davet hazırla'),
                      ),
                    ),
                  ],

                  // DURUM 3: Henüz Davet Oluşturulmadı (Ana Canlı & Sade Ekran)
                  if (invite == null && widget.inviteId == null && !busy) ...[
                    // Renkli Hero Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F7A4A), Color(0xFF25D366)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF25D366).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Arkadaşına Meydan Oku',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Süreyi seç, daveti gönder; arkadaşın tıkladığı an tahtadasınız!',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Oyun Süresi Başlığı
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          'Oyun Süresi',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F7A4A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selectedTime.plainLabel,
                            style: const TextStyle(
                              color: Color(0xFF0F7A4A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Popüler Süre Çipleri
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in popularPresets)
                          _buildTimeChip(preset, isPopular: true),
                      ],
                    ),

                    // Diğer Süreler (Kompakt Açılır Liste)
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: const ValueKey('challenge-more-time-controls'),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 2),
                        childrenPadding: const EdgeInsets.only(bottom: 6),
                        title: const Text(
                          'Diğer süre ve ek süreli tempolar',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final time in TimeControl.shorterPresets)
                                  if (!popularPresets.contains(time))
                                    _buildTimeChip(time),
                                for (final time in TimeControl.longerPresets)
                                  if (!popularPresets.contains(time))
                                    _buildTimeChip(time),
                                for (final time in TimeControl.tournamentPresets)
                                  _buildTimeChip(time),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // DİREKT WHATSAPP DAVETİ OLUŞTUR BUTONU
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('create-invite'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          shadowColor: const Color(0xFF25D366).withValues(alpha: 0.4),
                        ),
                        onPressed: create,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat_bubble_rounded, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isLocalDemo
                                    ? 'Deneme Daveti Oluştur'
                                    : 'WhatsApp ile Davet Gönder',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Alt Kısım: Sade Bağlantıyla Katılma Seçeneği
                    if (!isLocalDemo)
                      Center(
                        child: TextButton(
                          onPressed: _showJoinDialog,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link_rounded, size: 18),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Gelen davet bağlantısıyla katıl',
                                  style: TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
