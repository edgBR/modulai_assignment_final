trainRecipe <- function(df, min_tokens, max_tokens, step_tokens) {
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
      param_grid <- grid_regular(max_tokens(range = c(min_tokens, max_tokens)),
                                 levels = step_tokens
      )
      log_info("Param grid built")
      
      twitter_rec <- twitter_rec %>% 
        step_tokenize(text_stripped) %>%
        step_stopwords(text_stripped) %>%
        step_ngram(text_stripped, num_tokens = 3, min_num_tokens = 1) %>% 
        step_tokenfilter(text_stripped, max_tokens = tune(), min_times = min_tokens) %>% 
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
  return(list(initialsplit, train_split, test_split, twitter_rec, param_grid))
}

