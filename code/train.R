trainRecipe <- function(df, max_tokens) {
  tryCatch(
    {
      initialsplit <- initial_split(df, strata = is_positive)
      log_info("Initial split done")
      train_split <- training(initialsplit)
      log_info("Training split done")
      test_split <- testing(initialsplit)
      log_info("Testing split done")
      
      twitter_rec <- recipe(is_positive ~ text_stripped, 
                            data = df %>% select(-c(text, message)))
      # param_grid <- grid_regular(max_tokens(range = c(min_tokens, max_tokens)),
      #                            levels = step_tokens)
      # log_info("Param grid built")
      
      twitter_rec <- twitter_rec %>% 
        step_tokenize(text_stripped) %>%
        step_stopwords(text_stripped) %>%
        step_stem(text_stripped) %>%
        step_ngram(text_stripped, num_tokens = 3, min_num_tokens = 1) %>% 
        step_tokenfilter(text_stripped, max_tokens = max_tokens) %>% 
        step_tfidf(text_stripped)
      
    }, error = function(e){
      log_error(e)
      return(NA)
    }, warning = function(w){
      log_warn(w)
    }, finally = {
      log_info("Training recipe succeded")
    }
  )
  return(list(initialsplit, train_split, test_split, twitter_rec))
}

modelDef <- function(mode, engine) {
  if(engine == "xgboost") {
  model <- 
    boost_tree(mtry = tune(), 
               trees = 500,
               min_n = tune(),
               tree_depth = tune(), 
               learn_rate = tune(),
               loss_reduction = tune(),
               sample_size = tune()) %>%
    set_mode(mode) %>% 
    set_engine(engine)
  } else {
    model <- NULL
  }
  return(model)
}

xgbGrid <- function(training_data) {
  grid <- grid_latin_hypercube(
    tree_depth(),
    min_n(),
    loss_reduction(),
    sample_size = sample_prop(),
    finalize(mtry(), training_data),
    learn_rate(),
    size = 30
  )
  return(grid)
}

# modelParam <- function(model_def) {
#   if(model_def$engine == 'xgboost') {
#   model_param <- model_def %>%
#     parameters() %>% 
#     update(mtry = mtry(c(2L, 6L)),
#            # trees = trees(c(1000L, 2000L)),
#            # min_n = min_n(c(2L, 14L)),
#            tree_depth = tree_depth(c(1L, 4L))
#            # loss_reduction = loss_reduction(c(-10, 0)),
#            # learn_rate = learn_rate(),
#            # sample_size = sample_prop(c(.25, .75))
#     )
#   } else {
#     model_param <- NULL
#   }
#   
# }
