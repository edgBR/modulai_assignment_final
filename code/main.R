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
library(dials)
library(vip)
library(yardstick)

set.seed(2020)
log_level(level = "INFO")
doParallel::registerDoParallel()

source("get_data.R")
source("process_data.R")
source("train.R")
source("evaluate.R")

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


######### PROCESSING PIPELINE

twitter_data_small <- loadData(input_path = argument_parser$input_data, 
                         file_name = argument_parser$file_name)
twitter_data_big <- loadData(input_path = argument_parser$input_data, 
                                    file_name = "twitter_dataset_full.csv") %>% 
  select(is_positive, message)

### the target is the first column (is_positive), EDA and text analysis are done in the notebook
### using the plotting_utils file

processed_data <- processorBasic(df = twitter_data_big,
                                 sample_size = argument_parser$samples)

sentiment_results <- sentimentAnalyser(cleaned_df = processed_data, 
                                       engine = "bing")

######### TRAINING & HPO PIPELINE

training_configuration <- trainRecipe(processed_data, 
            max_tokens = 400)
xgb_model <- modelDef(mode = "classification", 
                      engine = "xgboost")
xgb_grid <- xgbGrid(training_data = training_configuration[[2]])

folds <- vfold_cv(training_configuration[[2]], # Not the best way of doing this
                  v = 3,
                  strata = "is_positive",
                  repeats = 1)

model_workflow <- workflow() %>%
  add_recipe(training_configuration[[4]]) %>% # Not the best way of doing this
  add_model(xgb_model)

xgb_search <- tune_grid(
  model_workflow,
  resamples = folds,
  grid = xgb_grid,
  control = control_resamples(save_pred = TRUE),
  metrics = metric_set(accuracy, roc_auc)
)

xgb_predictions <- collect_predictions(xgb_search)

best_accuracy <- select_best(xgb_search, "roc_auc")

final_model_workflow <- finalize_workflow(
  model_workflow,
  best_accuracy
  )


########### MODEL SAVING

final_result <- last_fit(final_model_workflow, 
                      training_configuration[[1]], 
                      metrics = metric_set(accuracy, roc_auc))

final_fit <- fit(final_model_workflow, 
                 processed_data %>% select(-c(text, message)))

model_object <- pull_workflow_fit(final_fit)$fit

saveRDS(model_object, 
        file = paste0(argument_parser$model, "xgboost.rds"))

########### EVALUATION PIPELINE - COMPARISON WITH BART

twitter_data_small <- twitter_data_small %>% 
  rename(text_stripped = message_clean) %>% 
  mutate(is_positive = as.factor(is_positive))

twitter_data_small <- twitter_data_small %>% 
  mutate(xgboost_pred = predict(final_fit, twitter_data_small)$.pred_class) %>% 
  mutate(binary_bart = case_when(
    bart_is_positive >= 0.5~1,
    bart_is_positive < 0.5~0
  ))


