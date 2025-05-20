from const import *


def blast_ref_lib_in_genome_file(genome_db: str, genome_name: str,
                                 ref_lib: str, ref_lib_file_path: str, processors: int):
    out = f"{genome_name}{FILE_NAME_SPLITER}blast{FILE_NAME_SPLITER}{ref_lib}"
    # out = genome_name + FILE_NAME_SPLITER + "blast" + FILE_NAME_SPLITER + ref_lib
    blast = (f"blastn -max_hsps 5 -perc_identity 80 -qcov_hsp_perc 100 -query \"{ref_lib_file_path}\" "
             f"-db \"{genome_db}\" -num_threads {processors} -outfmt '6 qacc sacc length pident gaps mismatch "
             f"qstart qend sstart send evalue qcovhsp' -out \"{out}\" 2>/dev/null")
    # Find where is the RefLib in the genome database
    subprocess.Popen(blast, shell=True).wait()


def blast_de_novo_result_in_ref_lib(file_name: str, ref_lib: str, ref_lib_file_path: str, processors: int):
    out = f"{file_name}{FILE_NAME_SPLITER}blast{FILE_NAME_SPLITER}{ref_lib}"
    # out = file_name + FILE_NAME_SPLITER + "blast" + FILE_NAME_SPLITER + ref_lib
    blast = (f"blastn -max_hsps 5 -perc_identity 80 -qcov_hsp_perc 80 -query \"{file_name}\" "
             f"-subject \"{ref_lib_file_path}\" -num_threads {processors} -outfmt '6 qseqid sseqid length pident "
             f"gaps mismatch qstart qend sstart send evalue qcovhsp' -out \"{out}\" 2>/dev/null")
    # Find whether there is any predicted TIR (GRFmite and TIRvish) inside the refLib
    subprocess.Popen(blast, shell=True).wait()

# def collect_blast_result():
#     df = pd.concat([pd.read_csv(f, header=None) for f in
#                     [f for f in os.listdir(".") if f.endswith("_RefLib") and os.path.getsize(f) != 0]])
#     csv_QUOTE_NONE = 3
#     df.to_csv("tem_blastResult", header=False, index=False, quoting=csv_QUOTE_NONE)


def blast_genome_file(TIRLearner_instance):
    print("Module 1, Step 1: Blast reference library in genome file")
    genome_db = TIRLearner_instance.genome_file_path + FILE_NAME_SPLITER + "db"
    mkDB = (f"makeblastdb -in {TIRLearner_instance.genome_file_path} -out {genome_db} "
            f"-parse_seqids -dbtype nucl 2>/dev/null")
    subprocess.Popen(mkDB, shell=True).wait()

    mp_args_list = [(genome_db, TIRLearner_instance.genome_name,
                     ref_lib, os.path.join(REFLIB_DIR_PATH, ref_lib),
                     TIRLearner_instance.processors)
                    for ref_lib in REFLIB_FILE_DICT[TIRLearner_instance.species]]

    # with mp.Pool(int(TIRLearner_instance.processors)) as pool:
    with mp.Pool(TIRLearner_instance.processors) as pool:
        pool.starmap(blast_ref_lib_in_genome_file, mp_args_list)

    subprocess.Popen(["find", ".", "-name", f"*{FILE_NAME_SPLITER}db*", "-delete"])  # remove blast db files


def blast_de_novo_result(TIRLearner_instance):
    print("Module 2, Step 6: Blast GRF and TIRvish result in reference library")
    mp_args_list = [(TIRLearner_instance.processed_de_novo_result_file_name,
                     ref_lib, os.path.join(REFLIB_DIR_PATH, ref_lib),
                     TIRLearner_instance.processors)
                    for ref_lib in REFLIB_FILE_DICT[TIRLearner_instance.species]]

    # with mp.Pool(int(TIRLearner_instance.processors)) as pool:
    with mp.Pool(TIRLearner_instance.processors) as pool:
        pool.starmap(blast_de_novo_result_in_ref_lib, mp_args_list)
