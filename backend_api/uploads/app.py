from flask import Flask, request, jsonify
import os
import tempfile
from werkzeug.utils import secure_filename
import json
from datetime import datetime

# Import PosturePredictor class dari kode kamu
# Pastikan file posture_predictor.py ada di folder yang sama
from posture_predictor import PosturePredictor

# Inisialisasi Flask app
app = Flask(__name__)

# Konfigurasi
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # Max file size 16MB
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'bmp'}

# Inisialisasi model saat startup (lebih efisien)
print("Loading posture detection model...")
try:
    predictor = PosturePredictor(model_path='posture_classification_model.h5')
    print("✅ Model loaded successfully!")
except Exception as e:
    print(f"❌ Error loading model: {e}")
    predictor = None

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def get_posture_analysis(predicted_class, confidence):
    """
    Analisis masalah dan saran berdasarkan hasil prediksi
    Sesuaikan dengan kelas model kamu: ['anterior_pelvic_tilt', 'forward_head_kyphosis', 'normal']
    """
    analysis_data = {
        'normal': {
            'status': 'Baik',
            'problems': [],
            'suggestions': [
                'Postur tubuh Anda sudah baik!',
                'Pertahankan posisi duduk dan berdiri yang benar',
                'Lakukan stretching ringan secara rutin'
            ],
            'severity': 'low',
            'color': '#4CAF50'  # Green
        },
        'forward_head_kyphosis': {
            'status': 'Perlu Perbaikan',
            'problems': [
                'Kepala terlalu maju (Forward Head Posture)',
                'Punggung atas membulat (Kyphosis)',
                'Dapat menyebabkan nyeri leher dan punggung'
            ],
            'suggestions': [
                'Lakukan chin tucks exercise 10-15 kali, 3 set per hari',
                'Perbaiki posisi layar komputer sejajar mata',
                'Strengthening otot leher bagian belakang',
                'Wall angel exercise untuk membuka dada',
                'Konsultasi dengan fisioterapis jika nyeri berlanjut'
            ],
            'severity': 'medium',
            'color': '#FF9800'  # Orange
        },
        'anterior_pelvic_tilt': {
            'status': 'Perlu Perbaikan',
            'problems': [
                'Panggul miring ke depan (Anterior Pelvic Tilt)',
                'Lordosis lumbal berlebihan',
                'Dapat menyebabkan nyeri punggung bawah'
            ],
            'suggestions': [
                'Strengthening otot glutes dan hamstring',
                'Stretching otot hip flexor dan erector spinae',
                'Dead bug exercise untuk core stability',
                'Posterior pelvic tilt exercise',
                'Hindari duduk terlalu lama tanpa istirahat'
            ],
            'severity': 'medium',
            'color': '#F44336'  # Red
        }
    }
    
    return analysis_data.get(predicted_class, analysis_data['normal'])

@app.route('/', methods=['GET'])
def home():
    """Homepage API"""
    return jsonify({
        'message': 'Posture Detection API',
        'version': '1.0',
        'status': 'running',
        'available_endpoints': [
            'GET /',
            'POST /predict',
            'GET /health'
        ]
    })

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    model_status = 'loaded' if predictor is not None else 'error'
    return jsonify({
        'status': 'healthy',
        'model_status': model_status,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/predict', methods=['POST'])
def predict_posture():
    """
    Main endpoint untuk prediksi postur
    Menerima foto dari Flutter dan mengembalikan hasil analisis
    """
    try:
        # Check apakah model sudah loaded
        if predictor is None:
            return jsonify({
                'success': False,
                'error': 'Model not loaded properly'
            }), 500

        # Check apakah ada file image
        if 'image' not in request.files:
            return jsonify({
                'success': False,
                'error': 'No image file provided'
            }), 400

        file = request.files['image']
        
        # Check apakah file dipilih
        if file.filename == '':
            return jsonify({
                'success': False,
                'error': 'No file selected'
            }), 400

        # Check apakah file extension valid
        if not allowed_file(file.filename):
            return jsonify({
                'success': False,
                'error': 'Invalid file type. Allowed: png, jpg, jpeg, bmp'
            }), 400

        # Simpan file temporary
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
            filename = secure_filename(file.filename)
            file.save(temp_file.name)
            temp_path = temp_file.name

        try:
            # Lakukan prediksi menggunakan PosturePredictor kamu
            predicted_class, confidence, scores = predictor.predict_single_image(temp_path)
            
            if predicted_class is None:
                return jsonify({
                    'success': False,
                    'error': 'Failed to process image'
                }), 500

            # Dapatkan analisis detail
            analysis = get_posture_analysis(predicted_class, confidence)
            
            # Buat response data
            response_data = {
                'success': True,
                'prediction': {
                    'class': predicted_class,
                    'confidence': round(float(confidence), 2),
                    'status': analysis['status'],
                    'severity': analysis['severity']
                },
                'analysis': {
                    'problems': analysis['problems'],
                    'suggestions': analysis['suggestions'],
                    'color': analysis['color']
                },
                'class_probabilities': {
                    class_name: round(float(score) * 100, 2) 
                    for class_name, score in zip(predictor.class_names, scores)
                },
                'timestamp': datetime.now().isoformat()
            }
            
            return jsonify(response_data)

        finally:
            # Hapus file temporary
            if os.path.exists(temp_path):
                os.unlink(temp_path)

    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Server error: {str(e)}'
        }), 500

@app.route('/model-info', methods=['GET'])
def model_info():
    """Get model information"""
    if predictor is None:
        return jsonify({
            'success': False,
            'error': 'Model not loaded'
        }), 500
    
    return jsonify({
        'success': True,
        'model_info': {
            'classes': predictor.class_names,
            'input_size': predictor.img_size,
            'total_classes': len(predictor.class_names)
        }
    })

# Error handlers
@app.errorhandler(413)
def too_large(e):
    return jsonify({
        'success': False,
        'error': 'File too large. Maximum size is 16MB'
    }), 413

@app.errorhandler(404)
def not_found(e):
    return jsonify({
        'success': False,
        'error': 'Endpoint not found'
    }), 404

@app.errorhandler(500)
def internal_error(e):
    return jsonify({
        'success': False,
        'error': 'Internal server error'
    }), 500

if __name__ == '__main__':
    # Create uploads directory if not exists
    os.makedirs('uploads', exist_ok=True)
    
    # Run the app
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)