import tensorflow as tf
import numpy as np
from PIL import Image
import os

class PosturePredictor:
    def __init__(self, model_path='posture_classification_model.h5', img_size=(224, 224)):
        self.img_size = img_size
    
        try:
            print(f"📦 Loading model from: {model_path}")
            self.model = tf.keras.models.load_model(model_path)
        
            # Print model summary
            print("🤖 Model Summary:")
            self.model.summary()
        
            # Daftar kelas
            self.class_names = ['anterior_pelvic_tilt', 'forward_head_kyphosis', 'normal']
        
            print(f"✅ Model loaded successfully! Input shape: {img_size}")
            print(f"🎯 Available classes: {self.class_names}")
        
        except Exception as e:
            print(f"❌ Failed to load model: {e}")
            raise
    
    def preprocess_image(self, image_path):
        try:
            print(f"🔍 Preprocessing image: {image_path}")
        
        # Check if file exists
            if not os.path.exists(image_path):
                print(f"❌ File not found: {image_path}")
                return None, None
        
        # Check file size
            file_size = os.path.getsize(image_path)
            print(f"📊 File size: {file_size} bytes")
        
            if file_size == 0:
                print("❌ File is empty")
                return None, None
        
        # Try TensorFlow method first
            try:
                img = tf.keras.preprocessing.image.load_img(
                    image_path, target_size=self.img_size
                )
                img_array = tf.keras.preprocessing.image.img_to_array(img)
                print("✅ Using TensorFlow image loading")
            
            except (AttributeError, Exception) as e:
                print(f"⚠️ TensorFlow method failed, using PIL: {e}")
            # Fallback to PIL method
                try:
                    img = Image.open(image_path)
                    print(f"📐 Original image size: {img.size}")
                    img = img.resize(self.img_size)
                    print(f"📏 Resized to: {self.img_size}")
                
                    if img.mode != 'RGB':
                        print(f"🔄 Converting from {img.mode} to RGB")
                        img = img.convert('RGB')
                
                    img_array = np.array(img, dtype=np.float32)
                    print("✅ Using PIL image loading")
                
                except Exception as pil_error:
                    print(f"❌ PIL loading failed: {pil_error}")
                    return None, None
        
            img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
            img_array /= 255.0  # Normalize to [0, 1]
        
            print(f"🎯 Final array shape: {img_array.shape}")
            print(f"📊 Array range: {img_array.min():.3f} to {img_array.max():.3f}")
        
            return img_array, img
        
        except Exception as e:
            print(f"❌ Error in preprocess_image: {str(e)}")
            import traceback
            traceback.print_exc()
            return None, None
    
    def predict_single_image(self, image_path):
        try:
            print("=" * 50)
            print(f"🎯 Predicting image: {os.path.basename(image_path)}")
        
        # Preprocess gambar
            img_array, original_img = self.preprocess_image(image_path)
        
            if img_array is None:
                print("❌ Preprocessing failed - returning None")
                return None, None, None
        
        # Check model input shape compatibility
            print(f"🤖 Model input shape: {self.model.input_shape}")
            print(f"📐 Image array shape: {img_array.shape}")
        
        # Lakukan prediksi
            print("🔮 Running model prediction...")
            predictions = self.model.predict(img_array, verbose=1)  # Set verbose=1 untuk debugging
        
            print(f"📊 Raw predictions: {predictions}")
            print(f"📊 Predictions shape: {predictions.shape}")
        
        # Apply softmax
            scores = tf.nn.softmax(predictions[0])
            print(f"🎯 Softmax scores: {scores}")
        
        # Dapatkan hasil prediksi
            predicted_idx = np.argmax(scores)
            predicted_class = self.class_names[predicted_idx]
            confidence = 100 * np.max(scores)
        
            print(f"✅ Prediction successful!")
            print(f"   Class: {predicted_class}")
            print(f"   Confidence: {confidence:.2f}%")
            print(f"   All scores: {scores.numpy()}")
        
            return predicted_class, confidence, scores.numpy()
        
        except Exception as e:
            print(f"❌ Error in predict_single_image: {str(e)}")
            import traceback
            traceback.print_exc()
            return None, None, None
    
    def predict_multiple_images(self, image_folder):
        """
        Prediksi semua gambar dalam folder - Simplified untuk API
        """
        results = []
        valid_extensions = ['.jpg', '.jpeg', '.png', '.bmp']
        
        for filename in os.listdir(image_folder):
            if any(filename.lower().endswith(ext) for ext in valid_extensions):
                image_path = os.path.join(image_folder, filename)
                
                predicted_class, confidence, scores = self.predict_single_image(image_path)
                
                if predicted_class:
                    results.append({
                        'filename': filename,
                        'predicted_class': predicted_class,
                        'confidence': confidence,
                        'scores': scores.numpy() if hasattr(scores, 'numpy') else scores
                    })
        
        return results

# Fungsi helper untuk API (optional)
def create_predictor(model_path='posture_classification_model.h5'):
    """
    Factory function untuk membuat PosturePredictor instance
    """
    try:
        return PosturePredictor(model_path)
    except Exception as e:
        print(f"Failed to create predictor: {e}")
        return None