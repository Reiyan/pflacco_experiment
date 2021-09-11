import numpy as np
import os
import pandas as pd

from mlxtend.feature_selection import SequentialFeatureSelector as SFS
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.svm import SVC
from sklearn.metrics import f1_score

INPUT_FOLDER = '/scratch/tmp/r_prag01/pflacco_experiment' 
OUTPUT_FOLDER = '/scratch/tmp/r_prag01/pflacco_sffs'
PROJ_FOLDER = '/home/r/r_prag01/pflacco_experiment'

MODELS = ['svm', 'rf', 'gbm']
HIGH_LEVEL_PROPS = ['multimodality', 'global_structure', 'funnel_structure']
SSIZE = 500

high_level_properties_classif = pd.read_csv(os.path.join(PROJ_FOLDER, 'BBOB_high_level_properties.csv'))
#high_level_properties = high_level_properties_classif.columns[1:]

# Read ELA csv files and merge into one data frame 
files = [filename for filename in os.listdir(INPUT_FOLDER) if filename.endswith('.csv')]
files = [filename for filename in files if f'SSize{SSIZE}_' in filename]
ela = []
for f in files:
    tmp = pd.read_csv(os.path.join(INPUT_FOLDER, f), dtype=np.float64)
    ela.append(tmp)
ela = pd.concat(ela)

# Remove limo features
ela = ela.drop(columns = [x for x in ela.columns if 'limo.' in x])
ela = ela.drop(columns = [x for x in ela.columns if 'costs_runtime' in x])
ela_colnames = [x for x in ela.columns if x not in ['fid', 'dim', 'iid', 'rep']]

# Merge ELA features with high level properties
ela = pd.merge(ela, high_level_properties_classif, how = 'left', on = ['fid'])

# Create X data set
X = ela[ela_colnames]

# Drop columns which contain NA or infinity values. These are: 'ela_meta.quad_simple.cond', 'ela_local.best2mean_contr.ratio', 'lon.global_funnel_strength_norm'
X.replace([np.inf, -np.inf], np.nan, inplace=True)
X = X.drop(columns=X.columns[X.isna().any().values])

# Sklearn models can only deal with float32 numbers. ELA Curvate feature in some rare cases exceeds the max number of float32.
# The strategy here is to replace these extremly large values (x*e^106) with the maximum or minimum of float32
X[X > np.finfo(np.float32).max] = float(np.finfo(np.float32).max)
X[X < np.finfo(np.float32).min] = np.finfo(np.float32).min

# Create y data set (for all high level properties)
label_colnames = ela.columns.difference(np.hstack([ela_colnames, ['fid', 'dim', 'iid', 'rep']]))
y_all = ela[label_colnames]

# Custom scoring function, which is nothing more than the basic F1 of sklearn. However, the parameter "average" has not the default value. This could not be passed via another parameter to the SFS.
# Hence, the creation of this wrapper function
def _f1(model, X, y_true):
    y_pred = model.predict(X)
    return f1_score(y_true, y_pred, average = 'weighted')

# Set seed
np.random.seed(100)

for model_ in MODELS:
    for hl_prop in HIGH_LEVEL_PROPS:

        y = y_all[hl_prop]
        if model_ == 'gbm':
            model = GradientBoostingClassifier(n_estimators=100, learning_rate=0.1, max_depth=3, min_samples_split = 2, random_state=2034)
        elif model_ == 'rf':
            model = RandomForestClassifier(random_state=2034)
        elif model_ == 'svm':
            model = SVC(random_state=2034)
        else:
            raise Exception('Invalid model selected.')

        # Perform forward backward feature selection
        sffs = SFS(model, k_features=(1,3), forward=True, floating=True, scoring=_f1, cv=5, n_jobs=-1)
        sffs = sffs.fit(X, y)

        # Write the all results to a dataframe
        sffs_result = pd.DataFrame.from_dict(sffs.get_metric_dict()).T
        sffs_result['hlevel'] = hl_prop
        sffs_result['model'] = model_
        sffs_result.to_csv(os.path.join(OUTPUT_FOLDER, f'sffs_{model_}_{hl_prop}_results.csv'), index = False)
