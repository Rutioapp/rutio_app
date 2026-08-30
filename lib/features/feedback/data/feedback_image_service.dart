import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const int feedbackScreenshotMaxSide = 1600;
const int feedbackScreenshotTargetBytes = 1000000;
const int feedbackScreenshotHardLimitBytes = 5 * 1000000;
const String feedbackScreenshotOutputMimeType = 'image/jpeg';

enum FeedbackImageErrorType {
  unsupportedType,
  notProcessable,
  compressionFailed,
  tooLarge,
  uploadFailed,
  cleanupFailed,
}

class FeedbackImageException implements Exception {
  const FeedbackImageException(
    this.type, {
    this.cause,
  });

  final FeedbackImageErrorType type;
  final Object? cause;

  @override
  String toString() => 'FeedbackImageException($type, cause: $cause)';
}

class FeedbackScreenshotSelection {
  const FeedbackScreenshotSelection({
    required this.file,
    required this.previewBytes,
    required this.mimeType,
  });

  final XFile file;
  final Uint8List previewBytes;
  final String? mimeType;

  String get path => file.path;
  String get name => file.name;
}

class FeedbackPreparedImage {
  const FeedbackPreparedImage({
    required this.file,
    required this.bytes,
    required this.cleanup,
  });

  final File file;
  final Uint8List bytes;
  final Future<void> Function() cleanup;

  String get path => file.path;
  int get sizeInBytes => bytes.lengthInBytes;
  String get contentType => feedbackScreenshotOutputMimeType;
}

abstract interface class FeedbackImagePicker {
  Future<XFile?> pickGalleryImage();
}

class ImagePickerFeedbackImagePicker implements FeedbackImagePicker {
  ImagePickerFeedbackImagePicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickGalleryImage() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
  }
}

abstract interface class FeedbackImageCompressor {
  Future<Uint8List?> compress({
    required String sourcePath,
    required int quality,
    required int minWidth,
    required int minHeight,
  });
}

class FlutterFeedbackImageCompressor implements FeedbackImageCompressor {
  const FlutterFeedbackImageCompressor();

  @override
  Future<Uint8List?> compress({
    required String sourcePath,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) {
    return FlutterImageCompress.compressWithFile(
      sourcePath,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
      keepExif: false,
      autoCorrectionAngle: true,
    );
  }
}

typedef FeedbackTempDirectoryProvider = Future<Directory> Function();

class FeedbackImageService {
  FeedbackImageService({
    FeedbackImagePicker? picker,
    FeedbackImageCompressor? compressor,
    FeedbackTempDirectoryProvider? tempDirectoryProvider,
    String Function()? uuidGenerator,
    void Function(String message)? logger,
  })  : _picker = picker ?? ImagePickerFeedbackImagePicker(),
        _compressor = compressor ?? const FlutterFeedbackImageCompressor(),
        _tempDirectoryProvider =
            tempDirectoryProvider ?? getTemporaryDirectory,
        _uuidGenerator = uuidGenerator ?? _defaultUuidGenerator,
        _logger = logger;

  final FeedbackImagePicker _picker;
  final FeedbackImageCompressor _compressor;
  final FeedbackTempDirectoryProvider _tempDirectoryProvider;
  final String Function() _uuidGenerator;
  final void Function(String message)? _logger;

  Future<FeedbackScreenshotSelection?> pickFromGallery() async {
    try {
      final picked = await _picker.pickGalleryImage();
      if (picked == null) return null;

      final mimeType = _safeMimeType(picked);
      _validateSelectionType(
        path: picked.path,
        name: picked.name,
        mimeType: mimeType,
      );

      final previewBytes = await picked.readAsBytes();
      if (previewBytes.isEmpty) {
        throw const FeedbackImageException(
          FeedbackImageErrorType.notProcessable,
        );
      }

      return FeedbackScreenshotSelection(
        file: picked,
        previewBytes: previewBytes,
        mimeType: mimeType,
      );
    } on FeedbackImageException {
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        _logger?.call(
          '[feedback_image_service] pick failure: ${error.runtimeType}',
        );
      }
      throw FeedbackImageException(
        FeedbackImageErrorType.notProcessable,
        cause: error,
      );
    }
  }

  Future<FeedbackPreparedImage> prepareForUpload(
    FeedbackScreenshotSelection selection,
  ) async {
    _validateSelectionType(
      path: selection.path,
      name: selection.name,
      mimeType: selection.mimeType,
    );

    final tempDirectory = await _tempDirectoryProvider();
    final outputDirectory = Directory(
      p.join(tempDirectory.path, 'feedback_screenshots'),
    );
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    Uint8List? bytes;
    for (final quality in _qualitySteps) {
      bytes = await _compressor.compress(
        sourcePath: selection.path,
        quality: quality,
        minWidth: feedbackScreenshotMaxSide,
        minHeight: feedbackScreenshotMaxSide,
      );

      if (bytes == null || bytes.isEmpty) {
        continue;
      }

      if (bytes.lengthInBytes <= feedbackScreenshotTargetBytes ||
          quality == _qualitySteps.last) {
        break;
      }
    }

    if (bytes == null || bytes.isEmpty) {
      throw const FeedbackImageException(
        FeedbackImageErrorType.compressionFailed,
      );
    }

    if (bytes.lengthInBytes > feedbackScreenshotHardLimitBytes) {
      throw const FeedbackImageException(FeedbackImageErrorType.tooLarge);
    }

    final tempPath = p.join(
      outputDirectory.path,
      'feedback_${_uuidGenerator()}.jpg',
    );
    final outputFile = File(tempPath);
    await outputFile.writeAsBytes(bytes, flush: true);

    return FeedbackPreparedImage(
      file: outputFile,
      bytes: bytes,
      cleanup: () async {
        try {
          if (await outputFile.exists()) {
            await outputFile.delete();
          }
        } catch (error) {
          if (kDebugMode) {
            _logger?.call(
              '[feedback_image_service] cleanup failure: ${error.runtimeType}',
            );
          }
          throw FeedbackImageException(
            FeedbackImageErrorType.cleanupFailed,
            cause: error,
          );
        }
      },
    );
  }

  static String _defaultUuidGenerator() => const Uuid().v4();

  void _validateSelectionType({
    required String path,
    required String name,
    required String? mimeType,
  }) {
    final normalizedMimeType = (mimeType ?? '').trim().toLowerCase();
    final extension = p.extension(name.isNotEmpty ? name : path)
        .replaceFirst('.', '')
        .trim()
        .toLowerCase();

    if (normalizedMimeType.isNotEmpty &&
        !_allowedMimeTypes.contains(normalizedMimeType)) {
      throw const FeedbackImageException(
        FeedbackImageErrorType.unsupportedType,
      );
    }

    if (extension.isNotEmpty && !_allowedExtensions.contains(extension)) {
      throw const FeedbackImageException(
        FeedbackImageErrorType.unsupportedType,
      );
    }
  }

  String? _safeMimeType(XFile file) {
    try {
      return file.mimeType;
    } on UnimplementedError {
      return null;
    } catch (_) {
      return null;
    }
  }

  static const List<int> _qualitySteps = <int>[
    92,
    84,
    76,
    68,
    60,
    52,
  ];

  static const Set<String> _allowedMimeTypes = <String>{
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/heic',
    'image/heif',
  };

  static const Set<String> _allowedExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'heic',
    'heif',
  };
}
