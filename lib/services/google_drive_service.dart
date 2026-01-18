import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleDriveService {
  static const String _folderName = 'Reporte de Pagos - Feelin Pay';

  final GoogleSignIn _googleSignIn;

  GoogleDriveService(this._googleSignIn);

  /// Inicializa la carpeta de reportes PRIVADA del usuario
  /// IMPORTANTE: Solo el usuario tiene acceso a esta carpeta
  /// Ningún servicio externo, bot o backend puede acceder a los datos
  Future<String?> setupReportFolder() async {
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        debugPrint(
          '❌ [DRIVE SERVICE] No se pudo obtener el cliente autenticado',
        );
        return null;
      }

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
