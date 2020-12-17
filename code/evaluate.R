evaluate <- function(model_workflow, new_data) {
  df_out <- new_data %>% 
    rename(text_stripped = message_clean) %>% 
    mutate(is_positive = as.factor(is_positive))
  
  df_out <- df_out %>% 
    mutate(xgboost_is_positive = predict(final_fit, 
                                         new_data = df_out, 
                                         type="prob")$.pred_1)
  return(df_out)
}