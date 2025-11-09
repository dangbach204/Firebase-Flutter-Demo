import 'package:appwrite/appwrite.dart';

class AppwriteService {
  static const String endpoint = 'https://nyc.cloud.appwrite.io/v1';
  static const String projectId = '690e997d000355680a8e';

  static const String bucketId = '1';

  static Client? _client;
  static Account? _account;
  static Storage? _storage;

  static Client get client {
    _client ??= Client().setEndpoint(endpoint).setProject(projectId);
    return _client!;
  }

  static Account get account {
    _account ??= Account(client);
    return _account!;
  }

  static Storage get storage {
    _storage ??= Storage(client);
    return _storage!;
  }

  static void initialize() {
    client;
  }
}
