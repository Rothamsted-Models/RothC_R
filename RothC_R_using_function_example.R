# For this to function as written, you may need to set the working directory 
# to the folder containing the downloaded files.

# setwd()

source("RothC_R_function.R")

RothC_model(filename = "RothC_input.dat")

year_results <- read.csv("year_results.csv")

month_results <- read.csv("month_results.csv")
