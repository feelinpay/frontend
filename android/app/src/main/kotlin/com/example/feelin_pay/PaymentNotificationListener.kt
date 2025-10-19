package com.example.feelin_pay

import android.app.Notification
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class PaymentNotificationListener : NotificationListenerService() {
    
    companion object {
        private const val TAG = "PaymentNotificationListener"
        private var methodChannel: MethodChannel? = null
        
        fun setMethodChannel(channel: MethodChannel?) {
            methodChannel = channel
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        
        sbn?.let { notification ->
            val packageName = notification.packageName
            val notificationData = notification.notification
            
            // Filtrar SOLO notificaciones de Yape (Mondero Digital) de Perú
            // Package name oficial: com.bcp.yape
            if (packageName == "com.bcp.yape" || 
                packageName.contains("com.bcp.yape", ignoreCase = true)) {
                
                Log.d(TAG, "Notificación de Yape detectada: $packageName")
                
                // Extraer información de la notificación
                val title = notificationData.extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
                val text = notificationData.extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
                val subText = notificationData.extras?.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
                
                // Enviar datos a Flutter
                methodChannel?.invokeMethod("onNotificationReceived", mapOf(
                    "packageName" to packageName,
                    "title" to title,
                    "text" to text,
                    "subText" to subText,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        Log.d(TAG, "Notificación removida: ${sbn?.packageName}")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "PaymentNotificationListener destruido")
    }
}
