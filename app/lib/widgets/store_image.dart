import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../data/file_store.dart';

/// A photo from the server through [FileStore]: kept on the phone once
/// shown, so it still shows without network. Two signed links to the same
/// file are the same image.
@immutable
class StoreImage extends ImageProvider<StoreImage> {
  StoreImage(this.url) : key = FileStore.keyFor(url);
  final String url;
  final String key;

  @override
  Future<StoreImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(StoreImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
        codec: _load(decode),
        scale: 1,
        debugLabel: url,
      );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await FileStore.instance.bytes(url);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) => other is StoreImage && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
