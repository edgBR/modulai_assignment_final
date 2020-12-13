#'@author Edgar Bahilo Rodríguez
#'@param input_path The directory where the input data is stored
#'@param file_name the file that we want to load
#'@return A tibble dataframe containing the twitter data


loadData <- function(input_path, file_name) {
  data <- tryCatch(
    {
      vroom(paste0(input_path, "/", file_name))
    }, error = function(e){
      log_error(e)
      return(NA)
    }, warning = function(w){
      log_warn(w)
      return(NULL)
    }, finally = {
      log_info("Reading data succeded")
    }
  )
}

