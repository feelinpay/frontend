package com.example.feelin_pay

import android.content.Context
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.feelin_pay/notification"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // CRITICAL FIX: Clear stale plugin configuration before Flutter starts
        try {
            val pluginPrefs = applicationContext.getSharedPreferences(
                "flutter_notification_cache",
                Context.MODE_PRIVATE
            )
            
            if (pluginPrefs != null) {
                pluginPrefs.edit()
                    .remove("promote_service_args")
                    .apply()
                Log.d("MainActivity", "✅ Cleared plugin config")
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "⚠️ Config cleanup failed: ${e.message}")
        }
        
        super.onCreate(savedInstanceState)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPersistentNotification" -> {
                    PersistentNotificationService.start(this)
                    result.success(true)
                }
                "stopPersistentNotification" -> {
                    PersistentNotificationService.stop(this)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}