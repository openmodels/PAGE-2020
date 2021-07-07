# Model Structure

## Overview

PAGE-2020 is constructed to reproduce the PAGE-ICE model structure,
which features ten time periods and eight world regions. These time
periods and regions are listed below. Climate change impacts for four
sectors are calculated in addition to the costs of mitigation-- herein
referred to as abatement policies-- and the costs of adaptation. Both
impacts and costs can be computed under parameter uncertainty.

This iteration of PAGE subsets the model into 33 components,
elaborated under the "Components" section below, and two basic parts:
climate and economy. There are also a number of components particular
to PAGE-2020 which assist with certain functionalities. Within the
climate model, gases and sulphates are split into three components
each-- namely the "Cycle", "Emissions", and "Forcing" components for
that gas. Forcings are then aggregated into "Total Forcing" and feed
into "Climate Temperature". The economic model includes "Abatement
Costs", "Adaptation Costs", and "Discontinuous" impacts as well as impacts from "Sea Level Rise", "Market Damages", and "Non-Market Damages". It also features an "Equity Weighting" component.

A schematic of the model, and full listing of components, follows below.

## Time periods and regions

The ten uneven timesteps employed in PAGE-2020 are 2020, 2030, 2040,
2050, 2075, 2100, 2150, 2200, 2250, and 2300. The baseline period used, prior to any modeled results, is 2015.

The eight regions included are Europe (EU), the United States (US or USA),
other countries in the Organisation for Economic Co-operation and
Development (OT or OECD), the former Union of Soviet Socialist Republics and
the rest of Europe (EE or USSR), China and centrally planned Asia (CA
or China), India
and Southeast Asia (IA or SEAsia), Africa and the Middle East (AF or Africa), and Latin
America (LA or LatAmerica).  These parenthetical labels are used throughout the data
files and in the model specification.  PAGE-2020, like PAGE-ICE, employs
the EU as a baseline region, with some processes calculated relative
to their EU values.

## Scenarios

PAGE-2020 uses the RCP-SSP scenario scheme used by the IPCC, along
with additional scenarios for studying a 1.5 C mitigation pathway and
mitigation that corresponds to the existing INDC commitments. These
scenarios combine both emissions and socioeconomic growth. The
available scenarios are: `Zero Emissions & SSP1`, `1.5 degC Target`,
`2 degC Target`, `2.5 degC Target`, `NDCs`, `NDCs Partial`, `BAU`,
`RCP1.9 & SSP1`, `RCP2.6 & SSP1`, `RCP4.5 & SSP2`, and `RCP8.5 & SSP5`.
These are described in more detail in
[Yumashev et al. (2019)](https://www.nature.com/articles/s41467-019-09863-x#Sec14).

## Sectors and gases

The model is divided into four impact sectors: sea level rise, market
damages (called "economic damages" in PAGE-ICE), non-market damages (called "non-economic" in PAGE-ICE), and discontinuities. The six greenhouse gases of the Kyoto Protocol are each included via components that respectively model CO2, CH4, N2O, and a subset of low-concentration gases collectively termed "linear gases." Linear gases include HFCs, PFCs, and SF6. Sulphate forcing is also modelled.

The four impact sectors in PAGE-2020 are modelled independently and
reflect damages as a proportion of GDP. Sea level rise is a lagged
linear function of global mean temperature. The market damages are
based on Burke et al. (2015). Discontinuity, or the risk of climate
change triggering large-scale damages, reflects a variety of different
possible types of disaster.

## Components

### Climate Model

The components in this portion of PAGE-2020 include:
- CH4 Cycle
- CH4 Emissions
- CH4 Forcing
- CO2 Cycle
- CO2 Emissions
- CO2 Forcing
- N2O Cycle
- N2O Emissions
- N2O Forcing
- Linear Gases (hereafter "LG") Cycle
- LG Emissions
- LG Forcing
- Sulphate Forcing
- Total Forcing
- Permafrost feedback (JULES and SiBCASA models)
- Climate Temperature
- Sea Level Rise

### Economic Model

The components in this portion of PAGE-2020 include:
- RCP and SSP scenario system
- Population
- GDP
- Market Damages
- Market Damages with Burke et al. calibration
- Non-Market Damages
- Sea Level Rise Damages
- Discontinuity
- Abatement Costs (for each gas)
- Adaptation Costs (for each impact sector)
- Total Abatement Costs
- Total Adaptation Costs
- Total Costs
- Equity Weighting

### Model interface scripts

The following scripts provide a basic function interface to the PAGE
model:
- main_model.jl: provides the `getpage` function, to get an
  initialised PAGE model.
- climate_model.jl: provides the `climatemodel` function, to get only the
  PAGE model.
- mcs.jl: provides the `do_monte_carlo_runs` function, to the model in
  Monte Carlo mode.
- compute_scc.jl: provides the `compute_scc_mcs` function to get a
  series of SCC Monte Carlo draws.

### Functional Components of PAGE-2020

The following scripts assist in the actual running of PAGE-2020, and
are further elaborated in the technical user guide.

- load_parameters.jl
- save_parameters.jl
- mctools.jl

### Schematic

![page-image](assets/PAGE-image.jpg)
