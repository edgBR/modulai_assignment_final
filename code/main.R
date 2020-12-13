library(vroom)
library(logger)
library(optparse)
library(dplyr)
library(tidyr)
library(tidytext)
library(textdata)
log_level(level = "INFO")

source("get_data.R")
source("process_data.R")

### Note, change defaults by environment variables that can be injected to the code if running
### as a container somewhere

option_list <- list( 
  make_option(c("-i", "--input_data"), default='../data/input/',
              help="Default input data directory[default]",
              metavar="character"),
  make_option(c("-o", "--output_data"), default='../data/output/',
              help="Default output data directory[default]",
              metavar="character"),
  make_option(c("-f", "--file_name"), default='twitter_dataset_full.csv',
              help="Default output data directory[default]",
              metavar="character"),
  make_option(c("-m", "--model"), default='../model/',
              help="Model directory",
              metavar="character")
)

# get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults

argument_parser <- parse_args(OptionParser(option_list=option_list))

twitter_data <- loadData(input_path = argument_parser$input_data, 
                         file_name = argument_parser$file_name)

### the target is the first column (is_positive), EDA and text analysis are done in the notebook

processed_data <- processor(df = twitter_data)

## move to EDA?

sentiment_results <- sentimentAnalyser(df_processed = processed_data)


