import os
import warnings

os.environ["KERAS_BACKEND"] = "torch"  # use pytorch as keras backend
os.environ["TF_CPP_MIN_LOG_LEVEL"] = '3'  # mute all tensorflow info, warnings, and error msgs. #shujun
os.environ["KMP_WARNINGS"] = '0'  # mute all OpenMP warnings. #shujun
# warnings.filterwarnings("ignore", category=FutureWarning)  # mute tensorflow warnings and pyarrow warning
warnings.filterwarnings("ignore", category=UserWarning)  # mute keras warning

# Use if True to suppress the PEP8: E402 warning
if True:  # noqa: E402
    import datetime
    import json
    import math
    import multiprocessing as mp
    import psutil
    import regex as re
    import shutil
    import subprocess
    import tempfile
    import time
    from typing import Union, Optional

    import numpy as np
    import pandas as pd
    import swifter

    from Bio import SeqIO
    from Bio.Seq import Seq
    from Bio.SeqRecord import SeqRecord

    from sklearn.preprocessing import LabelEncoder
    # Attention: sklearn does not automatically import its subpackages
    # import tensorflow as tf
    import torch
    import keras
    # from tensorflow.python.framework.errors_impl import InternalError
    # from keras.utils import to_categorical
    # from keras.models import load_model


# Acceptable additional args
CHECKPOINT_OFF = "CHECKPOINT_OFF"
NO_PARALLEL = "NO_PARALLEL"
SKIP_TIRVISH = "SKIP_TIRVISH"
SKIP_GRF = "SKIP_GRF"

FILE_NAME_SPLITER = "-+-"
CONSOLE_SPLITER_LEN = 32

TIR_SUPERFAMILIES = ("DTA", "DTC", "DTH", "DTM", "DTT")

CNN_MODEL_DIR_PATH = "./cnn0912/cnn0912.keras"
SANDBOX_DIR_NAME = "[DONT_ALTER]TIR-Learner_sandbox"
SPLIT_FASTA_TAG = "SplitFasta"

PROGRAM_ROOT_DIR_PATH = os.path.abspath(str(os.path.dirname(os.path.dirname(__file__))))
CNN_MODEL_DIR_PATH = os.path.join(PROGRAM_ROOT_DIR_PATH, CNN_MODEL_DIR_PATH)

REFLIB_DIR_NAME = "RefLib"
REFLIB_AVAILABLE_SPECIES = ("rice", "maize")
REFLIB_FILE_DICT = {species: [f"{species}_{TIR_type}_RefLib" for TIR_type in TIR_SUPERFAMILIES]
                    for species in REFLIB_AVAILABLE_SPECIES}
REFLIB_DIR_PATH = os.path.join(PROGRAM_ROOT_DIR_PATH, REFLIB_DIR_NAME)

DEFAULT_ALLOCATED_PROCESSORS = os.cpu_count() - 2 if os.cpu_count() > 2 else 1

TIRVISH_SPLIT_SEQ_LEN = 5 * (10 ** 6)  # 5 mb
TIRVISH_OVERLAP_SEQ_LEN = 50 * (10 ** 3)  # 50 kb

# TODO only for debug
# TIRvish_split_seq_len = 10 * (10 ** 3)
# TIRvish_overlap_seq_len = 10 * (10 ** 3)

SHORT_SEQ_LEN = 2000
# GENERAL_SPLIT_NUM_THRESHOLD = 5
# MIX_SPLIT_PERCENT_THRESHOLD = 0.05
# MIX_SHORT_SEQ_PROCESS_NUM = 2


def process_additional_args(additional_args: list[str]) -> tuple[str]:
    if additional_args == [""]:
        return tuple()
    processed_additional_args = tuple(map(str.upper, additional_args))
    if (SKIP_TIRVISH in processed_additional_args) and (SKIP_GRF in processed_additional_args):
        raise SystemExit("ERROR: \"skip_tirvish\" and \"skip_grf\" cannot be specified at the same time!")
    return processed_additional_args
