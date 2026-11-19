import 'match_socket.dart';
import 'match_socket_connector_stub.dart'
    if (dart.library.io) 'match_socket_connector_io.dart'
    if (dart.library.js_interop) 'match_socket_connector_web.dart'
    as platform;

MatchSocketConnector createMatchSocketConnector() =>
    platform.createMatchSocketConnector();
