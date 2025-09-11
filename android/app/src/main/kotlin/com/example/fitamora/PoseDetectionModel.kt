package com.example.fitamora

import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import java.nio.ByteBuffer

/**
 * PoseDetectionModel:
 * - Unified API untuk image / livestream usage
 * - Bisa pilih DelegateType.CPU atau DelegateType.GPU (jika perangkat support)
 * - Public stable method names: initialize(), start(), stop(), dispose(), detectImage(), detectLiveStream()
 */
class PoseDetectionModel(
    private val context: Context,
    private var runningMode: RunningMode = RunningMode.IMAGE,
    private var delegateType: DelegateType = DelegateType.CPU,
    var listener: DetectionListener? = null
) {
    private var poseLandmarker: PoseLandmarker? = null
    private var isInitialized = false

    enum class DelegateType { CPU, GPU }

    interface DetectionListener {
        fun onError(error: String)
        fun onResult(bundle: ResultBundle)
    }

    data class ResultBundle(
        val result: PoseLandmarkerResult,
        val inferenceTimeMs: Long,
        val imageHeight: Int,
        val imageWidth: Int
    )

    private val TAG = "PoseDetectionModel"
    private val MODEL_PATH = "pose_landmarker.task"

    /** Initialize (safe to call multiple times) */
    @Synchronized
    fun initialize(): Boolean
    {
        if (isInitialized) {
            Log.i(TAG, "Already initialized.")
            return true
        }
        try {
            Log.d(TAG, "Initializing PoseDetectionModel. Mode=$runningMode Delegate=$delegateType")
            val baseOptionsBuilder = BaseOptions.builder()
                .setModelAssetPath(MODEL_PATH)

            // Set delegate
            when (delegateType)
            {
                DelegateType.GPU -> {
                    // baseOptionsBuilder.setDelegate(BaseOptions.Delegate.GPU)
                    // Optionally set GPU options: BaseOptions.DelegateOptions.GpuOptions
                    baseOptionsBuilder.setDelegate(Delegate.GPU)
                }
                else -> {
                    baseOptionsBuilder.setDelegate(Delegate.CPU)
                }
            }

            val optionsBuilder = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(baseOptionsBuilder.build())
                .setRunningMode(runningMode)
                .setNumPoses(1)

            if (runningMode == RunningMode.LIVE_STREAM)
            {
                optionsBuilder
                    .setResultListener { result, input ->
                        // result.timestampMs() is model timestamp; compute total latency
                        val finishTimeMs = SystemClock.uptimeMillis()
                        val inferenceTime = finishTimeMs - result.timestampMs()
                        listener?.onResult(ResultBundle(result, inferenceTime, input.height, input.width))
                    }
                    .setErrorListener { e ->
                        Log.e(TAG, "Native error: ${e.message}")
                        listener?.onError(e.message ?: "Unknown native error")
                    }
            }

            val options = optionsBuilder.build()
            poseLandmarker = PoseLandmarker.createFromOptions(context, options)
            isInitialized = true

            Log.i(TAG, "PoseDetectionModel initialized successfully.")
            return true
        } catch (e: Exception) {
            val message = "Failed to initialize PoseDetectionModel: ${e.message}"
            Log.e(TAG, message, e)
            listener?.onError(message)

            isInitialized = false
            return false
        }
    }

    fun setDelegate(type: DelegateType) {
        if (delegateType != type) {
            delegateType = type
            Log.i(TAG, "Delegate changed to $delegateType - will re-init")
            dispose()
            initialize()
        }
    }

    fun setRunningMode(mode: RunningMode) {
        if (runningMode != mode) {
            runningMode = mode
            Log.i(TAG, "RunningMode changed to $runningMode - will re-init")
            dispose()
            initialize()
        }
    }

    /** Synchronous detect for images */
    fun detectImage(bitmap: Bitmap): ResultBundle?
    {
        if (!isInitialized || runningMode != RunningMode.IMAGE || poseLandmarker == null)
        {
            val msg = "Model not initialized or not in IMAGE mode"
            Log.w(TAG, msg)
            listener?.onError(msg)
            return null
        }
        val start = SystemClock.uptimeMillis()
        val mpImage: MPImage = BitmapImageBuilder(bitmap).build()
        val result = poseLandmarker?.detect(mpImage)
        val inference = SystemClock.uptimeMillis() - start
        return if (result != null) ResultBundle(result, inference, bitmap.height, bitmap.width) else null
    }

    /** Async detect from camera stream (LIVE_STREAM) */
    fun detectLiveStream(mpImage: MPImage, timestampMs: Long)
    {
        if (!isInitialized || runningMode != RunningMode.LIVE_STREAM || poseLandmarker == null) {
            val msg = "Model not initialized or not in LIVE_STREAM mode"
            Log.w(TAG, msg)
            listener?.onError(msg)
            return
        }
        try {
            poseLandmarker?.detectAsync(mpImage, timestampMs)
        } catch (e: Exception) {
            Log.e(TAG, "detectLiveStream error: ${e.message}", e)
            listener?.onError(e.message ?: "detectLiveStream exception")
        }
    }

    fun dispose()
    {
        try {
            poseLandmarker?.close()
            poseLandmarker = null
            isInitialized = false
            Log.i(TAG, "PoseDetectionModel disposed.")
        } catch (e: Exception) {
            Log.w(TAG, "Error disposing model: ${e.message}")
        }
    }
}
