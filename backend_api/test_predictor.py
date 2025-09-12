# test_predictor.py
from posture_predictor import PosturePredictor
import os

def test_predictor():
    print("🧪 Testing PosturePredictor...")
    
    # Initialize predictor
    predictor = PosturePredictor()
    
    # Test with a sample image
    test_image_path = "bad.png"  # Ganti dengan path gambar Anda
    
    if not os.path.exists(test_image_path):
        print("❌ Test image not found, please create a simple test image first")
        return
    
    # Test prediction
    result = predictor.predict_single_image(test_image_path)
    print(f"📋 Test result: {result}")

if __name__ == "__main__":
    test_predictor()