import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class GoogleDriveService {
  static const String _folderName = 'Reporte de Pagos - Feelin Pay';

  // Constructor no longer needs GoogleSignIn
  GoogleDriveService();

  /// Inicializa la carpeta de reportes PRIVADA del usuario
  /// IMPORTANTE: Solo el usuario tiene acceso a esta carpeta
  /// Ningún servicio externo, bot o backend puede acceder a los datos
  Future<String?> setupReportFolder(auth.AuthClient httpClient) async {
    try {
      final driveApi = drive.DriveApi(httpClient);

      // 1. Buscar si la carpeta ya existe
      debugPrint('🔍 [DRIVE SERVICE] Buscando carpeta privada: $_folderName');
      final query =
          "name = '$_folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final folderList = await driveApi.files.list(
        q: query,
        $fields: 'files(id, name)',
      );

      String? folderId;
      if (folderList.files != null && folderList.files!.isNotEmpty) {
        folderId = folderList.files!.first.id;
        debugPrint('✅ [DRIVE SERVICE] Carpeta privada encontrada: $folderId');
      } else {
        // 2. Crear la carpeta si no existe
        debugPrint('🆕 [DRIVE SERVICE] Creando nueva carpeta PRIVADA...');
        final folderMetadata = drive.File()
          ..name = _folderName
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await driveApi.files.create(
          folderMetadata,
          $fields: 'id',
        );
        folderId = createdFolder.id;
        debugPrint('✅ [DRIVE SERVICE] Carpeta PRIVADA creada: $folderId');
        debugPrint(
          '🔒 [DRIVE SERVICE] Solo el usuario tiene acceso a esta carpeta',
        );
      }

      return folderId;
    } catch (e) {
      debugPrint('❌ [DRIVE SERVICE] Error en setupReportFolder: $e');
      return null;
    }
  }
}
