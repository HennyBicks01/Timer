package com.example.timer_pip

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.res.Configuration
import androidx.annotation.NonNull
import android.app.RemoteAction
import android.app.PendingIntent
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.os.Bundle
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.timer_pip/pip"
    private var isTimerRunning = false
    private lateinit var methodChannel: MethodChannel
    private val CONTROL_TYPE_PLAY = 1
    private val CONTROL_TYPE_PAUSE = 2
    private val ACTION_PIP_CONTROL = "PIP_CONTROL"
    private val TIMER_CHANNEL = "com.example.timer_pip/timer"
    private lateinit var timerChannel: MethodChannel

    private val pipReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_PIP_CONTROL) {
                when (intent.getStringExtra("control")) {
                    "play" -> methodChannel.invokeMethod("playTimer", null)
                    "pause" -> methodChannel.invokeMethod("pauseTimer", null)
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registerReceiver(pipReceiver, IntentFilter(ACTION_PIP_CONTROL))
        handleIntent(intent)
    }

    override fun onDestroy() {
        unregisterReceiver(pipReceiver)
        super.onDestroy()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        timerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPiP" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val params = getPiPParams()
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
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            updatePiPActions()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STATUS_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getPiPParams(): PictureInPictureParams {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val builder = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(3, 4))
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setAutoEnterEnabled(true)
            }

            val actions = ArrayList<RemoteAction>()
            val icon = if (isTimerRunning) {
                Icon.createWithResource(this, android.R.drawable.ic_media_pause)
            } else {
                Icon.createWithResource(this, android.R.drawable.ic_media_play)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                this,
                if (isTimerRunning) CONTROL_TYPE_PAUSE else CONTROL_TYPE_PLAY,
                Intent(ACTION_PIP_CONTROL).apply {
                    putExtra("control", if (isTimerRunning) "pause" else "play")
                },
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )

            val action = RemoteAction(
                icon,
                if (isTimerRunning) "Pause" else "Play",
                if (isTimerRunning) "Pause timer" else "Start timer",
                pendingIntent
            )
            actions.add(action)

            builder.setActions(actions)
            return builder.build()
        }
        throw IllegalStateException("PiP not supported")
    }

    private fun updatePiPActions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && isInPictureInPictureMode) {
            setPictureInPictureParams(getPiPParams())
        }
    }

    override fun onUserLeaveHint() {
        if (isTimerRunning) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val params = getPiPParams()
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
            if (isInPictureInPictureMode) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    window.setDecorFitsSystemWindows(false)
                    window.insetsController?.let {
                        it.hide(WindowInsets.Type.systemBars())
                        it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                    }
                } else {
                    @Suppress("DEPRECATION")
                    window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
                }
            }
            methodChannel.invokeMethod("onPiPChanged", isInPictureInPictureMode)
        } catch (e: Exception) {
            // Handle error
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handlePiPControl(intent)
        handleIntent(intent)
    }

    private fun handlePiPControl(intent: Intent) {
        if (intent.action == ACTION_PIP_CONTROL) {
            when (intent.getStringExtra("control")) {
                "play" -> methodChannel.invokeMethod("playTimer", null)
                "pause" -> methodChannel.invokeMethod("pauseTimer", null)
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "android.intent.action.SET_TIMER") {
            val seconds = intent.getIntExtra("android.intent.extra.alarm.LENGTH", 0)
            if (seconds > 0) {
                timerChannel.invokeMethod("setTimer", seconds)
            }
        }
    }
}
