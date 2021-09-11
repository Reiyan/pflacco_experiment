import pandas as pd
import numpy as np
import os
from sklearn.ensemble import GradientBoostingClassifier
from mlxtend.feature_selection import SequentialFeatureSelector as SFS
from sklearn.metrics import f1_score


SSIZE = 500
FOLDER = 'pflacco_experiment' 

high_level_properties_classif = pd.read_csv(os.path.join('data', 'meta_data.csv'))
high_level_properties = high_level_properties_classif.columns[1:]

files = [filename for filename in os.listdir(FOLDER) if filename.endswith('.csv')]

ela = []
for f in files:
    tmp = pd.read_csv(os.path.join(FOLDER, f), dtype=np.float64)
    ela.append(tmp)

ela = pd.concat(ela)
# Remove limo features
ela = ela.drop(columns = [x for x in ela.columns if 'limo.' in x])
colnames = ela.columns
ela = pd.merge(ela, high_level_properties_classif, how = 'left', on = ['fid'])

X = ela[colnames]
y_all = ela[ela.columns.difference(colnames)]

X['ela_local.best2mean_contr.ratio'].replace(np.inf, 1, inplace=True)
X['ela_local.best2mean_contr.ratio'].replace(np.NINF, 0, inplace=True)
X['ela_meta.quad_simple.cond'].replace([np.inf, -np.inf], np.nan, inplace=True)



#X.replace([np.inf, -np.inf], np.nan)
X = X.fillna(0)

X[X > np.finfo(np.float32).max] = float(np.finfo(np.float32).max)
X[X < np.finfo(np.float32).min] = np.finfo(np.float32).min

def _f1(model, X, y_true):
    y_pred = model.predict(X)
    return f1_score(y_true, y_pred, average = 'weighted')

for hl_prop in high_level_properties:
    y = y_all[hl_prop]
    gbc = GradientBoostingClassifier(n_estimators=100, learning_rate=1.0, max_depth=1, random_state=0)

    sffs = SFS(gbc, k_features=(1,30), forward=True, floating=True, scoring=_f1, cv=0, n_jobs=1)
    sffs = sffs.fit(X, y)

    print('\nSFFS [' + str(hl_prop) + ']:')
    print(sffs.k_feature_idx_)
    print('CV Score: ' + str(sffs.k_score_))



print('test')