## Mapping, until Mimi can handle string parameters:
## String -> Int64
## "zero" -> 0, "rcp19" -> 19, "rcp26" -> 26, "rcp45" -> 45, "rcp85" -> 85, "rcpw" -> 10, "rcp26extra" -> 260
## "ssp1" -> 1, "ssp2" -> 2, "ssp5" -> 5, "sspw" -> 10, "ssp234" -> 234
## $(rcp) -> rcp$(rcp), $(ssp) -> ssp$(ssp)

@defcomp RCPSSPScenario begin
    region = Index()

    rcp = Parameter{Int64}() # like rcp26
    ssp = Parameter{Int64}() # like ssp1

    y_year = Parameter(index=[time], unit="year")
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
    grw_gdpgrowthrate = Variable(index=[time, region], unit="%/year") # From p.32 of Hope 2009


    function init(p, v, d)
        # Set the RCP values
        if p.rcp == 10
            v.er_CO2emissionsgrowth[:, :] =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_co2.csv"), readpagedata(nothing, "data/rcps/rcp45_co2.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_co2.csv"), p.weight_scenarios)
            v.er_CH4emissionsgrowth[:, :] =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_ch4.csv"), readpagedata(nothing, "data/rcps/rcp45_ch4.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_ch4.csv"), p.weight_scenarios)
            v.er_N2Oemissionsgrowth[:, :] =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_n2o.csv"), readpagedata(nothing, "data/rcps/rcp45_n2o.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_n2o.csv"), p.weight_scenarios)
            v.er_LGemissionsgrowth[:, :] =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_lin.csv"), readpagedata(nothing, "data/rcps/rcp45_lin.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_lin.csv"), p.weight_scenarios)
            v.pse_sulphatevsbase[:, :] =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_sulph.csv"), readpagedata(nothing, "data/rcps/rcp45_sulph.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_sulph.csv"), p.weight_scenarios)
            v.exf_excessforcing[:] =
                weighted_scenario(readpagedata(nothing, "data/rcps/rcp26_excess.csv"), readpagedata(nothing, "data/rcps/rcp45_excess.csv"),
                                  readpagedata(nothing, "data/rcps/rcp85_excess.csv"), p.weight_scenarios)
        elseif p.rcp == 260
            # Fill in within run_timestep
        elseif p.rcp == 0
            v.er_CO2emissionsgrowth[:, :] .= 0.
            v.er_CH4emissionsgrowth[:, :] .= 0.
            v.er_N2Oemissionsgrowth[:, :] .= 0.
            v.er_LGemissionsgrowth[:, :] .= 0.
            v.pse_sulphatevsbase[:, :] .= 0.
            v.exf_excessforcing[:] .= 0.
        else
            v.er_CO2emissionsgrowth[:, :] = readpagedata(nothing, "data/rcps/rcp$(p.rcp)_co2.csv")
            v.er_CH4emissionsgrowth[:, :] = readpagedata(nothing, "data/rcps/rcp$(p.rcp)_ch4.csv")
            v.er_N2Oemissionsgrowth[:, :] = readpagedata(nothing, "data/rcps/rcp$(p.rcp)_n2o.csv")
            v.er_LGemissionsgrowth[:, :] = readpagedata(nothing, "data/rcps/rcp$(p.rcp)_lin.csv")
            v.pse_sulphatevsbase[:, :] = readpagedata(nothing, "data/rcps/rcp$(p.rcp)_sulph.csv")
            v.exf_excessforcing[:] = readpagedata(nothing, "data/rcps/rcp$(p.rcp)_excess.csv")
        end

        # Set the SSP values
        if p.ssp == 234 || p.ssp == 10
            v.popgrw_populationgrowth[:, :] = (readpagedata(nothing, "data/ssps/ssp2_pop_rate.csv") +
                                   readpagedata(nothing, "data/ssps/ssp3_pop_rate.csv") +
                                   readpagedata(nothing, "data/ssps/ssp4_pop_rate.csv")) / 3
            v.grw_gdpgrowthrate[:, :] = (readpagedata(nothing, "data/ssps/ssp2_gdp_rate.csv") +
                                         readpagedata(nothing, "data/ssps/ssp3_gdp_rate.csv") +
                                         readpagedata(nothing, "data/ssps/ssp4_gdp_rate.csv")) / 3
            if p.ssp == 10
                v.popgrw_populationgrowth[:, :] =
                    weighted_scenario(readpagedata(nothing, "data/ssps/ssp1_pop_rate.csv"), v.popgrw_populationgrowth[:, :],
                                      readpagedata(nothing, "data/ssps/ssp5_pop_rate.csv"), p.weight_scenarios)
                v.grw_gdpgrowthrate[:, :] =
                    weighted_scenario(readpagedata(nothing, "data/ssps/ssp1_gdp_rate.csv"), v.grw_gdpgrowthrate[:, :],
                                      readpagedata(nothing, "data/ssps/ssp5_gdp_rate.csv"), p.weight_scenarios)
            end
        else
            v.popgrw_populationgrowth[:, :] = readpagedata(nothing, "data/ssps/ssp$(p.ssp)_pop_rate.csv")
            v.grw_gdpgrowthrate[:, :] = readpagedata(nothing, "data/ssps/ssp$(p.ssp)_gdp_rate.csv")
        end
    end

    function run_timestep(p, v, d, t)
        # Only used for rcp26extra
        if p.rcp == 260
            if is_first(t)
                duration = 5
            else
                duration = p.y_year[t] - p.y_year[t - 1]
            end

            extra_abate_period = ifelse(p.y_year[t] <= p.extra_abate_start || p.y_year[t] > p.extra_abate_end, 1.,
                                        (1 - p.extra_abate_rate / 100.)^duration)
            if is_first(t)
                v.extra_abate_compound[t] = extra_abate_period
            else
                v.extra_abate_compound[t] = extra_abate_period * v.extra_abate_compound[t - 1]
            end

            er_rcp26_CO2emissionsgrowth = readpagedata(nothing, "data/rcps/rcp26_co2.csv")
            er_rcp26_CH4emissionsgrowth = readpagedata(nothing, "data/rcps/rcp26_ch4.csv")
            er_rcp26_N2Oemissionsgrowth = readpagedata(nothing, "data/rcps/rcp26_n2o.csv")
            er_rcp26_LGemissionsgrowth = readpagedata(nothing, "data/rcps/rcp26_lin.csv")
            pse_rcp26_sulphatevsbase = readpagedata(nothing, "data/rcps/rcp26_sulph.csv")
            exf_rcp26_excessforcing = readpagedata(nothing, "data/rcps/rcp26_excess.csv")

            v.er_CO2emissionsgrowth[t, :] = (er_rcp26_CO2emissionsgrowth[t.t, :] - er_rcp26_CO2emissionsgrowth[p.y_year[:] .== 2100, :][:]) * v.extra_abate_compound[t] .+ er_rcp26_CO2emissionsgrowth[p.y_year[:] .== 2100, :][:]
            v.er_CH4emissionsgrowth[t, :] = er_rcp26_CH4emissionsgrowth[t.t, :] * v.extra_abate_compound[t]
            v.er_N2Oemissionsgrowth[t, :] = er_rcp26_N2Oemissionsgrowth[t.t, :] * v.extra_abate_compound[t]
            v.er_LGemissionsgrowth[t, :] = er_rcp26_LGemissionsgrowth[t.t, :] * v.extra_abate_compound[t]
            v.pse_sulphatevsbase[t, :] = pse_rcp26_sulphatevsbase[t.t, :] * v.extra_abate_compound[t]
            v.exf_excessforcing[t, :] = exf_rcp26_excessforcing[t.t, :] * v.extra_abate_compound[t]
        end
    end
end

function weighted_scenario(lowscen, medscen, highscen, weight)
    lowscen * .25 * (1 - weight / 100)^2 +
        medscen * .5 * (1 - (weight / 100)^2) +
        highscen * .25 * (1 + weight / 100)^2
end

function addrcpsspscenario(model::Model, scenario::String)
    rcpsspscenario = add_comp!(model, RCPSSPScenario)

    # Default parameters
    rcpsspscenario[:y_year] = Mimi.dim_keys(model.md, :time)
    rcpsspscenario[:extra_abate_rate] = 0
    rcpsspscenario[:extra_abate_start] = 2015
    rcpsspscenario[:extra_abate_end] = 2100
    rcpsspscenario[:weight_scenarios] = 0.

    if scenario == "Zero Emissions & SSP1"
        rcpsspscenario[:rcp] = 0
        rcpsspscenario[:ssp] = 1
    elseif scenario == "1.5 degC Target"
        rcpsspscenario[:rcp] = 260
        rcpsspscenario[:ssp] = 1
        rcpsspscenario[:extra_abate_rate] = 4.053014079712271
        rcpsspscenario[:extra_abate_start] = 2020
        rcpsspscenario[:extra_abate_end] = 2100
    elseif scenario == "2 degC Target"
        rcpsspscenario[:rcp] = 260
        rcpsspscenario[:ssp] = 1
        rcpsspscenario[:extra_abate_rate] = 0.2418203462401034
        rcpsspscenario[:extra_abate_start] = 2020
        rcpsspscenario[:extra_abate_end] = 2100
    elseif scenario == "2.5 degC Target"
        rcpsspscenario[:rcp] = 10
        rcpsspscenario[:ssp] = 10
        rcpsspscenario[:weight_scenarios] = -69.69860118334117
    elseif scenario == "NDCs"
        rcpsspscenario[:rcp] = 10
        rcpsspscenario[:ssp] = 10
        rcpsspscenario[:weight_scenarios] = -14.432092365610856
    elseif scenario == "NDCs Partial"
        rcpsspscenario[:rcp] = 10
        rcpsspscenario[:ssp] = 10
        rcpsspscenario[:weight_scenarios] = 10.318413035360622
    elseif scenario == "BAU"
        rcpsspscenario[:rcp] = 10
        rcpsspscenario[:ssp] = 10
        rcpsspscenario[:weight_scenarios] = 51.579276825415874
    elseif scenario == "RCP1.9 & SSP1"
        rcpsspscenario[:rcp] = 19
        rcpsspscenario[:ssp] = 1
    elseif scenario == "RCP2.6 & SSP1"
        rcpsspscenario[:rcp] = 26
        rcpsspscenario[:ssp] = 1
    elseif scenario == "RCP4.5 & SSP2"
        rcpsspscenario[:rcp] = 45
        rcpsspscenario[:ssp] = 2
    elseif scenario == "RCP8.5 & SSP5"
        rcpsspscenario[:rcp] = 85
        rcpsspscenario[:ssp] = 5
    elseif scenario == "RCP8.5 & SSP2"
        rcpsspscenario[:rcp] = 85
        rcpsspscenario[:ssp] = 2
    else
        error("Unknown scenario")
    end

    rcpsspscenario
end
