#'@author Edgar Bahilo Rodríguez
#'@param input_path The directory where the input data is stored
#'@param file_name the file that we want to load
#'@return A tibble dataframe containing the twitter data


processor <- function(df = twitter_data) {
   tryCatch(
    {
      df$message_stripped <- gsub("http\\S+", "", df$message)
      log_info("URLs removed")
      data_no_stem <- df %>% select(message_stripped) %>% unnest_tokens(word, message_stripped)
      log_info("Stemming removed")
      data_no_stop_words <- data_no_stem %>% anti_join(stop_words)
      log_info("Stop words removed")
    }, error = function(e){
      log_error(e)
      return(NA)
    }, warning = function(w){
      log_warn(w)
    }, finally = {
      log_info("Processing Data Succeded")
    }
  )
  return(data_no_stop_words)
}


sentimentAnalyser <- function(cleaned_df, engine) {
  df_out <- tryCatch(
    {
     cleaned_df %>% 
        inner_join(get_sentiments(lexicon = engine)) %>% 
        count(word, sentiment, sort = TRUE) %>% 
        ungroup()
      log_info(paste0("Sentiment table generated using engine: ", engine))
    }, error = function(e){
      log_error(e)
      return(NA)
    }, warning = function(w){
      log_warn(w)
    }, finally = {
      log_info("Sentiment Analyser Succeded")
    }
  )
  return(df_out)
}


sentimentCalculation <- function(sentiment_df) {
  df_out <- tryCatch(
    {
      sentiment_df %>% 
        inner_join(get_sentiments(lexicon = engine)) %>% 
        count(word, sentiment, sort = TRUE) %>% 
        ungroup()
      log_info(paste0("Sentiment table generated using engine: ", engine))
    }, error = function(e){
      log_error(e)
      return(NA)
    }, warning = function(w){
      log_warn(w)
    }, finally = {
      log_info("Sentiment Analyser Succeded")
    }
  )
  return(df_out)
}