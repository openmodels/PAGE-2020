@defcomp RCPSSPScenario begin
    region = Index()

    rcp::String = Parameter() # like rcp26
    ssp::String = Parameter() # like ssp1

    weight_scenarios = Parameter(unit="%") # from -100% to 100%, only used for sspw, rcpw

    extra_abate_rate = Parameter(unit="%/year") # only used for rcp26extra
    extra_abate_start = Parameter(unit="year")
    extra_abate_end = Parameter(unit="year")

    # RCP scenario values
    er_CO2emissionsgrowth = Variable(index=[time,region], unit="%")
    er_CH4emissionsgrowth = Variable(index=[time,region], unit="%")
    er_N2Oemissionsgrowth = Variable(index=[time,region], unit="%")
    er_LGemissionsgrowth = Variable(index=[time,region], unit="%")
    pse_sulphatevsbase = Variable(index=[time, region], unit="%")
    exf_excessforcing = Variable(index=[time], unit="W/m2")

    extra_abate_compound = Variable(index=[time])

    # SSP scenario values
    popgrw_populationgrowth = Variable(index=[time, region], unit="%/year") # From p.32 of Hope 2009
    grw_gdpgrowthrate = Variable(index=[time, region], unit="%/year") #From p.32 of Hope 2009


    function init(p, v, d)
        # Set the RCP values
        if rcp == "rcpw"
            v.er_CO2emissionsgrowth =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_co2.csv"), readpagedata(nothing, "data/rcps/rcp45_co2.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_co2.csv"), p.weight_scenarios)
            v.er_CH4emissionsgrowth =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_ch4.csv"), readpagedata(nothing, "data/rcps/rcp45_ch4.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_ch4.csv"), p.weight_scenarios)
            v.er_N2Oemissionsgrowth =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_n2o.csv"), readpagedata(nothing, "data/rcps/rcp45_n2o.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_n2o.csv"), p.weight_scenarios)
            v.er_LGemissionsgrowth =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_lin.csv"), readpagedata(nothing, "data/rcps/rcp45_lin.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_lin.csv"), p.weight_scenarios)
            v.pse_sulphatevsbase =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_sulph.csv"), readpagedata(nothing, "data/rcps/rcp45_sulph.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_sulph.csv"), p.weight_scenarios)
            v.exf_excessforcing =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_excess.csv"), readpagedata(nothing, "data/rcps/rcp45_excess.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_excess.csv"), p.weight_scenarios)
        elseif rcp == "rcp26extra"
            # Fill in within run_timestep
        elseif rcp == "zero"
            v.er_CO2emissionsgrowth = 0.
            v.er_CH4emissionsgrowth = 0.
            v.er_N2Oemissionsgrowth = 0.
            v.er_LGemissionsgrowth = 0.
            v.pse_sulphatevsbase = 0.
            v.exf_excessforcing = 0.
        else
            v.er_CO2emissionsgrowth = readpagedata(nothing, "data/rcps/$(rcp)_co2.csv")
            v.er_CH4emissionsgrowth = readpagedata(nothing, "data/rcps/$(rcp)_ch4.csv")
            v.er_N2Oemissionsgrowth = readpagedata(nothing, "data/rcps/$(rcp)_n2o.csv")
            v.er_LGemissionsgrowth = readpagedata(nothing, "data/rcps/$(rcp)_lin.csv")
            v.pse_sulphatevsbase = readpagedata(nothing, "data/rcps/$(rcp)_sulph.csv")
            v.exf_excessforcing = readpagedata(nothing, "data/rcps/$(rcp)_excess.csv")
        end

        # Set the SSP values
        if ssp == "ssp234" || ssp == "sspw"
            v.popgrw_populationgrowth = (readpagedata(nothing, "data/ssps/ssp2_pop_rate.csv") +
                                   readpagedata(nothing, "data/ssps/ssp3_pop_rate.csv") +
                                   readpagedata(nothing, "data/ssps/ssp4_pop_rate.csv")) / 3
            v.grw_gdpgrowthrate = (readpagedata(nothing, "data/ssps/ssp2_gdp_rate.csv") +
                                         readpagedata(nothing, "data/ssps/ssp3_gdp_rate.csv") +
                                         readpagedata(nothing, "data/ssps/ssp4_gdp_rate.csv")) / 3
            if ssp == "sspw"
                v.popgrw_populationgrowth =
                    weighted_scenario(readpagedata(nothing, "data/ssps/ssp1_pop_rate.csv"), p.popgrw_populationgrowth,
                                      readpagedata(nothing, "data/ssps/ssp5_pop_rate.csv"), p.weight_scenarios)
                v.grw_gdpgrowthrate =
                    weighted_scenario(readpagedata(nothing, "data/ssps/ssp1_gdp_rate.csv"), p.grw_gdpgrowthrate,
                                      readpagedata(nothing, "data/ssps/ssp5_gdp_rate.csv"), p.weight_scenarios)
            end
        else
            v.popgrw_populationgrowth = readpagedata(nothing, "data/ssps/$(ssp)_pop_rate.csv")
            v.grw_gdpgrowthrate = readpagedata(nothing, "data/ssps/$(ssp)_gdp_rate.csv")
        end
    end

    function run_timestep(p, v, d, t)
        # Only used for rcp26extra
        if rcp == "rcp26extra"
            if is_first(t)
                duration = 5
            else
                duration = p.year[t] - p.year[t-1]
            end

            extra_abate_period = ifelse(p.year[t] <= extra_abate_start || p.year[t] > extra_abate_end, 1.,
                                        (1 - extra_abate_rate / 100.)^duration)
            if is_first(t)
                v.extra_abate_compound[t] = extra_abate_period
            else
                v.extra_abate_compound[t] = extra_abate_period * v.extra_abate_compound[t-1]
            end

            er_rcp26_CO2emissionsgrowth = readpagedata(nothing, "data/rcps/rcp26_co2.csv")
            er_rcp26_CH4emissionsgrowth = readpagedata(nothing, "data/rcps/rcp26_ch4.csv")
            er_rcp26_N2Oemissionsgrowth = readpagedata(nothing, "data/rcps/rcp26_n2o.csv")
            er_rcp26_LGemissionsgrowth = readpagedata(nothing, "data/rcps/rcp26_lin.csv")
            pse_rcp26_sulphatevsbase = readpagedata(nothing, "data/rcps/rcp26_sulph.csv")
            exf_rcp26_excessforcing = readpagedata(nothing, "data/rcps/rcp26_excess.csv")

            v.er_CO2emissionsgrowth[t, :] = (er_rcp26_CO2emissionsgrowth[t, :] - er_rcp26_CO2emissionsgrowth[p.y_year == 2100, :]) * v.extra_abate_compound[t] + er_rcp26_CO2emissionsgrowth[p.y_year == 2100, :]
            v.er_CH4emissionsgrowth[t, :] = (er_rcp26_CH4emissionsgrowth[t, :] - er_rcp26_CH4emissionsgrowth[p.y_year == 2100, :]) * v.extra_abate_compound[t] + er_rcp26_CH4emissionsgrowth[p.y_year == 2100, :]
            v.er_N2Oemissionsgrowth[t, :] = (er_rcp26_N2Oemissionsgrowth[t, :] - er_rcp26_N2Oemissionsgrowth[p.y_year == 2100, :]) * v.extra_abate_compound[t] + er_rcp26_N2Oemissionsgrowth[p.y_year == 2100, :]
            v.er_LGemissionsgrowth[t, :] = (er_rcp26_LGemissionsgrowth[t, :] - er_rcp26_LGemissionsgrowth[p.y_year == 2100, :]) * v.extra_abate_compound[t] + er_rcp26_LGemissionsgrowth[p.y_year == 2100, :]
            v.pse_sulphatevsbase[t, :] = (pse_rcp26_sulphatevsbase[t, :] - pse_rcp26_sulphatevsbase[p.y_year == 2100, :]) * v.extra_abate_compound[t] + pse_rcp26_sulphatevsbase[p.y_year == 2100, :]
            v.exf_rcp26_excessforcing[t, :] = (exf_rcp26_excessforcing[t, :] - exf_rcp26_excessforcing[p.y_year == 2100, :]) * v.extra_abate_compound[t] + exf_rcp26_excessforcing[p.y_year == 2100, :]
        end
    end
end

function weighted_scenario(lowscen, medscen, highscen, weight)
    lowscen * .25 * (1 - p.weight_scenarios/100)^2 +
        medscen * .5 * (1 - (p.weight_scenarios/100)^2) +
        highscen * .25 * (1 + p.weight_scenarios/100)^2
end

function addrcpsspscenarios(model::Model, scenario::String)
    rcpsspscenario = add_comp!(model, RCPSSPScenario)

    if scenario == "Zero Emissions & SSP1"
        rcpsspscenario[:rcp] = "zero"
        rcpsspscenario[:ssp] = "ssp1"
    elseif sceanario == "1.5 degC Target"
        rcpsspscenario[:rcp] = "rcp26extra"
        rcpsspscenario[:ssp] = "ssp1"
        rcpsspscenario[:extra_abate_rate] = 4.053014079712271
        rcpsspscenario[:extra_abate_start] = 2020
        rcpsspscenario[:extra_abate_end] = 2100
    elseif scenario == "2 degC Target"
        rcpsspscenario[:rcp] = "rcp26extra"
        rcpsspscenario[:ssp] = "ssp1"
        rcpsspscenario[:extra_abate_rate] = 0.2418203462401034
        rcpsspscenario[:extra_abate_start] = 2020
        rcpsspscenario[:extra_abate_end] = 2100
    elseif scenario == "2.5 degC Target"
        rcpsspscenario[:rcp] = "rcpw"
        rcpsspscenario[:ssp] = "sspw"
        rcpsspscenario[:weight_scenarios] = -69.69860118334117
    elseif scenario == "NDCs"
        rcpsspscenario[:rcp] = "rcpw"
        rcpsspscenario[:ssp] = "sspw"
        rcpsspscenario[:weight_scenarios] = -14.432092365610856
    elseif scenario == "NDCs Partial"
        rcpsspscenario[:rcp] = "rcpw"
        rcpsspscenario[:ssp] = "sspw"
        rcpsspscenario[:weight_scenarios] = 10.318413035360622
    elseif scenario == "BAU"
        rcpsspscenario[:rcp] = "rcpw"
        rcpsspscenario[:ssp] = "sspw"
        rcpsspscenario[:weight_scenarios] = 51.579276825415874
    elseif scenario == "RCP2.6 & SSP1"
        rcpsspscenario[:rcp] = "rcp26"
        rcpsspscenario[:ssp] = "ssp1"
    elseif scenario == "RCP4.5 & SSP2"
        rcpsspscenario[:rcp] = "rcp45"
        rcpsspscenario[:ssp] = "ssp2"
    elseif scenario == "RCP8.5 & SSP5"
        rcpsspscenario[:rcp] = "rcp85"
        rcpsspscenario[:ssp] = "ssp5"
    else
        error("Unknown scenario")
    end

    rcpsspscenario
end