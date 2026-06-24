# The Rothamsted carbon model (RothC)

## Purpose

Roth C models the turnover of organic carbon in non-waterlogged top-soil.  It accounts for the effects of soil texture, temperature, moisture content and plant cover on the turnover process. It uses a monthly time step to calculate total organic carbon (t ha<sup>-1</sup>), microbial biomass carbon (t ha<sup>-1</sup>) and Δ<sup>14</sup>C (from which the equivalent radiocarbon age of the soil can be calculated). 

## This release
**Version 2.0.0:** Adds options to moisture function to allow for dryland soils to be modelled as in (Farina, Coleman & Whitmore, 2013). Retains options for standard running.

Requires small change to input files to accommodate the options and additional soil variables (silt (%), bulk density (g cm<sup>-3</sup>), organic carbon (%))

## Model history

The first version of RothC created by David Jenkinson and James Rayner in 1977 (Jenkinson and Rayner, 1977).

In 1987 an updated version was published, see Jenkinson et al. (1987).  This version included the prediction of the radiocarbon age of the soil, the pools POM (physically stabilized organic matter) and COM (chemically stabilized organic matter) were replaced with Hum (humified organic matter) and IOM (inert organic matter), and the microbial biomass pool was split into BioA (autochthonous biomass) and BioZ (zymogenous biomass).  

**In 1990, the two biomass pools were combined into a single pool (Jenkinson, 1990) this version is the classic version of the model (version 1.0.0).**

**Farina et al. (2013) modified the soil water dynamics for semi-arid regions, this has been incorporated into version 2.0.0 (retaining the functionality of version 1.0.0)**

Other published developments of the model include:

Giongo et al. (2020) created a daily version, for Caatinga shrublands, in the semiarid region, North-East Brazil.

 
## Description of files included

### RothC_description.pdf
This file contains the description of the model.


### RothC.R
This file contains the RothC code. Details of the inputs required, pools modelled, and units are in the code.
Note: the global assign (<<-) used for SMD within the RMF_Moist() function is required for the expected behaviour of the model (aligning with results from the other language versions). 
Users with experience in R can remap the inputs to environment variables and objects if more convenient. We have not provided code for this due to the many ways individuals can organise their data.

### RothC_function.R
This file contains the RothC code wrapped in a function with the argument “filename” used to supply the filepath of the input file. This is a minimal change but is to provide users with less experience a ready-made function (RothC_model). Those with more experience can enhance this function, and the code, linking directly to environment objects and variables. 

### Using_RothC_function.R
This file contains the simple code to load the function to your R environment and run the model with the example file. If the example file is not in the same working directory, the corresponding filepath would need to be provided as part of the filename string (i.e. “filepath/RothC_input.dat”).


### RothC_input.dat  
This file contains input variables for the model.

Value for the **opt_RMmoist** option can be 1, 2, or 3
Value for the **opt_SMDbare** option can be 1 or 2
*see RothC_description section 1.6.2.2 for explanation of these options*

Then values for **clay** (%), **soil depth** (cm), **inert organic matter** (IOM, t C ha<sup>-1</sup>),  **number of steps** (nsteps),  **silt** (%), **bulk density** (BD, g cm<sup>-3</sup>), **organic carbon** (OC, %), and **minRM_Moist** which is the minimum value to be used for the rate-modifying for soil moisture are recorded.  

The **last four variables** are only read in when **opt_RMmoist is 2 or 3**.
If **opt_RMmoist is 1** the value of **minRM_Moist** is taken as 0.2.

Following that there is a table which records monthly data on **year**, **month**, **percentage of modern carbon**  (%), **mean air temperature** (Tmp, °C), **total monthly rainfall** (Rain, mm), **total monthly open-pan evaporation** (Evap, mm), **all carbon input entering the soil from plants** (e.g. shoots, roots, root exudates) (Pl_inp, t C ha<sup>-1</sup>), **carbon input from organic amendment** (OA_inp, t C ha<sup>-1</sup>), **plant cover** (PC, 0 for no plants e.g. bare or post-harvest, 1 for plants e.g. crop or grass), and the **DPM/RPM ratio** (DPM_RPM) of the carbon inputs from plants.


### year_results.out
This file contains the yearly values of the SOC (both the pools and Total) and the delta 14-carbon.

The columns are:  
**Year**  
**Month** 	- Always December for the yearly output  
**DPM_t_C_ha** 	- Decomposable plant material (t C ha<sup>-1</sup>)  
**RPM_t_C_ha** 	- Resistant plant material (t C ha<sup>-1</sup>)  
**Bio_t_C_ha** 	- Microbial biomass (t C ha<sup>-1</sup>)  
**Hum_t_C_ha**	    - Humified organic matter (t C ha<sup>-1</sup>)  
**IOM_t_C_ha** 	- Inert organic matter (t C ha<sup>-1</sup>)  
**SOC_t_C_ha**	    - Total soil organic carbon (t C ha<sup>-1</sup>)
**CO2_t_C_ha**     - Accumulated carbon dioxide (t C ha<sup>-1</sup>)
**deltaC** 	- delta <sup>14</sup>C (‰)  


The total organic carbon (soil organic carbon) is equal to the sum of the 5 pools. 

TOC or SOC = DRM + RPM + BIO + HUM + IOM 
     
### month_results.out
This file contains the monthly inputs, rate modifying factors, SOC pools.

**Year**  
**Month**  
**Pl_inp_t_C_ha**	- C input (t C ha<sup>-1</sup>)  
**OA_inp_t_C_ha**	- Farmyard manure (t C ha<sup>-1</sup>)  
**TEMP_C**		    - Air temperature (C)  
**RM_TMP**		    - Rate modifying factor for temperature (-)  
**RAIN_mm**		    - Rainfall (mm)  
**PEVAP_mm**		- Open pan evaporation (mm)  
**SMD_mm**		    - Accumulated soil water deficit (mm)  
**RM_Moist**		- Rate modifying factor for soil moisture (-)  
**PC**			    - Soil plant cover (0 bare or 1 covered)  
**RM_PC**			- rate modifying factor for crop cover  
**DPM_t_C_ha**		- Decomposable plant material (t C ha<sup>-1</sup>)  
**RPM_t_C_ha**		- Resistant plant material (t C ha<sup>-1</sup>)  
**Bio_t_C_ha**		- Microbial biomass (t C ha<sup>-1</sup>)  
**Hum_t_C_ha**		- Humified organic matter (t C ha<sup>-1</sup>)  
**IOM_t_C_ha**		- Inert organic matter (t C ha<sup>-1</sup>)  
**SOC_t_C_ha**		- Total soil organic carbon (t C ha<sup>-1</sup>)  
**CO2_t_C_ha**      - Accumulated carbon dioxide (t C ha<sup>-1</sup>)

## Requirements
The code was written in R version 4.2.3. but only uses basic R functions, alongside those defined for the model.
The code as written uses an identical input file structure to the other languages we have releases of RothC for (Fortran and Python).


**Example of how to run the model**  
The file RothC_input.dat contains all the input data needed to run the model. The month results (month_results.out) and year results (year_results.out) files correspond to this input file as an example. 
The model is normally run to equilibrium using average temperature, rainfall, open pan evaporation, and an average carbon input to the soil. The equilibrium run is to initialise the soil carbon pools. Once the soil carbon pools have been initialised, the model is run for the period of interest. The met data (temperature, rainfall and evaporation) can be average or actual weather data. The carbon input to the soil can be: 1) adjusted so the modelled output matches the measured data, or 2) can be estimated from yield or biomass data (Bolinder et al., 2007), or NPP data.  

As mentioned in the file descriptions, the code has been provided as a standalone script and as a function script taking the filepath of the input file as an argument. 


## Note on the implementation of the (Wösten et al., 1999) and (van Genuchten, 1980) calculations with Farina et al. (2013)
The following code is present in the Fortran code but is unused so for clarity of the script these lines have been removed to here:

**Would be positioned between m and wc line 133**
    ksat (saturated hydraulic conductivity), l_star and l are not needed for the calculated soil properties for RothC

         ksat=exp(7.755 +0.0352*silt +0.93*t -0.967*BD^2
             -0.000484*clay^2 -0.000322*silt^2
             +0.001*silt^-1 -0.0748*(OC*1.72)^-1
             -0.643*log(silt) -0.01398*BD*clay -0.1673*BD*(OC*1.72)
             +0.02986*clay*t -0.03305*silt*t)

         l_star=(0.0202 +0.0006193*clay^2 -0.001136*(OC*1.72)^2
             -0.2316*log(OC*1.72) -0.03544*BD*clay +0.00283*BD*silt
             +0.0488*BD*OC*1.72)

         l=10*(exp(l_star)-1)/(exp(l_star)+1)

**The calculation of 0 mbar, wcSAT and X0 are also unused so removed to here.**
**0 mbar would be the first element of mbars vector and the for loop with i in 1:4 would be 1:5**
**wcSAT and X0 lines would go at the top of their respective sets approx. line 139 and line 144**
    wcSAT <- wc[[1]]
    X0 <- (wcSAT - wcFC)*10*depth

	
## References

Bolinder MA, Janzen HH, Gregorich EG, Angers DA, VandenBygaart AJ. An approach for estimating net primary productivity and annual carbon inputs to soil for common agricultural crops in Canada. Agriculture, Ecosystems & Environment 2007; 118: 29-42.  
Farina R, Coleman K, Whitmore AP. Modification of the RothC model for simulations of soil organic C dynamics in dryland regions. Geoderma 2013; 200: 18-30.  
Giongo V, Coleman K, Santana MD, Salviano AM, Olszveski N, Silva DJ, et al. Optimizing multifunctional agroecosystems in irrigated dryland agriculture to restore soil carbon - Experiments and modelling. Science of the Total Environment 2020; 725.  
Jenkinson DS. The Turnover of Organic-Carbon and Nitrogen in Soil. Philosophical Transactions of the Royal Society of London, Series B: Biological Sciences 1990; 329: 361-368.  
Jenkinson DS, Hart PBS, Rayner JH, Parry LC. Modelling the turnover of organic matter in long-term experiments at Rothamsted. INTECOL Bulletin 1987; 15: 1-8.  
Jenkinson DS, Rayner JH. Turnover of soil organic matter in some of the Rothamsted classical experiments. Soil Science 1977; 123: 298-305.  
van Genuchten, M. T. (1980). A Closed-form Equation for Predicting the Hydraulic Conductivity of Unsaturated Soils. Soil Science Society of America Journal, 44(5), 892–898. https://doi.org/https://doi.org/10.2136/sssaj1980.03615995004400050002x 
Wösten, J. H. M., Lilly, A., Nemes, A., & Le Bas, C. (1999). Development and use of a database of hydraulic properties of European soils. Geoderma, 90(3), 169–185. https://doi.org/10.1016/S0016-7061(98)00132-3 
