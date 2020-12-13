library(ggplot2)

#'@author Edgar Bahilo Rodríguez
#'@param df The directory where the input data is stored
#'@param top_n the file that we want to load
#'#'@param column_name
#'@return A ggplot object



get_top_words <- function(df, number_top) {
    plot_out <- tryCatch(
      {
        df %>% 
          count(word, sort = TRUE) %>% 
          top_n(number_top) %>% 
          mutate(word = reorder(word, n)) %>% 
          ggplot(aes(x = word, y = n)) +
          geom_col() + xlab(NULL) + coord_flip() +
          labs(x = "Count",
               y = "Unique words",
               title = paste0("Top ", as.character(number_top), 
                              " words in Twitter data set"))
        
      }, error = function(e){
        log_error(e)
        return(NA)
      }, warning = function(w){
        log_warn(w)
      }, finally = {
        log_info("Plot succeded")
      }
    )
    return(plot_out)
}


#TODO document function

get_sentiments_plot <- function(df, number_top) {
  plot_out <- tryCatch(
    {
      df %>% 
        group_by(sentiment) %>% 
        top_n(number_top) %>% 
        mutate(word = reorder(word, n)) %>% 
        ggplot(aes(x = word, y = n, fill = sentiment)) +
        geom_col(show.legend = FALSE)  + coord_flip() +
        facet_wrap(~sentiment, scales = "free_y") +
        labs(title = "Tweets according to basic sentiment engine",
             y = "Contribution to sentiment",
             x = "Null")
    }, error = function(e){
      log_error(e)
      return(NA)
    }, warning = function(w){
      log_warn(w)
    }, finally = {
      log_info("Plot succeded")
    }
  )
  return(plot_out)
}