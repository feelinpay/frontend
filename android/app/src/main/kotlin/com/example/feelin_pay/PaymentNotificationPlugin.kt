package com.example.feelin_pay

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class PaymentNotificationPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "payment_notifications")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        
        // Configurar el listener de notificaciones
        PaymentNotificationListener.setMethodChannel(channel)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                initializeNotificationListener(result)
            }
            "checkPermissions" -> {
                checkPermissions(result)
            }
            "requestPermissions" -> {
                requestPermissions(result)
            }
            "startListening" -> {
                startListening(result)
            }
            "stopListening" -> {
                stopListening(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initializeNotificationListener(result: Result) {
        try {
            // Verificar permisos
            if (!isNotificationListenerEnabled()) {
                result.error("PERMISSION_DENIED", "Permisos de notificación no concedidos", null)
                return
            }
            
            // Iniciar servicio de escucha
            val intent = Intent(context, PaymentNotificationListener::class.java)
            context.startService(intent)
            
            result.success(true)
        } catch (e: Exception) {
            result.error("INITIALIZATION_ERROR", "Error al inicializar: ${e.message}", null)
        }
    }

    private fun checkPermissions(result: Result) {
        val hasNotificationPermission = isNotificationListenerEnabled()
        val hasSystemAlertPermission = Settings.canDrawOverlays(context)
        
        result.success(mapOf(
            "notificationPermission" to hasNotificationPermission,
            "systemAlertPermission" to hasSystemAlertPermission
        ))
    }

    private fun requestPermissions(result: Result) {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
        result.success(true)
    }

    private fun startListening(result: Result) {
        try {
            val intent = Intent(context, PaymentNotificationListener::class.java)
            context.startService(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("START_ERROR", "Error al iniciar escucha: ${e.message}", null)
        }
    }

    private fun stopListening(result: Result) {
        try {
            val intent = Intent(context, PaymentNotificationListener::class.java)
            context.stopService(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Error al detener escucha: ${e.message}", null)
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val pkgName = context.packageName
        val flat = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
        return flat != null && flat.contains(pkgName)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
