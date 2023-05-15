from find_solint import GetSolint

# set std score, for which you want to find the solint
optimal_score = 2

# reference solution interval
ref_solint = 10

S1 = GetSolint('../bad1min.h5', optimal_score, ref_solint)
S1.get_phasediff_score()

S2 = GetSolint('../bad2min.h5', optimal_score, ref_solint)
S2.get_phasediff_score()

S4 = GetSolint('../bad4min.h5', optimal_score, ref_solint)
S4.get_phasediff_score()

S10 = GetSolint('../bad10min.h5', optimal_score, ref_solint)
solint10 = S10.best_solint

S15 = GetSolint('../bad15min.h5', optimal_score, ref_solint)
S15.get_phasediff_score()

S20 = GetSolint('../bad20min.h5', optimal_score, ref_solint)
S20.get_phasediff_score()

print([[1, 2, 4, 10, 15, 20], [S1.cstd, S2.cstd, S4.cstd, S10.cstd, S15.cstd, S20.cstd]])

# OPTIONAL
S10.plot_C("T=" + str(round(solint10, 2)) + " min",
           extrapoints=[[1, 2, 4, 15, 20], [S1.cstd, S2.cstd, S4.cstd, S15.cstd, S20.cstd]])