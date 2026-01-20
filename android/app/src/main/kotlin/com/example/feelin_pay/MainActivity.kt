package com.example.feelin_pay

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.feelin.pay/native_utils"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchIntent") {
                val action = call.argument<String>("action")
                val packageName = call.argument<String>("package")
                val componentName = call.argument<String>("component")
                val data = call.argument<String>("data")
                val flags = call.argument<Int>("flags")

                try {
                    val intent = Intent()
                    
                    if (action != null) intent.action = action
                    if (data != null) intent.data = Uri.parse(data)
                    if (packageName != null && componentName != null) {
                        intent.component = ComponentName(packageName, componentName)
                    } else if (packageName != null) {
                        intent.`package` = packageName
                    }
                    
                    if (flags != null) {
                        intent.addFlags(flags)
                    } else {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    val msg = "Error launching intent: ${e.message}"
                    Log.e("MainActivity", msg)
                    // No fallamos el result, solo devolvemos false para manejarlo en Dart suavemente
                    result.success(false) 
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "✅ MainActivity initialized")
    }
}