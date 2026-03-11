import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:password_manager_app/services/auth_service.dart';
import 'dart:convert';

import 'auth_service_test.mocks.dart';

void main() {
  late AuthService authService;
  late MockClient mockClient;

  const token = 'valid_token';

  setUp(() {
    mockClient = MockClient();
    authService = AuthService(client: mockClient);
  });

  group('AuthService Cross Platform Sync Tests', () {

    final validVault = {
      'blob': {
        'vault_salt': 'salt123',
        'nonce': 'nonce123',
        'ciphertext': 'cipher123'
      }
    };

    test('getVault returns vault when server responds 200', () async {
      when(mockClient.get(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token},
      )).thenAnswer((_) async => http.Response(jsonEncode(validVault), 200));

      final result = await authService.getVault(token);

      expect(result['blob']['vault_salt'], 'salt123');
      expect(result.containsKey('blob'), true);
    });

    test('getVault handles malformed JSON response', () async {
      when(mockClient.get(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token},
      )).thenAnswer((_) async => http.Response('invalid_json', 200));

      expect(() async => await authService.getVault(token), throwsException);
    });

    test('getVault handles network exception', () async {
      when(mockClient.get(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token},
      )).thenThrow(Exception('Network error'));

      expect(() async => await authService.getVault(token), throwsException);
    });

    test('getVault returns correct ciphertext', () async {
      when(mockClient.get(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token},
      )).thenAnswer((_) async => http.Response(jsonEncode(validVault), 200));

      final result = await authService.getVault(token);

      expect(result['blob']['ciphertext'], 'cipher123');
    });

    test('updateVault returns true when server confirms success', () async {
      final encryptedBlob = {
        'vault_salt': 'salt123',
        'nonce': 'nonce123',
        'ciphertext': 'cipher123'
      };

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      final result = await authService.updateVault(token, encryptedBlob);

      expect(result, true);
    });

    test('updateVault returns false on server error', () async {
      final encryptedBlob = {'vault_salt': 'salt123'};

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Server error', 500));

      final result = await authService.updateVault(token, encryptedBlob);

      expect(result, false);
    });

    test('updateVault handles authentication failure (401)', () async {
      final encryptedBlob = {'vault_salt': 'salt123'};

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('Unauthorized', 401));

      final result = await authService.updateVault(token, encryptedBlob);

      expect(result, false);
    });

    test('updateVault correctly sends blob structure', () async {
      final encryptedBlob = {
        'vault_salt': 'saltABC',
        'nonce': 'nonceABC',
        'ciphertext': 'cipherABC'
      };

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      await authService.updateVault(token, encryptedBlob);

      final captured = verify(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured.single as String;

      final body = jsonDecode(captured);

      expect(body.containsKey('blob'), true);
      expect(body['blob']['nonce'], 'nonceABC');
    });

    test('full sync cycle works correctly', () async {

      when(mockClient.get(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token},
      )).thenAnswer((_) async => http.Response(jsonEncode(validVault), 200));

      final pulledVault = await authService.getVault(token);

      expect(pulledVault['blob']['vault_salt'], 'salt123');

      final newBlob = {
        'vault_salt': 'updatedSalt',
        'nonce': 'updatedNonce',
        'ciphertext': 'updatedCipher'
      };

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      final success = await authService.updateVault(token, newBlob);

      expect(success, true);
    });

    test('handles empty vault blob from server', () async {
      final emptyVault = {'blob': {}};

      when(mockClient.get(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token},
      )).thenAnswer((_) async => http.Response(jsonEncode(emptyVault), 200));

      final result = await authService.getVault(token);

      expect(result['blob'], isEmpty);
    });

    test('large encrypted vault payload upload', () async {

      final largeBlob = {
        'vault_salt': 'salt',
        'nonce': 'nonce',
        'ciphertext': 'A' * 5000
      };

      when(mockClient.post(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      final result = await authService.updateVault(token, largeBlob);

      expect(result, true);
    });

    test('multiple sequential sync operations', () async {

      when(mockClient.get(
        Uri.parse('${AuthService.baseUrl}/vault'),
        headers: {'Authorization': token},
      )).thenAnswer((_) async => http.Response(jsonEncode(validVault), 200));

      for (int i = 0; i < 5; i++) {
        final vault = await authService.getVault(token);
        expect(vault.containsKey('blob'), true);
      }
    });

  });
}