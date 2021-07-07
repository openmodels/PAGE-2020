using Mimi
using CSV

## Notes:
## Applied PAGE09 weighting is non-stochastic

include("../src/main_model.jl")

for scenario in ["RCP4.5 & SSP2", "RCP8.5 & SSP5", "RCP1.9 & SSP1", "RCP2.6 & SSP1"]

    m0 = getpage(scenario, false, false, true; use_page09weights=true, page09_discontinuity=true, page09_sealevelrise=true) # just updating climate
    set_param!(m0, :NonMarketDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m0, :SLRDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m0, :MarketDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    m1 = getpage(scenario, false, false, true; use_page09weights=true, page09_discontinuity=true) # long-tailed SLR
    set_param!(m1, :NonMarketDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m1, :SLRDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m1, :MarketDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    m2 = getpage(scenario, true, false, true; use_page09weights=true, page09_discontinuity=true) # no sea-ice, yes perma
    set_param!(m2, :NonMarketDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m2, :SLRDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m2, :MarketDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    m3 = getpage(scenario, true, true, true; use_page09weights=true, page09_discontinuity=true) # all arctic
    set_param!(m3, :NonMarketDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m3, :SLRDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m3, :MarketDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    m4 = getpage(scenario, true, true, true; use_page09weights=true) # reduced discontinuity
    set_param!(m4, :NonMarketDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m4, :SLRDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m4, :MarketDamages, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    set_param!(m4, :Discontinuity, :GDP_per_cap_focus_0_FocusRegionEU, 27934.244777382406)
    m5 = getpage(scenario, true, true, true; use_page09weights=true)  # update GDPpc_0
    m6 = getpage(scenario, true, true, true) # update weighting
    m7 = getpage(scenario, true, true, false) # full PAGE-ICE

    samplesize = 50000
    year = 2020
    pulse_size = 75000.

    # Setup of location of final results
    scc_results0 = zeros(samplesize)
    scc_results1 = zeros(samplesize)
    scc_results2 = zeros(samplesize)
    scc_results3 = zeros(samplesize)
    scc_results4 = zeros(samplesize)
    scc_results5 = zeros(samplesize)
    scc_results6 = zeros(samplesize)
    scc_results7 = zeros(samplesize)
    scc_results8 = zeros(samplesize)
    dmg_results0 = zeros(samplesize, 8)
    dmg_results1 = zeros(samplesize, 8)
    dmg_results2 = zeros(samplesize, 8)
    dmg_results3 = zeros(samplesize, 8)
    dmg_results4 = zeros(samplesize, 8)
    dmg_results5 = zeros(samplesize, 8)
    dmg_results6 = zeros(samplesize, 8)
    dmg_results7 = zeros(samplesize, 8)
    dmg_results8 = zeros(samplesize, 8)

    function mc_scc_calculation(sim_inst::SimulationInstance, trialnum::Int, ntimesteps::Int, ignore::Nothing)
        scc_results0[trialnum] = sim_inst.models[1][:EquityWeighting, :tdac_totalimpactandadaptation_2200]
        scc_results1[trialnum] = sim_inst.models[2][:EquityWeighting, :tdac_totalimpactandadaptation_2200]
        scc_results2[trialnum] = sim_inst.models[3][:EquityWeighting, :tdac_totalimpactandadaptation_2200]
        scc_results3[trialnum] = sim_inst.models[4][:EquityWeighting, :tdac_totalimpactandadaptation_2200]
        scc_results4[trialnum] = sim_inst.models[5][:EquityWeighting, :tdac_totalimpactandadaptation_2200]
        scc_results5[trialnum] = sim_inst.models[5][:EquityWeighting, :tdac_totalimpactandadaptation]
        scc_results6[trialnum] = sim_inst.models[6][:EquityWeighting, :tdac_totalimpactandadaptation]
        scc_results7[trialnum] = sim_inst.models[7][:EquityWeighting, :tdac_totalimpactandadaptation]
        scc_results8[trialnum] = sim_inst.models[8][:EquityWeighting, :tdac_totalimpactandadaptation]

        dmg_results0[trialnum, :] = sum(sim_inst.models[1][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][1:8, :] + sim_inst.models[1][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated][1:8, :], dims=1)
        dmg_results1[trialnum, :] = sum(sim_inst.models[2][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][1:8, :] + sim_inst.models[2][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated][1:8, :], dims=1)
        dmg_results2[trialnum, :] = sum(sim_inst.models[3][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][1:8, :] + sim_inst.models[3][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated][1:8, :], dims=1)
        dmg_results3[trialnum, :] = sum(sim_inst.models[4][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][1:8, :] + sim_inst.models[4][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated][1:8, :], dims=1)
        dmg_results4[trialnum, :] = sum(sim_inst.models[5][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated][1:8, :] + sim_inst.models[5][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated][1:8, :], dims=1)
        dmg_results5[trialnum, :] = sum(sim_inst.models[5][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] + sim_inst.models[5][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated], dims=1)
        dmg_results6[trialnum, :] = sum(sim_inst.models[6][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] + sim_inst.models[6][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated], dims=1)
        dmg_results7[trialnum, :] = sum(sim_inst.models[7][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] + sim_inst.models[7][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated], dims=1)
        dmg_results8[trialnum, :] = sum(sim_inst.models[8][:EquityWeighting, :addt_equityweightedimpact_discountedaggregated] + sim_inst.models[8][:EquityWeighting, :aact_equityweightedadaptation_discountedaggregated], dims=1)
    end

    # get simulation
    mcs = getsim()

    mm0 = get_marginal_model(m0, year=year, pulse_size=pulse_size)
    mm1 = get_marginal_model(m1, year=year, pulse_size=pulse_size)
    mm2 = get_marginal_model(m2, year=year, pulse_size=pulse_size)
    mm3 = get_marginal_model(m3, year=year, pulse_size=pulse_size)
    mm4 = get_marginal_model(m4, year=year, pulse_size=pulse_size)
    mm5 = get_marginal_model(m5, year=year, pulse_size=pulse_size)
    mm6 = get_marginal_model(m6, year=year, pulse_size=pulse_size)
    mm7 = get_marginal_model(m7, year=year, pulse_size=pulse_size)

    # Run
    res = run(mcs, [mm0, mm1, mm2, mm3, mm4, mm5, mm6, mm7], samplesize; post_trial_func=mc_scc_calculation)

    results = DataFrame(page09=scc_results0, bigslr=scc_results1, permaf=scc_results2, seaice=scc_results3, redisc=scc_results4,
                        to2300=scc_results5, gdppc0=scc_results6, newwts=scc_results7, burked=scc_results8)

    if scenario == "1.5 degC Target"
        suffix = "deg1p5"
    elseif scenario == "RCP1.9 & SSP1"
        suffix = "ssp119"
    elseif scenario == "RCP2.6 & SSP1"
        suffix = "ssp126"
    elseif scenario == "RCP4.5 & SSP2"
        suffix = "ssp245"
    elseif scenario == "RCP8.5 & SSP5"
        suffix = "ssp585"
    elseif scenario == "RCP8.5 & SSP2"
        suffix = "ssp285"
    end
    CSV.write("xscc-damages-$suffix.csv", results)

    using Tables
    CSV.write("page09-xreg-$suffix.csv", Tables.table(dmg_results0; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("bigslr-xreg-$suffix.csv", Tables.table(dmg_results1; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("permaf-xreg-$suffix.csv", Tables.table(dmg_results2; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("seaice-xreg-$suffix.csv", Tables.table(dmg_results3; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("redisc-xreg-$suffix.csv", Tables.table(dmg_results4; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("to2300-xreg-$suffix.csv", Tables.table(dmg_results5; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("gdppc0-xreg-$suffix.csv", Tables.table(dmg_results6; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("newwts-xreg-$suffix.csv", Tables.table(dmg_results7; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
    CSV.write("burked-xreg-$suffix.csv", Tables.table(dmg_results8; header=[:EU, :US, :OT, :EE, :CA, :IA, :AF, :LA]))
end
