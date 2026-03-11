import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, Process;

class LocalAuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _getUsernameKey() => 'auth_usernames';
  String _getPasswordKey(String username) => 'auth_password_$username';
  String _getLastUsernameKey() => 'auth_last_username';

  /// Save username and plaintext password securely
  Future<void> saveCredentials(String username, String password) async {
    // Store the password mapped to the username
    await _storage.write(key: _getPasswordKey(username), value: password);
    // Remember the last logged in username to default to it
    await _storage.write(key: _getLastUsernameKey(), value: username);
  }

  /// Retrieve stored credentials for the last user or a specific user
  Future<Map<String, String>?> getCredentials([String? specificUsername]) async {
    final usernameToFetch = specificUsername ?? await _storage.read(key: _getLastUsernameKey());
    
    if (usernameToFetch != null) {
      final password = await _storage.read(key: _getPasswordKey(usernameToFetch));
      if (password != null) {
        return {'username': usernameToFetch, 'password': password};
      }
    }
    return null;
  }

  /// Clear stored credentials for a specific user
  Future<void> clearCredentials(String username) async {
    await _storage.delete(key: _getPasswordKey(username));
    
    final lastUser = await _storage.read(key: _getLastUsernameKey());
    if (lastUser == username) {
      await _storage.delete(key: _getLastUsernameKey());
    }
  }

  /// Prompt the user for device-level identity verification
  Future<bool> authenticate({String reason = 'Please authenticate to access your vault'}) async {
    // Check if we are on an unsupported platform for local_auth
    try {
      if (Platform.isLinux) {
        // Use pkexec to prompt for the system user's password on Linux
        final result = await Process.run('pkexec', ['true']);
        return result.exitCode == 0;
      }
      
      if (Platform.isWindows) {
        print('Bypassing local authentication as it is not fully supported on Windows');
      }
    } catch (_) {
      // In case Platform gives an issue (e.g. on web)
    }

    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      print('Error during local authentication: $e');
      return false;
    } catch (e) {
      print('Unsupported platform for local authentication: $e');
      return false;
    }
  }
}
