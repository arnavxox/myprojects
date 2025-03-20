# Import libraries
import pandas as pd
import numpy as np
import statsmodels.api as sm

# Load dataset
plfs = pd.read_csv('C:/Users/arnav/Desktop/Academia/TISS/Sem 3/Macro and Micro/HHV1_Merged_Coded.csv')

# Create gender variable and filter data
plfs['gender'] = plfs['Sex'].map({1: 'Male', 2: 'Female', 3: 'Other'})
plfs = plfs[(plfs['Log(Wages)'] != 0) & (plfs['Sex'] != 3)]
plfs['gender_dummy'] = (plfs['Sex'] == 1).astype(int)

# Filter working age population (15-60)
plfs_filtered = plfs[plfs['Age'].between(15, 60)].copy()

# Create dummy variables for classification
# Urban = 1, Rural = 0
if 'Sector' in plfs_filtered.columns:
    plfs_filtered['sector'] = (plfs_filtered['Sector'] == 2).astype(int)
else:
    print("Warning: 'Sector' column not found!")

# Disadvantaged groups = 1, Others = 0
if 'Social Group' in plfs_filtered.columns:
    plfs_filtered['social_group'] = plfs_filtered['Social Group'].isin([1, 2, 3]).astype(int)
else:
    print("Warning: 'Social Group' column not found!")

# Large firms = 1, Small firms = 0
firm_size_col = '(Principal) No. Of Workers In The Enterprise'
if firm_size_col in plfs_filtered.columns:
    plfs_filtered[firm_size_col] = pd.to_numeric(plfs_filtered[firm_size_col], errors='coerce')
    plfs_filtered['firm_size'] = (plfs_filtered[firm_size_col] >= 10).astype(int)
else:
    print(f"Warning: '{firm_size_col}' column not found!")

# Professional/Managerial/Technical = 1, Others = 0
if 'Occupation Code (NCO)' in plfs_filtered.columns:
    plfs_filtered['Occupation Code (NCO)'] = pd.to_numeric(plfs_filtered['Occupation Code (NCO)'], errors='coerce')
    plfs_filtered['occupation'] = ((plfs_filtered['Occupation Code (NCO)'] >= 100) &
                                   (plfs_filtered['Occupation Code (NCO)'] < 400)).astype(int)
else:
    print("Warning: 'Occupation Code (NCO)' column not found!")

# MODEL 1: Basic human capital model
model1_cols = ['Age', 'No. of years in Formal Education', 'gender_dummy', 'Log(Wages)']
df_model_1 = plfs_filtered[model1_cols].dropna()

# Run Model 1 regression
X1 = sm.add_constant(df_model_1[['Age', 'No. of years in Formal Education', 'gender_dummy']])
y1 = df_model_1['Log(Wages)']
model_1 = sm.OLS(y1, X1).fit()

# Display Model 1 results
print("\nModel 1 Results:")
print(model_1.summary())
gender_effect_model1 = (np.exp(model_1.params['gender_dummy']) - 1) * 100
print(f"\nGender wage gap (Model 1): {gender_effect_model1:.2f}%")

# MODEL 2: Extended model with structural factors
required_cols = ['Age', 'No. of years in Formal Education', 'gender_dummy',
                 'sector', 'social_group', 'firm_size', 'occupation', 'Log(Wages)']
missing_cols = [col for col in required_cols if col not in plfs_filtered.columns]

if missing_cols:
    print(f"Cannot run Model 2. Missing columns: {missing_cols}")
else:
    # Run Model 2 regression
    df_model_2 = plfs_filtered[required_cols].dropna()
    X2 = sm.add_constant(df_model_2[required_cols[:-1]])  # All columns except Log(Wages)
    y2 = df_model_2['Log(Wages)']
    model_2 = sm.OLS(y2, X2).fit()

    # Display Model 2 results
    print("\nModel 2 Results:")
    print(model_2.summary())
    gender_effect_model2 = (np.exp(model_2.params['gender_dummy']) - 1) * 100
    print(f"\nGender wage gap (Model 2): {gender_effect_model2:.2f}%")
