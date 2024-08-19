from flask import Flask, request, jsonify
import cv2
import os
import numpy as np
import tensorflow as tf
from typing import List
from tensorflow.python.client import device_lib

app = Flask(__name__)

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path="model/my_model.tflite")
interpreter.allocate_tensors()

def print_available_devices():
    devices = device_lib.list_local_devices()
    for device in devices:
        print(f"Device Name: {device.name}, Device Type: {device.device_type}")
        
# Functional
def load_video(path:str, max_frames: int = 75) -> List[float]:

    cap = cv2.VideoCapture(path)
    frames = []
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    total_frames = min(frame_count, max_frames)
    print(f"Total frames available in the video: {frame_count}")
    print(f"Total frames extracted for processing: {total_frames}")
    for _ in range(int(cap.get(cv2.CAP_PROP_FRAME_COUNT))):
        ret, frame = cap.read()
        frame = tf.image.rgb_to_grayscale(frame)
        frames.append(frame[190:236,80:220,:])
    cap.release()

    mean = tf.math.reduce_mean(frames)
    std = tf.math.reduce_std(tf.cast(frames, tf.float32))
    return tf.cast((frames - mean), tf.float32) / std

def load_data(path: str):
    path = bytes.decode(path.numpy())

    # Handle file paths dynamically
    file_name = os.path.splitext(os.path.basename(path))[0]
    vPath = os.path.join(f'{file_name}.mp4')

    frames = load_video(vPath)

    return frames

def decode_predictions(predictions, vocab):
    return ''.join([vocab.get(idx, '') for idx in predictions])  # Use '?' for unknown indices

vocab = {
    0: "",
    1: "a",    2: "b",    3: "c",    4: "d",    5: "e",    6: "f",    7: "g",
    8: "h",    9: "i",    10: "j",   11: "k",   12: "l",   13: "m",   14: "n",
    15: "o",   16: "p",   17: "q",   18: "r",   19: "s",   20: "t",   21: "u",
    22: "v",   23: "w",   24: "x",   25: "y",   26: "z",   27: "'",   28: "?",
    29: "!",   30: "1",   31: "2",   32: "3",   33: "4",   34: "5",   35: "6",
    36: "7",   37: "8",   38: "9",   39: " " }

# Upload video endpoint
@app.route('/upload', methods=['POST'])
def upload_video():
    if 'video' not in request.files:
        return jsonify({'error': 'No video file provided'}), 400
    
    video_file = request.files['video']
    
    # Save the video file to a temporary location
    video_path = os.path.join(video_file.filename)
    video_file.save(video_path)
    
    frames = load_data(tf.convert_to_tensor(video_path))
    
    # Get input and output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    input_details = interpreter.get_input_details()
    
    # Convert frame
    frames = np.array(frames, dtype=np.float32)
    print("sampai - ngubah array")
    frames = np.reshape(frames, (75, 46, 140, 1))
    print(f"Expected input shape: {input_details[0]['shape']}")
    input_data = np.expand_dims(frames, axis=0)
    # Set the input tensor
    interpreter.set_tensor(input_details[0]['index'], input_data)
    print("Setting interpreter tensor..")
    
    # Run inference
    print ("Inference will run on :")
    print_available_devices()
    try:
        print("Running inferece...")
        interpreter.invoke()
        print("Inference completed.")
    except Exception as e:
        print(f"Error during inference: {str(e)}")
        return jsonify({'error': 'Model inference failed'}), 500
    
    output_details = interpreter.get_output_details()
    output_data = interpreter.get_tensor(output_details[0]['index'])
    predictions = np.argmax(output_data, axis=-1)
    
    # Output prediction
    text_output = decode_predictions(predictions[0], vocab)
    print(text_output)

    return jsonify({'predicted_text': text_output}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
