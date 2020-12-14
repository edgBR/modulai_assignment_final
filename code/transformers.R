library(keras)
library(tensorflow)
library(dplyr)
library(tfdatasets)
library(text2vec)


transformer = reticulate::import('transformers')
physical_devices = tf$config$list_physical_devices('GPU')
tf$config$experimental$set_memory_growth(physical_devices[[1]],TRUE) #CUDA does not work

tf$keras$backend$set_floatx('float32')

# get Tokenizer
transformer$RobertaTokenizer$from_pretrained('roberta-base', do_lower_case=TRUE)

# get Model with weights
transformer$TFRobertaModel$from_pretrained('roberta-base')

small_transformer <- twitter_data_small %>% 
  sample_n(2000) %>% 
  data.table::as.data.table()

idx_train = sample.int(nrow(small_transformer)*0.8)

train = small_transformer[idx_train,]
test = small_transformer[!idx_train,]

ai_m = list(
  c('TFGPT2Model',       'GPT2Tokenizer',       'gpt2'),
  c('TFRobertaModel',    'RobertaTokenizer',    'roberta-base'),
  c('TFElectraModel',    'ElectraTokenizer',    'google/electra-small-generator')
)


# parameters
max_len = 50L
epochs = 2
batch_size = 10

# create a list for model results
gather_history = list()

for (i in 1:length(ai_m)) {
  
  # tokenizer
  tokenizer = glue::glue("transformer${ai_m[[i]][2]}$from_pretrained('{ai_m[[i]][3]}',
                         do_lower_case=TRUE)") %>% 
    rlang::parse_expr() %>% eval()
  
  # model
  model_ = glue::glue("transformer${ai_m[[i]][1]}$from_pretrained('{ai_m[[i]][3]}')") %>% 
    rlang::parse_expr() %>% eval()
  
  # inputs
  text = list()
  # outputs
  label = list()
  
  data_prep = function(data) {
    for (i in 1:nrow(data)) {
      
      txt = tokenizer$encode(data[['message_clean']][i],max_length = max_len, 
                             truncation=T) %>% 
        t() %>% 
        as.matrix() %>% list()
      lbl = data[['is_possitive']][i] %>% t()
      
      text = text %>% append(txt)
      label = label %>% append(lbl)
    }
    list(do.call(plyr::rbind.fill.matrix,text), do.call(plyr::rbind.fill.matrix,label))
  }
  
  train_ = data_prep(train)
  test_ = data_prep(test)
  
  # slice dataset
  tf_train = tensor_slices_dataset(list(train_[[1]],train_[[2]])) %>% 
    dataset_batch(batch_size = batch_size, drop_remainder = TRUE) %>% 
    dataset_shuffle(128) %>% dataset_repeat(epochs) %>% 
    dataset_prefetch(tf$data$experimental$AUTOTUNE)
  
  tf_test = tensor_slices_dataset(list(test_[[1]],test_[[2]])) %>% 
    dataset_batch(batch_size = batch_size)
  
  # create an input layer
  input = layer_input(shape=c(max_len), dtype='int32')
  hidden_mean = tf$reduce_mean(model_(input)[[1]], axis=1L) %>% 
    layer_dense(64,activation = 'relu')
  # create an output layer for binary classification
  output = hidden_mean %>% layer_dense(units=1, activation='sigmoid')
  model = keras_model(inputs=input, outputs = output)
  
  # compile with AUC score
  model %>% compile(optimizer= tf$keras$optimizers$Adam(learning_rate=3e-5, epsilon=1e-08, clipnorm=1.0),
                    loss = tf$losses$BinaryCrossentropy(from_logits=F),
                    metrics = tf$metrics$AUC())
  
  print(glue::glue('{ai_m[[i]][1]}'))
  # train the model
  history = model %>% keras::fit(tf_train, epochs=epochs, #steps_per_epoch=len/batch_size,
                                 validation_data=tf_test)
  gather_history[[i]]<- history
  names(gather_history)[i] = ai_m[[i]][1]
}


res = sapply(1:3, function(x) {
  do.call(rbind,gather_history[[x]][["metrics"]]) %>% 
    as.data.frame() %>% 
    tibble::rownames_to_column() %>% 
    mutate(model_names = names(gather_history[x])) 
}, simplify = F) %>% do.call(plyr::rbind.fill,.) %>% 
  mutate(rowname = stringr::str_extract(rowname, 'loss|val_loss|auc|val_auc')) %>% 
  rename(epoch_1 = V1, epoch_2 = V2)