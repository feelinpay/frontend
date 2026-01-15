package com.example.feelin_pay

import android.content.Context
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // CRITICAL FIX: Clear ALL plugin configuration before Flutter starts
        try {
            val pluginPrefs = applicationContext.getSharedPreferences(
                "flutter_notification_cache",
                Context.MODE_PRIVATE
            )
            
            if (pluginPrefs != null) {
                // Clear ALL stored configuration to prevent JSONException
                pluginPrefs.edit()
                    .clear() // Remove everything
                    .apply()
                Log.d("MainActivity", "✅ Cleared ALL plugin config")
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "⚠️ Config cleanup failed: ${e.message}")
        }
        
        super.onCreate(savedInstanceState)
    }
}