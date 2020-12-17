library(dplyr)
library(tidyr)
library(tidytext)
library(stringr)
library(textdata)

#'@author Edgar Bahilo Rodríguez
#'@param input_path The directory where the input data is stored
#'@param file_name the file that we want to load
#'@return A tibble dataframe containing the twitter data



processorBasic <- function(df, sample_size) {
  tryCatch(
    df_out <- {
      df <- sample_n(df, size = sample_size)
      log_info(paste0("Selecting ", sample_size, " observations"))
      df <- df %>% filter(!str_detect(message, "^RT")) 
      log_info("Removed retweets")
      df <- df %>% 
        mutate(text = str_remove_all(message, "@[[:alnum:]]+")) %>% #this is not working as expected
        mutate(text = str_remove_all(text, "#[[:alnum:]]+")) # this is not working as expected
      log_info("Removed @usernames and hashtags")
      df <- df %>% mutate(text = str_replace_all(text, "&amp;", "and"))
      log_info("Changing & by and")
      df <- df %>% mutate(text = str_replace_all(text, "\\\n", " "))
      log_info("Cleaning spaces")
      df <- df %>% mutate(text = str_remove_all(message, "&lt;|&gt;"))
      log_info("Removed < and >")
      df <- df %>% 
        mutate(text_stripped = str_remove_all(text, " ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)"))
         #removing hyperlinks just in case
      log_info("URLs removed")
      df_out <- df %>% mutate(text_stripped = str_to_lower(text_stripped))
      log_info("Forced lowercase")
      df_out <- df_out %>% mutate(is_positive = as.factor(is_positive))
    }, error = function(e){
      message(e)
     return(NA)
    }, warning = function(w){
      message(w)
      return(NULL)
    }
    )
return(df_out)
}

### TODO Document function
sentimentAnalyser <- function(cleaned_df, engine) {
  df_out <- tryCatch(
    {
      cleaned_df %>% 
        unnest_tokens(word, text_stripped) %>% 
        anti_join(stop_words) %>% 
        inner_join(get_sentiments(lexicon = engine)) %>% 
        count(word, sentiment, sort = TRUE) %>% 
        ungroup() 
    }, error = function(e){
      log_error(e)
      return(NA)
    }, warning = function(w){
      log_warn(w)
    }, finally = {
      log_info(paste0("Sentiment table generated using engine: ", engine))
      log_info("Sentiment Analyser Succeded")
    }
  )
  return(df_out)
}


# sentimentScore <- function(sentiment_df) {
#   sent_score <- tryCatch(
#     {   
#         case_when(
#         nrow(sentiment_df)== 0~0,
#         nrow(sentiment_df)>0~sum(sentiment_df$score)
#       )
#       
#     }, error = function(e){
#       log_error(e)
#       return(NA)
#     }, warning = function(w){
#       log_warn(w)
#     }, finally = {
#       log_info("Sentiment Score Calculation Succeded")
#     }
#   )
#   return(sent_score)
# }

# zero_type = case_when(
#   nrow(sentiment_df) == 0~"Type 1",
#   nrow(sentiment_df)>0~"Type 2",
# )