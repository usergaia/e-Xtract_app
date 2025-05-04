from ultralytics import YOLO

# Load the YOLO11 model
model = YOLO("best.pt")

# Export the model to TFLite format
model.export(format="tflite")  # creates 'yolo11n_float32.tflite'

# '[name ng model]_float32.tflite' lang kailangan jan

print("Done")