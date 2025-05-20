from const import *


def get_start_end(genome_file: str, df_in: pd.DataFrame, flag_verbose: bool, length: int = 200) -> pd.DataFrame:
    df = df_in.copy()
    df["start"] = df.swifter.progress_bar(flag_verbose).apply(lambda x: min(x["sstart"], x["send"]), axis=1)
    df["end"] = df.swifter.progress_bar(flag_verbose).apply(lambda x: max(x["sstart"], x["send"]), axis=1)
    df["sstart"] = df["start"]
    df["send"] = df["end"]

    df["start"] = df.swifter.progress_bar(flag_verbose).apply(lambda x: max(x["sstart"] - length, 1) - 1, axis=1)
    # start = start - length if start > length else 1, start--
    df["end"] = df.swifter.progress_bar(flag_verbose).apply(lambda x: x["send"] + length, axis=1)

    # Ensure "end" not exceeding seq's length
    fasta_len_dict = {rec.id: len(rec.seq) for rec in SeqIO.parse(genome_file, "fasta")}
    df["end"] = df.swifter.progress_bar(flag_verbose).apply(lambda x: min(x["end"], fasta_len_dict[x["seqid"]]), axis=1)

    # df["p_start"] = df.apply(lambda x: max(min(x["p1"], x["p2"]) - length, 1) - 1, axis=1)
    # # p_start = min(p1, p2)
    # # p_start = p_start - 200 if p_start > 200 else 1
    # df["p_end"] = df.apply(lambda x: max(x["p1"], x["p2"]) + length, axis=1)

    df = df.drop_duplicates(["start", "end", "seqid", "TIR_type"], keep="first", ignore_index=True)
    return df


def __get_fasta_pieces_single_seqid_SeqIO(df_in: pd.DataFrame, genome_SeqRecord: SeqIO.SeqRecord, seqid: str,
                                          flag_verbose: bool) -> Optional[pd.DataFrame]:
    df = df_in[df_in["seqid"] == seqid].copy()
    if df.shape[0] == 0:
        return None

    df["seq"] = df.swifter.progress_bar(flag_verbose).apply(
        lambda x: str(genome_SeqRecord.seq[x["start"]: x["end"]]), axis=1)
    return df.dropna()


def get_fasta_pieces_SeqIO(genome_file: str, df_in: pd.DataFrame,
                           processors: int, flag_verbose: bool) -> Optional[pd.DataFrame]:
    if df_in is None or df_in.shape[0] == 0:
        return None

    df = df_in.copy()
    genome_SeqIO_index = SeqIO.index(genome_file, "fasta")
    mp_args_list = [(df, genome_SeqIO_index[seqid], seqid, flag_verbose) for seqid in genome_SeqIO_index]
    with mp.Pool(processors) as pool:
        df_with_seq_list = pool.starmap(__get_fasta_pieces_single_seqid_SeqIO, mp_args_list)
    return pd.concat(df_with_seq_list).sort_index()


def execute(TIRLearner_instance) -> pd.DataFrame:
    df = get_start_end(TIRLearner_instance.genome_file_path, TIRLearner_instance["base"],
                       TIRLearner_instance.flag_verbose)
    return get_fasta_pieces_SeqIO(TIRLearner_instance.genome_file_path, df, TIRLearner_instance.processors,
                                  TIRLearner_instance.flag_verbose)
