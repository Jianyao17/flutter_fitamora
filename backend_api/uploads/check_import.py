import sys

# Print all places Python looks for modules
print("Python module search paths:")
for path in sys.path:
    print(f"  {path}")

print("\n" + "="*50 + "\n")

# Try to import tensorflow and see what happens
try:
    import tensorflow as tf
    print("TensorFlow imported successfully!")
    print(f"Module file: {tf.__file__}")
    print(f"Version: {tf.__version__}")
except Exception as e:
    print(f"Import failed: {e}")
    print(f"Error type: {type(e).__name__}")