# RothC R version 2.0.0
# 
# Authors: Jonah Prout, Alice Milne, and Kevin Coleman
#
# Written in R version 4.2.3 (2023-03-15 ucrt)
#
# The Rothamsted Carbon Model: RothC
# Developed by David Jenkinson and Kevin Coleman
# 
# An example input file is provided with the release (RothC_input.dat).
# The example file structure is a way to present the necessary inputs collectively and consistently.
# Users can adapt the code to source the inputs from the R environment or use input files of the same structure.
#
# The structure of the input file matches the corresponding version in our other releases (Fortran and Python).
#
# INPUTS:
# 
# option switches (see Description PDF for more detail)
# 
# opt_RMmoist: 1 = classic RothC moisture function using clay (%) down to matric potential -1500 kPa
#              2 = moisture function calculated using additional variables down to matric potential -100 000 kPa
#              3 = moisture function calculated using additional variables down to -1500 kPa
# opt_SMDbare: 1 = bare soil moisture deficit threshold set as in classic RothC
#              2 = bare soil moisture deficit threshold set to -1500 kPa
# 
# Soil variables required for all opt_RMmoist
# 
# clay:     clay content of the soil (units: %)
# depth:    depth of topsoil (units: cm)
# IOM:      inert organic matter (t C /ha)
# nsteps:   number of timesteps
# 
# Soil variables only required for opt_RMmoist = 2 or 3
#
# silt: silt content of the soil (units:%)
# BD: bulk density (units: g cm^-3)
# OC: soil organic carbon concentration (units: %)
# min_RMmoist: minimum value to give to the rate modifying factor for moisture (0.2 in classic RothC)
# 
# year:     year
# month:    month (1-12)
# modern:   %modern
# TEMP:     air temperature (C)
# RAIN:     rainfall (mm)
# PEVAP:    open pan evaporation (mm). A pan coefficient is used to convert open-pan evaporation to potential evapotranspiration in the RMF_Moist function
# Pl_inp:   carbon input from plants to the soil each month (units: t C /ha)
# OA_inp:   organic amendment input to the soil each month; parameterised for Farmyard manure (units: t C /ha)
# PC:       plant cover (0 = no cover, 1 = covered by a crop)
# DPM/RPM:  ratio of DPM to RPM for carbon additions to the soil (units: none)
# 
# OUTPUTS:
# 
# All pools are carbon and not organic matter
# 
# DPM:   Decomposable Plant Material (units: t C /ha)
# RPM:   Resistant Plant Material    (units: t C /ha)
# Bio:   Microbial Biomass           (units: t C /ha)
# Hum:   Humified Organic Matter     (units: t C /ha)
# IOM:   Inert Organic Matter        (units: t C /ha)
# SOC:   Soil Organic Matter / Total organic Matter (units: t C / ha)
# 
# DPM_Rage:   radiocarbon age of DPM
# RPM_Rage:   radiocarbon age of RPM
# Bio_Rage:   radiocarbon age of Bio
# Hum_Rage:   radiocarbon age of Hum
# Total_Rage: radiocarbon age of SOC (or TOC)
# 
# SMD:       soil moisture deficit (mm per soil depth)
# RM_Temp:   rate modifying factor for temperature (0.0 - ~5.0)
# RM_Moist:  rate modifying factor for moisture (0.0 - 1.0)
# RM_PC:     rate modifying factor for plant retainment (0.6 or 1.0)

###############################################################################

# Model functions
RothC_model <- function(filename){
  # Calculates the rate modifying factor for temperature (RMF_Temp)
  RMF_Temp <- function(TEMP){
    if(TEMP < -5.0){
      RM_Temp <- 0.0
    } else {
      RM_Temp <- 47.91 / (exp(106.06/(TEMP+18.27)) + 1.0)
    }
  }
  
  # Calculates the rate modifying factor for moisture (RMF_Moist)
  # setting the additional variables for opt_RMmoist %in% c(2,3) to NULL
  # if opt_RMmoist is 2 or 3, code will expect values for the NULL arguments
  RMF_Moist <- function(RAIN, PEVAP, clay, depth, PC, SMD, opt_RMmoist, opt_SMDbare, 
                        silt = NULL, OC = NULL, BulkD = NULL, min_RMmoist = NULL){
    RMFMax <- 1.0
    if(opt_RMmoist == 1){
      
      RMFMin <- 0.2
      
      # Calc soil water functions properties
      SMD15bar <- -(20+1.3*clay-0.01*(clay*clay))
      SMD15barAdj <- SMD15bar*depth/23.0
      SMD1bar <- 0.444*SMD15barAdj
      
    } else if(opt_RMmoist %in% c(2,3)){
      
      RMFMin <- min_RMmoist
      
      mbars <- c(0, 50, 1000, 15000, 1000000)
      
      t <- 1 # note t = topsoil, in Wosten et al 1999, topsoil and subsoil have values 1 or 0
      # RothC only models topsoils so t is always 1
      
      alpha <- exp(-14.96+0.03135*clay+0.0351*silt+0.646*(OC*1.72)
                   +15.29*BD-0.192*t-4.671*BD^2-0.000781*clay^2
                   -0.00687*(OC*1.72)^2
                   +0.0449*(OC*1.72)^-1+0.0663*log(silt)
                   +0.1482*log(OC*1.72)
                   -0.04546*BD*silt-0.4852*BD*(OC*1.72)+0.00673*clay*t)
      
      thetaS <- (0.7919+0.001691*clay-0.29619*BD-0.000001491*silt^2
                 +0.0000821*(OC*1.72)^2+0.02427*clay^-1
                 +0.01113*silt^-1+0.01472*log(silt)
                 -0.0000733*(OC*1.72)*clay-0.000619*BD*clay
                 -0.001183*BD*(OC*1.72)-0.0001664*silt*t)
      
      n <- exp(-25.23 -0.02195*clay +0.0074*silt -0.194*(OC*1.72)
               +45.5*BD-7.24*BD^2 +0.0003658*clay^2
               +0.002885*(OC*1.72)^2 -12.81*BD^-1 -0.1524*silt^-1
               -0.01958*(OC*1.72)^-1 -0.2876*log(silt)
               -0.0709*log(OC*1.72) -44.6*log(BD) -0.02264*BD*clay
               +0.0896*BD*(OC*1.72) +0.00718*clay*t)+1
      
      thetaR <- 0.01
      
      m <- 1-1/n
      
      # ksat (saturated hydraulic conductivity), l_star and l are calculated in Wosten and van Genuchten but not needed to calculated the soil properties for RothC 
      # The calculations have been left in the code in case required, but commented out
      #
      #      ksat=exp(7.755 +0.0352*silt +0.93*t -0.967*BD^2 
      #          -0.000484*clay^2 -0.000322*silt^2
      #          +0.001*silt^-1 -0.0748*(OC*1.72)^-1
      #          -0.643*log(silt) -0.01398*BD*clay -0.1673*BD*(OC*1.72)
      #          +0.02986*clay*t -0.03305*silt*t)
      #     
      #      l_star=(0.0202 +0.0006193*clay^2 -0.001136*(OC*1.72)^2
      #          -0.2316*log(OC*1.72) -0.03544*BD*clay +0.00283*BD*silt
      #          +0.0488*BD*OC*1.72)
      #     
      #      l=10*(exp(l_star)-1)/(exp(l_star)+1)
      
      wc <- list()
      
      for(i in 1:5){
        wc[[i]] <- thetaR + (thetaS-thetaR)/ (1+(alpha*mbars[i])^n)^m
      }
      
      wcSAT <- wc[[1]]
      wcFC <- wc[[2]]
      wc1 <- wc[[3]]
      wcWP <- wc[[4]]
      wc1000 <- wc[[5]]
      
      X0 <- (wcSAT - wcFC)*10*depth
      X1 <- (wc1 - wcFC)*10*depth
      X2 <- (wcWP - wcFC)*10*depth
      X3 <- (wc1000 - wcFC)*10*depth
      
      SMD15bar <- X2 # X2 has been adjusted for depth
      SMD15barAdj <- SMD15bar
      SMD1bar <- X1
      SMD1000bar <- X3
    }
    
    if(opt_SMDbare == 1){
      if(opt_RMmoist == 1){
        SMDbare <- 0.556 * SMD15barAdj
      } else {
        SMDbare <- SMD15barAdj - (0.6388/0.8) * (SMD15barAdj - SMD1bar)
      }
    } else {
      SMDbare <- SMD15barAdj
    }
    
    if(opt_RMmoist %in% c(1, 3)){
      SMDMaxAdj <- SMD15barAdj
    } else if(opt_RMmoist == 2){
      SMDMaxAdj <- SMD1000bar
    }
    
    DF <- RAIN - 0.75*PEVAP # 0.75 is used as a pan coefficient to convert open-pan evaporation to potential evapotranspiration
    
    minSMDDF <- min(0.0, SMD+DF)
    minSMDbareSMD <- min(SMDbare, SMD)
    
    if(PC == 1){
      SMD1 <- max(SMDMaxAdj, minSMDDF)
    } else {
      SMD1 <- max(minSMDbareSMD,minSMDDF)
    }
    
    SMD <<- SMD1 # global assign required here for expected behaviour of the model.
    
    if(opt_RMmoist %in% c(1,3)){
      
      if(SMD1 > SMD1bar){
        RM_Moist <- 1.0
      } else {
        RM_Moist <- (RMFMin + (RMFMax - RMFMin) * (SMD15barAdj - SMD1) / (SMD15barAdj - SMD1bar))
      }
      
    } else {
      
      if(SMD1 > SMD1bar){
        RM_Moist <- 1.0
      } else if(SMD1 >  SMD15barAdj) {
        RM_Moist <- (RMFMin + (RMFMax - RMFMin) * (SMD15barAdj - SMD1) / (SMD15barAdj - SMD1bar))
      } else {
        RM_Moist <- min_RMmoist
      }
      
    }
    
  }
  
  # Calculates the plant retainment modifying factor (RMF_PC)
  RMF_PC <- function(PC){
    if(PC == 0){
      RM_PC <- 1.0
    } else {
      RM_PC <- 0.6 
    }
    
  }
  
  ###############################################################################
  
  # program RothC_R
  
  # set initial pool values (0 to allow spin-up method)
  DPM <- 0.0
  RPM <- 0.0
  Bio <- 0.0
  Hum <- 0.0
  SOC <- 0.0
  
  DPM_Rage <- 0.0
  RPM_Rage <- 0.0
  Bio_Rage <- 0.0
  Hum_Rage <- 0.0
  IOM_Rage <- 50000
  
  # set initial soil moisture deficit
  SMD <- 0.0
  TOC1 <- 0.0
  
  # read in RothC input data file 
  df_opts <- read.csv(filename,skip = 3, header = 1, nrows = 1, sep = '')
  opt_RMmoist <- df_opts[[1,'opt_RMmoist']]
  opt_SMDbare <- df_opts[[1,'opt_SMDbare']]
  df_head <- read.csv(filename, skip = 6, header = 1, nrows = 1, sep = '')# sep = '' can be removed if file is comma delimited
  colnames(df_head) <- c('clay','depth','iom','nsteps','silt','BD','OC','min_RMmoist')
  clay <- df_head[[1,'clay']]
  depth <- df_head[[1,'depth']]
  IOM <- df_head[[1,'iom']]
  nsteps <- df_head[[1,'nsteps']]
  if(opt_RMmoist %in% c(2,3)){
    silt <- df_head[[1,'silt']]
    OC <- df_head[[1,'OC']]
    BD <- df_head[[1,'BD']]
    min_RMmoist <- df_head[[1,'min_RMmoist']]
  }
  df <- read.csv(filename, skip = 9, header = 1, sep = '')# sep = '' can be removed if file is comma delimited
  colnames(df) <- c('t_year', 't_month', 't_mod', 't_temp','t_rain','t_evap', 't_Pl_inp', 't_OA_inp', 't_PC', 't_DPM_RPM')
  
  # run RothC to equilibrium using first 12 months of input file df (spin-up)
  k <- 0
  j <- 0
  
  SOC <- DPM + RPM + Bio + Hum + IOM
  
  timeFact <- 12
  
  test = 100.0
  while(test > 0.000001){
    k <- k + 1
    j <- j + 1
    
    if(k == timeFact+1){
      k <- 1
    }
    
    TEMP <- df$t_temp[k]
    RAIN <- df$t_rain[k]
    PEVAP <- df$t_evap[k]
    
    PC <- df$t_PC[k]
    DPM_RPM <- df$t_DPM_RPM[k]
    
    Pl_inp <- df$t_Pl_inp[k]
    
    OA_inp <- df$t_OA_inp[k]
    
    modernC <- df$t_mod[k] / 100.0
    
    Total_Rage <- 0.0
    
    # calculate RMFs for temperature, moisture, and plant cover
    RM_Temp <- RMF_Temp(TEMP)
    if(opt_RMmoist == 1){
      RM_Moist <- RMF_Moist(RAIN, PEVAP, clay, depth, PC, SMD, opt_RMmoist, opt_SMDbare)
    } else if(opt_RMmoist %in% c(2,3)){
      RM_Moist <- RMF_Moist(RAIN, PEVAP, clay, depth, PC, SMD, opt_RMmoist, opt_SMDbare, silt, OC, BulkD, min_RMmoist)
    }
    RM_PC <- RMF_PC(PC)
    
    # combine RMFs into one.
    RateM <- RM_Temp*RM_Moist*RM_PC
    
    # zero is used when calculating the radiocarbon stage
    zero <- 0
    
    # rate constants are parameters so don't need to be passed
    DPM_k <- 10.0
    RPM_k <- 0.3
    Bio_k <- 0.66
    Hum_k <- 0.02
    
    conr <- log(2)/5568.0
    
    tstep <- 1.0/timeFact # monthly 1/12, or daily 1/365
    
    exc <- exp(-conr*tstep)
    
    # decomposition
    DPM1 <- DPM * exp(-RateM*DPM_k*tstep)
    RPM1 <- RPM * exp(-RateM*RPM_k*tstep)
    Bio1 <- Bio * exp(-RateM*Bio_k*tstep)
    Hum1 <- Hum * exp(-RateM*Hum_k*tstep)
    
    DPM_d <- DPM - DPM1
    RPM_d <- RPM - RPM1
    Bio_d <- Bio - Bio1
    Hum_d <- Hum - Hum1
    
    x <- 1.67*(1.85+1.60*exp(-0.0786*clay))
    
    # proportion C from each pool into CO2, Bio and Hum
    DPM_co2 <- DPM_d*(x/(x+1))
    DPM_Bio <- DPM_d*(0.46/(x+1))
    DPM_Hum <- DPM_d*(0.54/(x+1))
    
    RPM_co2 <- RPM_d*(x/(x+1))
    RPM_Bio <- RPM_d*(0.46/(x+1))
    RPM_Hum <- RPM_d*(0.54/(x+1))
    
    Bio_co2 <- Bio_d*(x/(x+1))
    Bio_Bio <- Bio_d*(0.46/(x+1))
    Bio_Hum <- Bio_d*(0.54/(x+1))
    
    Hum_co2 <- Hum_d*(x/(x+1))
    Hum_Bio <- Hum_d*(0.46/(x+1))
    Hum_Hum <- Hum_d*(0.54/(x+1))
    
    # update C pools
    DPM2 <- DPM1
    RPM2 <- RPM1
    Bio2 <- Bio1 + DPM_Bio + RPM_Bio + Bio_Bio + Hum_Bio
    Hum2 <- Hum1 + DPM_Hum + RPM_Hum + Bio_Hum + Hum_Hum
    
    # split plant C to DPM and RPM
    Pl_C_DPM <- DPM_RPM / (DPM_RPM + 1.0) * Pl_inp
    Pl_C_RPM <- 1.0 / (DPM_RPM + 1.0) * Pl_inp
    
    # split OA C to DPM, RPM and Hum
    OA_C_DPM <- 0.49*OA_inp
    OA_C_RPM <- 0.49*OA_inp
    OA_C_Hum <- 0.02*OA_inp
    
    # add Plant C and OA_C to DPM, RPM and Hum
    DPM <- DPM2 + Pl_C_DPM + OA_C_DPM
    RPM <- RPM2 + Pl_C_RPM + OA_C_RPM
    Hum <- Hum2 + OA_C_Hum
    Bio <- Bio2
    
    SOC <- DPM + RPM + Bio + Hum + IOM
    
    # calc new ract of each pool
    DPM_Ract <- DPM1 * exp(-conr*DPM_Rage)
    RPM_Ract <- RPM1 * exp(-conr*RPM_Rage)
    
    Bio_Ract <- Bio1 * exp(-conr*Bio_Rage)
    DPM_Bio_Ract <- DPM_Bio * exp(-conr*DPM_Rage)
    RPM_Bio_Ract <- RPM_Bio * exp(-conr*RPM_Rage)
    Bio_Bio_Ract <- Bio_Bio * exp(-conr*Bio_Rage)
    Hum_Bio_Ract <- Hum_Bio * exp(-conr*Hum_Rage)
    
    Hum_Ract <- Hum1 * exp(-conr*Hum_Rage)
    DPM_Hum_Ract <- DPM_Hum * exp(-conr*DPM_Rage)
    RPM_Hum_Ract <- RPM_Hum * exp(-conr*RPM_Rage)
    Bio_Hum_Ract <- Bio_Hum * exp(-conr*Bio_Rage)
    Hum_Hum_Ract <- Hum_Hum * exp(-conr*Hum_Rage)
    
    IOM_Ract <- IOM * exp(-conr*IOM_Rage)
    
    # assign new C from plant and organic amendment the correct age
    Pl_DPM_Ract <- modernC * Pl_C_DPM
    Pl_RPM_Ract <- modernC * Pl_C_RPM
    
    OA_DPM_Ract <- modernC * OA_C_DPM
    OA_RPM_Ract <- modernC * OA_C_RPM
    OA_Hum_Ract <- modernC * OA_C_Hum
    
    # update ract for each pool
    DPM_Ract_new <- Pl_DPM_Ract + OA_DPM_Ract + DPM_Ract*exc
    RPM_Ract_new <- Pl_RPM_Ract + OA_RPM_Ract + RPM_Ract*exc
    
    Bio_Ract_new <- (Bio_Ract + DPM_Bio_Ract + RPM_Bio_Ract + Bio_Bio_Ract + Hum_Bio_Ract)*exc
    Hum_Ract_new <- (Hum_Ract + DPM_Hum_Ract + RPM_Hum_Ract + Bio_Hum_Ract + Hum_Hum_Ract)*exc
    
    Total_Ract <- DPM_Ract_new + RPM_Ract_new + Bio_Ract_new + Hum_Ract_new + IOM_Ract
    
    # calculate rage of each pool
    if(DPM <= zero){
      DPM_Rage <- zero
    } else {
      DPM_Rage <- log(DPM/DPM_Ract_new)/conr
    }
    
    if(RPM <= zero){
      RPM_Rage <- zero
    } else {
      RPM_Rage <- log(RPM/RPM_Ract_new)/conr
    }
    
    if(Bio <= zero){
      Bio_Rage <- zero
    } else {
      Bio_Rage <- log(Bio/Bio_Ract_new)/conr
    }
    
    if(Hum <= zero){
      Hum_Rage <- zero
    } else {
      Hum_Rage <- log(Hum/Hum_Ract_new)/conr
    }
    
    if(SOC <= zero){
      Total_Rage <- zero
    } else {
      Total_Rage <- log(SOC/Total_Ract)/conr
    }
    
    # at the end of each year this checks the stock against previous end of year 
    if(k %% timeFact == 0){
      TOC0 <- TOC1
      TOC1 <- DPM + RPM + Bio + Hum
      test <- abs(TOC1-TOC0)
    }
  }
  
  Total_Delta <- (exp(-Total_Rage/8035.0) - 1.0) * 1000.0
  
  co2_tot <- 0
  
  year_list <- list()
  year_list[[1]] <- data.frame(1, j, DPM, RPM, Bio, Hum, IOM, SOC, co2_tot, Total_Delta)
  colnames(year_list[[1]]) <- c('Year','Month','DPM_t_C_ha','RPM_t_C_ha','Bio_t_C_ha','Hum_t_C_ha','IOM_t_C_ha','SOC_t_C_ha','CO2_t_C_ha','deltaC')
  
  month_list <- list()
  
  # run RothC after spin-up
  for(i in seq(timeFact+1, nsteps,1)){
    
    TEMP <- df$t_temp[i]
    RAIN <- df$t_rain[i]
    PEVAP <- df$t_evap[i]
    
    PC <- df$t_PC[i]
    DPM_RPM <- df$t_DPM_RPM[i]
    
    Pl_inp <- df$t_Pl_inp[i]
    OA_inp <- df$t_OA_inp[i]
    
    modernC <- df$t_mod[i] / 100.0
    
    # Calculate RMFs
    RM_Temp <- RMF_Temp(TEMP)
    if(opt_RMmoist == 1){
      RM_Moist <- RMF_Moist(RAIN, PEVAP, clay, depth, PC, SMD, opt_RMmoist, opt_SMDbare)
    } else if(opt_RMmoist %in% c(2,3)){
      RM_Moist <- RMF_Moist(RAIN, PEVAP, clay, depth, PC, SMD, opt_RMmoist, opt_SMDbare, silt, OC, BulkD, min_RMmoist)
    }
    RM_PC <- RMF_PC(PC)
    
    # Combine RMFs into one.
    RateM <- RM_Temp*RM_Moist*RM_PC
    
    # decomposition
    DPM1 <- DPM * exp(-RateM*DPM_k*tstep)
    RPM1 <- RPM * exp(-RateM*RPM_k*tstep)
    Bio1 <- Bio * exp(-RateM*Bio_k*tstep)
    Hum1 <- Hum * exp(-RateM*Hum_k*tstep)
    
    DPM_d <- DPM - DPM1
    RPM_d <- RPM - RPM1
    Bio_d <- Bio - Bio1
    Hum_d <- Hum - Hum1
    
    x <- 1.67*(1.85+1.60*exp(-0.0786*clay))
    
    # proportion C from each pool into CO2, Bio and Hum
    DPM_co2 <- DPM_d*(x/(x+1))
    DPM_Bio <- DPM_d*(0.46/(x+1))
    DPM_Hum <- DPM_d*(0.54/(x+1))
    
    RPM_co2 <- RPM_d*(x/(x+1))
    RPM_Bio <- RPM_d*(0.46/(x+1))
    RPM_Hum <- RPM_d*(0.54/(x+1))
    
    Bio_co2 <- Bio_d*(x/(x+1))
    Bio_Bio <- Bio_d*(0.46/(x+1))
    Bio_Hum <- Bio_d*(0.54/(x+1))
    
    Hum_co2 <- Hum_d*(x/(x+1))
    Hum_Bio <- Hum_d*(0.46/(x+1))
    Hum_Hum <- Hum_d*(0.54/(x+1))
    
    # update C pools
    DPM2 <- DPM1
    RPM2 <- RPM1
    Bio2 <- Bio1 + DPM_Bio + RPM_Bio + Bio_Bio + Hum_Bio
    Hum2 <- Hum1 + DPM_Hum + RPM_Hum + Bio_Hum + Hum_Hum
    
    co2_tot_i <- co2_tot + DPM_co2 + RPM_co2 + Bio_co2 + Hum_co2
    co2_tot <- co2_tot_i
    
    # split plant C to DPM and RPM
    Pl_C_DPM <- DPM_RPM / (DPM_RPM + 1.0) * Pl_inp
    Pl_C_RPM <- 1.0 / (DPM_RPM + 1.0) * Pl_inp
    
    # split organic amendment C to DPM, RPM and Hum
    OA_C_DPM <- 0.49*OA_inp
    OA_C_RPM <- 0.49*OA_inp
    OA_C_Hum <- 0.02*OA_inp
    
    # add Plant C and organic amendment C to DPM, RPM and Hum
    DPM <- DPM2 + Pl_C_DPM + OA_C_DPM
    RPM <- RPM2 + Pl_C_RPM + OA_C_RPM
    Hum <- Hum2 + OA_C_Hum
    Bio <- Bio2
    
    SOC <- DPM + RPM + Bio + Hum + IOM
    
    # calc new ract of each pool
    DPM_Ract <- DPM1 * exp(-conr*DPM_Rage)
    RPM_Ract <- RPM1 * exp(-conr*RPM_Rage)
    
    Bio_Ract <- Bio1 * exp(-conr*Bio_Rage)
    DPM_Bio_Ract <- DPM_Bio * exp(-conr*DPM_Rage)
    RPM_Bio_Ract <- RPM_Bio * exp(-conr*RPM_Rage)
    Bio_Bio_Ract <- Bio_Bio * exp(-conr*Bio_Rage)
    Hum_Bio_Ract <- Hum_Bio * exp(-conr*Hum_Rage)
    
    Hum_Ract <- Hum1 * exp(-conr*Hum_Rage)
    DPM_Hum_Ract <- DPM_Hum * exp(-conr*DPM_Rage)
    RPM_Hum_Ract <- RPM_Hum * exp(-conr*RPM_Rage)
    Bio_Hum_Ract <- Bio_Hum * exp(-conr*Bio_Rage)
    Hum_Hum_Ract <- Hum_Hum * exp(-conr*Hum_Rage)
    
    IOM_Ract <- IOM * exp(-conr*IOM_Rage)
    
    # assign new C from plant and OA the correct age
    Pl_DPM_Ract <- modernC * Pl_C_DPM
    Pl_RPM_Ract <- modernC * Pl_C_RPM
    
    OA_DPM_Ract <- modernC * OA_C_DPM
    OA_RPM_Ract <- modernC * OA_C_RPM
    OA_Hum_Ract <- modernC * OA_C_Hum
    
    # update ract for each pool
    DPM_Ract_new <- OA_DPM_Ract + Pl_DPM_Ract + DPM_Ract*exc
    RPM_Ract_new <- OA_RPM_Ract + Pl_RPM_Ract + RPM_Ract*exc
    
    Bio_Ract_new <- (Bio_Ract + DPM_Bio_Ract + RPM_Bio_Ract + Bio_Bio_Ract + Hum_Bio_Ract)*exc
    Hum_Ract_new <- (Hum_Ract + DPM_Hum_Ract + RPM_Hum_Ract + Bio_Hum_Ract + Hum_Hum_Ract)*exc
    
    Total_Ract <- DPM_Ract_new + RPM_Ract_new + Bio_Ract_new + Hum_Ract_new + IOM_Ract
    
    # calculate rage of each pool
    if(DPM <= zero){
      DPM_Rage <- zero
    } else {
      DPM_Rage <- log(DPM/DPM_Ract_new)/conr
    }
    
    if(RPM <= zero){
      RPM_Rage <- zero
    } else {
      RPM_Rage <- log(RPM/RPM_Ract_new)/conr
    }
    
    if(Bio <= zero){
      Bio_Rage <- zero
    } else {
      Bio_Rage <- log(Bio/Bio_Ract_new)/conr
    }
    
    if(Hum <= zero){
      Hum_Rage <- zero
    } else {
      Hum_Rage <- log(Hum/Hum_Ract_new)/conr
    }
    
    if(SOC <= zero){
      Total_Rage <- zero
    } else {
      Total_Rage <- log(SOC/Total_Ract)/conr
    }
    
    Total_Delta <- (exp(-Total_Rage/8035.0) - 1.0)*1000.0
    
    # appending outputs to a list
    month_list[[i-timeFact]] <- data.frame(df[[i, 't_year']], df[[i,'t_month']],Pl_inp, OA_inp, TEMP, RM_Temp, RAIN, PEVAP, SMD, RM_Moist, PC, RM_PC, DPM, RPM, Bio, Hum, IOM, SOC, co2_tot)
    colnames(month_list[[i-timeFact]]) = c('Year','Month','Pl_inp_t_C_ha','OA_inp_t_C_ha','TEMP_C','RM_Temp','RAIN_mm','PEVAP_mm','SMD_mm','RM_Moist','PC','RM_PC','DPM_t_C_ha','RPM_t_C_ha','Bio_t_C_ha','Hum_t_C_ha','IOM_t_C_ha','SOC_t_C_ha',"CO2_t_C_ha")
    # appending outputs to end of year_list when loop i equals timeFact
    if(df$t_month[i] == timeFact){
      timeFact_index <- as.integer(i/timeFact)
      year_list[[timeFact_index]] <- data.frame(df[i,'t_year'], df[i,'t_month'],DPM, RPM, Bio, Hum, IOM, SOC, co2_tot, Total_Delta)
      colnames(year_list[[timeFact_index]]) = c('Year','Month','DPM_t_C_ha','RPM_t_C_ha','Bio_t_C_ha','Hum_t_C_ha','IOM_t_C_ha','SOC_t_C_ha',"CO2_t_C_ha",'deltaC')
      print(paste(i, DPM, RPM, Bio, Hum, IOM, SOC, Total_Delta))
    }
    
  }
  
  output_years <- do.call(rbind,year_list)
  
  output_months <- do.call(rbind, month_list)
  
  write.csv(output_years,
            'year_results.csv',
            row.names = FALSE)
  
  write.csv(output_months,
            'month_results.csv',
            row.names = FALSE)
}