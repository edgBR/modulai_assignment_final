import transformers
from transformers import BertModel, BertTokenizer, AdamW, get_linear_schedule_with_warmup
import torch
import numpy as np
import pandas as pd
import seaborn as sns
from pylab import rcParams
import matplotlib.pyplot as plt
from matplotlib import rc
from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix, classification_report
from collections import defaultdict
from textwrap import wrap
from torch import nn, optim
from torch.utils.data import Dataset, DataLoader


RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
torch.manual_seed(RANDOM_SEED)
device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

PRE_TRAINED_MODEL_NAME = 'bert-base-cased'
tokenizer = BertTokenizer.from_pretrained(PRE_TRAINED_MODEL_NAME)

data_clean = pd.read_csv(filepath_or_buffer="data/input/dataset_small_w_bart_preds.csv")

text = data_clean["message_clean"].astype(str).tolist()
marked_text = []
for e in text:
    marked_text.append("[CLS] " + str(e) + " [SEP]")
print(*marked_text)

tokens = tokenizer.tokenize( data_clean["message_clean"].astype(str).tolist())
token_ids = tokenizer.convert_tokens_to_ids(tokens)
