import 'dart:io';

/// Shared form sanitization / validation and attachment size checks.
class FormValidators {
  FormValidators._();

  static final emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const maxAttachmentBytes = 5 * 1024 * 1024; // 5 MB
  static const maxPregnancyAttachments = 5;
  static const attachmentExtensions = ['pdf', 'png', 'jpg', 'jpeg'];

  static String sanitizeEmail(String raw) => raw.trim().toLowerCase();

  static String sanitizePhone(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  /// Required email by default.
  static String? validateEmail(String? value, {bool required = true}) {
    final sanitized = sanitizeEmail(value ?? '');
    if (sanitized.isEmpty) return required ? 'Enter your email' : null;
    if (!emailFormat.hasMatch(sanitized)) return 'Enter a valid email address';
    return null;
  }

  /// Optional by default — empty is OK; otherwise exactly 10 digits.
  static String? validatePhone(String? value, {bool required = false}) {
    final digits = sanitizePhone(value ?? '');
    if (digits.isEmpty) return required ? 'Enter your phone number' : null;
    if (digits.length != 10) return 'Phone number must be exactly 10 digits';
    return null;
  }

  /// Returns an error message if the file is invalid; null if OK.
  static String? validateAttachment(
    File file, {
    List<String> allowedExtensions = attachmentExtensions,
    int maxBytes = maxAttachmentBytes,
  }) {
    final name = file.path.split(Platform.pathSeparator).last.toLowerCase();
    final dot = name.lastIndexOf('.');
    final ext = dot == -1 ? '' : name.substring(dot + 1);
    if (!allowedExtensions.contains(ext)) {
      return 'Only ${allowedExtensions.map((e) => e.toUpperCase()).join(', ')} files are allowed';
    }
    final size = file.lengthSync();
    if (size > maxBytes) {
      return 'File must be ${maxBytes ~/ (1024 * 1024)} MB or smaller';
    }
    return null;
  }

  static void assertAttachmentAllowed(
    File file, {
    List<String> allowedExtensions = attachmentExtensions,
    int maxBytes = maxAttachmentBytes,
  }) {
    final error = validateAttachment(file, allowedExtensions: allowedExtensions, maxBytes: maxBytes);
    if (error != null) throw Exception(error);
  }
}
