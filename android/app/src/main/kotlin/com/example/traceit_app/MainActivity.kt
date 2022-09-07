package com.example.traceit_app

import androidx.annotation.NonNull
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    val TAG: String = "GATT Server"
    val CHANNEL: String = "com.traceit_traceit_app/gatt"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "startGattServer") {
                Log.i(TAG, "Test")
            } else {
                result.notImplemented()
            }
        }
    }
}
