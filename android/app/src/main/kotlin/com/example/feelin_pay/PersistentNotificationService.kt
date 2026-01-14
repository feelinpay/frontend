package com.example.feelin_pay

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class PersistentNotificationService : Service() {
    
    companion object {
        private const val CHANNEL_ID = "feelin_pay_persistent"
        private const val NOTIFICATION_ID = 999
        private const val TAG = "PersistentNotification"
        
        fun start(context: Context) {
            val intent = Intent(context, PersistentNotificationService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stop(context: Context) {
            val intent = Intent(context, PersistentNotificationService::class.java)
            context.stopService(intent)
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        Log.d(TAG, "✅ Persistent notification service started")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Recreate notification if service is restarted
        startForeground(NOTIFICATION_ID, createNotification())
        return START_STICKY // Service will be restarted if killed
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Payment Listener Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Persistent notification for payment listening"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Feelin Pay")
            .setContentText("Escuchando notificaciones de pago")
            .setSmallIcon(android.R.drawable.ic_dialog_info) // You can replace with your app icon
            .setContentIntent(pendingIntent)
            .setOngoing(true) // Makes it non-dismissible
            .setAutoCancel(false)
            .setShowWhen(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "⚠️ Persistent notification service destroyed")
    }
}
