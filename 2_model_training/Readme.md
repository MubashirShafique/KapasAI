# 🌿 Cotton Leaf Disease & Insect Detection Using Deep Learning

A comprehensive Deep Learning-based project for **Cotton Crop Health Monitoring**, designed to automatically detect **Cotton Leaf Diseases** and **Cotton Leaf Insects** using TensorFlow, Keras, and MobileNetV2. This system helps farmers and agricultural experts identify plant health issues at an early stage, improving crop productivity and reducing losses.


## Overview

Cotton is one of the most important cash crops worldwide. Diseases and insect attacks can significantly reduce yield and quality. This project leverages **Convolutional Neural Networks (CNNs)** and **Transfer Learning with MobileNetV2** to build two intelligent classification models:

1. **Cotton Leaf Disease Detection Model**
2. **Cotton Leaf Insect Detection Model**

Both models are trained on labeled cotton leaf image datasets and exported into lightweight formats suitable for deployment on web and mobile applications.


## Features

✅ Automatic Cotton Leaf Disease Detection  
✅ Automatic Cotton Leaf Insect Detection  
✅ Transfer Learning using MobileNetV2  
✅ TensorFlow Lite Model Export (.tflite)  
✅ Keras Model Export (.keras)  
✅ High Accuracy Classification  
✅ Mobile & Edge Device Compatible  
✅ Easy Integration into Flutter, Android, and Web Applications



# 📂 Project Structure

```text
2_MODEL_TRAINING/
│
├── insect_detection_model_training/
│   ├── Cotton_Leaf_Insect_Detection.ipynb
│   ├── cotton_insect_mobilenetv2.keras
│   ├── cotton_insect_mobilenetv2_float16.tflite
│   └── insect_labels.txt
│
├── leaf_disease_detection_model_training/
│   ├── Cotton_Leaf_Disease_Detection.ipynb
│   ├── cotton_leaf_mobilenetv2.keras
│   ├── cotton_leaf_mobilenetv2_float16.tflite
│   └── cotton_leaf_labels.txt
│
└── README.md

```