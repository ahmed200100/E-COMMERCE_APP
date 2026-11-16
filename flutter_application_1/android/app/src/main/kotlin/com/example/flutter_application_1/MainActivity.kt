package com.example.flutter_application_1

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.speech.RecognizerIntent
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "nova_store/voice_search"
    private val speechRequestCode = 7310
    private val microphoneRequestCode = 7311
    private var pendingSpeechResult: MethodChannel.Result? = null
    private var requestedLocale = "en-US"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "listen") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingSpeechResult != null) {
                    result.error("busy", "Voice search is already active", null)
                    return@setMethodCallHandler
                }
                pendingSpeechResult = result
                requestedLocale = call.argument<String>("locale") ?: "en-US"
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
                    == PackageManager.PERMISSION_GRANTED
                ) {
                    launchSpeechRecognition()
                } else {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.RECORD_AUDIO),
                        microphoneRequestCode,
                    )
                }
            }
    }

    private fun launchSpeechRecognition() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, requestedLocale)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, requestedLocale)
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak a product name")
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        try {
            startActivityForResult(intent, speechRequestCode)
        } catch (_: Exception) {
            pendingSpeechResult?.error("unavailable", "Speech recognition is not available on this device", null)
            pendingSpeechResult = null
        }
    }

    @Deprecated("Deprecated in Android, retained for the speech recognition activity result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != speechRequestCode) return
        val words = if (resultCode == Activity.RESULT_OK) {
            data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
        } else null
        pendingSpeechResult?.success(words ?: "")
        pendingSpeechResult = null
    }

    @Deprecated("Deprecated in Android, retained for microphone permission callback")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != microphoneRequestCode) return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            launchSpeechRecognition()
        } else {
            pendingSpeechResult?.error("permission_denied", "Microphone permission was denied", null)
            pendingSpeechResult = null
        }
    }
}
