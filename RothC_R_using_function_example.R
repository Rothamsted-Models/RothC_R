# For this to function as written, you may need to set the working directory 
# to the folder containing the downloaded files.

# The code will function if you set an explicit filepath for filename;
# however without setting a working directory, the results csv files may appear 
# where this script is located or in the current working directory.

# In practice, the results can be captured to the environment instead of or in addition to the csv files.


setwd("B:/Github_RothC_development/RothC_R_git/")

source("RothC_R_function.R")

RothC_model(filename = "RothC_input.dat")

year_results <- read.csv("year_results.csv")

month_results <- read.csv("month_results.csv")
