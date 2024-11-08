import os

# Get the list of all files in the current directory
files = os.listdir('.')

# Filter out .py and .txt files
filtered_files = [f for f in files if not f.endswith('.py') and not f.endswith('.txt')]

# Loop through each file in the filtered list
for file in filtered_files:
    try:
        # Create new filename with .txt extension
        new_filename = os.path.splitext(file)[0] + '.txt'
        
        # Read the contents of the existing file
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Save the content to a new .txt file
        with open(new_filename, 'w', encoding='utf-8') as f:
            f.write(content)
            
        print(f"Converted {file} to {new_filename}")
    except Exception as e:
        print(f"Error converting {file}: {str(e)}")