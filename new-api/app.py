from flask import Flask, request, jsonify
import os
import tempfile
from werkzeug.utils import secure_filename
import json
from datetime import datetime

# Import PosturePredictor class dari kode yang sudah dibuat
from posture_predictor import PosturePredictor

# Inisialisasi Flask app
app = Flask(__name__)

# Konfigurasi
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # Max file size 16MB
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'bmp', 'webp', 'jfif'}

# Inisialisasi model saat startup (lebih efisien)
print("Loading posture detection model...")
predictor = None

try:
    # Check if model file exists
    model_path = 'model.pkl'
    if os.path.exists(model_path):
        predictor = PosturePredictor(model_path=model_path)
        print("✅ Model loaded successfully!")
    else:
        print(f"❌ Model file not found: {model_path}")
        print("Available files:", os.listdir('.'))
except Exception as e:
    print(f"❌ Error loading model: {e}")
    predictor = None

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def get_posture_analysis(predictions, probabilities):
    """
    Analisis masalah dan saran berdasarkan hasil prediksi multilabel
    Labels: ['forward_head', 'kyphosis', 'anterior_pelvic_tilt', 'normal']
    """
    
    # Determine detected conditions
    detected_conditions = []
    for label, detected in predictions.items():
        if detected and label != 'normal':
            detected_conditions.append(label)
    
    # Create condition key for analysis lookup
    if predictions.get('normal', False):
        condition_key = 'normal'
    else:
        # Sort conditions for consistent lookup
        condition_key = '_'.join(sorted(detected_conditions))
        if not condition_key:  # No conditions detected but not normal
            condition_key = 'unclear'
    
    analysis_data = {
        'normal': {
            'status': 'Postur Baik',
            'severity': 'none',
            'color': '#4CAF50',  # Green
            'problems': [],
            'suggestions': [
                '🎉 Postur tubuh Anda sudah baik!',
                '💪 Pertahankan posisi duduk dan berdiri yang benar',
                '🧘‍♀️ Lakukan stretching ringan secara rutin untuk maintenance',
                '⏰ Tetap aware terhadap postur saat beraktivitas lama'
            ],
            'exercise_program': [
                {
                    'name': 'Full body stretch',
                    'set': 1,
                    'rep': None,
                    'duration': 300,  # 5 minutes
                    'rest': None,
                    'description': 'Peregangan menyeluruh untuk maintenance'
                },
                {
                    'name': 'Shoulder circles',
                    'set': 2,
                    'rep': 12,
                    'duration': None,
                    'rest': 30,
                    'description': 'Gerakan melingkar bahu untuk relaksasi'
                },
                {
                    'name': 'Deep breathing',
                    'set': 3,
                    'rep': None,
                    'duration': 60,
                    'rest': 20,
                    'description': 'Latihan pernapasan untuk relaksasi'
                }
            ],
            'risk_level': 'low'
        },
        
        'forward_head': {
            'status': 'Forward Head Posture',
            'severity': 'medium',
            'color': '#FF9800',  # Orange
            'problems': [
                '📱 Kepala terlalu maju dari garis vertikal tubuh',
                '💻 Posisi kerja yang tidak ergonomis',
                '😰 Ketegangan pada otot leher bagian belakang',
                '⚠️ Risiko nyeri leher dan sakit kepala'
            ],
            'suggestions': [
                '🔧 Sesuaikan tinggi layar komputer sejajar dengan mata',
                '💺 Gunakan kursi dengan headrest yang mendukung leher',
                '⏱️ Lakukan break setiap 30 menit untuk neck stretching',
                '🧘‍♂️ Praktikkan chin tuck exercise 3x sehari',
                '💪 Perkuat otot deep neck flexors'
            ],
            'exercise_program': [
                {
                    'name': 'Chin tucks',
                    'set': 3,
                    'rep': 12,
                    'duration': None,
                    'rest': 30,
                    'description': 'Tarik dagu ke belakang, tahan 5 detik'
                },
                {
                    'name': 'Neck retraction stretch',
                    'set': 2,
                    'rep': None,
                    'duration': 30,
                    'rest': 15,
                    'description': 'Peregangan otot leher belakang'
                },
                {
                    'name': 'Upper trap stretch',
                    'set': 2,
                    'rep': None,
                    'duration': 30,
                    'rest': 15,
                    'description': 'Miringkan kepala ke samping, tahan'
                },
                {
                    'name': 'Deep breathing',
                    'set': 1,
                    'rep': None,
                    'duration': 120,
                    'rest': None,
                    'description': 'Pernapasan dalam untuk relaksasi'
                }
            ],
            'risk_level': 'medium'
        },
        
        'kyphosis': {
            'status': 'Kyphosis (Punggung Membulat)',
            'severity': 'medium',
            'color': '#F44336',  # Red
            'problems': [
                '🔄 Punggung atas terlalu membulat ke depan',
                '💺 Postur duduk yang buruk dalam waktu lama',
                '💪 Lemahnya otot punggung atas dan rhomboid',
                '😰 Ketegangan berlebih pada otot pektoral',
                '⚠️ Risiko nyeri punggung dan gangguan pernapasan'
            ],
            'suggestions': [
                '🧘‍♀️ Lakukan wall angel exercise untuk membuka dada',
                '💪 Perkuat otot rhomboid dan middle trapezius',
                '🔧 Gunakan bantal lumbar saat duduk',
                '📏 Perhatikan postur saat menggunakan smartphone',
                '🏃‍♂️ Lakukan aktivitas yang memperkuat punggung'
            ],
            'exercise_program': [
                {
                    'name': 'Wall angels',
                    'set': 3,
                    'rep': 15,
                    'duration': None,
                    'rest': 45,
                    'description': 'Gerakan seperti angel di dinding'
                },
                {
                    'name': 'Cat-cow stretch',
                    'set': 2,
                    'rep': 12,
                    'duration': None,
                    'rest': 30,
                    'description': 'Peregangan tulang belakang dinamis'
                },
                {
                    'name': 'Thoracic extension',
                    'set': 2,
                    'rep': 10,
                    'duration': None,
                    'rest': 30,
                    'description': 'Ekstensi punggung atas'
                },
                {
                    'name': 'Chest doorway stretch',
                    'set': 1,
                    'rep': None,
                    'duration': 60,
                    'rest': None,
                    'description': 'Peregangan dada di kusen pintu'
                }
            ],
            'risk_level': 'medium-high'
        },
        
        'anterior_pelvic_tilt': {
            'status': 'Anterior Pelvic Tilt',
            'severity': 'medium',
            'color': '#E91E63',  # Pink-Red
            'problems': [
                '🔄 Panggul miring terlalu ke depan',
                '📐 Lordosis lumbar yang berlebihan',
                '💪 Hip flexors yang terlalu kencang',
                '😰 Lemahnya otot glutes dan core',
                '⚠️ Risiko nyeri punggung bawah kronis'
            ],
            'suggestions': [
                '💪 Perkuat otot glutes dan hamstring',
                '🧘‍♀️ Lakukan hip flexor stretching secara rutin',
                '🏋️‍♂️ Latihan core strengthening',
                '🚶‍♂️ Hindari duduk terlalu lama tanpa break',
                '🛏️ Perhatikan posisi tidur (hindari prone position)'
            ],
            'exercise_program': [
                {
                    'name': 'Pelvic tilts',
                    'set': 3,
                    'rep': 15,
                    'duration': None,
                    'rest': 30,
                    'description': 'Gerakan miring panggul ke belakang'
                },
                {
                    'name': 'Hip flexor stretch',
                    'set': 2,
                    'rep': None,
                    'duration': 45,
                    'rest': 20,
                    'description': 'Lunge stretch untuk hip flexor'
                },
                {
                    'name': 'Glute bridges',
                    'set': 3,
                    'rep': 12,
                    'duration': None,
                    'rest': 45,
                    'description': 'Angkat panggul untuk perkuat glutes'
                },
                {
                    'name': 'Dead bug exercise',
                    'set': 2,
                    'rep': 10,
                    'duration': None,
                    'rest': 30,
                    'description': 'Core stability exercise'
                }
            ],
            'risk_level': 'medium'
        },
        
        'forward_head_kyphosis': {
            'status': 'Forward Head + Kyphosis',
            'severity': 'high',
            'color': '#D32F2F',  # Dark Red
            'problems': [
                '📱💻 Kombinasi forward head dan punggung membulat',
                '⚠️ Upper cross syndrome pattern',
                '😰 Ketegangan tinggi pada leher dan punggung atas',
                '💨 Dapat mengganggu fungsi pernapasan',
                '🎯 Memerlukan intervensi komprehensif'
            ],
            'suggestions': [
                '🚨 Segera perbaiki ergonomi workstation',
                '💪 Kombinasi chin tuck + thoracic extension',
                '🧘‍♀️ Fokus pada mobility dan strengthening',
                '⏱️ Break lebih sering (setiap 20-25 menit)',
                '👨‍⚕️ Pertimbangkan konsultasi fisioterapis'
            ],
            'exercise_program': [
                {
                    'name': 'Chin tuck + wall angels combo',
                    'set': 3,
                    'rep': 10,
                    'duration': None,
                    'rest': 60,
                    'description': 'Kombinasi koreksi kepala dan bahu'
                },
                {
                    'name': 'Cat-cow with neck extension',
                    'set': 2,
                    'rep': 8,
                    'duration': None,
                    'rest': 45,
                    'description': 'Mobilitas menyeluruh spine'
                },
                {
                    'name': 'Upper trap + chest stretch',
                    'set': 2,
                    'rep': None,
                    'duration': 45,
                    'rest': 30,
                    'description': 'Peregangan otot yang kencang'
                },
                {
                    'name': 'Deep breathing focus',
                    'set': 3,
                    'rep': None,
                    'duration': 90,
                    'rest': 30,
                    'description': 'Pernapasan untuk relaksasi total'
                }
            ],
            'risk_level': 'high'
        },
        
        'forward_head_anterior_pelvic_tilt': {
            'status': 'Forward Head + Anterior Pelvic Tilt',
            'severity': 'high',
            'color': '#7B1FA2',  # Purple
            'problems': [
                '🔗 Kompensasi postural dari kepala hingga panggul',
                '⚖️ Ketidakseimbangan rantai kinetik',
                '😰 Ketegangan global pada fascia anterior',
                '⚠️ Risiko nyeri multi-segmental',
                '🎯 Pola kompensasi yang kompleks'
            ],
            'suggestions': [
                '🏋️‍♂️ Global approach: head to pelvis correction',
                '🧘‍♀️ Fokus pada anterior chain stretching',
                '💪 Perkuat posterior chain muscles',
                '📏 Perhatikan alignment saat semua aktivitas',
                '👨‍⚕️ Sangat disarankan konsultasi profesional'
            ],
            'exercise_program': [
                {
                    'name': 'Global posture reset',
                    'set': 2,
                    'rep': None,
                    'duration': 120,
                    'rest': 60,
                    'description': 'Wall stand dengan koreksi menyeluruh'
                },
                {
                    'name': 'Hip flexor + neck stretch combo',
                    'set': 2,
                    'rep': None,
                    'duration': 60,
                    'rest': 45,
                    'description': 'Peregangan rantai anterior'
                },
                {
                    'name': 'Chin tuck + pelvic tilt',
                    'set': 3,
                    'rep': 12,
                    'duration': None,
                    'rest': 45,
                    'description': 'Koreksi simultan kepala-panggul'
                },
                {
                    'name': 'Full body integration',
                    'set': 1,
                    'rep': None,
                    'duration': 180,
                    'rest': None,
                    'description': 'Integrasi gerakan seluruh tubuh'
                }
            ],
            'risk_level': 'high'
        },
        
        'kyphosis_anterior_pelvic_tilt': {
            'status': 'Kyphosis + Anterior Pelvic Tilt',
            'severity': 'high',
            'color': '#E65100',  # Deep Orange
            'problems': [
                '🌊 S-curve spine yang berlebihan',
                '⚖️ Kompensasi thoracolumbar junction',
                '💪 Imbalance global fleksor vs ekstensor',
                '😰 Tekanan tinggi pada diskus intervertebralis',
                '⚠️ Risiko degenerasi tulang belakang'
            ],
            'suggestions': [
                '🎯 Target mid-spine mobility restoration',
                '💪 Perkuat deep core dan postural muscles',
                '🧘‍♀️ Mobilisasi thoracolumbar junction',
                '📐 Koreksi pelvic alignment sebagai prioritas',
                '👨‍⚕️ Monitoring profesional sangat direkomendasikan'
            ],
            'exercise_program': [
                {
                    'name': 'Cat-cow + pelvic tilt',
                    'set': 3,
                    'rep': 12,
                    'duration': None,
                    'rest': 45,
                    'description': 'Mobilitas spine + koreksi panggul'
                },
                {
                    'name': 'Thoracic extension + hip flexor stretch',
                    'set': 2,
                    'rep': None,
                    'duration': 60,
                    'rest': 45,
                    'description': 'Target area bermasalah utama'
                },
                {
                    'name': 'Core integration exercise',
                    'set': 3,
                    'rep': 8,
                    'duration': None,
                    'rest': 60,
                    'description': 'Dead bug dengan kontrol spine'
                },
                {
                    'name': 'Postural reset sequence',
                    'set': 1,
                    'rep': None,
                    'duration': 240,
                    'rest': None,
                    'description': 'Sekuens koreksi menyeluruh'
                }
            ],
            'risk_level': 'high'
        },
        
        'forward_head_kyphosis_anterior_pelvic_tilt': {
            'status': 'Triple Postur Problem',
            'severity': 'critical',
            'color': '#B71C1C',  # Very Dark Red
            'problems': [
                '🚨 Masalah postur menyeluruh dari kepala hingga panggul',
                '⛓️ Gangguan rantai kinetik total',
                '😰 Kompensasi multi-segmental yang kompleks',
                '💔 Risiko tinggi nyeri kronis dan degenerasi',
                '🎯 Membutuhkan intervensi profesional segera'
            ],
            'suggestions': [
                '🚨 PRIORITAS TINGGI: Konsultasi fisioterapis/ortopedi',
                '⏱️ Break setiap 15-20 menit dari aktivitas',
                '💺 Evaluasi total ergonomi workstation',
                '🧘‍♀️ Gentle mobility work, hindari forcing',
                '📊 Monitor progress dengan professional guidance'
            ],
            'exercise_program': [
                {
                    'name': 'Gentle global mobility',
                    'set': 1,
                    'rep': None,
                    'duration': 300,
                    'rest': None,
                    'description': 'Mobilitas lembut seluruh tubuh'
                },
                {
                    'name': 'Awareness exercise',
                    'set': 3,
                    'rep': None,
                    'duration': 60,
                    'rest': 120,
                    'description': 'Latihan kesadaran postural'
                },
                {
                    'name': 'Gentle strengthening',
                    'set': 2,
                    'rep': 5,
                    'duration': None,
                    'rest': 90,
                    'description': 'Penguatan ringan targeted muscles'
                },
                {
                    'name': 'Relaxation breathing',
                    'set': 2,
                    'rep': None,
                    'duration': 180,
                    'rest': 60,
                    'description': 'Pernapasan untuk relaksasi total'
                }
            ],
            'risk_level': 'critical'
        },
        
        'unclear': {
            'status': 'Postur Tidak Jelas',
            'severity': 'unknown',
            'color': '#757575',  # Grey
            'problems': [
                '❓ Pola postur tidak dapat diidentifikasi dengan jelas',
                '📸 Kemungkinan kualitas gambar kurang optimal',
                '🔍 Diperlukan analisis lebih lanjut'
            ],
            'suggestions': [
                '📷 Coba ambil foto dengan pencahayaan yang lebih baik',
                '📐 Pastikan posisi berdiri tegak menghadap samping',
                '🧘‍♂️ Lakukan self-assessment postur di cermin',
                '📞 Pertimbangkan konsultasi langsung dengan ahli postur'
            ],
            'exercise_program': [
                {
                    'name': 'General postural awareness',
                    'set': 1,
                    'rep': None,
                    'duration': 300,
                    'rest': None,
                    'description': 'Latihan kesadaran postur umum'
                }
            ],
            'risk_level': 'unknown'
        }
    }
    
    return analysis_data.get(condition_key, analysis_data['unclear'])

@app.route('/', methods=['GET'])
def home():
    """Homepage API"""
    return jsonify({
        'message': 'Multilabel Posture Detection API',
        'version': '2.0',
        'status': 'running',
        'model_type': 'MediaPipe + XGBoost Multilabel',
        'labels': ['forward_head', 'kyphosis', 'anterior_pelvic_tilt', 'normal'],
        'available_endpoints': [
            'GET /',
            'POST /predict',
            'GET /health',
            'GET /model-info'
        ]
    })

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    model_status = 'loaded' if predictor is not None else 'error'
    model_info = {}
    
    if predictor is not None:
        model_info = {
            'model_name': predictor.model_name,
            'labels': predictor.labels,
            'model_loaded': True
        }
    
    return jsonify({
        'status': 'healthy',
        'model_status': model_status,
        'model_info': model_info,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/predict', methods=['POST'])
def predict_posture():
    """
    Main endpoint untuk prediksi postur multilabel
    Menerima foto dari Flutter dan mengembalikan hasil analisis
    """
    try:
        # Check apakah model sudah loaded
        if predictor is None:
            return jsonify({
                'success': False,
                'error': 'Model not loaded properly. Please check server logs.'
            }), 500

        # Check apakah ada file image
        if 'image' not in request.files:
            return jsonify({
                'success': False,
                'error': 'No image file provided. Please upload an image.'
            }), 400

        file = request.files['image']
        
        # Check apakah file dipilih
        if file.filename == '':
            return jsonify({
                'success': False,
                'error': 'No file selected. Please choose an image file.'
            }), 400

        # Check apakah file extension valid
        if not allowed_file(file.filename):
            return jsonify({
                'success': False,
                'error': f'Invalid file type. Allowed formats: {", ".join(ALLOWED_EXTENSIONS)}'
            }), 400

        # Simpan file temporary
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
            filename = secure_filename(file.filename)
            file.save(temp_file.name)
            temp_path = temp_file.name

        try:
            # Lakukan prediksi menggunakan PosturePredictor multilabel
            result = predictor.predict_single_image(temp_path)
            
            if 'error' in result:
                return jsonify({
                    'success': False,
                    'error': f'Failed to process image: {result["error"]}'
                }), 500

            # Extract predictions and probabilities
            predictions = result['predictions']
            probabilities = result['probabilities']
            
            # Get detailed analysis
            analysis = get_posture_analysis(predictions, probabilities)
            
            # Determine primary status
            detected_conditions = [label.replace('_', ' ').title() 
                                 for label, detected in predictions.items() 
                                 if detected and label != 'normal']
            
            if not detected_conditions:
                if predictions.get('normal', False):
                    primary_status = 'Normal'
                else:
                    primary_status = 'Unclear'
            elif len(detected_conditions) == 1:
                primary_status = detected_conditions[0]
            else:
                primary_status = 'Multiple Issues'
            
            # Calculate overall confidence
            max_confidence = max(probabilities.values())
            
            # Format detected conditions for response
            formatted_conditions = []
            for condition in result.get('detected_conditions', []):
                if condition != 'No issues detected':
                    formatted_conditions.append(condition)
            
            if not formatted_conditions and predictions.get('normal', False):
                formatted_conditions = ['Normal Posture']
            elif not formatted_conditions:
                formatted_conditions = ['No clear issues detected']
            
            # Create comprehensive response
            response_data = {
                'success': True,
                'prediction': {
                    'primary_status': primary_status,
                    'detected_conditions': formatted_conditions,
                    'overall_confidence': round(float(max_confidence), 3),
                    'model_used': result.get('model_used', 'Unknown'),
                    'total_issues': len([d for d in detected_conditions if d]),
                    'severity': analysis['severity']
                },
                'analysis': {
                    'status': analysis['status'],
                    'problems': analysis['problems'],
                    'suggestions': analysis['suggestions'],
                    'exercise_program': analysis['exercise_program'],
                    'risk_level': analysis['risk_level'],
                    'color': analysis['color']
                },
                'detailed_predictions': {
                    label: {
                        'detected': bool(detected),
                        'probability': round(float(probabilities[label]), 3),
                        'confidence_level': 'high' if probabilities[label] > 0.8 else 
                                          'medium' if probabilities[label] > 0.6 else 'low'
                    }
                    for label, detected in predictions.items()
                },
                'summary': {
                    'normal_detected': predictions.get('normal', False),
                    'issues_count': len(detected_conditions),
                    'highest_probability_label': max(probabilities.items(), key=lambda x: x[1])[0],
                    'needs_attention': analysis['severity'] in ['high', 'critical']
                },
                'metadata': {
                    'timestamp': datetime.now().isoformat(),
                    'processing_successful': True,
                    'image_processed': True
                }
            }
            
            return jsonify(response_data)

        finally:
            # Hapus file temporary
            if os.path.exists(temp_path):
                os.unlink(temp_path)

    except Exception as e:
        print(f"Error in prediction: {str(e)}")  # Server-side logging
        return jsonify({
            'success': False,
            'error': f'Server error occurred during processing: {str(e)}',
            'error_type': type(e).__name__
        }), 500

@app.route('/model-info', methods=['GET'])
def model_info():
    """Get detailed model information"""
    if predictor is None:
        return jsonify({
            'success': False,
            'error': 'Model not loaded'
        }), 500
    
    return jsonify({
        'success': True,
        'model_info': {
            'model_name': predictor.model_name,
            'model_type': 'Multilabel Classification',
            'framework': 'MediaPipe + XGBoost',
            'labels': predictor.labels,
            'total_labels': len(predictor.labels),
            'prediction_type': 'multilabel',
            'input_requirements': {
                'type': 'image',
                'formats': list(ALLOWED_EXTENSIONS),
                'max_size_mb': 16,
                'recommended_resolution': '800x600 or higher'
            },
            'output_format': {
                'predictions': 'boolean per label',
                'probabilities': 'float 0-1 per label', 
                'analysis': 'detailed text analysis',
                'exercises': 'structured exercise program'
            }
        }
    })

@app.route('/labels', methods=['GET'])
def get_labels():
    """Get all available labels and their descriptions"""
    label_descriptions = {
        'forward_head': {
            'name': 'Forward Head Posture',
            'description': 'Kepala terlalu maju dari garis vertikal tubuh',
            'common_causes': ['Screen time berlebihan', 'Postur kerja buruk', 'Text neck'],
            'severity': 'medium'
        },
        'kyphosis': {
            'name': 'Kyphosis',
            'description': 'Punggung atas membulat berlebihan ke depan',
            'common_causes': ['Duduk membungkuk', 'Otot punggung lemah', 'Postur smartphone'],
            'severity': 'medium-high'
        },
        'anterior_pelvic_tilt': {
            'name': 'Anterior Pelvic Tilt',
            'description': 'Panggul miring terlalu ke depan',
            'common_causes': ['Hip flexor kencang', 'Core lemah', 'Duduk lama'],
            'severity': 'medium'
        },
        'normal': {
            'name': 'Normal Posture',
            'description': 'Postur tubuh dalam alignment yang baik',
            'common_causes': ['Aktivitas fisik teratur', 'Kesadaran postur baik'],
            'severity': 'none'
        }
    }
    
    return jsonify({
        'success': True,
        'labels': label_descriptions,
        'total_labels': len(label_descriptions)
    })

# Error handlers
@app.errorhandler(413)
def too_large(e):
    return jsonify({
        'success': False,
        'error': 'File too large. Maximum allowed size is 16MB.',
        'max_size_mb': 16
    }), 413

@app.errorhandler(404)
def not_found(e):
    return jsonify({
        'success': False,
        'error': 'Endpoint not found. Check available endpoints at GET /'
    }), 404

@app.errorhandler(400)
def bad_request(e):
    return jsonify({
        'success': False,
        'error': 'Bad request. Please check your input parameters.'
    }), 400

@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({
        'success': False,
        'error': 'Method not allowed. Check the correct HTTP method for this endpoint.'
    }), 405

if __name__ == '__main__':
    # Create necessary directories
    os.makedirs('uploads', exist_ok=True)
    os.makedirs('temp', exist_ok=True)
    
    # Get port from environment variable (Railway/Heroku will provide this)
    port = int(os.environ.get('PORT', 5000))
    
    # Print startup information
    print("="*60)
    print("🚀 MULTILABEL POSTURE DETECTION API")
    print("="*60)
    print(f"📊 Model Status: {'✅ Loaded' if predictor else '❌ Failed'}")
    print(f"🏷️  Labels: {predictor.labels if predictor else 'N/A'}")
    print(f"🤖 Model: {predictor.model_name if predictor else 'N/A'}")
    print(f"🌐 Server starting on port: {port}")
    print("="*60)
    
    # Run the app
    app.run(
        host='0.0.0.0', 
        port=port, 
        debug=False,  # Set to False for production
        threaded=True  # Handle multiple requests
    )