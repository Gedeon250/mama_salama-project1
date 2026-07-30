import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

enum ChwDocumentKind { cv, proofOfExpertise }

/// Unsigned client-side uploads to Cloudinary, standing in for Firebase
/// Storage (which needs the paid Blaze plan). Cloud name + upload preset
/// are meant to be embedded in the client for this unsigned-upload flow —
/// see Cloudinary's docs on unsigned uploads.
class CloudinaryService {
  CloudinaryService({CloudinaryPublic? client}) : _client = client ?? CloudinaryPublic('rugayi', 'mama_salama', cache: false);

  final CloudinaryPublic _client;

  Future<String> uploadProfilePicture(String uid, File file) async {
    final response = await _client.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'profile_pictures',
        identifier: '$uid-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    return response.secureUrl;
  }

  Future<String> uploadChwDocument(String uid, File file, ChwDocumentKind kind) async {
    final response = await _client.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Raw,
        folder: 'chw_applications/$uid',
        identifier: '${kind.name}-${DateTime.now().millisecondsSinceEpoch}${_extensionOf(file.path)}',
      ),
    );
    return response.secureUrl;
  }

  Future<String> uploadChatAttachment(String threadId, File file, {required bool isImage}) async {
    final response = await _client.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: isImage ? CloudinaryResourceType.Image : CloudinaryResourceType.Raw,
        folder: 'chat_attachments/$threadId',
        identifier: '${DateTime.now().millisecondsSinceEpoch}${_extensionOf(file.path)}',
      ),
    );
    return response.secureUrl;
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot);
  }
}
