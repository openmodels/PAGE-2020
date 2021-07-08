################################################################################
###################### DEFINE MASTER PARAMETERS FOR THIS FILE ##################
################################################################################

using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV
using Random
using StatsBase
using Statistics

# specify model settings
function set_globalbools()
    global use_variability = false

    # set random seed to have similar variability development in the base and the marginal model.
    # set variability seed.
    if use_variability
        global varseed = rand(1:1000000000000)
    end

    global use_linear = false
    global use_logburke = false
    global use_logpopulation = false
    global use_logwherepossible = true
end

set_globalbools()

include("main_model_annualGrowth.jl")

scenarios = ["RCP4.5 & SSP2", "RCP2.6 & SSP1", "RCP8.5 & SSP5", "RCP1.9 & SSP1"]
if length(ARGS) > 0
    scenarios = [scenarios[parse(Int64, ARGS[1])]]
end

# define the output directory
dir_output = joinpath(@__DIR__, "../../output-annualGrowth/")

# define number of Monte Carlo runs
if !@isdefined samplesize
    samplesize = 50000
end

# define the seed
masterseed = 22081994

# define the pulse size
scc_pulse_size = 75000.

################################################################################
################### MC MODEL RUNS    ###########################################
################################################################################

# PART II: triangular rho (growth effects) distributions
df_sccMC = DataFrame(permafr=false, seaice=false, ge_string="-999", scen="-999",
                                  convergence=-999.,  bound=-999., eqwshare=-999.,
                                  civvalue=-999., pulse=-999.,
                                  mean=-999., median=-999., min=-999., max=-999., perc25=-999.,
                                  perc75=-999., sd=-999., varcoeff=-999.,
                                  perc05=-999., perc95=-999., perc10=-999., perc90=-999.)

# get the SCC for three different growth effects distributions and scenarios
for jj_scen in scenarios
    for jj_gestring in ["EMPIRICAL"]
        for jj_permafr in [true]
            for jj_seaice in [true]
                for jj_civvalue in [1.]
                    for jj_cbabs in [740.65]
                        for jj_eqwshare in [0.99]
                            for jj_convergence in [1.]
                                for jj_pulse in [scc_pulse_size]

                                    # set the ge_string parameters
                                    if jj_gestring == "EMPIRICAL"
                                        ge_string_min = 0.
                                        ge_string_mode = 0.
                                        ge_string_max = 0.0001
                                        ge_use_empirical = 1.
                                    end

                                    # print out the parameters to track progress
                                    print(string("Scen_", jj_scen, " Ge-mode_", jj_gestring,
                                                 " Permafr_", jj_permafr, " Seaice_", jj_seaice, " Civvalue_", jj_civvalue,
                                                 " cbabs_", jj_cbabs, " eqwshare_", jj_eqwshare,
                                                 " convergence", jj_convergence, "pulse_", jj_pulse))

                                    # define the output for the Monte Carlo files
                                    dir_MCoutput = string(dir_output, "mc_diGE/ge", jj_gestring,
                                                                    "_scen", jj_scen,
                                                                    "_pf", jj_permafr,
                                                                    "_se", jj_seaice,
                                                                    "_co", jj_convergence, "_bd", jj_cbabs, "_eq", jj_eqwshare,
                                                                    "_ci", jj_civvalue,
                                                                    "_p", jj_pulse,
                                                                     "/")

                                    # calculate the stochastic mean SCC
                                    Random.seed!(masterseed)
                                    global scc_mcs_object = get_scc_mcs(samplesize, 2020, dir_MCoutput,
                                                                        scenario=jj_scen,
                                                                        pulse_size=jj_pulse,
                                                                        use_permafrost=jj_permafr,
                                                                        use_seaice=jj_seaice,
                                                                        use_page09damages=false,
                                                                        ge_minimum=ge_string_min,
                                                                        ge_maximum=ge_string_max,
                                                                        ge_mode=ge_string_mode,
                                                                        ge_use_empirical=ge_use_empirical,
                                                                        civvalue_multiplier=jj_civvalue,
                                                                        use_convergence=jj_convergence,
                                                                        cbabs=jj_cbabs,
                                                                        eqwbound=jj_eqwshare)

                                    # write out the full distribution
                                    writedlm(string(dir_output, "SCC_MCS_scen", jj_scen, "_per", jj_permafr, "_sea", jj_seaice,
                                                            "_ge", jj_gestring,
                                                            "_conv", jj_convergence, "_bou", jj_cbabs, "_eqw", jj_eqwshare,
                                                            "_civ", jj_civvalue,
                                                            "_pul", jj_pulse,  ".csv"),
                                                            scc_mcs_object, ",")

                                    println(scc_mcs_object)

                                    # push the results into the data frame
                                    push!(df_sccMC, [jj_permafr, jj_seaice, jj_gestring,  jj_scen,
                                                    jj_convergence,  jj_cbabs, jj_eqwshare,
                                                    jj_civvalue, jj_pulse,
                                                    mean(scc_mcs_object[:, 1]),
                                                    median(scc_mcs_object[:, 1]),
                                                    minimum(scc_mcs_object[:, 1]),
                                                    maximum(scc_mcs_object[:, 1]),
                                                    StatsBase.percentile(scc_mcs_object[:, 1], 25),
                                                    StatsBase.percentile(scc_mcs_object[:, 1], 75),
                                                    Statistics.std(scc_mcs_object[:, 1]),
                                                    Statistics.std(scc_mcs_object[:, 1]) / mean(scc_mcs_object[:, 1]),
                                                    StatsBase.percentile(scc_mcs_object[:, 1], 5),
                                                    StatsBase.percentile(scc_mcs_object[:, 1], 95),
                                                    StatsBase.percentile(scc_mcs_object[:, 1], 10),
                                                    StatsBase.percentile(scc_mcs_object[:, 1], 90)])

                                    # clean out the scc_mcs_object
                                    global scc_mcs_object = nothing
                                    ge_string_min = nothing
                                    ge_string_max = nothing
                                    ge_string_mode = nothing

                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

# remove the first placeholder row
df_sccMC = df_sccMC[df_sccMC[!, :scen] .!= "-999", :]

# export the results
CSV.write(string(dir_output, "MimiPageGrowthEffectsResultsMonteCarlo.csv"), df_sccMC)
