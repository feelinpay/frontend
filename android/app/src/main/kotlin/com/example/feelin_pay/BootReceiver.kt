package com.example.feelin_pay

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import id.flutter.flutter_background_service.BackgroundService

/**
 * BroadcastReceiver que inicia el servicio de notificaciones
 * cuando el dispositivo se enciende (BOOT_COMPLETED)
 * 
 * Solo inicia el servicio si el usuario tiene sesión activa
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "📱 Device boot completed, checking for active session...")
            
            // Verificar si hay sesión activa (token guardado)
            val prefs = context.getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE)
            val hasSession = prefs.contains("auth_token")
            
            if (hasSession) {
                Log.d("BootReceiver", "✅ Active session found, starting background service...")
                
                try {
                    // Iniciar el servicio de fondo
                    val serviceIntent = Intent(context, BackgroundService::class.java)
                    context.startForegroundService(serviceIntent)
                    
                    Log.d("BootReceiver", "🚀 Background service started successfully")
                } catch (e: Exception) {
                    Log.e("BootReceiver", "❌ Error starting background service: ${e.message}")
                }
            } else {
                Log.d("BootReceiver", "⚠️ No active session, skipping service start")
            }
        }
    }
}
