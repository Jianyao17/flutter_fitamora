package com.example.fitamora

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.SystemClock
import android.util.Log
import androidx.annotation.NonNull
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.vision.core.RunningMode
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.example.fitamora/method"
    private val EVENT_CHANNEL = "com.example.fitamora/event"

    private var eventSink: EventChannel.EventSink? = null
    private lateinit var poseModel: PoseDetectionModel
    private lateinit var backgroundExecutor: ExecutorService

    private val TAG = "MainActivity"

    private var delegateMode = PoseDetectionModel.DelegateType.GPU
    private var runningMode = RunningMode.IMAGE // Default ke live stream

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine)
    {
        super.configureFlutterEngine(flutterEngine)
        backgroundExecutor = Executors.newSingleThreadExecutor()

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler
            {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "EventChannel onListen")
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "EventChannel onCancel")
                    eventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method)
                {
                    "initialize" -> {
                        val modeStr = call.argument<String>("runningMode") ?: "LIVE_STREAM"
                        runningMode = when (modeStr)
                        {
                            "IMAGE"         -> RunningMode.IMAGE
                            "LIVE_STREAM"   -> RunningMode.LIVE_STREAM
                            "VIDEO"         -> RunningMode.VIDEO
                            else -> RunningMode.IMAGE
                        }
                        initializeModel()
                        result.success(null)
                    }
                    "detectImage" -> {
                        val path = call.argument<String>("path")
                        if (path != null)
                        {
                            backgroundExecutor.execute {
                                val bitmap = BitmapFactory.decodeFile(path)
                                if (runningMode != RunningMode.IMAGE)
                                {
                                    runningMode = RunningMode.IMAGE
                                    poseModel.setRunningMode(RunningMode.IMAGE)
                                }
                                val res = poseModel.detectImage(bitmap)
                                runOnUiThread {
                                    if (res != null) {
                                        val map = formatBundleToMap(res)
                                        result.success(map)
                                    } else {
                                        result.error("ERROR", "Pose detection failed", null)
                                    }
                                }
                            }
                        } else {
                            result.error("ERROR", "No path provided", null)
                        }
                    }
                    "detectImageStream" -> {
                        val imageBytes = call.argument<ByteArray>("imageBytes")
                        if (imageBytes != null)
                        {
                            // Pastikan model dalam mode yang benar
                            if (runningMode != RunningMode.LIVE_STREAM)
                            {
                                runningMode = RunningMode.LIVE_STREAM
                                poseModel.setRunningMode(RunningMode.LIVE_STREAM)
                            }
                            backgroundExecutor.execute {
                                // Decode JPEG byte array menjadi Bitmap
                                val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                                if (bitmap != null)
                                {
                                    val mpImage = BitmapImageBuilder(bitmap).build()
                                    // Gunakan timestamp dari sistem untuk akurasi
                                    poseModel.detectLiveStream(mpImage, SystemClock.uptimeMillis())
                                    bitmap.recycle() // Bebaskan memori bitmap setelah digunakan
                                } else {
                                    Log.e(TAG, "Gagal decode byte array menjadi bitmap.")
                                }
                            }
                            // Segera kembalikan success karena proses berjalan async
                            result.success(null)
                        } else {
                            result.error("ERROR", "imageBytes tidak boleh null", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun initializeModel()
    {
        // Inisialisasi model pose detection
        poseModel = PoseDetectionModel(
            context = this,
            runningMode = runningMode,
            delegateType = delegateMode,
            listener = object : PoseDetectionModel.DetectionListener
            {
                override fun onError(error: String) {
                    Log.e(TAG, "Model error: $error")
                    runOnUiThread { eventSink?.error("ERROR", error, null) }
                }
                override fun onResult(bundle: PoseDetectionModel.ResultBundle) {
                    val map = formatBundleToMap(bundle)
                    runOnUiThread { eventSink?.success(map) }
                }
            }
        )
        val initOk = poseModel.initialize()
        if (!initOk) {
            Log.e(TAG, "Pose model failed to initialize")
        }
    }

    override fun onDestroy()
    {
        super.onDestroy()
        backgroundExecutor.shutdown()
        if (::poseModel.isInitialized) {
            poseModel.dispose()
        }
    }

    // Helper: format bundle ke Map untuk Flutter
    private fun formatBundleToMap(bundle: PoseDetectionModel.ResultBundle): Map<String, Any>
    {
        val landmarksList = mutableListOf<Map<String, Any>>()
        if (bundle.result.landmarks().isNotEmpty())
        {
            val poseLandmarks = bundle.result.landmarks()[0]
            poseLandmarks.forEach { lm ->
                val x = lm.x().toDouble()
                val y = lm.y().toDouble()
                val z = lm.z().toDouble()
                val visibility = lm.visibility().orElse(0.0f)

                landmarksList.add(
                    mapOf(
                        "x" to x, "y" to y, "z" to z,
                        "visibility" to visibility
                    )
                )
            }
        }

        return mapOf(
            "landmarks" to landmarksList,
            "inferenceTimeMs" to bundle.inferenceTimeMs,
            "imageHeight" to bundle.imageHeight,
            "imageWidth" to bundle.imageWidth
        )
    }
}