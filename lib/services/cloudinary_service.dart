import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:dio/dio.dart';

enum ChwDocumentKind { cv, proofOfExpertise }

class CloudinaryService {
  CloudinaryService({CloudinaryPublic? client}) : _client = client ?? CloudinaryPublic('rugayi', 'mama_salama', cache: false);

  final CloudinaryPublic _client;

  Future<String> uploadProfilePicture(String uid, File file) async {
    final response = await _upload(
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
    // PDFs are image assets on Cloudinary; forcing Raw against an unsigned
    // image-oriented preset returns HTTP 400. Auto lets Cloudinary pick
    // image/raw/video from the file.
    final response = await _upload(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Auto,
        folder: 'chw_applications/$uid',
        identifier: '${kind.name}-${DateTime.now().millisecondsSinceEpoch}${_extensionOf(file.path)}',
      ),
    );
    return response.secureUrl;
  }

  Future<String> uploadChatAttachment(String threadId, File file, {required bool isImage}) async {
    final response = await _upload(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: isImage ? CloudinaryResourceType.Image : CloudinaryResourceType.Auto,
        folder: 'chat_attachments/$threadId',
        identifier: '${DateTime.now().millisecondsSinceEpoch}${_extensionOf(file.path)}',
      ),
    );
    return response.secureUrl;
  }

  Future<CloudinaryResponse> _upload(CloudinaryFile file) async {
    try {
      return await _client.uploadFile(file);
    } on DioException catch (e) {
      throw Exception(_cloudinaryErrorMessage(e));
    }
  }

  String _cloudinaryErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map && data['error']['message'] != null) {
      return 'Upload failed: ${data['error']['message']}';
    }
    if (data is Map && data['error'] is String) {
      return 'Upload failed: ${data['error']}';
    }
    final header = e.response?.headers.value('x-cld-error');
    if (header != null && header.isNotEmpty) return 'Upload failed: $header';
    return 'Upload failed (${e.response?.statusCode ?? 'network error'}). Check your connection and Cloudinary unsigned preset.';
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot);
  }
}
