from pflacco.sampling import create_initial_sample
from pflacco.classical_ela_features import *
from pflacco.local_optima_network_features import *
from pflacco.misc_features import * 

import cocoex
import os
import pandas as pd
import sys

L_BOUND = -5
U_BOUND = 5
REPITIONS = 10
BLOCKS = 3
SAMPLE_SIZE_FACTOR = 50
EXP_FOLDER = '/scratch/tmp/r_prag01/pflacco_experiment/'

def calculate_features(problem_ids):
    suite = cocoex.Suite("bbob", f"instances:{problem_ids[2]}", f"function_indices:{problem_ids[0]} dimensions:{problem_ids[1]}")

    for f in suite:
        # Get meta information about the opt problem
        fid = f.id_function
        iid = f.id_instance
        dim = f.dimension
        
        results = []
        for rep in range(REPITIONS):
            # Set seeds, this ensures, that at least for every (fid,dim,iid) the seeds are different over all x repetitions
            np.random.seed(int(fid) * int(iid) * int(dim) *(rep + 1))
            random.seed(int(fid) * int(iid) * int(dim) * (rep + 1))

            X = create_initial_sample(dim, sample_coefficient = SAMPLE_SIZE_FACTOR, lower_bound = L_BOUND, upper_bound = U_BOUND, sample_type = 'lhs')
            y = X.apply(lambda x: f(x.values), axis = 1)

            meta = calculate_ela_meta(X, y)
            pca = calculate_pca(X, y)
            nbc = calculate_nbc(X, y)
            disp = calculate_dispersion(X, y)
            ic = calculate_information_content(X, y)
            distr = calculate_ela_distribution(X, y)
            #limo = calculate_limo(X, y, L_BOUND, U_BOUND, blocks = BLOCKS)
            cm_angle = calculate_cm_angle(X, y, L_BOUND, U_BOUND, blocks = BLOCKS)
            cm_conv = calculate_cm_conv(X, y, L_BOUND, U_BOUND, blocks = BLOCKS)
            cm_grad = calculate_cm_grad(X, y, L_BOUND, U_BOUND, blocks = BLOCKS)
            ela_conv = calculate_ela_conv(X, y, f)
            ela_level = calculate_ela_level(X, y)
            ela_curvate = calculate_ela_curvate(X, y, f, dim, L_BOUND, U_BOUND)
            ela_local = calculate_ela_local(X, y, f, dim, L_BOUND, U_BOUND)

            fdc = calculate_fitness_distance_correlation(X, y)

            if SAMPLE_SIZE_FACTOR == 500:
                lon = compute_lon_features(f, dim, L_BOUND, U_BOUND, basin_hopping_iteration = 100, stopping_threshold = 1000)
                hc = calculate_hill_climbing_features(f, dim, L_BOUND, U_BOUND, n_runs = 200, budget_factor_per_run = 80)
                grad = calculate_gradient_features(f, dim, L_BOUND, U_BOUND, budget_per_random_walk = 1000)
                si = calculate_sobol_indices_features(f, dim, L_BOUND, U_BOUND)
                ls = calculate_length_scales_features(f, dim, L_BOUND, U_BOUND, budget_factor_per_dim=100)
            else:
                lon = compute_lon_features(f, dim, L_BOUND, U_BOUND, basin_hopping_iteration = 50, stopping_threshold = 1000)
                hc = calculate_hill_climbing_features(f, dim, L_BOUND, U_BOUND, n_runs = 50, budget_factor_per_run = 50)
                grad = calculate_gradient_features(f, dim, L_BOUND, U_BOUND, budget_per_random_walk = 50)
                si = calculate_sobol_indices_features(f, dim, L_BOUND, U_BOUND, sampling_coefficient = 50)
                ls = calculate_length_scales_features(f, dim, L_BOUND, U_BOUND, budget_factor_per_dim = 50)

            res = {**hc, **grad, **fdc, **meta, **pca, **nbc, **disp, **ic, **distr, **cm_angle, **cm_conv, **cm_grad, **ela_conv, **ela_level, **ela_curvate, **ela_local, **ls, **si, **lon}
            res['fid'] = fid
            res['dim'] = dim
            res['iid'] = iid
            res['rep'] = rep

            results.append(res)

        df = pd.DataFrame(results)
        df.to_csv(os.path.join(EXP_FOLDER, f'F{fid}_D{dim}_I{iid}_SSize{SAMPLE_SIZE_FACTOR}_features.csv'), index = False)


if __name__ == '__main__':
    if len(sys.argv) == 4:
        calculate_features([int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])])
    else:
        raise SyntaxError("Insufficient number of arguments passed")
