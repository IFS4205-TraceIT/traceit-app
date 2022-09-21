package com.example.traceit_app

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

object TempIdMethodChannel : FlutterActivity() {
    private const val CHANNEL_NAME_TEMPID: String = "com.traceit.traceit_app/tempid"
    private lateinit var methodChannel: MethodChannel

    fun configureChannel(@NonNull flutterEngine: FlutterEngine) {
        methodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME_TEMPID)
    }

    suspend fun getTempId(): String {
        val deferred = CompletableDeferred<String>()

        // Run on main UI thread
        CoroutineScope(Dispatchers.Main).launch {
            methodChannel.invokeMethod("getTempId", null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    deferred.complete(result as String)
                }

                override fun error(
                    errorCode: String,
                    errorMessage: String?,
                    errorDetails: Any?
                ) {
                    Log.e("TempidMethodChannel", "error: $errorMessage")
                    deferred.complete("error")
                }

                override fun notImplemented() {
                    Log.e("TempidMethodChannel", "notImplemented")
                    deferred.complete("notImplemented")
                }
            })
        }

        val tempId = deferred.await()
        return tempId
    }
}