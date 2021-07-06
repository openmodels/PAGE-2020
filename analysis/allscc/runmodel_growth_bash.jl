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
samplesize = 50000

# define the seed
masterseed = 22081994

# define the pulse size
scc_pulse_size = 75000.

# define loop parameters that are held constant across rho and adaptation rate values
jj_scen = "RCP4.5 & SSP2"
jj_page09damages = false
jj_permafr = true
jj_seaice = true
jj_civvalue = 1.

# define the persistence (which should differ across runs) - VARY THIS ACROSS WORKERS
jj_ge = parse(Float64, ARGS[1]) * 0.1 # range to be covered: [0:0.1:1;]

# define the adaptation parameter
jj_geadapt = parse(Float64, ARGS[2]) * 0.005 # range to be covered: [0:0.005:0.04] - VARY THIS ACROSS WORKERS

# throw an error to halt the process if zero persistence is combined with non-zero adaptation (which is redundant)
if jj_geadapt > 0. && jj_ge == 0.
    error("This combination of persistence and adaptation is redundant and the process has been interrupted")
end

################################################################################
################### MC MODEL RUNS    ###########################################
################################################################################

# define the output for the Monte Carlo files
dir_MCoutput = string(dir_output, "montecarlo-singleGE/scen", jj_scen, "_permafr", jj_permafr, "_seaice", jj_seaice,
                                    "_page09", jj_page09damages, "/", "ge", jj_ge,
                                    "_geadapt", jj_geadapt,
                                    "_civ", jj_civvalue, "/")

# fix the seed and calculate the SCC
Random.seed!(masterseed)
scc_mcs_object = get_scc_mcs(samplesize, 2020, dir_MCoutput,
                            scenario=jj_scen,
                            pulse_size=scc_pulse_size,
                            use_permafrost=jj_permafr,
                            use_seaice=jj_seaice,
                            use_page09damages=jj_page09damages,
                            ge_minimum=jj_ge,
                            ge_maximum=jj_ge + 10^(-20),
                            ge_mode=jj_ge,
                            civvalue_multiplier=jj_civvalue,
                            geadrate = jj_geadapt)

# save out all relevant SCC summary stats into a Dataframe
df_sccMC_singleGE = DataFrame(damagePAGE09=jj_page09damages,
                            permafr=jj_permafr,
                            seaice=jj_seaice,
                            ge=jj_ge,
                            scen=jj_scen,
                            pulse_size=scc_pulse_size,
                            civvalue=jj_civvalue,
                            ge_adapt = jj_geadapt,
                            mean=mean(scc_mcs_object[:, 1]),
                            median=median(scc_mcs_object[:, 1]),
                            min=minimum(scc_mcs_object[:, 1]),
                            max=maximum(scc_mcs_object[:, 1]),
                            perc25=StatsBase.percentile(scc_mcs_object[:, 1], 25),
                            perc75=StatsBase.percentile(scc_mcs_object[:, 1], 75),
                            sd=Statistics.std(scc_mcs_object[:, 1]),
                            varcoeff=Statistics.std(scc_mcs_object[:, 1]) / mean(scc_mcs_object[:, 1]),
                            perc05=StatsBase.percentile(scc_mcs_object[:, 1], 5),
                            perc95=StatsBase.percentile(scc_mcs_object[:, 1], 95),
                            perc10=StatsBase.percentile(scc_mcs_object[:, 1], 10),
                            perc90=StatsBase.percentile(scc_mcs_object[:, 1], 90),
                            share_zeroSCC = count(scc_mcs_object .== 0.) / samplesize)

# write out the SCC distribution
writedlm(string(dir_MCoutput, "SCC_MC.csv"),
                        scc_mcs_object, ",")

# export the results DataFrame
CSV.write(string(dir_MCoutput, "MimiPageGrowthEffectsResults_SCC_fixedGE.csv"), df_sccMC_singleGE)
