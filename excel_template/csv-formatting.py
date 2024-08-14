import pandas as pd
import openpyxl
from openpyxl.utils.dataframe import dataframe_to_rows
import os

# Get the directory of the current script
current_dir = os.path.dirname(os.path.abspath(__file__))

# Read the CSV file
csv_file = os.path.join(current_dir, 'real_estate_cashflow_report.csv')
df = pd.read_csv(csv_file)

# Load the Excel template
template_file = os.path.join(current_dir, 'template.xlsx')
workbook = openpyxl.load_workbook(template_file)

# Select the worksheet where you want to insert the data
worksheet = workbook['Sheet1']  # Change 'Sheet1' to your sheet name

# Clear the existing content in the data range
# Adjust the range as needed
worksheet.delete_rows(2, worksheet.max_row)  # Assuming headers are in row 1

# Write the DataFrame to the Excel sheet
for r in dataframe_to_rows(df, index=False, header=False):
    worksheet.append(r)

# Save the workbook
output_file = os.path.join(current_dir, 'formatted_real_estate_cashflow_report.xlsx')
workbook.save(output_file)

print(f"Formatted report saved as: {output_file}")