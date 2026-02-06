import sys
import pandas as pd

if len(sys.argv) != 5:
    print("Usage: python fold_enrichment.py <file1> <file2> <file3> <file4>")
    sys.exit(1)

file1, file2, file3, file4 = sys.argv[1:5]

original = pd.read_csv(file1, sep='\t', header=None)
rand1 = pd.read_csv(file2, sep='\t', header=None)
rand2 = pd.read_csv(file3, sep='\t', header=None)
rand3 = pd.read_csv(file4, sep='\t', header=None)

#print(f"Loaded {file1}: {original.shape}")
#print(f"Loaded {file2}: {rand1.shape}")
#print(f"Loaded {file3}: {rand2.shape}")
#print(f"Loaded {file4}: {rand3.shape}")

#Forcing a new hash to be created
#print(f"Count of column 3: {original.iloc[:, 3].count()}")
#original_counts = original.iloc[:, 3].value_counts()
original_counts = original.iloc[:, 3].value_counts()
rand1_counts = rand1.iloc[:, 3].value_counts()
rand2_counts = rand2.iloc[:, 3].value_counts()
rand3_counts = rand3.iloc[:, 3].value_counts()

# Combine random counts into a DataFrame
rand_counts_df = pd.DataFrame([rand1_counts, rand2_counts, rand3_counts]).fillna(0)

# Calculate the average count for each unique value across the three random sets
rand_avg_counts = rand_counts_df.mean(axis=0)
rand_stnd_dev_counts = rand_counts_df.std(axis=0)

# Calculate fold enrichment: original_counts divided by average random counts
fold_enrichment = original_counts / rand_avg_counts
print(rand_avg_counts)
print("-----------------")
print(original_counts)
print("-----------------")
print(rand1_counts)
print(rand2_counts)
print(rand3_counts)
print("-----------------")

fold_enrichment = fold_enrichment.reset_index()
fold_enrichment.columns = ['feature', 'Fold_Enrichment', 'Std_Dev']
fold_enrichment['Std_Dev'] = rand_stnd_dev_counts.loc[fold_enrichment['feature']].values

# Print and save results
print("Fold enrichment:")
print(fold_enrichment)

fold_enrichment.to_csv("fold_enrichment_results.txt", sep='\t', header=True)