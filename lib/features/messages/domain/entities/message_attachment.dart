import 'package:equatable/equatable.dart';

class MessageAttachment extends Equatable {
  const MessageAttachment({
    required this.id,
    required this.messageId,
    this.storagePath,
    required this.mimeType,
    this.fileName,
    this.sizeBytes,
    this.width,
    this.height,
    this.durationMs,
    this.localPath,
    this.thumbnailLocalPath,
    this.uploadStatus = 'pending',
  });

  final String id;
  final String messageId;
  final String? storagePath;
  final String mimeType;
  final String? fileName;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final int? durationMs;
  final String? localPath;
  final String? thumbnailLocalPath;
  final String uploadStatus;

  bool get isUploaded => uploadStatus == 'uploaded';
  bool get isUploading => uploadStatus == 'uploading';
  bool get isFailed => uploadStatus == 'failed';

  @override
  List<Object?> get props => [
        id,
        messageId,
        storagePath,
        mimeType,
        fileName,
        sizeBytes,
        width,
        height,
        durationMs,
        localPath,
        thumbnailLocalPath,
        uploadStatus,
      ];
}
