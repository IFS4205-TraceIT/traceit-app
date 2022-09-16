package com.example.traceit_app

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object StorageMethodChannel : FlutterActivity() {
    private const val CHANNEL_NAME_STORAGE: String = "com.traceit.traceit_app/storage"
    private lateinit var methodChannel: MethodChannel

    fun configureChannel(@NonNull flutterEngine: FlutterEngine) {
        methodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME_STORAGE)
    }

    fun writeCloseContact(tempid: String, rssi: Int) {
        val arguments: Map<String, Any> = mapOf(
            "tempid" to tempid,
            "rssi" to rssi
        )

        runOnUiThread {
            methodChannel.invokeMethod("writeCloseContact", arguments)
        }
    }
}