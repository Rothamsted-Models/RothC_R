# Revision History

## Version 2.0.0
This version adds options to align with the Farina et al. (2013) which explored changing the effect of soil moisture for semi-arid soils.
The model can be run as before (version 1.0) through specific options.

Options are for the soil moisture rate modifying factor: opt_RMmoist and opt_SMDbare.

When opt_RMmoist is given the value 2 or 3, four additional variables are required:
Silt (%), bulk density (cm<sup>-3</sup>), organic carbon (%), and the value to use as the minimum for soil moisture rate modifying factor (the value aligning with version 1.0 is 0.2).
These are not required when opt_RMmoist is given the value 1.

The example files have been updated to show the new structures of the files.
See README.md and RothC_description.pdf for more details.

## Version 1.0.2
Adds the revision history file. Removes a setwd() function from RothC_script.R and corrects the filename within RothC_R_using_function_example.R

## Version 1.0.1
The first release of the R version to connect with Zenodo. Minor change to readme file. 

## Version 1.0.0
This version was the initial release of RothC (R version) aligning with Jenkinso (1990) (also previously referred to as RothC 26.3)
