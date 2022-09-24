package com.example.traceit_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL_NAME_GATT: String = "com.traceit.traceit_app/gatt"

    private lateinit var gattServerManager: GattServerManager

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        gattServerManager = GattServerManager(applicationContext)

        configureStorageMethodChannel(flutterEngine)
        configureTempIdMethodChannel(flutterEngine)
        configureGattMethodChannel(flutterEngine)
    }

    private fun configureStorageMethodChannel(flutterEngine: FlutterEngine) {
        StorageMethodChannel.configureChannel(flutterEngine)
    }

    private fun configureTempIdMethodChannel(flutterEngine: FlutterEngine) {
        TempIdMethodChannel.configureChannel(flutterEngine)
    }

    private fun configureGattMethodChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME_GATT
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
