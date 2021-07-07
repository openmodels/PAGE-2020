using Mimi
using CSV
using DataFrames

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

# set global values for technical configuration options
set_globalbools()

# get main_model file
include("main_model_annual.jl")
include("mcs_annual.jl")
include("compute_scc_annual.jl")

if !@isdefined samplesize
    samplesize = 50000
end

for scenario in ["RCP1.9 & SSP1", "RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
    model = "PAGE-ANN"
    # define model, default settings: getpage(NDCs scenario, permafrost, no sea-ice, no page09damages)
    m = getpage(scenario, true, true)
    # run model
    run(m)

    # open up Explorer UI, for visual exploration of the variables
    # explore(m)

    # do general monte carlo simulation and save the output
    do_monte_carlo_runs(samplesize, scenario, joinpath(@__DIR__, "../../output", scenario, model))

    # get the social cost of carbon for the Monte Carlo simulations and save the output
    sccs = compute_scc_mcs(m, samplesize, year=2020)
    # store results in DataFrame
    df = DataFrame(Any[fill(model, samplesize), fill(scenario, samplesize), sccs], [:ModelName, :ScenarioName, :SCC])
    # write out to csv
    DIR = joinpath(@__DIR__, "..", "../output")
    CSV.write(joinpath(DIR, string(model, "_", scenario, "_", "scc.csv")), df)
end
