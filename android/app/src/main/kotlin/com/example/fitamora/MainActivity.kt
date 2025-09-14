package com.example.fitamora

import android.graphics.BitmapFactory
import android.os.SystemClock
import android.util.Log
import android.view.Surface
import androidx.annotation.NonNull
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.vision.core.RunningMode
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterActivity()
{
    private val METHOD_CHANNEL = "com.example.fitamora/method"
    private val EVENT_CHANNEL = "com.example.fitamora/event"
    private val OVERLAY_VIEW_TYPE = "com.example.fitamora/overlay_view"

    private var eventSink: EventChannel.EventSink? = null

    private lateinit var poseModel: PoseDetectionModel
    private lateinit var backgroundExecutor: ExecutorService
    private var nativeCamera: MainCamera? = null

    // Tambahkan variabel untuk Texture
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var poseRiggingRenderer: PoseRiggingRenderer? = null

    private val TAG = "MainActivity"

    private var delegateMode = PoseDetectionModel.DelegateType.GPU
    private var runningMode = RunningMode.LIVE_STREAM

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine)
    {
        super.configureFlutterEngine(flutterEngine)
        backgroundExecutor = Executors.newSingleThreadExecutor()

        // --- Daftarkan PlatformViewFactory di sini ---
        val factory = PoseRiggingRenderer.Companion.Factory {
            poseRiggingRenderer = PoseRiggingRenderer(this)
            poseRiggingRenderer!!
        }
        flutterEngine
            .platformViewsController.registry
            .registerViewFactory(OVERLAY_VIEW_TYPE, factory)

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
                        runningMode = when (modeStr) {
                            "IMAGE" -> RunningMode.IMAGE
                            "LIVE_STREAM" -> RunningMode.LIVE_STREAM
                            "VIDEO" -> RunningMode.VIDEO
                            else -> RunningMode.LIVE_STREAM
                        }
                        initializeModel()
                        result.success(null)
                    }

                    "startNativeCamera" -> {
                        val useFrontCamera = call.argument<Boolean>("useFrontCamera") ?: true
                        startNativeCamera(useFrontCamera) { previewSize ->
                            // Kirim textureId dan ukuran preview kembali ke Flutter
                            val response = mapOf(
                                "textureId" to textureEntry?.id(),
                                "previewWidth" to previewSize.width.toDouble(),
                                "previewHeight" to previewSize.height.toDouble()
                            )
                            result.success(response)
                        }
                    }

                    "stopNativeCamera" -> {
                        stopNativeCamera()
                        result.success(null)
                    }

                    "switchCamera" -> {
                        // Switching kamera memerlukan pembuatan ulang sesi,
                        // jadi paling mudah adalah stop dan start lagi
                        nativeCamera?.switchCamera()
                        result.success(mapOf(
                            "isFrontCamera" to (nativeCamera?.isFrontCamera() ?: true)
                        ))
                    }

                    "isCameraRunning" -> {
                        result.success(nativeCamera?.isRunning() ?: false)
                    }

                    "detectImage" -> {
                        val path = call.argument<String>("path")
                        if (path != null)
                        {
                            backgroundExecutor.execute {
                                val bitmap = BitmapFactory.decodeFile(path)
                                if (runningMode != RunningMode.IMAGE) {
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

                    else -> result.notImplemented()
                }
            }
    }

    private fun initializeModel()
    {
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
                override fun onResult(bundle: PoseDetectionModel.ResultBundle)
                {
                    // 1. Kirim data landmark ke Flutter (untuk logika, jika ada)
                    val map = formatBundleToMap(bundle)
                    runOnUiThread { eventSink?.success(map) }

                    // 2. Kirim hasil mentah ke PoseRiggingRenderer untuk digambar
                    if (bundle.result.landmarks().isNotEmpty())
                    {
                        runOnUiThread {
                            poseRiggingRenderer?.setResults(
                                bundle.result,
                                bundle.imageHeight,
                                bundle.imageWidth
                            )
                        }
                    }
                }
            }
        )
        if (!poseModel.initialize()) {
            Log.e(TAG, "Pose model failed to initialize")
        }
    }

    private fun startNativeCamera(useFrontCamera: Boolean, onStarted: (android.util.Size) -> Unit)
    {
        try {
            if (nativeCamera?.isRunning() == true) {
                Log.w(TAG, "Camera already running")
                return
            }

            if (runningMode != RunningMode.LIVE_STREAM) {
                runningMode = RunningMode.LIVE_STREAM
                poseModel.setRunningMode(RunningMode.LIVE_STREAM)
            }

            // Buat TextureEntry baru
            textureEntry = flutterEngine!!.renderer.createSurfaceTexture()
            val surfaceTexture = textureEntry!!.surfaceTexture()

            // Buat Surface dari SurfaceTexture
            val surface = Surface(surfaceTexture)

            nativeCamera = MainCamera(
                context = this,
                poseModel = poseModel,
                previewSurface = surface,
                onError = { error ->
                    Log.e(TAG, "Native camera error: $error")
                    runOnUiThread {
                        eventSink?.error("CAMERA_ERROR", error, null)
                    }
                }
            )

            val previewSize = nativeCamera!!.previewSize
            surfaceTexture.setDefaultBufferSize(previewSize.width, previewSize.height)

            nativeCamera?.startCamera(useFrontCamera)
            Log.i(TAG, "Native camera started")

            // Panggil callback setelah kamera berhasil dimulai
            onStarted(previewSize)

        } catch (e: Exception) {
            Log.e(TAG, "Failed to start native camera: ${e.message}", e)
            runOnUiThread {
                eventSink?.error("CAMERA_ERROR", "Failed to start native camera: ${e.message}", null)
            }
        }
    }

    private fun stopNativeCamera()
    {
        try {
            nativeCamera?.stopCamera()
            nativeCamera = null

            // Lepaskan texture entry
            textureEntry?.release()
            textureEntry = null

            runOnUiThread {
                poseRiggingRenderer?.clear()
            }

            Log.i(TAG, "Native camera stopped and texture released")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping native camera: ${e.message}")
        }
    }

    override fun onDestroy()
    {
        super.onDestroy()
        stopNativeCamera()
        backgroundExecutor.shutdown()
        if (::poseModel.isInitialized) {
            poseModel.dispose()
        }
    }

    override fun onPause()
    {
        super.onPause()
        // Kita stop kamera sepenuhnya saat pause untuk melepas resource
        stopNativeCamera()
    }

    override fun onResume()
    {
        super.onResume()
        // Kamera akan di-restart dari sisi Flutter jika diperlukan
    }

    private fun formatBundleToMap(bundle: PoseDetectionModel.ResultBundle): Map<String, Any>
    {
        val landmarksList = mutableListOf<Map<String, Any>>()
        if (bundle.result.landmarks().isNotEmpty()) {
            val poseLandmarks = bundle.result.landmarks()[0]
            poseLandmarks.forEach { lm ->
                landmarksList.add(
                    mapOf(
                        "x" to lm.x().toDouble(),
                        "y" to lm.y().toDouble(),
                        "z" to lm.z().toDouble(),
                        "visibility" to lm.visibility().orElse(0.0f)
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