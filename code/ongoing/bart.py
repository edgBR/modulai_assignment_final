
import pandas as pd
import torch
from transformers import BartForSequenceClassification, BartTokenizer, __version__ as tv
import numpy as np


'''

Bart model is from the Transformers package by Huggingface
https://github.com/huggingface/transformers

Our version: 3.3.1

'''


print(tv)


DEVICE = 'cuda:0'

class BartZeroShot:
    def __init__(self):

        self.nli_model = BartForSequenceClassification.from_pretrained('facebook/bart-large-mnli')
        self.nli_model = self.nli_model.to(DEVICE)
        self.tokenizer = BartTokenizer.from_pretrained('facebook/bart-large-mnli')

    def predict(self, sentence, label):
        x = self.tokenizer.encode(sentence, f'this text is {label}',#f'This text is about {label}.',
                             return_tensors='pt',
                             max_length=500,
                             truncation = True,     
                             truncation_strategy='only_first')
        logits = self.nli_model(x.to(DEVICE))[0]

        entail_contradiction_logits = logits[:,[0,2]]
        probs = entail_contradiction_logits.softmax(1)
        prob_label_is_true = probs[:,1].item()
        return prob_label_is_true