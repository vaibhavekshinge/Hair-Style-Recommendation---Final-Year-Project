import cloudinary
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import numpy as np
import joblib
import os
import cv2
import functions_only_save as fos
import pandas as pd
from io import BytesIO
import recommender as rec
import base64
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import requests

api_key = "Your Api key"   #Segmind face swap api

class Feedback(BaseModel):
    favorite: str
    least_favorite: str


app = FastAPI()

df = pd.DataFrame(columns = ['0','1','2','3','4','5','6','7','8','9','10','11',	'12',	'13',	'14',	'15',	'16','17',
                             '18',	'19',	'20',	'21',	'22',	'23',	'24','25',	'26',	'27',	'28',	'29',
                             '30',	'31',	'32',	'33',	'34',	'35',	'36',	'37',	'38',	'39',	'40',	'41',
                             '42',	'43',	'44',	'45',	'46',	'47',	'48',	'49',	'50',	'51',	'52',	'53',
                             '54',	'55',	'56',	'57',	'58',	'59',	'60',	'61',	'62',	'63',	'64',	'65',
                             '66',	'67',	'68',	'69',	'70',	'71',	'72',	'73',	'74',	'75',	'76',	'77',
                             '78',	'79',	'80',	'81',	'82',	'83',	'84',	'85',	'86',	'87',	'88',	'89',
                             '90',	'91',	'92',	'93',	'94',	'95',	'96',	'97',	'98',	'99',	'100',	'101',
                             '102',	'103',	'104',	'105',	'106',	'107',	'108',	'109',	'110',	'111',	'112',	'113',
                             '114',	'115',	'116',	'117',	'118',	'119',	'120',	'121',	'122',	'123',	'124',	'125',
                             '126',	'127',	'128',	'129',	'130',	'131',	'132',	'133',	'134',	'135',	'136',	'137',
                             '138',	'139',	'140',	'141',	'142',	'143','A1','A2','A3','A4','A5','A6','A7','A8','A9',
                            'A10','A11','A12','A13','A14','A15','A16','Width','Height','H_W_Ratio','Jaw_width','J_F_Ratio',
                             'MJ_width','MJ_J_width'])

# Allow CORS (Cross-Origin Resource Sharing)
origins = ["*"]  # You can restrict this to your frontend's domain if needed

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure Cloudinary
cloudinary.config(
    cloud_name='dtve9mfks',
    api_key='Your cloudinary api key',
    api_secret='Cloudinary api secret'
)

style_df = pd.DataFrame()
style_df = pd.DataFrame(columns = ['face_shape','hair_length','location','filename','score'])
        
rec.process_rec_pics(style_df)


@app.post("/predict/")
async def predict(file: UploadFile = File(...)):
    try:
        # Print basic file information
        print(f"Received file: {file.filename}")

        # Await the reading of the uploaded file
        file_content = await file.read()

        # Print the size of the file content to verify it's being read
        print(f"File content size: {len(file_content)} bytes")

        # Convert the file content to an image (PIL Image)
        image = Image.open(BytesIO(file_content))

        # Save the image file temporarily for verification (optional)
        image.save("uploaded_image_test.jpg")
        print("Image saved as uploaded_image_test.jpg for debugging")
        
        # Load the pre-trained model, PCA, and scaler
        model = joblib.load("face_shape_model.pkl")
        scaler = joblib.load("scaler.pkl")
        pca = joblib.load("pca.pkl")
        
        my_photo = "uploaded_image_test.jpg"

        # Proceed with face shape detection and prediction
        file_num = 2035
        fos.make_face_df_save(my_photo, file_num, df)
        dfc = df
        test_row = dfc.loc[file_num].values.reshape(1, -1)
        test_row = scaler.transform(test_row)

        # Predict the face shape using the pre-trained model
        predicted_shape = model.predict(test_row)
        
        reccomended_image, recdf =rec.run_recommender(predicted_shape[0], "n", "l", "Vaibhav", style_df)
        
        return {"predicted_shape": predicted_shape[0], "hairstyles": reccomended_image}

    except Exception as e:
        # Print the error to terminal for debugging
        print(f"Error occurred: {e}")
        return {"error": str(e)}

    
@app.post("/face_swap/")
async def face_swap(input_face: UploadFile = File(...), target_face: UploadFile = File(...)):
    try:
        # Helper function to convert image file to base64
        def image_file_to_base64(image_path):
           with open(image_path, 'rb') as f:
               image_data = f.read()
           return  base64.b64encode(image_data).decode('utf-8')

        # Read and encode both input images to base64
        input_face_data = await input_face.read()
        target_face_data = await target_face.read()
        
        image1 = Image.open(BytesIO(input_face_data))
        image2 = Image.open(BytesIO(target_face_data))
        
        image1.save("input_image.jpg")
        image2.save("target_image.jpg")
        
        input_face_base64 = image_file_to_base64("input_image.jpg")
        target_face_base64 = image_file_to_base64("target_image.jpg")

        # Define the payload for the API request
        data = {
            "input_face_image": input_face_base64,
            "target_face_image": target_face_base64,
            "file_type": "jpg",
            "face_restore": True
        }

        headers = {'x-api-key': api_key}

        # Call Segmind API to perform face swap
        response = requests.post("https://api.segmind.com/v1/sd2.1-faceswapper", json=data, headers=headers)

        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail="Face swap API request failed.")
        
        clink = cloudinary.uploader.upload(response.content)
        
        return {'swap_image_url' : clink['secure_url']}

    except Exception as e:
        print(f"Error occurred during face swap: {e}")
        raise HTTPException(status_code=500, detail="An error occurred during the face swap process.")
    
@app.post("/feedback/")
async def feedback(feedback: Feedback):
    try:
        favorite = feedback.favorite
        least_favorite = feedback.least_favorite
        
        # Assuming you have access to style_df globally or can load it here
        # Update the scores based on user feedback
        for index, row in style_df.iterrows():
            # Assuming 'filename' is unique for each hairstyle
            if row['filename'] == favorite:
                style_df.at[index, 'score'] += 5  # Increase score for favorite
            elif row['filename'] == least_favorite:
                style_df.at[index, 'score'] -= 5  # Decrease score for least favorite
        
        # Optionally, you can save the updated style_df to your database or file here
        # style_df.to_csv('path_to_your_file.csv', index=False)  # Example

        return {"message": "Feedback received and scores updated."}
    except Exception as e:
        print(f"Error occurred: {e}")
        raise HTTPException(status_code=500, detail="An error occurred while processing feedback.")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


