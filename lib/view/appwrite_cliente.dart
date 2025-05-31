import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;


class AppwriteClient {
  static final Client _client = Client()
      .setEndpoint('https://fra.cloud.appwrite.io/v1')
      .setProject('68206e05002f50b7b3c1');

  static Client get client => _client;
  static Account get account => Account(_client);
  static Databases get databases => Databases(_client);
  static Storage get storage => Storage(_client);
  static Future<bool> isSessionActive() async {
    try {
      await account.get(); // Tenta obter dados do usuário
      return true; // Se funcionou, tem sessão ativa
    } catch (e) {
      return false; // Se falhou, não tem sessão válida
    }
  }
  static Future<bool> isAdmin(String email) async {
    return email == 'benjie@gmail.com'; // Email do admin
  }
}