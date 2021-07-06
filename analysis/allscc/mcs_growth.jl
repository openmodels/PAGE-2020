using Distributions
using DataFrames
using Mimi

include("../../src/utils/mctools.jl")

function setorup_param!(m::Model, param::Symbol, value)
    try
        set_param!(m, param, value)
    catch e
        update_param!(m, param, value)
    end
end

function getsim(ge_minimum::Union{Float64,Nothing}=nothing,
                ge_maximum::Union{Float64,Nothing}=nothing,
                ge_mode::Union{Float64,Nothing}=nothing,
                civvalue_multiplier::Union{Float64,Nothing}=1.)

    mcs = @defsim begin

        ############################################################################
        # Define random variables (RVs)
        ############################################################################

        # The folllowing RVs are in more than one component.  For clarity they are
        # set here as opposed to below within the blocks of RVs separated by component
        # so that they are not set more than once.

        save_savingsrate = TriangularDist(10, 20, 15) # components: MarketDamages, MarketDamagesBurke, NonMarketDamages. GDP, SLRDamages
        tcal_CalibrationTemp = TriangularDist(2.5, 3.5, 3.) # components: MarketDamages, NonMarketDamages, SLRDamages, Discountinuity

        wincf_weightsfactor_sea["USA"] = TriangularDist(.6, 1, .8) # components: SLRDamages, Discountinuity (weights for market and nonmarket are non-stochastic and uniformly 1)
        wincf_weightsfactor_sea["OECD"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["USSR"] = TriangularDist(.2, .6, .4)
        wincf_weightsfactor_sea["China"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["SEAsia"] = TriangularDist(.4, 1.2, .8)
        wincf_weightsfactor_sea["Africa"] = TriangularDist(.4, .8, .6)
        wincf_weightsfactor_sea["LatAmerica"] = TriangularDist(.4, .8, .6)

        automult_autonomoustechchange = TriangularDist(0.5, 0.8, 0.65)  # components: AdaptationCosts, AbatementCosts

        # The following RVs are divided into blocks by component

        # CO2cycle
        air_CO2fractioninatm = TriangularDist(57, 67, 62)
        res_CO2atmlifetime = TriangularDist(50, 100, 70)
        # ccf_CO2feedback = TriangularDist(0, 0, 0) # only usable if lb <> ub
        ccfmax_maxCO2feedback = TriangularDist(10, 30, 20)
        stay_fractionCO2emissionsinatm = TriangularDist(0.25, 0.35, 0.3)
        ce_0_basecumCO2emissions = TriangularDist(1830000, 2240000, 2040000)
        a1_percentco2oceanlong = TriangularDist(4.3,	41.6, 23.0)
        a2_percentco2oceanshort = TriangularDist(23.1, 30.1, 26.6)
        a3_percentco2land = TriangularDist(11.4, 42.5, 27.0)
        t1_timeco2oceanlong = TriangularDist(248.9, 376.2, 312.5)
        t2_timeco2oceanshort = TriangularDist(25.9, 43.9, 34.9)
        t3_timeco2land = TriangularDist(2.8, 5.7, 4.3)
        rt_g0_baseglobaltemp = TriangularDist(0.903, 0.989, 0.946)

        # SiBCASA Permafrost
        perm_sib_af = TriangularDist(1.42609149897258, 2.32504747848815, 1.87556948873036)
        perm_sib_sens_c_co2 = TriangularDist(28191.1555428869, 35688.3253432574, 31939.7404430722)
        perm_sib_lag_c_co2 = TriangularDist(35.4926669856915, 87.8949041341782, 61.6937855599349)
        perm_sib_pow_c_co2 = TriangularDist(0.107020247715729, 0.410961185142816, 0.258990716429273)
        perm_sib_sens_c_ch4 = TriangularDist(1240.3553299183, 3348.11995329232, 2294.23764160531)
        perm_sib_lag_c_ch4 = TriangularDist(75.1943160023131, 337.382510123922, 206.288413063117)
        perm_sib_pow_c_ch4 = TriangularDist(-0.108779283732708, 0.610889007954489, 0.25105486211089)

        # JULES Permafrost
        perm_jul_af = TriangularDist(1.70960411816136, 2.16221162526313, 1.93590787171224)
        perm_jul_sens_c_co2 = TriangularDist(24726.8035695649, 99008.7553497378, 61867.7794596514)
        perm_jul_lag_c_co2 = TriangularDist(252.558368389676, 834.674343162273, 543.616355775975)
        perm_jul_pow_c_co2 = TriangularDist(-0.226045987062471, 1.14010750072118, 0.457030756829357)
        perm_jul_ch4_co2_c_ratio = TriangularDist(2.77492291880781, 9.52902519167579, 6.04453870625663)

        # SulphateForcing
        d_sulphateforcingbase = TriangularDist(-0.8, -0.2, -0.4)
        ind_slopeSEforcing_indirect = TriangularDist(-0.8, 0, -0.4)

        # ClimateTemperature
        frt_warminghalflife = TriangularDist(10, 55, 20)        # from PAGE-ICE v6.2 documentation
        tcr_transientresponse = TriangularDist(0.8, 2.7, 1.8)   # from PAGE-ICE v6.2 documentation
        alb_emulator_rand = TriangularDist(-1., 1., 0.)
        ampf_amplification["EU"] = TriangularDist(1.05, 1.53, 1.23)
        ampf_amplification["USA"] = TriangularDist(1.16, 1.54, 1.32)
        ampf_amplification["OECD"] = TriangularDist(1.14, 1.31, 1.21)
        ampf_amplification["USSR"] = TriangularDist(1.41, 1.9, 1.64)
        ampf_amplification["China"] = TriangularDist(1, 1.3, 1.21)
        ampf_amplification["SEAsia"] = TriangularDist(0.84, 1.15, 1.04)
        ampf_amplification["Africa"] = TriangularDist(0.99, 1.42, 1.22)
        ampf_amplification["LatAmerica"] = TriangularDist(0.9, 1.18, 1.04)

        # SeaLevelRise
        s0_initialSL = TriangularDist(0.17, 0.21, 0.19)                             # taken from PAGE-ICE v6.20 default
        sltemp_SLtemprise = TriangularDist(0.7, 3., 1.5)                            # median sensitivity to GMST changes
        sla_SLbaselinerise = TriangularDist(0.5, 1.5, 1.)                           # asymptote for pre-industrial
        sltau_SLresponsetime = Gamma(16.0833333333333333, 24.)                      # fat-tailed distribution of time constant T_sl, sea level response time, from mode=362, mean = 386

        # GDP
        isat0_initialimpactfxnsaturation = TriangularDist(15, 25, 20)
        ge_growtheffects = TriangularDist(ge_minimum, ge_maximum, ge_mode)
        ge_seed_empiricaldistribution = Uniform(0, 10^10)

        # MarketDamages
        iben_MarketInitialBenefit = TriangularDist(0, .3, .1)
        W_MarketImpactsatCalibrationTemp = TriangularDist(.2, .8, .5)
        pow_MarketImpactExponent = TriangularDist(1.5, 3, 2)
        ipow_MarketIncomeFxnExponent = TriangularDist(-.3, 0, -.1)

        # MarketDamagesBurke
        impf_coeff_lin = TriangularDist(-0.0139791885347898, -0.0026206307945989, -0.00829990966469437)
        impf_coeff_quadr = TriangularDist(-0.000599999506482576, -0.000400007300924579, -0.000500003403703578)

        MarketDamagesBurke_rtl_abs_0_realizedabstemperature["EU"] = TriangularDist(6.76231496767033, 13.482086163781, 10.1222005657257)
        MarketDamagesBurke_rtl_abs_0_realizedabstemperature["USA"] = TriangularDist(9.54210085883826, 17.3151395362191, 13.4286201975287)
        MarketDamagesBurke_rtl_abs_0_realizedabstemperature["OECD"] = TriangularDist(9.07596053028087, 15.0507477943984, 12.0633541623396)
        MarketDamagesBurke_rtl_abs_0_realizedabstemperature["USSR"] = TriangularDist(3.01320548016903, 11.2132204366259, 7.11321295839747)
        MarketDamagesBurke_rtl_abs_0_realizedabstemperature["China"] = TriangularDist(12.2330402806912, 17.7928749427573, 15.0129576117242)
        MarketDamagesBurke_rtl_abs_0_realizedabstemperature["SEAsia"] = TriangularDist(23.3863348263352, 26.5136231383473, 24.9499789823412)
        MarketDamagesBurke_rtl_abs_0_realizedabstemperature["Africa"] = TriangularDist(20.1866940491107, 23.5978086497453, 21.892251349428)
        MarketDamagesBurke_rtl_abs_0_realizedabstemperature["LatAmerica"] = TriangularDist(19.4846849750102, 22.7561130637973, 21.1203990194037)

        # NonMarketDamages
        tcal_CalibrationTemp = TriangularDist(2.5, 3.5, 3.)
        iben_NonMarketInitialBenefit = TriangularDist(0, .2, .05)
        w_NonImpactsatCalibrationTemp = TriangularDist(.1, 1, .5)
        pow_NonMarketExponent = TriangularDist(1.5, 3, 2)
        ipow_NonMarketIncomeFxnExponent = TriangularDist(-.2, .2, 0)

        # SLRDamages
        scal_calibrationSLR = TriangularDist(0.45, 0.55, .5)
        # iben_SLRInitialBenefit = TriangularDist(0, 0, 0) # only usable if lb <> ub
        W_SatCalibrationSLR = TriangularDist(.5, 1.5, 1)
        pow_SLRImpactFxnExponent = TriangularDist(.5, 1, .7)
        ipow_SLRIncomeFxnExponent = TriangularDist(-.4, -.2, -.3)

        # Discontinuity
        rand_discontinuity = Uniform(0, 1)
        tdis_tolerabilitydisc = TriangularDist(1, 2, 1.5)
        pdis_probability = TriangularDist(10, 30, 20)
        wdis_gdplostdisc = TriangularDist(1, 5, 3)
        ipow_incomeexponent = TriangularDist(-.3, 0, -.1)
        distau_discontinuityexponent = TriangularDist(10, 30, 20)

        # EquityWeighting
        civvalue_civilizationvalue = TriangularDist(1e10 * civvalue_multiplier,
                                                    1e11 * civvalue_multiplier,
                                                    5e10 * civvalue_multiplier)
        ptp_timepreference = TriangularDist(0.1, 2, 1)
        emuc_utilityconvexity = TriangularDist(0.5, 2, 1)

        # AbatementCosts
        AbatementCostParametersCO2_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50, 6.0, -22)
        AbatementCostParametersCH4_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-67, 6.0, -30)
        AbatementCostParametersN2O_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-20, 6.0, -7.0)
        AbatementCostParametersLin_emit_UncertaintyinBAUEmissFactorinFocusRegioninFinalYear = TriangularDist(-50, 50, 0)

        AbatementCostParametersCO2_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 40, 20)
        AbatementCostParametersCH4_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 20, 10)
        AbatementCostParametersN2O_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 20, 10)
        AbatementCostParametersLin_q0propinit_CutbacksinNegativeCostinFocusRegioninBaseYear = TriangularDist(0, 20, 10)

        AbatementCostParametersCO2_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400, -100, -200)
        AbatementCostParametersCH4_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-8000, -1000, -4000)
        AbatementCostParametersN2O_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-15000, 0, -7000)
        AbatementCostParametersLin_c0init_MostNegativeCostCutbackinBaseYear = TriangularDist(-400, -100, -200)

        AbatementCostParametersCO2_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60, 80, 70)
        AbatementCostParametersCH4_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35, 70, 50)
        AbatementCostParametersN2O_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(35, 70, 50)
        AbatementCostParametersLin_qmaxminusq0propinit_MaxCutbackCostatPositiveCostinBaseYear = TriangularDist(60, 80, 70)

        AbatementCostParametersCO2_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100, 700, 400)
        AbatementCostParametersCH4_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(3000, 10000, 6000)
        AbatementCostParametersN2O_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(2000, 60000, 20000)
        AbatementCostParametersLin_cmaxinit_MaximumCutbackCostinFocusRegioninBaseYear = TriangularDist(100, 600, 300)

        AbatementCostParametersCO2_ies_InitialExperienceStockofCutbacks = TriangularDist(100000, 200000, 150000)
        AbatementCostParametersCH4_ies_InitialExperienceStockofCutbacks = TriangularDist(1500, 2500, 2000)
        AbatementCostParametersN2O_ies_InitialExperienceStockofCutbacks = TriangularDist(30, 80, 50)
        AbatementCostParametersLin_ies_InitialExperienceStockofCutbacks = TriangularDist(1500, 2500, 2000)

        # the following variables need to be set, but set the same in all 4 abatement cost components
        # note that for these regional variables, the first region is the focus region (EU), which is set in the preceding code, and so is always one for these variables

        emitf_uncertaintyinBAUemissfactor["USA"] = TriangularDist(0.8, 1.2, 1.0)
        emitf_uncertaintyinBAUemissfactor["OECD"] = TriangularDist(0.8, 1.2, 1.0)
        emitf_uncertaintyinBAUemissfactor["USSR"] = TriangularDist(0.65, 1.35, 1.0)
        emitf_uncertaintyinBAUemissfactor["China"] = TriangularDist(0.5, 1.5, 1.0)
        emitf_uncertaintyinBAUemissfactor["SEAsia"] = TriangularDist(0.5, 1.5, 1.0)
        emitf_uncertaintyinBAUemissfactor["Africa"] = TriangularDist(0.5, 1.5, 1.0)
        emitf_uncertaintyinBAUemissfactor["LatAmerica"] = TriangularDist(0.5, 1.5, 1.0)

        q0f_negativecostpercentagefactor["USA"] = TriangularDist(0.75, 1.5, 1.0)
        q0f_negativecostpercentagefactor["OECD"] = TriangularDist(0.75, 1.25, 1.0)
        q0f_negativecostpercentagefactor["USSR"] = TriangularDist(0.4, 1.0, 0.7)
        q0f_negativecostpercentagefactor["China"] = TriangularDist(0.4, 1.0, 0.7)
        q0f_negativecostpercentagefactor["SEAsia"] = TriangularDist(0.4, 1.0, 0.7)
        q0f_negativecostpercentagefactor["Africa"] = TriangularDist(0.4, 1.0, 0.7)
        q0f_negativecostpercentagefactor["LatAmerica"] = TriangularDist(0.4, 1.0, 0.7)

        cmaxf_maxcostfactor["USA"] = TriangularDist(0.8, 1.2, 1.0)
        cmaxf_maxcostfactor["OECD"] = TriangularDist(1.0, 1.5, 1.2)
        cmaxf_maxcostfactor["USSR"] = TriangularDist(0.4, 1.0, 0.7)
        cmaxf_maxcostfactor["China"] = TriangularDist(0.8, 1.2, 1.0)
        cmaxf_maxcostfactor["SEAsia"] = TriangularDist(1, 1.5, 1.2)
        cmaxf_maxcostfactor["Africa"] = TriangularDist(1, 1.5, 1.2)
        cmaxf_maxcostfactor["LatAmerica"] = TriangularDist(0.4, 1.0, 0.7)

        q0propmult_cutbacksatnegativecostinfinalyear = TriangularDist(0.3, 1.2, 0.7)
        qmax_minus_q0propmult_maxcutbacksatpositivecostinfinalyear = TriangularDist(1, 1.5, 1.3)
        c0mult_mostnegativecostinfinalyear = TriangularDist(0.5, 1.2, 0.8)
        curve_below_curvatureofMACcurvebelowzerocost = TriangularDist(0.25, 0.8, 0.45)
        curve_above_curvatureofMACcurveabovezerocost = TriangularDist(0.1, 0.7, 0.4)
        cross_experiencecrossoverratio = TriangularDist(0.1, 0.3, 0.2)
        learn_learningrate = TriangularDist(0.05, 0.35, 0.2)

        # AdaptationCosts
        AdaptiveCostsSeaLevel_cp_costplateau_eu = TriangularDist(0.01, 0.04, 0.02)
        AdaptiveCostsSeaLevel_ci_costimpact_eu = TriangularDist(0.0005, 0.002, 0.001)
        AdaptiveCostsEconomic_cp_costplateau_eu = TriangularDist(0.005, 0.02, 0.01)
        AdaptiveCostsEconomic_ci_costimpact_eu = TriangularDist(0.001, 0.008, 0.003)
        AdaptiveCostsNonEconomic_cp_costplateau_eu = TriangularDist(0.01, 0.04, 0.02)
        AdaptiveCostsNonEconomic_ci_costimpact_eu = TriangularDist(0.002, 0.01, 0.005)

        cf_costregional["USA"] = TriangularDist(0.6, 1, 0.8)
        cf_costregional["OECD"] = TriangularDist(0.4, 1.2, 0.8)
        cf_costregional["USSR"] = TriangularDist(0.2, 0.6, 0.4)
        cf_costregional["China"] = TriangularDist(0.4, 1.2, 0.8)
        cf_costregional["SEAsia"] = TriangularDist(0.4, 1.2, 0.8)
        cf_costregional["Africa"] = TriangularDist(0.4, 0.8, 0.6)
        cf_costregional["LatAmerica"] = TriangularDist(0.4, 0.8, 0.6)


        ############################################################################
        # Indicate which parameters to save for each model run
        ############################################################################

        save(EquityWeighting.td_totaldiscountedimpacts,
             ClimateTemperature.rt_g_globaltemperature,
             GDP.gdp,
             EquityWeighting.grwnet_realizedgdpgrowth,
             GDP.cbreg_regionsatbound
             )

    end # de
    return mcs
end

# Reformat the RV results into the format used for testing
function reformat_RV_outputs(samplesize::Int; output_path::String=joinpath(@__DIR__, "../../output"))

    # create vectors to hold results of Monte Carlo runs
    td = zeros(samplesize);
    tpc = zeros(samplesize);
    tac = zeros(samplesize);
    te = zeros(samplesize);
    ft = zeros(samplesize);
    rt_g = zeros(samplesize);
    s = zeros(samplesize);
    c_co2concentration = zeros(samplesize);
    rgdppercap_slr = zeros(samplesize);
    rgdppercap_market = zeros(samplesize);
    rgdppercap_nonmarket = zeros(samplesize);
    rgdppercap_disc = zeros(samplesize);

    # load raw data
    # no filter
    td      = load_RV("EquityWeighting_td_totaldiscountedimpacts", "td_totaldiscountedimpacts"; output_path=output_path)
    tpc     = load_RV("EquityWeighting_tpc_totalaggregatedcosts", "tpc_totalaggregatedcosts"; output_path=output_path)
    tac     = load_RV("EquityWeighting_tac_totaladaptationcosts", "tac_totaladaptationcosts"; output_path=output_path)
    te      = load_RV("EquityWeighting_te_totaleffect", "te_totaleffect"; output_path=output_path)

    # time index
    c_co2concentration = load_RV("CO2Cycle_c_CO2concentration", "c_CO2concentration"; output_path=output_path)
    ft      = load_RV("TotalForcing_ft_totalforcing", "ft_totalforcing"; output_path=output_path)
    rt_g    = load_RV("ClimateTemperature_rt_g_globaltemperature", "rt_g_globaltemperature"; output_path=output_path)
    s       = load_RV("SeaLevelRise_s_sealevel", "s_sealevel"; output_path=output_path)

    # region index
    rgdppercap_slr          = load_RV("SLRDamages_rgdp_per_cap_SLRRemainGDP", "rgdp_per_cap_SLRRemainGDP"; output_path=output_path)
    rgdppercap_market       = load_RV("MarketDamagesBurke_rgdp_per_cap_MarketRemainGDP", "rgdp_per_cap_MarketRemainGDP"; output_path=output_path)
    rgdppercap_nonmarket    = load_RV("NonMarketDamages_rgdp_per_cap_NonMarketRemainGDP", "rgdp_per_cap_NonMarketRemainGDP"; output_path=output_path)
    rgdppercap_disc         = load_RV("Discontinuity_rgdp_per_cap_NonMarketRemainGDP", "rgdp_per_cap_NonMarketRemainGDP"; output_path=output_path)

    # resave data
    df = DataFrame(td=td, tpc=tpc, tac=tac, te=te, c_co2concentration=c_co2concentration, ft=ft, rt_g=rt_g, sealevel=s, rgdppercap_slr=rgdppercap_slr, rgdppercap_market=rgdppercap_market, rgdppercap_nonmarket=rgdppercap_nonmarket, rgdppercap_di=rgdppercap_disc)
    save(joinpath(output_path, "mimipagemontecarlooutput.csv"), df)
end



function do_monte_carlo_runs(samplesize::Int, scenario::String="RCP4.5 & SSP2", output_path::String=joinpath(@__DIR__, "../../output"))
    # get simulation
    mcs = getsim()

    # get a model
    m = getpage(scenario)
    run(m)

    # Run
    res = run(mcs, m, samplesize; trials_output_filename=joinpath(output_path, "trialdata.csv"), results_output_dir=output_path)

    # reformat outputs for testing and analysis
    reformat_RV_outputs(samplesize, output_path=output_path)
end



function compute_scc_mcs(m::Model, samplesize::Int; year::Union{Int,Nothing}=nothing, eta::Union{Float64,Nothing}=nothing, prtp::Union{Float64,Nothing}=nothing, pulse_size=75000.)# , varseed::Union{Int, Nothing} = nothing)
    # Setup of location of final results
    scc_results = zeros(samplesize)

    function mc_scc_calculation(sim_inst, trialnum::Int, ntimesteps::Int, ignore::Nothing)
        marginal = sim_inst.models[1]

        marg_damages = marginal[:EquityWeighting, :td_totaldiscountedimpacts]

        scc_results[trialnum] = marg_damages
    end

    # get simulation
    mcs = getsim()

    # Setup models
    eta == nothing ? nothing : setorup_param!(m, :emuc_utilityconvexity, eta)
    prtp == nothing ? nothing : setorup_param!(m, :ptp_timepreference, prtp * 100.)

    mm = get_marginal_model(m, year=year, pulse_size=pulse_size)# , varseed=varseed)   # Returns a marginal model that has already been run

    # Run
    res = run(mcs, mm, samplesize; post_trial_func=mc_scc_calculation)

    return scc_results
end

function get_scc_mcs(samplesize::Int, year::Int, output_path::String=joinpath(@__DIR__, "../../output");
                      eta::Union{Float64,Nothing}=nothing, prtp::Union{Float64,Nothing}=nothing,
                      pulse_size::Union{Float64,Nothing}=75000.,
                      scenario::String="RCP4.5 & SSP2",
                      use_permafrost::Bool=true, use_seaice::Bool=true, use_page09damages::Bool=false,
                      ge_minimum::Union{Float64, Nothing} = nothing,
                      ge_maximum::Union{Float64, Nothing} = nothing,
                      ge_mode::Union{Float64, Nothing} = nothing,
                      ge_use_empirical::Union{Float64, Nothing} = nothing,
                      civvalue_multiplier::Union{Float64, Nothing} = 1.,
                      use_convergence::Union{Float64, Nothing} = nothing,
                      cbabs::Union{Float64, Nothing} = nothing,
                      eqwbound::Union{Float64, Nothing} = nothing,
                      geadrate::Union{Float64, Nothing} = nothing)

    # Setup the marginal model and modify key parameters if they are specified
    m = getpage(scenario, use_permafrost, use_seaice, use_page09damages)
    if use_convergence != nothing
        setorup_param!(m, :use_convergence, use_convergence)
    end
    if ge_use_empirical != nothing
        setorup_param!(m, :ge_use_empiricaldistribution, ge_use_empirical)
    end
    if cbabs != nothing
        setorup_param!(m, :cbabs_pcconsumptionbound, cbabs)
    end
    if eqwbound != nothing
        setorup_param!(m, :eqwbound_maxshareofweighteddamages, eqwbound)
    end
    if geadrate != nothing
        setorup_param!(m, :geadrate_growtheffects_adaptationrate, geadrate)
    end

    mm = compute_scc_mm(m, year=year, eta=eta, prtp=prtp, pulse_size=pulse_size)[:mm]

    # Setup SCC calculation and place for results
    scc_results = zeros(samplesize)

    function my_scc_calculation(mcs, trialnum::Int, ntimesteps::Int, tup::Union{Tuple,Nothing})
        base, marginal = mcs.models
        scc_results[trialnum] = (marginal[:EquityWeighting, :td_totaldiscountedimpacts] - base[:EquityWeighting, :td_totaldiscountedimpacts]) / pulse_size
    end

    # Setup MC simulation
    mcs_def = getsim(ge_minimum, ge_maximum, ge_mode, civvalue_multiplier)
    mcs_inst = run(mcs_def, [mm.base, mm.modified], samplesize; results_output_dir=output_path, post_trial_func=my_scc_calculation)
    set_models!(mcs_inst, [mm.base, mm.modified])
    generate_trials!(mcs_inst, samplesize, filename=joinpath(output_path, "scc_trials.csv"))

    scc_results
end
