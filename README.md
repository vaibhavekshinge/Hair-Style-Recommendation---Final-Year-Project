# Smart Groom: Hairstyle Recommendation and Try-On System

Smart Groom is an AI-powered application that revolutionizes the way users choose hairstyles by providing personalized hairstyle recommendations based on their face shape. The application includes a real-time hairstyle try-on feature, allowing users to visualize how a hairstyle looks on them before committing to a salon appointment. This project combines computer vision, machine learning, and modern app development to enhance user experience and redefine personal styling.

---

## 🛠️ **Project Features**

1. **Face Shape Detection**:
   - The system uses a machine learning model trained to detect the user's face shape (e.g., oval, square, round, etc.) from an uploaded photo.
   - This forms the basis for personalized hairstyle recommendations.

2. **Hairstyle Recommendation**:
   - Based on the detected face shape, the system suggests the six most suitable hairstyles from a curated dataset.
   - Recommendations are backed by research on what hairstyles best complement each face shape.

3. **Real-Time Hairstyle Try-On**:
   - Users can upload their own image and select a hairstyle to apply.
   - The application uses a face swap API to superimpose the chosen hairstyle onto the user’s face, providing a realistic preview.

4. **Feedback Integration**:
   - Users can rate and provide feedback on the suggested hairstyles.
   - Feedback is used to enhance the recommendation model, ensuring better suggestions in the future.

5. **User-Friendly Interface**:
   - The app includes an interactive and visually appealing Flutter-based frontend.
   - Users can book salon appointments and download hairstyle previews.

---

## 🚀 **How It Works**

### **1. Input Phase**
   - The user uploads an image of their face to the app.
   - Optional: Users can specify their styling preferences.

### **2. Face Shape Detection**
   - The backend processes the uploaded image using a machine learning model.
   - Dlib and face recognition libraries are utilized to extract facial landmarks and determine the face shape.

### **3. Hairstyle Recommendation**
   - Based on the detected face shape, the system retrieves hairstyle recommendations from the dataset.
   - The recommendations are displayed in a user-friendly format.

### **4. Hairstyle Try-On**
   - When the user selects a recommended hairstyle, the app sends the user's face image and the selected hairstyle to a face swap API.
   - The API generates a merged image, showing the user with the chosen hairstyle.

### **5. Feedback**
   - Users can provide feedback by rating the suggestions, helping improve the accuracy and quality of future recommendations.

---

## 📁 **Project Structure**

### Backend:
- **Framework**: FastAPI
- **Functionality**:
  - Image preprocessing.
  - Face shape detection using a custom-trained CNN model.
  - Hairstyle recommendations using pre-curated datasets.
  - Integration with Cloudinary for image storage and SegMind API for face swap.

### Frontend:
- **Framework**: Flutter
- **Functionality**:
  - Image upload and API calls for face shape detection and hairstyle recommendations.
  - Interactive UI for selecting and trying on hairstyles.

### Machine Learning:
- **Libraries**:
  - Dlib, OpenCV, TensorFlow/Keras, FastAPI.
- **Models**:
  - A CNN model trained on a dataset of face images with annotated face shapes.
  - Recommendation logic based on clustering and classification techniques.

---

## 🖥️ **Technology Stack**

- **Frontend**: Flutter
- **Backend**: FastAPI
- **Storage**: Cloudinary (for storing images)
- **Machine Learning**:
  - TensorFlow/Keras for training the model.
  - Dlib for face shape detection.
- **Face Swap API**: SegMind API

---

## 🔧 **Setup Instructions**

### Prerequisites:
- Python 3.8 or later
- Node.js for Flutter (Frontend)
- FastAPI (Backend)

### Steps:
1. **Clone the repository**:
   ```bash
   git clone (https://github.com/vaibhavekshinge/Hair-Style-Recommendation---Final-Year-Project.git)
   cd smart-groom
