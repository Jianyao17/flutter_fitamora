package com.example.fitamora

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PointF
import android.view.View
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlin.math.min

/**
 * PlatformView native Android yang bertugas menggambar hasil deteksi pose.
 * Gaya visualnya meniru PoseRiggingPainter dari kode Dart.
 * Berisi semua kelas yang dibutuhkan dalam satu file (View, Factory, dan data helpers).
 */
class PoseRiggingRenderer(context: Context) : PlatformView
{
    private val drawingView: DrawingView = DrawingView(context)

    // Mengembalikan View native yang akan ditampilkan di Flutter.
    override fun getView(): View {
        return drawingView
    }

    override fun dispose() {
        // Tidak ada yang perlu di-dispose secara spesifik di sini.
    }

    /**
     * Meneruskan hasil deteksi dari MediaPipe ke DrawingView untuk digambar ulang.
     */
    fun setResults(
        poseLandmarkerResults: PoseLandmarkerResult,
        imageHeight: Int,
        imageWidth: Int
    ) {
        drawingView.setResults(poseLandmarkerResults, imageHeight, imageWidth)
    }

    /**
     * Membersihkan canvas dari gambar pose.
     */
    fun clear() {
        drawingView.clear()
    }

    /**
     * Factory class yang diwajibkan oleh Flutter untuk membuat instance dari PlatformView.
     * Ditempatkan di sini sebagai 'companion object' agar semua kode relevan ada dalam satu file.
     */
    companion object {
        class Factory(private val createView: () -> PlatformView) : PlatformViewFactory(StandardMessageCodec.INSTANCE)
        {
            override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
                return createView()
            }
        }
    }

    /**
     * View internal yang menangani semua logika penggambaran di Canvas.
     */
    private class DrawingView(context: Context) : View(context)
    {
        private var results: PoseLandmarkerResult? = null
        private var imageWidth: Int = 1
        private var imageHeight: Int = 1

        // --- STYLING CONSTANTS (diadaptasi dari PoseRiggingPainter.dart) ---
        companion object {
            private const val LANDMARK_RADIUS = 8.0f     // 4.0 * 2
            private const val JOINT_RADIUS = 12.0f      // 6.0 * 2
            private const val CONNECTION_STROKE_WIDTH = 4.0f // 2.0 * 2
            private const val BORDER_STROKE_WIDTH = 3.0f   // 1.5 * 2

            // Warna (didefinisikan langsung, tidak perlu colors.xml)
            private val FACE_COLOR = Color.rgb(255, 235, 59) // Yellow
            private val TORSO_COLOR = Color.rgb(33, 150, 243) // Blue
            private val LEFT_ARM_COLOR = Color.rgb(76, 175, 80) // Green
            private val RIGHT_ARM_COLOR = Color.rgb(244, 67, 54) // Red
            private val LEFT_LEG_COLOR = Color.rgb(156, 39, 176) // Purple
            private val RIGHT_LEG_COLOR = Color.rgb(255, 152, 0) // Orange
            private val CONNECTION_COLOR = Color.WHITE
            private val SHADOW_COLOR = Color.argb(128, 0, 0, 0) // Hitam 50% transparan
        }

        // --- Paint Objects (disiapkan agar tidak dibuat ulang setiap frame) ---
        private val landmarkPaint = Paint()
        private val landmarkBorderPaint = Paint().apply {
            style = Paint.Style.STROKE
            strokeWidth = BORDER_STROKE_WIDTH
            color = Color.argb(204, 255, 255, 255) // Putih 80% transparan
        }
        private val shadowPaint = Paint().apply {
            color = SHADOW_COLOR
        }
        private val connectionPaint = Paint().apply {
            color = CONNECTION_COLOR
            strokeWidth = CONNECTION_STROKE_WIDTH
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
        }
        private val connectionShadowPaint = Paint().apply {
            color = SHADOW_COLOR
            strokeWidth = CONNECTION_STROKE_WIDTH + 3.0f // Sedikit lebih tebal untuk efek blur
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            maskFilter = android.graphics.BlurMaskFilter(2.0f, android.graphics.BlurMaskFilter.Blur.NORMAL)
        }

        fun setResults(
            poseLandmarkerResults: PoseLandmarkerResult,
            imageHeight: Int,
            imageWidth: Int
        ) {
            results = poseLandmarkerResults
            this.imageHeight = imageHeight
            this.imageWidth = imageWidth
            invalidate() // Memicu onDraw untuk menggambar ulang View
        }

        fun clear() {
            results = null
            invalidate()
        }

        override fun onDraw(canvas: Canvas) {
            super.onDraw(canvas)
            val currentResults = results ?: return
            if (currentResults.landmarks().isEmpty() || imageWidth <= 1 || imageHeight <= 1) {
                return
            }

            // Gambar koneksi lebih dulu agar berada di belakang landmark
            drawConnections(canvas, currentResults.landmarks()[0])
            drawLandmarks(canvas, currentResults.landmarks()[0])
        }

        private fun drawConnections(canvas: Canvas, landmarks: List<NormalizedLandmark>) {
            for (connection in PoseLandmarkConnections.POSE_CONNECTIONS) {
                val start = landmarks.getOrNull(connection.first.index)
                val end = landmarks.getOrNull(connection.second.index)
                if (start == null || end == null) continue

                val p1 = mapPoint(start, canvas)
                val p2 = mapPoint(end, canvas)

                // Gambar bayangan garis terlebih dahulu
                canvas.drawLine(p1.x, p1.y, p2.x, p2.y, connectionShadowPaint)
                // Gambar garis utama di atasnya
                canvas.drawLine(p1.x, p1.y, p2.x, p2.y, connectionPaint)
            }
        }

        private fun drawLandmarks(canvas: Canvas, landmarks: List<NormalizedLandmark>) {
            landmarks.forEachIndexed { index, landmark ->
                val type = PoseLandmarkType.fromIndex(index) ?: return@forEachIndexed

                val point = mapPoint(landmark, canvas)
                val color = getLandmarkColor(type)
                val radius = if (isJointLandmark(type)) JOINT_RADIUS else LANDMARK_RADIUS

                // Gambar bayangan titik
                shadowPaint.color = SHADOW_COLOR
                canvas.drawCircle(point.x + 2f, point.y + 2f, radius, shadowPaint)

                // Gambar isian titik berwarna
                landmarkPaint.color = color
                canvas.drawCircle(point.x, point.y, radius, landmarkPaint)

                // Gambar border putih
                canvas.drawCircle(point.x, point.y, radius, landmarkBorderPaint)
            }
        }

        /**
         * Fungsi kunci: Menerjemahkan koordinat MediaPipe (normalized 0-1) ke koordinat Canvas (pixel).
         * Fungsi ini juga menangani "letterboxing" untuk memastikan aspect ratio gambar
         * tetap terjaga saat ditampilkan di canvas yang mungkin memiliki aspect ratio berbeda.
         */
        private fun mapPoint(landmark: NormalizedLandmark, canvas: Canvas): PointF
        {
            // Asumsi: Rotasi dan mirroring sudah ditangani di MainCamera.kt.
            // Kita hanya perlu scale dan center (letterbox).

            val scaleX = canvas.width.toFloat() / imageWidth.toFloat()
            val scaleY = canvas.height.toFloat() / imageHeight.toFloat()
            val scale = min(scaleX, scaleY) // Gunakan skala terkecil agar gambar pas

            // Hitung offset untuk menempatkan gambar di tengah canvas
            val offsetX = (canvas.width.toFloat() - imageWidth.toFloat() * scale) / 2f
            val offsetY = (canvas.height.toFloat() - imageHeight.toFloat() * scale) / 2f

            val finalX = landmark.x() * imageWidth.toFloat() * scale + offsetX
            val finalY = landmark.y() * imageHeight.toFloat() * scale + offsetY

            return PointF(finalX, finalY)
        }

        private fun getLandmarkColor(type: PoseLandmarkType): Int
        {
            return when (type) {
                in PoseLandmarkGroups.FACE -> FACE_COLOR
                in PoseLandmarkGroups.TORSO -> TORSO_COLOR
                in PoseLandmarkGroups.LEFT_ARM -> LEFT_ARM_COLOR
                in PoseLandmarkGroups.RIGHT_ARM -> RIGHT_ARM_COLOR
                in PoseLandmarkGroups.LEFT_LEG -> LEFT_LEG_COLOR
                in PoseLandmarkGroups.RIGHT_LEG -> RIGHT_LEG_COLOR
                else -> Color.GRAY // Warna default untuk landmark yang tidak terkelompok
            }
        }

        private fun isJointLandmark(type: PoseLandmarkType): Boolean {
            return type in PoseLandmarkGroups.JOINTS
        }
    }
}

// --- DATA HELPER OBJECTS (untuk meniru struktur dan logika dari kode Dart) ---

/**
 * Enum untuk merepresentasikan setiap landmark berdasarkan indeksnya agar kode lebih mudah dibaca.
 */
enum class PoseLandmarkType(val index: Int) {
    NOSE(0), LEFT_EYE_INNER(1), LEFT_EYE(2), LEFT_EYE_OUTER(3),
    RIGHT_EYE_INNER(4), RIGHT_EYE(5), RIGHT_EYE_OUTER(6),
    LEFT_EAR(7), RIGHT_EAR(8), MOUTH_LEFT(9), MOUTH_RIGHT(10),
    LEFT_SHOULDER(11), RIGHT_SHOULDER(12), LEFT_ELBOW(13), RIGHT_ELBOW(14),
    LEFT_WRIST(15), RIGHT_WRIST(16), LEFT_PINKY(17), RIGHT_PINKY(18),
    LEFT_INDEX(19), RIGHT_INDEX(20), LEFT_THUMB(21), RIGHT_THUMB(22),
    LEFT_HIP(23), RIGHT_HIP(24), LEFT_KNEE(25), RIGHT_KNEE(26),
    LEFT_ANKLE(27), RIGHT_ANKLE(28), LEFT_HEEL(29), RIGHT_HEEL(30),
    LEFT_FOOT_INDEX(31), RIGHT_FOOT_INDEX(32);

    companion object {
        private val map = values().associateBy(PoseLandmarkType::index)
        fun fromIndex(index: Int) = map[index]
    }
}

/**
 * Object untuk mengelompokkan landmark berdasarkan bagian tubuh untuk pewarnaan dan styling.
 */
object PoseLandmarkGroups {
    val FACE = setOf(
        PoseLandmarkType.NOSE, PoseLandmarkType.LEFT_EYE_INNER, PoseLandmarkType.LEFT_EYE,
        PoseLandmarkType.LEFT_EYE_OUTER, PoseLandmarkType.RIGHT_EYE_INNER, PoseLandmarkType.RIGHT_EYE,
        PoseLandmarkType.RIGHT_EYE_OUTER, PoseLandmarkType.LEFT_EAR, PoseLandmarkType.RIGHT_EAR,
        PoseLandmarkType.MOUTH_LEFT, PoseLandmarkType.MOUTH_RIGHT
    )
    val TORSO = setOf(
        PoseLandmarkType.LEFT_SHOULDER, PoseLandmarkType.RIGHT_SHOULDER,
        PoseLandmarkType.LEFT_HIP, PoseLandmarkType.RIGHT_HIP
    )
    val LEFT_ARM = setOf(
        PoseLandmarkType.LEFT_ELBOW, PoseLandmarkType.LEFT_WRIST,
        PoseLandmarkType.LEFT_PINKY, PoseLandmarkType.LEFT_INDEX, PoseLandmarkType.LEFT_THUMB
    )
    val RIGHT_ARM = setOf(
        PoseLandmarkType.RIGHT_ELBOW, PoseLandmarkType.RIGHT_WRIST,
        PoseLandmarkType.RIGHT_PINKY, PoseLandmarkType.RIGHT_INDEX, PoseLandmarkType.RIGHT_THUMB
    )
    val LEFT_LEG = setOf(
        PoseLandmarkType.LEFT_KNEE, PoseLandmarkType.LEFT_ANKLE,
        PoseLandmarkType.LEFT_HEEL, PoseLandmarkType.LEFT_FOOT_INDEX
    )
    val RIGHT_LEG = setOf(
        PoseLandmarkType.RIGHT_KNEE, PoseLandmarkType.RIGHT_ANKLE,
        PoseLandmarkType.RIGHT_HEEL, PoseLandmarkType.RIGHT_FOOT_INDEX
    )
    val JOINTS = setOf(
        PoseLandmarkType.LEFT_SHOULDER, PoseLandmarkType.RIGHT_SHOULDER, PoseLandmarkType.LEFT_ELBOW,
        PoseLandmarkType.RIGHT_ELBOW, PoseLandmarkType.LEFT_WRIST, PoseLandmarkType.RIGHT_WRIST,
        PoseLandmarkType.LEFT_HIP, PoseLandmarkType.RIGHT_HIP, PoseLandmarkType.LEFT_KNEE,
        PoseLandmarkType.RIGHT_KNEE, PoseLandmarkType.LEFT_ANKLE, PoseLandmarkType.RIGHT_ANKLE
    )
}

/**
 * Object yang mendefinisikan koneksi antar landmark untuk digambar sebagai garis.
 */
object PoseLandmarkConnections {
    val POSE_CONNECTIONS = listOf(
        // Torso
        PoseLandmarkType.LEFT_SHOULDER to PoseLandmarkType.RIGHT_SHOULDER,
        PoseLandmarkType.LEFT_SHOULDER to PoseLandmarkType.LEFT_HIP,
        PoseLandmarkType.RIGHT_SHOULDER to PoseLandmarkType.RIGHT_HIP,
        PoseLandmarkType.LEFT_HIP to PoseLandmarkType.RIGHT_HIP,
        // Left Arm
        PoseLandmarkType.LEFT_SHOULDER to PoseLandmarkType.LEFT_ELBOW,
        PoseLandmarkType.LEFT_ELBOW to PoseLandmarkType.LEFT_WRIST,
        // Right Arm
        PoseLandmarkType.RIGHT_SHOULDER to PoseLandmarkType.RIGHT_ELBOW,
        PoseLandmarkType.RIGHT_ELBOW to PoseLandmarkType.RIGHT_WRIST,
        // Left Leg
        PoseLandmarkType.LEFT_HIP to PoseLandmarkType.LEFT_KNEE,
        PoseLandmarkType.LEFT_KNEE to PoseLandmarkType.LEFT_ANKLE,
        // Right Leg
        PoseLandmarkType.RIGHT_HIP to PoseLandmarkType.RIGHT_KNEE,
        PoseLandmarkType.RIGHT_KNEE to PoseLandmarkType.RIGHT_ANKLE
    )
}