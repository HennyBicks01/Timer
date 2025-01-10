package com.example.timer_pip

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.res.Configuration
import androidx.annotation.NonNull

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.timer_pip/pip"
    private var isTimerRunning = false
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPiP" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val aspectRatio = Rational(3, 4)
                            val params = PictureInPictureParams.Builder()
                                .setAspectRatio(aspectRatio)
                                .build()
                            enterPictureInPictureMode(params)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("PIP_ERROR", e.message, null)
                    }
                }
                "updateTimerStatus" -> {
                    try {
                        isTimerRunning = call.argument<Boolean>("isRunning") ?: false
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STATUS_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onUserLeaveHint() {
        if (isTimerRunning) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val aspectRatio = Rational(3, 4)
                    val params = PictureInPictureParams.Builder()
                        .setAspectRatio(aspectRatio)
                        .build()
                    enterPictureInPictureMode(params)
                }
            } catch (e: Exception) {
                // Handle error
            }
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        try {
            methodChannel.invokeMethod("onPiPChanged", isInPictureInPictureMode)
        } catch (e: Exception) {
            // Handle error
        }
    }
}
