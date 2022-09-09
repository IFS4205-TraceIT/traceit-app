package com.example.traceit_app

import androidx.annotation.NonNull
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    val CHANNEL: String = "com.traceit_traceit_app/gatt"

    private lateinit var gattServerManager: GattServerManager

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        gattServerManager = GattServerManager(applicationContext)

        MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isRunning" -> {
                    result.success(gattServerManager.isRunning())
                }
                "start" -> {
                    gattServerManager.startGattServer()
                    result.success(true)
                }
                "stop" -> {
                    gattServerManager.stopGattServer()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
