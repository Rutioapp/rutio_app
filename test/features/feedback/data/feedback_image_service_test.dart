import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rutio/features/feedback/data/feedback_image_service.dart';

void main() {
  test('canceling the picker is not an error', () async {
    final service = FeedbackImageService(
      picker: _FakeImagePicker(null),
      compressor: _FakeImageCompressor(),
      tempDirectoryProvider: _tempDirectoryProvider,
      uuidGenerator: () => 'prepared-uuid',
    );

    final selection = await service.pickFromGallery();

    expect(selection, isNull);
  });

  test('selected image is represented with preview bytes and mime type',
      () async {
    final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final service = FeedbackImageService(
      picker: _FakeImagePicker(
        XFile.fromData(
          bytes,
          name: 'capture.png',
          mimeType: 'image/png',
        ),
      ),
      compressor: _FakeImageCompressor(),
      tempDirectoryProvider: _tempDirectoryProvider,
      uuidGenerator: () => 'prepared-uuid',
    );

    final selection = await service.pickFromGallery();

    expect(selection, isNotNull);
    expect(selection!.previewBytes, bytes);
    expect(selection.mimeType, 'image/png');
  });

  test('unsupported image types are rejected early', () async {
    final service = FeedbackImageService(
      picker: _FakeImagePicker(
        XFile.fromData(
          Uint8List.fromList(<int>[1, 2, 3]),
          name: 'document.pdf',
          mimeType: 'application/pdf',
        ),
      ),
      compressor: _FakeImageCompressor(),
      tempDirectoryProvider: _tempDirectoryProvider,
    );

    expect(
      service.pickFromGallery,
      throwsA(
        isA<FeedbackImageException>().having(
          (error) => error.type,
          'type',
          FeedbackImageErrorType.unsupportedType,
        ),
      ),
    );
  });

  test('prepareForUpload writes a JPEG temp file that can be cleaned up',
      () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'feedback-image-service-test-',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final sourceBytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
    final prepared = await FeedbackImageService(
      picker: _FakeImagePicker(
        XFile.fromData(
          sourceBytes,
          name: 'capture.png',
          mimeType: 'image/png',
        ),
      ),
      compressor: _FakeImageCompressor(
        bytesByQuality: <int, Uint8List>{
          92: Uint8List.fromList(<int>[10, 11, 12, 13]),
        },
      ),
      tempDirectoryProvider: () async => tempDirectory,
      uuidGenerator: () => 'prepared-uuid',
    ).prepareForUpload(
      FeedbackScreenshotSelection(
        file: XFile.fromData(
          sourceBytes,
          name: 'capture.png',
          mimeType: 'image/png',
        ),
        previewBytes: sourceBytes,
        mimeType: 'image/png',
      ),
    );

    expect(prepared.contentType, feedbackScreenshotOutputMimeType);
    expect(prepared.sizeInBytes, 4);
    expect(prepared.path, endsWith('feedback_prepared-uuid.jpg'));
    expect(await File(prepared.path).exists(), isTrue);

    await prepared.cleanup();

    expect(await File(prepared.path).exists(), isFalse);
  });

  test('prepareForUpload rejects oversized outputs', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'feedback-image-service-test-',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final service = FeedbackImageService(
      picker: _FakeImagePicker(
        XFile.fromData(
          Uint8List.fromList(<int>[1, 2, 3]),
          name: 'capture.png',
          mimeType: 'image/png',
        ),
      ),
      compressor: _FakeImageCompressor(
        bytesByQuality: <int, Uint8List>{
          92: Uint8List(5 * 1000000 + 1),
          84: Uint8List(5 * 1000000 + 1),
          76: Uint8List(5 * 1000000 + 1),
          68: Uint8List(5 * 1000000 + 1),
          60: Uint8List(5 * 1000000 + 1),
          52: Uint8List(5 * 1000000 + 1),
        },
      ),
      tempDirectoryProvider: () async => tempDirectory,
      uuidGenerator: () => 'prepared-uuid',
    );

    final selection = FeedbackScreenshotSelection(
      file: XFile.fromData(
        Uint8List.fromList(<int>[1, 2, 3]),
        name: 'capture.png',
        mimeType: 'image/png',
      ),
      previewBytes: Uint8List.fromList(<int>[1, 2, 3]),
      mimeType: 'image/png',
    );

    expect(
      () => service.prepareForUpload(selection),
      throwsA(
        isA<FeedbackImageException>().having(
          (error) => error.type,
          'type',
          FeedbackImageErrorType.tooLarge,
        ),
      ),
    );
  });
}

Future<Directory> _tempDirectoryProvider() async {
  return Directory.systemTemp.createTemp('feedback-image-service-test-');
}

class _FakeImagePicker implements FeedbackImagePicker {
  _FakeImagePicker(this.result);

  final XFile? result;

  @override
  Future<XFile?> pickGalleryImage() async => result;
}

class _FakeImageCompressor implements FeedbackImageCompressor {
  _FakeImageCompressor({
    this.bytesByQuality = const <int, Uint8List>{},
  });

  final Map<int, Uint8List> bytesByQuality;

  @override
  Future<Uint8List?> compress({
    required String sourcePath,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) async {
    return bytesByQuality[quality] ?? Uint8List.fromList(<int>[1, 2, 3, 4]);
  }
}
