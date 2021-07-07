#' Function script: Mapping emissions, GDP, and population from SSPs to PAGE ====
#' Author: Dmitry Yumashev (+ edits Jarmo Kikstra) ====


# 0.0: install and load packages ==== 
pkgs.install <- c("stringr",
                  "readxl",
                  "writexl",
                  "tidyverse",
                  "data.table",
                  "here")
# install.packages(pkgs.install) #uncomment if packages above not installed.
library(stringr)
library(readxl)
library(writexl)
library(tidyverse)
library(data.table)
library(here)

# 0.1: set correct working directory and paths ====
# # set working directory to this file
try(setwd(dirname(rstudioapi::getActiveDocumentContext()$path)))
# base path 
here::i_am("SSP_IAM_V2_201811.csv")
RAW_DATA_PATH <- paste0(here(), "/")
DATA_PATH_SSP <- paste0(RAW_DATA_PATH, "SSP_IAM_V2_201811.csv")
OUT_DATA_PATH_TEMP <- paste0(here(), "/../data-raw/")
OUT_DATA_PATH <- paste0(here(), "/../data/")

# 0.2: specification of years, variables, and scenarios to prepare ====
scenario_years <- 2010:2100 # define the required scenario years for which the SSP data is to be prepared
total_scenario_years = length(scenario_years)
base_year <- 2020 # define the base year relative to which the % changes in emissions are to be calculated
required_scenarios <- "SSP1-19" # paste("SSP", 1:5, sep="") # SSP1 - SSP5
selected_variables <- c("Emissions|BC",
                        "Emissions|CH4",
                        "Emissions|CO",
                        "Emissions|CO2",
                        "Emissions|F-Gases",
                        ### "Emissions|Kyoto Gases", # This is an aggregate category itself! Exclude it from the mapping for obvious reasons
                        "Emissions|N2O",
                        ### "Emissions|NH3", # This is an indirect GHG as some of it may get converted to N2O, a direct GHG. Exclude it due to large uncertainties involved
                        ### "Emissions|NOx", # This is an indirect GHG as some of it may get converted to N2O, a direct GHG. Exclude it due to large uncertainties involved
                        "Emissions|OC",
                        "Emissions|Sulfur",
                        "Emissions|VOC") 

# 0.3: read regional mappings of SSP R5.2 and PAGE region codes ====
filenametext.region <- paste0(RAW_DATA_PATH, "Region_Mapping_SSP_PAGE.csv")
RegionGroupingData <- read.csv(filenametext.region, header = TRUE)
RegionGroupingData$R_PAGE_Description <- NULL
r5_regions <- unique(RegionGroupingData$R5)


# 0.3: read GHG mappings of SSP R5.2 and PAGE region codes ====
filenametext.ghg <- paste0(RAW_DATA_PATH, "GHG_Mapping_SSP_PAGE.csv")
GHGGroupingData <- read.csv(filenametext.ghg, header = TRUE)
GHGGroupingData$GHG_PAGE_Description <- NULL


# 0.4: read SSP data (country-level SSP projections for R5.2-level emissions (from SSP database)) ====
filenametext.ssp <- paste0(RAW_DATA_PATH, "SSP_IAM_V2_201811.csv")
RawData <- read.csv(filenametext.ssp, header = TRUE)
str(RawData)
selected_cols_char <- c("MODEL", "SCENARIO", "REGION", "VARIABLE", "UNIT") # specify the variables to read -- see the structure of the file
selected_ssp_years <- seq(min(scenario_years), max(scenario_years), by = 10) # see the structure of the file 
total_selected_ssp_years <- length(selected_ssp_years)
selected_ssp_years_x <- paste("X", selected_ssp_years, sep="") # auxiliary variable to match with the year names as read from the csv file
selected_cols_all <- c(selected_cols_char, selected_ssp_years_x) # all selected columns combined
RawData <- RawData[ , selected_cols_all]

# 0.5: extract scenarios and (GHG) variables to extract  ====
selected_models <- unique(RawData$MODEL) # "OECD Env-Growth" # this model has GDP projections for all WA countries; other model's don't
total_scenarios <- length(required_scenarios)
required_scenarios_with_suffix <- required_scenarios # paste(required_scenarios, "_v9_130325", sep="") # as in the input file
total_variables <- length(selected_variables)

SelectedData <- RawData[RawData$MODEL %in% selected_models & 
                          RawData$SCENARIO %in% required_scenarios_with_suffix &
                          RawData$REGION %in% r5_regions &
                          RawData$VARIABLE %in% selected_variables, ]

str(SelectedData)
rm(RawData)



# 0.6: reformat selected data ====

### now use gather() to reformat the data frame from wide to long, clustering all ssp years in a single data column
ReformattedData <- SelectedData %>% gather(Year, Value, selected_ssp_years_x) # NOTE: use the adjusted variable name for years, containing X
# set the scaling flag to zero
flag_scaling <- 0
str(ReformattedData)
rm(SelectedData)
ReformattedData$Year <- as.numeric(str_remove(ReformattedData$Year, "X")) ### remove X in front of the years and convert into numbers

# 0.7: prepare for creating separate data frames for each variable ====
VariableUnits <- ReformattedData[ReformattedData$VARIABLE %in% selected_variables, c("VARIABLE", "UNIT")] # extract units for each variable as a separate data frame 
VariableUnits <- VariableUnits[!duplicated(VariableUnits), ] # remove duplicates
ReformattedData$UNIT <- NULL # remove the units variable from the main dataframe 


# 0.8: scale GHG emissions, as index relative to their values in the base year ====
rowsselection <- which(ReformattedData$Year == base_year) # extract the dataframe containing only the base year values
df <- ReformattedData[rowsselection, ]
df_rep <- df[rep(seq_len(nrow(df)), each = total_selected_ssp_years), ]  # replicate this dataframe for all ssp years, Base R functions
df <- merge(ReformattedData, df_rep, by=c("MODEL", "SCENARIO", "REGION", "VARIABLE")) # merge df_rep with the main dataframe

# after the merger, Value.x contains original values in all SSP years, while Value.y 
# contains the corresponding values from 2020; divide one by another to get the 
# required percentage relative to the vase year and create a new column for these new values
df[c("ValRelPct")] <- 100 * df$Value.x / df$Value.y # UNITS: % relative to base year

# rename Year.x back to Year and remove the other columns
df <- df %>% rename(Year = Year.x)
df$Value.x <- NULL
df$Year.y <- NULL
df$Value.y <- NULL

# restore the previous name
ReformattedData <- df



# 0.9: Add PAGE-ICE GHG category information to the original dataframe ====

### rename GHG_SSP to VARIABLE in the auxiliary GHGGroupingData dataframe and merge 
### it with the main SSP dataframe to map to PAGE GHG catagories 
GHGGroupingData <- GHGGroupingData  %>% rename(VARIABLE = GHG_SSP)
ReformattedData <- merge(ReformattedData, GHGGroupingData, by = c("VARIABLE"))
ReformattedData$VARIABLE <- NULL # remove the original VARIABLE


# 1: perform calculations on the SSP data ====

# 1.1: [N/A] work out the mean of ValRelPct over all GHG componentsthe components of the Excess GHG category ====
### NOTE: This is a very rough calculation since the Excess category includes multiple GHGs with very different levels of emissions and GWP;
### However, the decline in the emissions relative to their base year values follows roughly the same trajectory for all the components involved, 
### which is why we simply average over the individual trajectories

# therefore - we skip this and do it for all PAGE GHG groups in the same manner.

# 1.2: Perform the averaging automatically for ALL PAGE GHG groups ====  
### for gas, model - done together for the ease of calculation and in case there are further multiple entries
df <- ReformattedData
df <- aggregate(x = df[c("ValRelPct")], by=df[c("MODEL", "SCENARIO", "REGION", "Year", "GHG_PAGE")], FUN=mean)
ReformattedData <- df

### for gas - now work out the mean of ValRelPct over all the models used to derive SSPs;
df <- ReformattedData
df <- aggregate(x = df[c("ValRelPct")], by=df[c("SCENARIO", "REGION", "Year", "GHG_PAGE")], FUN=mean)
ReformattedData <- df

# 1.3: Map onto PAGE-regions ====

### finally, we arrived at the stage when we can rename R5 to REGION in the auxiliary 
### RegionGroupingData dataframe and merge it with the main SSP dataframe to map to PAGE regions 
RegionGroupingData <- RegionGroupingData  %>% rename(REGION = R5)
ReformattedData <- merge(ReformattedData, RegionGroupingData, by = c("REGION"))
ReformattedData$REGION <- NULL # remove the original REGION variable
ReformattedData$SCENARIO <- NULL # also remove the scenario column (unless multiple scenarios need to be processed)

### sort the order of rows and columns
rowsselection <- order(ReformattedData$R_PAGE, ReformattedData$GHG_PAGE, ReformattedData$Year)
colsselection <- c("R_PAGE", "GHG_PAGE", "Year", "ValRelPct")
ReformattedData <- ReformattedData[rowsselection, colsselection]


# 2: Write out data ====
# map page rcp simple file names 
ssp_gas_names <- ordered(unique(ReformattedData_mimi$GHG_PAGE))
page_gas_names <- c("ch4", "co2", "excess", "lin", "n2o", "sulph") 
gas.conversion <- page_gas_names
names(gas.conversion) <- ssp_gas_names

### write out long-format data
ReformattedData_mimi <- tibble(ReformattedData) %>% 
  pivot_wider(names_from = "R_PAGE", values_from = "ValRelPct") %>% 
  mutate(ghg_out_name=gas.conversion[ReformattedData_mimi$GHG_PAGE])

# loop to write out all gases in separate data frames
### N.B. requires editing to make more flexible for multiple RCPs, or to include other variables like GDP and population
for (gas in page_gas_names){
  filenametext_output <- paste0(
    OUT_DATA_PATH_TEMP,
    "rcps/",
    "rcp19_",
    gas,
    ".csv"
  )
  
  write.csv(ReformattedData_mimi %>% 
              filter(ghg_out_name==gas) %>% 
              select(-GHG_PAGE, -ghg_out_name) %>% 
              rename(year=Year), 
            filenametext_output, quote = TRUE, row.names = FALSE)  
}






# ##############################################################################
#
# NOTE: The fragments below could be adapted to map SSP GDP and population onto 
# PAGE regions
# 
# ############################################################################## 
#
# ### scale population and gdp according to the units (millions / billions)
# 
# if (flag_scaling == 0){
#   
#   flag_scaling <- 1 # to safeguard from re-running the same scaling twice
#   
#   for (i in 1:total_variables){
#     
#     if (selected_variables[i] == "GDP|PPP"){
#       
#       # gdp
#       scale_factor <- 1e9 # billions
#       
#     } else if (selected_variables[i] == "Population"){
#       
#       # population
#       scale_factor <- 1e6 # millions
#       
#     }
#     
#     rowsselection <- which(ReformattedData$VARIABLE == selected_variables[i]) 
#     ReformattedData[rowsselection, c("Value")] <- ReformattedData[rowsselection, c("Value")] * scale_factor 
#     rm(rowsselection)
#     
#   }
#   
# }
# 
# #
# 
# ScaledData <- ReformattedData
# 
# rm(ReformattedData)
# 
# 
# ### remove unused variables from the data frame
# 
# ScaledData$MODEL <- NULL
# 
# 
# 
# ##############
# 
# ### calculate GDP per capita in the SSP datasets
# 
# # first define subframe with selected columns
# SubFrame <- ScaledData[c("SCENARIO", "REGION", "Year")]
# 
# # then identify unique combinations in this subframe
# UniqueFrame <- unique(SubFrame)
# 
# # checks
# # str(SubFrame)
# # str(UniqueFrame)
# # 
# # SubFrame[1, ]
# # SubFrame[2, ]
# # SubFrame[3, ]
# # SubFrame[4, ]
# # 
# # UniqueFrame[1, ]
# # UniqueFrame[2, ]
# 
# # identify the rows than match across all the three variables
# 
# total_rows <- nrow(SubFrame)
# unique_rows <- nrow(UniqueFrame)
# 
# gdppercap <- array(NA, dim = c(total_rows))
# 
# for (i in 1:unique_rows){
# 
#   # # debugging
#   # i <- 1
#   
#   current_scenario <- UniqueFrame[i, ]$SCENARIO
#   current_country <- UniqueFrame[i, ]$REGION
#   current_year <- UniqueFrame[i, ]$Year
#   
#   rowsselection <- which(SubFrame$SCENARIO %in% current_scenario &
#                      SubFrame$REGION %in% current_country &
#                      SubFrame$Year %in% current_year)
# 
#   # within these rows, identify elements corresponding specifically to gdp and population
#   x <- (ScaledData$VARIABLE[rowsselection] == "GDP|PPP") # TRUE / FALSE vector entries 
#   y <- (ScaledData$VARIABLE[rowsselection] == "Population") # TRUE / FALSE vector entries 
#   
#   # corresponding values
#   z <- ScaledData$Value[rowsselection]
#   
#   # extract gdp in the numerator and population in the denominator using the TRUE / FALSE vector entries; 
#   # divide the two to get gdp pre cap, and record the result into the current rows selection, entering
#   # non-zeros only where there is gdp data
#   gdppercap[rowsselection] <- x * (sum(x * z) / sum(y * z))
#   
#   rm(rowsselection)
#   
# }
# 
# gdppercap[gdppercap == 0] <- NA
# 
# rm(SubFrame)
# rm(UniqueFrame)
# 
# # combine the gdppercap vector with the main dataframe; the rows' order is consistent in both
# 
# blended <- cbind(ScaledData, gdppercap)
# 
# # replace the original GDP PPP entries (absolute values) with GDP per capita values
# 
# rowsselection <- which(blended$VARIABLE == "GDP|PPP")
# 
# blended$Value[rowsselection] <- blended$gdppercap[rowsselection]
# 
# # rename GDP|PPP to "ppp ph17" (flag_gdp) NOTE: use the same rows selection for GDP as above, then re-select for population
# 
# blended$VARIABLE[rowsselection] <- flag_gdp
# 
# rm(rowsselection)
# 
# # rename Population to "pop 17" (flag_pop); 
# 
# rowsselection <- which(blended$VARIABLE == "Population")
# 
# blended$VARIABLE[rowsselection] <- flag_pop 
# 
# rm(rowsselection)
# 
# # remove the gdppercap column
# 
# blended$gdppercap <- NULL
# 
# # revert back to the ScaledData variable
# 
# ScaledData <- blended 
# 
# rm(blended)
# 
# 
# ##############
# 
# ### calculate mean ssp values for the overlapping period (between 2005 and 2015 as a default, or any other specified period) and work out the relevant scaling factors based on the historic data
# 
# # NOTE: the scaling automatically converts to the right currency units as per those adopted for the historic data ($2016 or $current; ssps use $2005 as a default)
# 
# # first define subframe with selected columns
# SubFrame <- ScaledData[c("SCENARIO", "REGION", "VARIABLE")]
# 
# # then identify unique combinations in this subframe
# UniqueFrame <- unique(SubFrame)
# 
# # checks
# # str(SubFrame)
# # str(UniqueFrame)
# 
# # identify the rows than match across all the three variables
# 
# total_rows <- nrow(SubFrame)
# unique_rows <- nrow(UniqueFrame)
# 
# scalingpar <- array(NA, dim = c(total_rows))
# 
# for (i in 1:unique_rows){
#   
#   # # debugging
#   # i <- 1
#   
#   current_scenario <- UniqueFrame[i, ]$SCENARIO
#   current_country <- UniqueFrame[i, ]$REGION
#   current_variable <- UniqueFrame[i, ]$VARIABLE
#   
#   # exclude Palestinean territories for now as we don't have historic data for them
#   if (current_country == "PSE"){next}
#   
#   # first, extract the corresponding average over the historic period -- need only a single value 
#   # in the averagevalue as they were all recorded the same for each combination of country and variable 
#   
#   rowsselection <- which(GDP_And_Pop_Historic$Country == current_country & GDP_And_Pop_Historic$Variable == current_variable)
#   
#   y <- unique(GDP_And_Pop_Historic$averagevalue[rowsselection]) 
#   
#   average_for_historic <- y[!is.na(y)]
#   
#   rm(rowsselection)
#   
#   # now work out the average across the overlapping years for the ssps
#   
#   rowsselection <- which(SubFrame$SCENARIO %in% current_scenario &
#                            SubFrame$REGION %in% current_country &
#                            SubFrame$VARIABLE %in% current_variable)
#      
#   # within these rows, identify elements corresponding specifically to the overlapping years
#   x <- (ScaledData$Year[rowsselection] %in% overlapping_years) # TRUE / FALSE vector entries 
#   
#   # extract the values for the given rows selection
#   z <- ScaledData$Value[rowsselection] 
#   
#   # now work out the average over the elements with the TRUE flag (i.e. there is an overlap);
#   # we don't need to produce a vector in this instance since the same average applies to the entire time range -> don't multiply by x
#   average_for_ssp <- (sum(x * z) / sum(x)) 
#   
#   # use average values between 2010 and 2020 stored in GDP_And_Pop_Historic to scale ssps
#   
#   # scaling factor; NOTE: historic average must be in the numerator, ssp in denominator; 
#   # the scalar value gets assigned to ALL the entries, i.e. corresponding to all the ssp years
#   scalingpar[rowsselection] <- average_for_historic / average_for_ssp 
#   
#   rm(rowsselection)
#   
# }
# 
# scalingpar[scalingpar == 0] <- NA
# scalingpar[is.nan(scalingpar)] <- NA
# 
# rm(SubFrame)
# rm(UniqueFrame)
# 
# # combine the gdppercap vector with the main dataframe; the rows' order is consistent in both
# 
# blended <- cbind(ScaledData, scalingpar)
# 
# ScaledData <- blended 
# 
# rm(blended)
# 
# 
# ### !!! NOTE: there appear to be some irregularities in tbl_Data for GDP, for example in IRQ between 2003 and 2004; 
# ### as a result, the GDP scaling parameter appears to be quite high for some countries (way above the GDP deflator values between 2005-2016);
# ### We may have to reconstruct tbl_Data for all WA countires based on World Bank records (https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.CD?locations=IQ)
# 
# ### NOTE: population records in tbl_Data and ssps appear to match much better (scaling  parameter close to 1)
# 
# 
# ##############
# 
# ### apply the scaling to the values and remove the scaling parameter column
# 
# ScaledData$Value <- ScaledData$Value * ScaledData$scalingpar # element by element multiplication
# 
# ScaledData$scalingpar <- NULL
# 
# # also clear the averages from the historic data frame
# GDP_And_Pop_Historic$averagevalue <- NULL
# 
# 
# ##############
# 
# ### linearly interpolate ssps for all the required scenario years (the latter are defined at the top of the script)
# 
# # first define subframe with selected columns
# SubFrame <- ScaledData[c("SCENARIO", "REGION", "VARIABLE")]
# 
# # then identify unique combinations in this subframe
# UniqueFrame <- unique(SubFrame)
# 
# # checks
# # str(SubFrame)
# # str(UniqueFrame)
# 
# # identify the rows than match across all the three variables
# 
# total_rows <- nrow(SubFrame)
# unique_rows <- nrow(UniqueFrame)
# 
# # note the new total number of data points
# total_variable_combinations <- total_scenarios * total_countries * total_variables
# new_total_rows <- total_scenario_years * total_variable_combinations 
# 
# # pre-allocate auxiliary matrix to record the interpolated data
# auxmatrix <- array(NA, dim=c(new_total_rows,5))
# 
# for (i in 1:unique_rows){
#   
#   # # debugging
#   # i <- 1
#   
#   current_scenario <- UniqueFrame[i, ]$SCENARIO
#   current_country <- UniqueFrame[i, ]$REGION
#   current_variable <- UniqueFrame[i, ]$VARIABLE
#   
#   # exclude Palestinean territories for now as we don't have historic data for them
#   if (current_country == "PSE"){next}
#   
#   # now work out the average across the overlapping years for the ssps
#   
#   rowsselection <- which(SubFrame$SCENARIO %in% current_scenario &
#                            SubFrame$REGION %in% current_country &
#                            SubFrame$VARIABLE %in% current_variable)
#   
#   # within these rows, extract all years
#   x <- ScaledData$Year[rowsselection]   
#   
#   # extract the values for the given rows selection
#   y <- ScaledData$Value[rowsselection] 
#   
#   rm(rowsselection)
#   
#   # linearly interpolate to scenario_years and extract the corresponding values ($y)
#   list <- approx(x, y, scenario_years, method="linear")
#   
#   ValueInterp <- list$y
#   
#   # define the through-rows index for the new matrix with interpolated years 
#   
#   rows <- (1+(i-1)*total_scenario_years):(i*total_scenario_years)
#   
#   # note the order: same as for the historic data + additional scenario column at the front
#   auxmatrix[rows, 1] <- current_scenario # replicate scalar
#   auxmatrix[rows, 2] <- current_country # replicate scalar
#   #
#   auxmatrix[rows, 3] <- scenario_years # feed in vector
#   #
#   auxmatrix[rows, 4] <- ValueInterp # feed in vector
#   #
#   auxmatrix[rows, 5] <- current_variable # replicate scalar
#   
#   #
#   
# }
# 
# rm(SubFrame)
# rm(UniqueFrame)
# 
# # convert the auxiliary array to a dataframe with the corresponding column names
# 
# # NOTE: column names must be the same as for the historic data to allow for data frame merging
# 
# ScaledInterpolatedSceanarios <- data.frame(auxmatrix)
# colnames(ScaledInterpolatedSceanarios) <- c("Scenario", "Country", "Year", "Value", "Variable")
# 
# rm(auxmatrix)
# rm(ScaledData)
# 
# # make sure the years and values are in numeric format (not char)
# 
# ScaledInterpolatedSceanarios$Value <- as.numeric(ScaledInterpolatedSceanarios$Value)
# ScaledInterpolatedSceanarios$Year <- as.numeric(ScaledInterpolatedSceanarios$Year)
# 
# ### round the population down to the nearest integer (scaling and interpolating produced non-integer values) 
# 
# rowsselection <- which(ScaledInterpolatedSceanarios$Variable == flag_pop)
# 
# ScaledInterpolatedSceanarios$Value[rowsselection] <- as.integer(floor(ScaledInterpolatedSceanarios$Value[rowsselection]))
# 
# rm(rowsselection)
# 
# 
# ##############
# 
# ### re-order the scenarios frame in line with the historic frame, moving the scenarios column to the end 
# 
# # rows
# sortorder_r <- order(ScaledInterpolatedSceanarios$Country, ScaledInterpolatedSceanarios$Year) 
# # columns (most important)
# sortorder_c <- c("Country", "Year", "Value", "Variable", "Scenario")
# # re-order
# ScaledInterpolatedSceanarios <- ScaledInterpolatedSceanarios[sortorder_r , sortorder_c]
# 
# 
# ##############
# 
# ### concatenate historic data with scaled ssp projections, and write into a file
# 
# # specify correct working directory
# setwd(DATA_PATH_WA)
# 
# # set the name of the output file
# # NOTE: use scenario name as a sheet name
# filenameoutput <- "tbl_Data_SSPs.xlsx"
# 
# # delete the file if it already exists -- otherwise write.xlsx will complain
# unlink(filenameoutput)
# 
# ###
# 
# x <- unique(GDP_And_Pop_Historic$Year)
# 
# historic_years <- x[x<min(scenario_years)] # prior to the scenario years
# total_historic_years <- length(historic_years)
# 
# # cut historic dataframe to the specified historic years
# 
# GDP_And_Pop_Historic_Cut <- GDP_And_Pop_Historic[GDP_And_Pop_Historic$Year %in% historic_years, ]
# 
# 
# # from this point onward, it makes sense to loop over ssps and extract the blocks from the scenarios frame that correspond to each ssp individually
# 
# for (kscen in 1:total_scenarios){
# 
#   # # debugging
#   # kscen <- 1
#   
#   current_scenario <- required_scenarios[kscen]
#   
#   rowsselection <- which(ScaledInterpolatedSceanarios$Scenario == current_scenario)
#   
#   SubFrameOneScenario <- ScaledInterpolatedSceanarios[rowsselection, ]
#   
#   rm(rowsselection)
#   
#   # remove the scenario column
#   
#   SubFrameOneScenario$Scenario <- NULL
#   
#   ### now attach the dataframe to the end of the historic data frame using rbind
#   
#   CombinedFrameHistoricOneScenario <- rbind(GDP_And_Pop_Historic_Cut, SubFrameOneScenario)
#   
#   # re-order the rows in the combined dataframe  
#   
#   # rows
#   sortorder_r <- order(CombinedFrameHistoricOneScenario$Country, CombinedFrameHistoricOneScenario$Year, -rank(CombinedFrameHistoricOneScenario$Variable)) 
#   
#   # re-order
#   CombinedFrameHistoricOneScenario <- CombinedFrameHistoricOneScenario[sortorder_r , ]
#   
#   
#   # rename Variable -> Destination (identifier distinguishing between gdp and population) to match with the WoT name
#   CombinedFrameHistoricOneScenario <- CombinedFrameHistoricOneScenario %>% rename(Destination = Variable)
#   
#   ### finally, save the dataframe in the output file
#   
#   write.xlsx(CombinedFrameHistoricOneScenario, filenameoutput, sheetName = current_scenario, # NOTE: use scenario name as a sheet name
#              col.names = TRUE, row.names = FALSE, append = TRUE) # NOTE: use FALSE for row names and TRUE for append (to add to the same file in the loop)
#   
# }
# 
# 
# 
# ##############
# 
