using Mimi

include("../../src/compute_scc.jl")

function setorup_param!(m::Model, param::Symbol, value)
    try
        set_param!(m, param, value)
    catch e
        update_param!(m, param, value)
    end
end

"""
Applies undiscounting factor to get the SCC, discounted to the emissions year instead of the base year.
"""
function undiscount_scc(m::Model, year::Int)
    df = m[:EquityWeighting, :df_utilitydiscountfactor_ann]
    consfocus0 = m[:GDP, :cons_percap_consumption_0][1]
    consfocus = m[:GDP, :cons_percap_consumption_ann][:, 1]
    emuc = m[:EquityWeighting, :emuc_utilityconvexity]
    sccii = getpageindexfromyear(year)

    return df[sccii] * ((consfocus[sccii] / consfocus0)^-emuc)
end
"""
compute_scc(m::Model = get_model(); year::Union{Int, Nothing} = nothing, eta::Union{Float64, Nothing} = nothing, prtp::Union{Float64, Nothing} = nothing)

Computes the social cost of CO2 for an emissions pulse in `year` for the provided Mimi-PAGE model.
If no model is provided, the default model from main_model.get_model() is used.
Discounting scheme can be specified by the `eta` and `prtp` parameters, which will update the values of emuc_utilitiyconvexity and ptp_timepreference in the model.
If no values are provided, the discount factors will be computed using the default PAGE values of emuc_utilitiyconvexity=1.1666666667 and ptp_timepreference=1.0333333333.
"""
function compute_scc(m::Model=get_model(); year::Union{Int,Nothing}=nothing, eta::Union{Float64,Nothing}=nothing, prtp::Union{Float64,Nothing}=nothing, pulse_size=75000.)
    year === nothing ? error("Must specify an emission year. Try `compute_scc(m, year=2020)`.") : nothing
    !(year in page_years) ? error("Cannot compute the scc for year $year, year must be within the model's time index $page_years.") : nothing

    eta == nothing ? nothing : setorup_param!(m, :emuc_utilityconvexity, eta)
    prtp == nothing ? nothing : setorup_param!(m, :ptp_timepreference, prtp * 100.)

    mm = get_marginal_model(m, year=year, pulse_size=pulse_size)   # Returns a marginal model that has already been run
    scc = mm[:EquityWeighting, :td_totaldiscountedimpacts_ann] / undiscount_scc(mm.base, year)

    return scc
end

"""
compute_scc_mm(m::Model = get_model(); year::Union{Int, Nothing} = nothing, eta::Union{Float64, Nothing} = nothing, prtp::Union{Float64, Nothing} = nothing)

Returns a NamedTuple (scc=scc, mm=mm) of the social cost of carbon and the MarginalModel used to compute it.
Computes the social cost of CO2 for an emissions pulse in `year` for the provided Mimi-PAGE model.
If no model is provided, the default model from main_model.get_model() is used.
Discounting scheme can be specified by the `eta` and `prtp` parameters, which will update the values of emuc_utilitiyconvexity and ptp_timepreference in the model.
If no values are provided, the discount factors will be computed using the default PAGE values of emuc_utilitiyconvexity=1.1666666667 and ptp_timepreference=1.0333333333.
"""
function compute_scc_mm(m::Model=get_model(); year::Union{Int,Nothing}=nothing, eta::Union{Float64,Nothing}=nothing, prtp::Union{Float64,Nothing}=nothing, pulse_size=75000.)
    year === nothing ? error("Must specify an emission year. Try `compute_scc(m, year=2020)`.") : nothing
    !(year in page_years) ? error("Cannot compute the scc for year $year, year must be within the model's time index $page_years.") : nothing

    eta == nothing ? nothing : setorup_param!(m, :emuc_utilityconvexity, eta)
    prtp == nothing ? nothing : setorup_param!(m, :ptp_timepreference, prtp * 100.)

    mm = get_marginal_model(m, year=year, pulse_size=pulse_size)   # Returns a marginal model that has already been run
    scc = mm[:EquityWeighting, :td_totaldiscountedimpacts_ann] / undiscount_scc(mm.base, year)
    scc_disaggregated = mm[:EquityWeighting, :addt_equityweightedimpact_discountedaggregated_ann] / undiscount_scc(mm.base, year)

    return (scc = scc, scc_disaggregated = scc_disaggregated, mm = mm)
end

"""
get_marginal_model(m::Model = get_model(); year::Union{Int, Nothing} = nothing)
Returns a Mimi MarginalModel where the provided m is the base model, and the marginal model has additional emissions of CO2 in year `year`.
If no Model m is provided, the default model from main_model.get_model() is used as the base model.
Note that the returned MarginalModel has already been run.
"""
function get_marginal_model(m::Model=get_model(); year::Union{Int,Nothing}=nothing, pulse_size=75000.)
    year === nothing ? error("Must specify an emission year. Try `get_marginal_model(m, year=2020)`.") : nothing
    !(year in page_years) ? error("Cannot add marginal emissions in $year, year must be within the model's time index $page_years.") : nothing

    mm = create_marginal_model(m, pulse_size)

    add_comp!(mm.modified, ExtraEmissions, :extra_emissions; after=:co2emissions)
    connect_param!(mm.modified, :extra_emissions => :e_globalCO2emissions, :co2emissions => :e_globalCO2emissions)
    set_param!(mm.modified, :extra_emissions, :pulse_size, pulse_size)
    set_param!(mm.modified, :extra_emissions, :pulse_year, year)

    connect_param!(mm.modified, :CO2Cycle => :e_globalCO2emissions, :extra_emissions => :e_globalCO2emissions_adjusted)

    run(mm)
    return mm
end

function compute_scc_mcs(m::Model, samplesize::Int; year::Union{Int,Nothing}=nothing, eta::Union{Float64,Nothing}=nothing, prtp::Union{Float64,Nothing}=nothing, pulse_size=75000.)
    # Setup of location of final results
    scc_results = zeros(samplesize)

    function mc_scc_calculation(sim_inst::SimulationInstance, trialnum::Int, ntimesteps::Int, ignore::Nothing)
        marginal = sim_inst.models[1]
        marg_damages = marginal[:EquityWeighting, :td_totaldiscountedimpacts_ann] / undiscount_scc(mm.base, year)
        scc_results[trialnum] = marg_damages
    end

    # get simulation
    mcs = getsim()

    # Setup models
    eta == nothing ? nothing : setorup_param!(m, :emuc_utilityconvexity, eta)
    prtp == nothing ? nothing : setorup_param!(m, :ptp_timepreference, prtp * 100.)

    mm = get_marginal_model(m, year=year, pulse_size=pulse_size)   # Returns a marginal model that has already been run

    # Run
    res = run(mcs, mm, samplesize; post_trial_func=mc_scc_calculation)

    scc_results
end
