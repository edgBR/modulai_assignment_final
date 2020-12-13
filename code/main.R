library(vroom)
library(logger)
library(optparse)
library(dplyr)
library(tidyr)
library(tidytext)
library(textdata)
library(stringr)
library(stopwords)
library(tidymodels)
library(textrecipes)
library(discrim)
library(tune)

log_level(level = "INFO")

source("get_data.R")
source("process_data.R")
source("train.R")

### Note, change defaults by environment variables that can be injected to the code if running
### as a container somewhere

option_list <- list( 
  make_option(c("-i", "--input_data"), default='../data/input/',
              help="Default input data directory[default]",
              metavar="character"),
  make_option(c("-s", "--samples"), default=50000,
              help="Number of training samples",
              metavar="integer"),
  make_option(c("-o", "--output_data"), default='../data/output/',
              help="Default output data directory[default]",
              metavar="character"),
  make_option(c("-f", "--file_name"), default='dataset_small_w_bart_preds.csv',
              help="Default output data directory[default]",
              metavar="character"),
  make_option(c("-m", "--model"), default='../model/',
              help="Model directory",
              metavar="character")
)

# get command line options, if help option encountered print help and exit,
# otherwise if options not found on command line then set defaults

argument_parser <- parse_args(OptionParser(option_list=option_list))

twitter_data_small <- loadData(input_path = argument_parser$input_data, 
                         file_name = argument_parser$file_name)
twitter_data_big <-  loadData(input_path = argument_parser$input_data, 
                                    file_name = "twitter_dataset_full.csv") %>% 
  select(is_positive, message)

### the target is the first column (is_positive), EDA and text analysis are done in the notebook
### using the plotting_utils file

processed_data <- processorBasic(df = twitter_data_big,
                                 sample_size = argument_parser$samples)

## move to EDA?

sentiment_results <- sentimentAnalyser(cleaned_df = processed_data, 
                                       engine = "bing")



training_configuration <- trainRecipe(processed_data, 
            min_tokens = 100, 
            max_tokens = 400, 
            step_tokens = 5)

set.seed(2020)

svm_spec <- svm_rbf() %>%
  set_mode("classification") %>%
  set_engine("liquidSVM")


folds <- vfold_cv(training_configuration[[2]], # Not the best way of doing this
                  repeats = 1)

model_workflow <- workflow() %>%
  add_recipe(training_configuration[[4]]) %>% # Not the best way of doing this
  add_model(svm_spec)

model_resamples_tunning <- tune_grid(
  model_workflow,
  folds,
  grid = training_configuration[[5]], # Not the best way of doing this
  control = control_resamples(save_pred = TRUE),
  metrics = metric_set(accuracy, sensitivity, specificity)
)

best_accuracy <- select_best(model_resamples_tunning, "roc_auc")

final_model <- finalize_workflow(
  model_resamples_tunning,
  best_accuracy
  )

