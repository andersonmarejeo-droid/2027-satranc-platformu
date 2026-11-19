import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'match_socket.dart';

MatchSocketConnector createMatchSocketConnector() =>
    const _WebMatchSocketConnector();

class _WebMatchSocketConnector implements MatchSocketConnector {
  const _WebMatchSocketConnector();

  @override
  Future<MatchSocket> connect(Uri uri) async {
    final socket = web.WebSocket(uri.toString());
    try {
      await socket.onOpen.first.timeout(const Duration(seconds: 10));
      return _WebMatchSocket(socket);
    } catch (_) {
      socket.close();
      rethrow;
    }
  }
}

class _WebMatchSocket implements MatchSocket {
  _WebMatchSocket(this._socket) {
    _messageSubscription = _socket.onMessage.listen((event) {
      final data = event.data;
      if (data.isA<JSString>()) {
        _messages.add((data as JSString).toDart);
      } else {
        _messages.addError(const FormatException('Expected text message.'));
      }
    });
    _errorSubscription = _socket.onError.listen((_) {
      _messages.addError(StateError('Match WebSocket failed.'));
    });
    _closeSubscription = _socket.onClose.listen((_) {
      if (!_messages.isClosed) unawaited(_messages.close());
    });
  }

  final web.WebSocket _socket;
  final StreamController<Object?> _messages = StreamController<Object?>();
  late final StreamSubscription<web.MessageEvent> _messageSubscription;
  late final StreamSubscription<web.Event> _errorSubscription;
  late final StreamSubscription<web.CloseEvent> _closeSubscription;
  bool _closed = false;

  @override
  Stream<Object?> get messages => _messages.stream;

  @override
  void sendText(String value) => _socket.send(value.toJS);

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _socket.close();
    await _messageSubscription.cancel();
    await _errorSubscription.cancel();
    await _closeSubscription.cancel();
    if (!_messages.isClosed) await _messages.close();
  }
}
