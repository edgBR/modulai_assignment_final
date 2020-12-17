import tensorflow as tf
import tensorflow_hub as hub
module_url = "https://tfhub.dev/google/universal-sentence-encoder-large/3"
# Import the Universal Sentence Encoder's TF Hub module
embed = hub.Module(module_url)




data_clean = pd.read_csv(filepath_or_buffer="data/output/processed_data.csv")

X = data_clean['text_stripped'].tolist()

Y = data_clean['is_positive'].values


with tf.Session() as session:
  session.run([tf.global_variables_initializer(), tf.tables_initializer()])
  message_embeddings = session.run(embed(X))

message_train, message_test, y_train, y_test = train_test_split(X, Y, test_size=0.25, random_state=2020)

from keras.preprocessing.text import Tokenizer

tokenizer = Tokenizer(num_words=500, filters='!"#$%&()*+,-./:;<=>?@[\\]^_`{|}~\t\n',
    lower=True)
tokenizer.fit_on_texts(message_train)

X_train = tokenizer.texts_to_sequences(message_train_train).todense()
X_test = tokenizer.texts_to_sequences(message_train_test).todense()

maxlen=100

X_train = keras.preprocessing.sequence.pad_sequences(X_train, maxlen=maxlen)
X_test = keras.preprocessing.sequence.pad_sequences(X_test, maxlen=maxlen)

