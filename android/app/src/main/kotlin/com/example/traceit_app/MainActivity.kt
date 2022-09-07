package com.example.traceit_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.traceit_app/method"

    private var gattServerManager: GattServerManager? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        gattServerManager = GattServerManager(applicationContext)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "start") {
                result.success(gattServerManager!!.startGattServer())
            } else if (call.method == "stop") {
                result.success(gattServerManager!!.stopGattServer())
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDestroy() {

        super.onDestroy()
    }
}
