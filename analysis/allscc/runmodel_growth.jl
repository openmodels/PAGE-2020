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

include("main_model_growth.jl")

# define the model regions in the order that Mimi returns stuff
myregions = ["EU", "USA", "Other OECD","Former USSR","China","Southeast Asia","Africa","Latin America"]
myyears = [2020, 2030, 2040, 2050, 2075, 2100, 2150, 2200, 2250, 2300]

# define the output directory
dir_output = joinpath(@__DIR__, "../../output/")

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

# PART I: SCC for fixed rho values (growth effects)
df_sccMC_singleGE = DataFrame(damagePAGE09=false, permafr=false, seaice=false, ge=-999., scen="-999", pulse_size=-999.,
                                 civvalue=-999.,
                                  mean=-999., median=-999., min=-999., max=-999., perc25=-999.,
                                  perc75=-999., sd=-999., varcoeff=-999., perc05=-999., perc95=-999.,
                                  perc10=-999., perc90=-999.)
for jj_page09damages in [false]
    for jj_permafr in [true, false]
        for jj_seaice in [true, false]
            for jj_scen in ["RCP1.9 & SSP1", "RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
                for jj_civvalue in [1., 10.0^20]
#              for jj_gdploss in [1., 0.]

                    # jump undesired combinations
                    if jj_page09damages != false && (jj_permafr != true  || jj_seaice != true || jj_civvalue != 1.)
                        continue
                    elseif jj_permafr != true && (jj_seaice != true || jj_civvalue != 1.)
                        continue
                    elseif jj_permafr != jj_seaice
                        continue
                    end
                        # print the parameter combination to track progress
                    print(string("page09_", jj_page09damages, " Permafr_", jj_permafr, " Scen_", jj_scen, " Seaice_", jj_seaice
                                     ))

                    # loop through the different values for rho
                    for jj_ge in [0:0.1:1;]

                        # print out the growth effects to track progress
                        print(string("Rho = ", jj_ge))

                        # define the output for the Monte Carlo files
                        dir_MCoutput = string(dir_output, "montecarlo-singleGE/scen", jj_scen, "_permafr", jj_permafr, "_seaice", jj_seaice,
                                                        "_page09", jj_page09damages, "/", "ge", jj_ge,
                                                        "_civ", jj_civvalue, "/")

                        # fix the seed and calculate the SCC using a triangular distribution collapsing to a single value and removing the civilization value bound
                        Random.seed!(masterseed)
                        global scc_mcs_object = get_scc_mcs(samplesize, 2020, dir_MCoutput,
                                                                scenario=jj_scen,
                                                                pulse_size=scc_pulse_size,
                                                                use_permafrost=jj_permafr,
                                                                use_seaice=jj_seaice,
                                                                use_page09damages=jj_page09damages,
                                                                ge_minimum=jj_ge,
                                                                ge_maximum=jj_ge + 10^(-10),
                                                                ge_mode=jj_ge,
                                                                civvalue_multiplier=jj_civvalue)

                        # write results into the data frame
                        push!(df_sccMC_singleGE, [jj_page09damages, jj_permafr, jj_seaice, jj_ge,
                                                      jj_scen, scc_pulse_size, jj_civvalue,
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

                      # clean out the MCS objects
                        scc_mcs_object = nothing
                    end
                end
            end
        end
    end
end

# remove the first placeholder row
df_sccMC_singleGE = df_sccMC_singleGE[df_sccMC_singleGE[!, :scen] .!= "-999", :]

# export the results
CSV.write(string(dir_output, "MimiPageGrowthEffectsResults_SCC_fixedGE.csv"), df_sccMC_singleGE)


# PART II: triangular rho (growth effects) distributions
df_sccMC = DataFrame(permafr=false, seaice=false, ge_string="-999", scen="-999",
                                  convergence=-999.,  bound=-999., eqwshare=-999.,
                                  civvalue=-999., pulse=-999.,
                                  mean=-999., median=-999., min=-999., max=-999., perc25=-999.,
                                  perc75=-999., sd=-999., varcoeff=-999.,
                                  perc05=-999., perc95=-999., perc10=-999., perc90=-999.)

# get the SCC for three different growth effects distributions and scenarios
for jj_scen in ["RCP4.5 & SSP2", "RCP2.6 & SSP1", "RCP8.5 & SSP5", "RCP1.9 & SSP1"]
    for jj_gestring in ["EMPIRICAL", "MEDIUM", "MILD", "EMPIRICAL+"]
        for jj_permafr in [true]
            for jj_seaice in [true]
                for jj_civvalue in [1., 10.0^20]
                    for jj_cbabs in [740.65, 740.65 / 2, 740.65 * 2]
                        for jj_eqwshare in [0.99, 0.95, 0.999]
                            for jj_convergence in [1., 0.]
                                for jj_pulse in [scc_pulse_size, scc_pulse_size / 1000., scc_pulse_size / 10., scc_pulse_size * 10.]

                                    # jump undesired or infeasible combinations
                                    if jj_scen != "RCP4.5 & SSP2" && (jj_gestring != "EMPIRICAL" || jj_permafr != true ||
                                                                        jj_seaice != true || jj_civvalue != 1. || jj_cbabs != 740.65 ||
                                                                        jj_eqwshare != 0.99 || jj_convergence != 1. || jj_pulse != scc_pulse_size)
                                        continue
                                    elseif jj_permafr != jj_seaice
                                        continue
                                    elseif jj_gestring != "EMPIRICAL" && (jj_cbabs != 740.65 || jj_eqwshare != 0.99 || jj_convergence != 1. || jj_pulse != scc_pulse_size)
                                        continue
                                    elseif jj_civvalue != 1. && (jj_cbabs != 740.65 || jj_eqwshare != 0.99 || jj_convergence != 1. || jj_pulse != scc_pulse_size)
                                        continue
                                    elseif jj_cbabs != 740.65 && (jj_civvalue != 1. || jj_gestring != "EMPIRICAL" || jj_eqwshare != 0.99 || jj_convergence != 1. || jj_pulse != scc_pulse_size)
                                        continue
                                    elseif jj_eqwshare != 0.99 && (jj_civvalue != 1. || jj_gestring != "EMPIRICAL" || jj_convergence != 1. || jj_pulse != scc_pulse_size)
                                        continue
                                    elseif jj_convergence != 1. && (jj_civvalue != 1. || jj_gestring != "EMPIRICAL" || jj_pulse != scc_pulse_size)
                                        continue
                                    end

                                    # set the ge_string parameters
                                    if jj_gestring == "MILD"
                                        ge_string_min = 0.
                                        ge_string_mode = 0.
                                        ge_string_max = 0.5280681 # value based on converging ratio of marginal impacts from Burke et al regression for 1Lag (temperature and precipitation)
                                        ge_use_empirical = 0.
                                    elseif jj_gestring == "MEDIUM"
                                        ge_string_min = 0.
                                        ge_string_mode = 0.5280681
                                        ge_string_max = 1.
                                        ge_use_empirical = 0.
                                    elseif jj_gestring == "EMPIRICAL"
                                        ge_string_min = 0.
                                        ge_string_mode = 0.
                                        ge_string_max = 0.0001
                                        ge_use_empirical = 1.
                                    elseif jj_gestring == "EMPIRICAL+"
                                        ge_string_min = 0.
                                        ge_string_mode = 0.
                                        ge_string_max = 0.0001
                                        ge_use_empirical = 2.
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
