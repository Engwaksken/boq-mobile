import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Turns any error into a short message a user can act on. Raw exception text
/// (stack traces, SQL, framework or platform errors) is never shown.
String friendlyError(Object? error) {
  if (error is ApiException) return error.message;

  if (error is SocketException || error is HandshakeException) {
    return AppErrorMessages.noInternet;
  }
  if (error is TimeoutException) return AppErrorMessages.timeout;
  if (error is http.ClientException) {
    final text = error.message.toLowerCase();
    return text.contains('too long') || text.contains('timed out')
        ? AppErrorMessages.timeout
        : AppErrorMessages.noInternet;
  }
  if (error is FileSystemException) return AppErrorMessages.file;
  if (error is FormatException) return AppErrorMessages.invalidResponse;

  return AppErrorMessages.generic;
}

/// Friendly text for an HTTP status when the server gave no usable message.
String friendlyStatusMessage(int status) {
  if (status == 401) return AppErrorMessages.sessionExpired;
  if (status == 403) return AppErrorMessages.forbidden;
  if (status == 404) return 'The requested item could not be found.';
  if (status == 408) return AppErrorMessages.timeout;
  if (status == 413) return 'The file is too large to upload.';
  if (status == 419) return AppErrorMessages.sessionExpired;
  if (status == 422) return 'Please check the details you entered.';
  if (status == 429) {
    return 'Too many requests. Please wait a moment and try again.';
  }
  if (status == 503) return AppErrorMessages.unavailable;
  if (status >= 500) return AppErrorMessages.server;
  return AppErrorMessages.generic;
}

class AppErrorMessages {
  static const noInternet =
      'No internet connection. Please connect to Wi-Fi or mobile data and try again.';
  static const timeout =
      'The connection is slow and the request timed out. Please try again.';
  static const server =
      'The server is having a problem right now. Please try again shortly.';
  static const unavailable =
      'The service is temporarily unavailable. Please try again shortly.';
  static const sessionExpired =
      'Your session has expired. Please sign in again.';
  static const forbidden = 'You do not have permission to perform this action.';
  static const invalidResponse =
      'The server returned an unexpected response. Please try again.';
  static const file = 'The file could not be saved or opened on this device.';
  static const generic = 'Something went wrong. Please try again.';
}
