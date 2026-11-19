import 'dart:io';

import 'package:flutter/services.dart';

/// Headless tests read the exact shipped source bytes without waiting for the
/// platform asset channel. Production uses Flutter's rootBundle.
class SourceAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(await File(key).readAsBytes());
}
