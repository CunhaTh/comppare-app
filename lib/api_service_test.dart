/*import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get_connect/http/src/http/mock/http_request_mock.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart'; import 'package:mockito/annotations.dart'; import 'package:mockito/mockito.dart'; import 'package:test/test.dart'; import 'albuns_criados.dart'; // Ajuste o caminho conforme necessário

@GenerateMocks([http.Client]) void main() { group('ApiService', () { late ApiService apiService; late MockClient mockClient;

setUp(() {
  mockClient = MockClient();
  apiService = ApiService(authToken: 'test_token');
});

test('createFolder should return Folder with id and name', () async {
  final responseBody = jsonEncode({
    'data': {
      'idPasta': 1,
      'nomePasta': 'Test Folder',
      'dataCriacao': '2025-05-15T18:59:00Z',
    },
  });

  when(mockClient.post(
    any,
    headers: anyNamed('headers'),
    body: anyNamed('body'),
  )).thenAnswer((_) async => http.Response(responseBody, 200));

  final folder = await apiService.createFolder('Test Folder', 2);

  expect(folder.id, 1);
  expect(folder.name, 'Test Folder');
  expect(folder.creationDate, isNotNull);
});

test('createFolder should throw exception on failure', () async {
  when(mockClient.post(
    any,
    headers: anyNamed('headers'),
    body: anyNamed('body'),
  )).thenAnswer((_) async => http.Response('Error', 400));

  expect(
    () => apiService.createFolder('Test Folder', 2),
    throwsException,
  );
});

test('createSubAlbum should send multipart request', () async {
  when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
      .thenAnswer((_) async => http.Response('Success', 200));

  await apiService.createSubAlbum(
    folderId: 1,
    subAlbumName: 'Test SubAlbum',
    images: [Uint8List.fromList([0, 1, 2])],
    tags: ['tag1', 'tag2'],
  );

  verify(mockClient.post(
    any,
    headers: anyNamed('headers'),
    body: anyNamed('body'),
  )).called(1);
}); */