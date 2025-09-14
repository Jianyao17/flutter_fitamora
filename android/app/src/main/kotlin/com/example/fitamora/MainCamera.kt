package com.example.fitamora

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.*
import android.hardware.camera2.*
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import android.util.Log
import android.util.Size
import android.view.Surface
import androidx.core.app.ActivityCompat
import com.google.mediapipe.framework.image.BitmapImageBuilder
import java.io.ByteArrayOutputStream

class MainCamera(
    private val context: Context,
    private val poseModel: PoseDetectionModel,
    private val previewSurface: Surface,
    private val onError: (String) -> Unit
) {
    private val TAG = "MainCamera"

    private var cameraManager: CameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null
    private var imageReader: ImageReader? = null

    private var cameraId: String = ""
    private var facing = CameraCharacteristics.LENS_FACING_FRONT
    private var isStarted = false
    private var frameCount = 0

    // Ukuran preview default, bisa disesuaikan
    val previewSize = Size(480, 640)

    fun startCamera(useFrontCamera: Boolean = true)
    {
        if (isStarted) {
            Log.w(TAG, "Camera already started")
            return
        }
        facing =
            if (useFrontCamera) CameraCharacteristics.LENS_FACING_FRONT
            else CameraCharacteristics.LENS_FACING_BACK

        try {
            setupCamera()
            startBackgroundThread()
            openCamera()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start camera: ${e.message}", e)
            onError("Failed to start camera: ${e.message}")
        }
    }

    fun stopCamera()
    {
        if (!isStarted) return

        try {
            captureSession?.close()
            captureSession = null

            cameraDevice?.close()
            cameraDevice = null

            imageReader?.close()
            imageReader = null

            stopBackgroundThread()
            isStarted = false

            Log.i(TAG, "Camera stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping camera: ${e.message}")
        }
    }

    fun switchCamera()
    {
        stopCamera()
        facing = if (facing == CameraCharacteristics.LENS_FACING_FRONT) {
            CameraCharacteristics.LENS_FACING_BACK
        } else {
            CameraCharacteristics.LENS_FACING_FRONT
        }
        startCamera(facing == CameraCharacteristics.LENS_FACING_FRONT)
    }

    private fun setupCamera()
    {
        try {
            for (id in cameraManager.cameraIdList)
            {
                val characteristics = cameraManager.getCameraCharacteristics(id)
                val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)

                if (lensFacing == facing) {
                    cameraId = id
                    // Opsi: Anda bisa memilih previewSize yang didukung oleh kamera di sini
                    // val map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
                    // val supportedSizes = map?.getOutputSizes(ImageFormat.YUV_420_888)
                    break
                }
            }

            if (cameraId.isEmpty()) {
                throw RuntimeException("No camera found with desired facing: $facing")
            }

            // Setup ImageReader untuk menerima frame untuk diproses oleh MediaPipe
            imageReader = ImageReader.newInstance(
                previewSize.width,
                previewSize.height,
                ImageFormat.YUV_420_888,
                2 // Buffer count (bisa disesuaikan)
            )

            imageReader?.setOnImageAvailableListener(
                { reader ->
                    val image = reader.acquireLatestImage()
                    if (image != null)
                    {
                        // Frame skipping bisa disesuaikan
                        frameCount++
                        if (frameCount % 3 == 0) { // Proses setiap 3 frame untuk performa lebih baik
                            processFrame(image)
                        }
                        image.close()
                    }
                }, backgroundHandler)

        } catch (e: Exception) {
            Log.e(TAG, "Camera setup failed: ${e.message}", e)
            throw e
        }
    }

    private fun openCamera()
    {
        if (ActivityCompat.checkSelfPermission(
                context, Manifest.permission.CAMERA
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            onError("Camera permission not granted")
            return
        }

        try {
            cameraManager.openCamera(cameraId, object : CameraDevice.StateCallback()
            {
                override fun onOpened(camera: CameraDevice) {
                    Log.i(TAG, "Camera opened: $cameraId")
                    cameraDevice = camera
                    createCaptureSession()
                }
                override fun onDisconnected(camera: CameraDevice) {
                    Log.w(TAG, "Camera disconnected")
                    camera.close()
                    cameraDevice = null
                }
                override fun onError(camera: CameraDevice, error: Int) {
                    Log.e(TAG, "Camera error: $error")
                    camera.close()
                    cameraDevice = null
                    onError("Camera error: $error")
                }
            }, backgroundHandler)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open camera: ${e.message}", e)
            onError("Failed to open camera: ${e.message}")
        }
    }

    private fun createCaptureSession()
    {
        try {
            // Sekarang kita punya dua target: satu untuk preview di Flutter, satu untuk dianalisis
            val surfaces = listOf(previewSurface, imageReader!!.surface)
            cameraDevice?.createCaptureSession(
                surfaces,
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(session: CameraCaptureSession) {
                        Log.i(TAG, "Capture session configured")
                        captureSession = session
                        startPreview()
                        isStarted = true
                    }
                    override fun onConfigureFailed(session: CameraCaptureSession) {
                        Log.e(TAG, "Capture session configuration failed")
                        onError("Failed to configure capture session")
                    }
                },
                backgroundHandler
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create capture session: ${e.message}", e)
            onError("Failed to create capture session: ${e.message}")
        }
    }

    private fun startPreview()
    {
        try {
            val captureBuilder = cameraDevice?.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)

            // Tambahkan kedua surface sebagai target
            captureBuilder?.addTarget(previewSurface)
            captureBuilder?.addTarget(imageReader!!.surface)

            captureBuilder?.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE)
            captureBuilder?.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON)

            val captureRequest = captureBuilder?.build()
            captureSession?.setRepeatingRequest(captureRequest!!, null, backgroundHandler)

            Log.i(TAG, "Preview started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start preview: ${e.message}", e)
            onError("Failed to start preview: ${e.message}")
        }
    }

    private fun processFrame(image: android.media.Image)
    {
        try {
            // Konversi YUV_420_888 ke Bitmap
            val bitmap = yuv420ToBitmap(image)

            if (bitmap != null)
            {
                // Deteksi pose menggunakan MediaPipe
                val mpImage = BitmapImageBuilder(bitmap).build()
                poseModel.detectLiveStream(mpImage, SystemClock.uptimeMillis())

                bitmap.recycle()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing frame: ${e.message}", e)
        }
    }

    private fun yuv420ToBitmap(image: android.media.Image): Bitmap?
    {
        try {
            val planes = image.planes
            val yBuffer = planes[0].buffer
            val uBuffer = planes[1].buffer
            val vBuffer = planes[2].buffer

            val ySize = yBuffer.remaining()
            val uSize = uBuffer.remaining()
            val vSize = vBuffer.remaining()

            val nv21 = ByteArray(ySize + uSize + vSize)

            yBuffer.get(nv21, 0, ySize)
            vBuffer.get(nv21, ySize, vSize)
            uBuffer.get(nv21, ySize + vSize, uSize)

            val yuvImage = YuvImage(nv21, ImageFormat.NV21, image.width, image.height, null)
            val out = ByteArrayOutputStream()
            yuvImage.compressToJpeg(Rect(0, 0, image.width, image.height), 100, out)
            val jpegArray = out.toByteArray()

            val rawBitmap = BitmapFactory.decodeByteArray(jpegArray, 0, jpegArray.size)

            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val rotation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 0

            val matrix = Matrix()
            if (facing == CameraCharacteristics.LENS_FACING_FRONT)
            {
                matrix.postRotate(rotation.toFloat())
                matrix.postScale(-1f, 1f)
            } else {
                matrix.postRotate(rotation.toFloat())
            }

            return Bitmap.createBitmap(
                rawBitmap, 0, 0,
                rawBitmap.width, rawBitmap.height,
                matrix, true)

        } catch (e: Exception) {
            Log.e(TAG, "Error converting YUV to Bitmap: ${e.message}", e)
            return null
        }
    }

    private fun startBackgroundThread()
    {
        backgroundThread = HandlerThread("CameraBackground")
        backgroundThread?.start()
        backgroundHandler = Handler(backgroundThread!!.looper)
    }

    private fun stopBackgroundThread()
    {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join()
            backgroundThread = null
            backgroundHandler = null
        } catch (e: InterruptedException) {
            Log.e(TAG, "Background thread interrupted: ${e.message}")
        }
    }

    fun getCurrentCameraId(): String = cameraId
    fun isFrontCamera(): Boolean = facing == CameraCharacteristics.LENS_FACING_FRONT
    fun isRunning(): Boolean = isStarted
}