using Mimi
using Distributions
using CSVFiles
using DataFrames
using CSV
using Random
using StatsBase
using Statistics


# get main_model file
include("../../src/main_model.jl")
include("../../src/mcs.jl")
include("../../src/compute_scc.jl")

if !@isdefined samplesize
    samplesize = 50000
end

for scenario in ["RCP1.9 & SSP1", "RCP2.6 & SSP1", "RCP4.5 & SSP2", "RCP8.5 & SSP5"]
    model = "PAGE-ICE"
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
    DIR = joinpath(@__DIR__, "..", "..", "output")
    CSV.write(joinpath(DIR, string(model, "_", scenario, "_", "scc.csv")), df)
end
