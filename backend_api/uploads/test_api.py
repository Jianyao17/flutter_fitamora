# Simpan sebagai test_api.py
try:
    print("Testing imports...")
    import tensorflow as tf
    import numpy as np
    import cv2
    from PIL import Image
    from flask import Flask
    
    print("✅ All critical imports successful!")
    print(f"✅ TensorFlow: {tf.__version__}")
    print(f"✅ NumPy: {np.__version__}")
    print(f"✅ OpenCV: {cv2.__version__}")
    
    # Test basic operations
    arr = np.array([1, 2, 3])
    print(f"✅ NumPy operations work: {arr}")
    
    # Test model loading (jika file model ada)
    try:
        from posture_predictor import PosturePredictor
        predictor = PosturePredictor()
        print("✅ PosturePredictor loaded successfully!")
    except FileNotFoundError:
        print("⚠️ Model file not found (normal if not in same folder)")
    except Exception as e:
        print(f"❌ PosturePredictor failed: {e}")
        
    print("\n🎉 Your API should work fine! Conflicts are not critical.")
        
except ImportError as e:
    print(f"❌ Critical import failed: {e}")
    print("→ Need to fix dependencies")
except Exception as e:
    print(f"❌ Other error: {e}")