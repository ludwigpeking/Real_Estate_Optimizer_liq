import os
from PIL import Image

def convert_jpg_to_png(directory):
    # Check if the directory exists
    if not os.path.exists(directory):
        print("The specified directory does not exist")
        return

    # Iterate over all files in the directory
    for filename in os.listdir(directory):
        if filename.endswith(".jpg"):
            # Construct full file path
            full_file_path = os.path.join(directory, filename)
            # Open the image file
            with Image.open(full_file_path) as img:
                # Define the new filename and new full path
                new_filename = filename[:-4] + '.png'
                new_full_path = os.path.join(directory, new_filename)
                # Save the image in PNG format
                img.save(new_full_path, 'PNG')
                print(f"Converted {filename} to {new_filename}")

# Specify the directory containing JPG files
directory_path = 'C:/Users/liq32/AppData/Roaming/SketchUp/SketchUp 2017/SketchUp/Plugins/SketchUpPlugin-2405-liq/icons'  # Change this to your directory
convert_jpg_to_png(directory_path)
