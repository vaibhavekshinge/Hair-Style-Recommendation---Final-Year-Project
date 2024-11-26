import requests
from PIL import Image, ImageDraw,ImageFont
import face_recognition
import pandas as pd
import numpy as np
from os.path import basename
import math
import pathlib
from pathlib import Path
import os
import random
import matplotlib.pyplot as plt
import uuid
import cloudinary
import cloudinary.uploader

# Configure Cloudinary
cloudinary.config(
    cloud_name='dtve9mfks',
    api_key='415118217882929',
    api_secret='osuxslfgrwkn2Gj0_DGTzpzXduM'
)

image_dir = "data/pics"

style_df = pd.DataFrame()
style_df = pd.DataFrame(columns = ['face_shape','hair_length','location','filename','score'])

def process_rec_pics(style_df,image_dir = "data/pics"):
    image_root = "data/rec_pics" 
    dir_list = ['diamond','heart','oblong','oval','round','square','triangle']
    filenum = 0   
    for dd in dir_list: 
            image_dir = image_root + '/' + dd
            sub_dir = [q for q in pathlib.Path(image_dir).iterdir() if q.is_dir()]
            #print(sub_dir)
            start_j = 0
            end_j = len(sub_dir)

            for j in range(start_j, end_j):
                    #images_dir = [p for p in pathlib.Path(sub_dir[j]).iterdir() if p.is_file()]

                    for p in pathlib.Path(sub_dir[j]).iterdir():
                        shape_array= []

                        face_shape = os.path.basename(os.path.dirname(os.path.dirname(p)))
                        hair_length = os.path.basename(os.path.dirname(p)) 
                        sub_dir_file = p
                        face_file_name = os.path.basename(p)

                        shape_array.append(face_shape)
                        shape_array.append(hair_length)
                        shape_array.append(sub_dir_file)
                        shape_array.append(face_file_name)  
                        
                        random.seed(filenum)  # this keeps the score the same each time I run it
                        rand = random.randint(25,75)  # make a random score to start the rec. engine
                        shape_array.append(rand)

                        style_df.loc[filenum] = np.array(shape_array)

                        filenum += 1
    return(filenum)

process_rec_pics(style_df)

style_df

def run_recommender(face_shape_input, updo_input, hair_length_input, name, style_df, r=6):
    print("Hello, %s." % name)

    # Validate face shape input
    valid_shapes = ['diamond', 'heart', 'oblong', 'oval', 'round', 'square', 'triangle']
    if face_shape_input not in valid_shapes:
        face_shape_input = input("What is your face shape? ")

    # Determine hair length based on user input
    if updo_input in ['n', 'no', 'N', 'No', 'NO']:
        hair_length_input = hair_length_input.lower()
        if hair_length_input in ['short', 's']:
            hair_length_input = 'Short'
        elif hair_length_input in ['long', 'l']:
            hair_length_input = 'Long'
    else:
        hair_length_input = 'Updo'

    print(hair_length_input)
    print(face_shape_input)

    # Filter recommended hairstyles based on face shape and hair length
    recommended_df = style_df.loc[
        (style_df['face_shape'] == face_shape_input) & 
        (style_df['hair_length'] == hair_length_input)
    ].sort_values('score', ascending=False).reset_index(drop=True)

    recommended_df = recommended_df.head(r)

    # Upload images to Cloudinary and prepare response
    result_images = []
    for p in range(0, r):
        image_path = str(recommended_df.iloc[p]['location'])
        image_path = image_path.replace('\\', '/')

        # Upload the image to Cloudinary
        response = cloudinary.uploader.upload(image_path)
        result_images.append({
            'score': recommended_df.iloc[p]['score'],
            'url': response['secure_url'],  # Get the secure URL for the uploaded image
            'filename': recommended_df.iloc[p]['filename']
        })

    return result_images, recommended_df




def run_recommender_face_shape(test_shape,style_df,hair_length_input):
    face_shape_input = test_shape
    r = 6
    
    n_col = 3
    n_row = 2
    img_path = []
    recommended_df = style_df.loc[(style_df['face_shape'] ==face_shape_input) & (style_df['hair_length']== hair_length_input)].sort_values('score', ascending = 0).reset_index(drop=True)
    recommended_df = recommended_df.head(r)
    
    plt.figure(figsize=(4 * n_col, 3 * n_row))
    plt.subplots_adjust(bottom=.06, left=.01, right=.99, top=.90, hspace=.50)    
    font = ImageFont.truetype("fonts/Arial.ttf", 60)
    for p in range(0,r):
        idea = str(recommended_df.iloc[p]['location'] )
        idea = idea.replace('\\', '/')
        img = Image.open(idea)
        plt.subplot(n_row, n_col, p+1 )
        img_path.append(idea)
        draw = ImageDraw.Draw(img)
        plt.title(p+1,fontsize = 40)
        plt.xlabel(recommended_df.iloc[p]['score'],fontsize = 20)
        plt.xticks([])
        plt.yticks([])
        plt.imshow(img)
        img.close()

    #plt.show()
    img_id = uuid.uuid4()
    img_filename=f"output/output_{img_id}.png"
    plt.savefig(img_filename)
    return img_filename
    #return img_path
