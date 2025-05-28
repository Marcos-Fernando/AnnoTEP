#!/usr/bin/env python3

import argparse
from Bio import SeqIO


def load_intact_annotations(ref_file):
    """Cria um dicionário: {coord: anotacao}"""
    annot_map = {}
    with open(ref_file) as f:
        for record in SeqIO.parse(f, "fasta"):
            header = record.description
            if '#' in header:
                coord, annot = header.split('#', 1)
                annot_map[coord] = annot
    return annot_map


def normalize_coord(header):
    """Remove _INT ou _LTR do ID"""
    base = header.split('#')[0]
    return base.replace('_INT', '').replace('_LTR', '')


def annotate_ltrlib(lib_file, ref_dict, out_file, log_file=None):
    not_found = []

    with open(out_file, 'w') as fout:
        for record in SeqIO.parse(lib_file, "fasta"):
            original_header = record.description
            coord_base = normalize_coord(original_header)
            loc_with_suffix = original_header.split('#')[0]

            if coord_base in ref_dict:
                annot = ref_dict[coord_base]
            else:
                annot = original_header.split('#')[1]
                not_found.append(original_header)

            new_header = f"{loc_with_suffix}#{annot}"
            record.description = new_header
            record.id = new_header
            SeqIO.write(record, fout, "fasta")

    if log_file:
        with open(log_file, 'w') as logf:
            if not_found:
                for entry in not_found:
                    logf.write(entry + '\n')
            else:
                logf.write("# Nenhuma entrada faltando anotação.\n")


def main():
    parser = argparse.ArgumentParser(description="Anota LTRlib.fa com base em LTR.intact.raw.fa (por coordenada exata).")
    parser.add_argument('--ref', required=True, help='Arquivo .LTR.intact.raw.fa com anotação completa')
    parser.add_argument('--lib', required=True, help='Arquivo .LTRlib.fa a ser anotado')
    parser.add_argument('--out', required=True, help='Arquivo de saída anotado')
    parser.add_argument('--log', required=False, help='(Opcional) Log de entradas não encontradas')
    args = parser.parse_args()

    print("📖 Carregando anotações do .intact.raw.fa...")
    ref_dict = load_intact_annotations(args.ref)

    print("✍️ Anotando .LTRlib.fa com base nas coordenadas...")
    annotate_ltrlib(args.lib, ref_dict, args.out, args.log)

    print(f"✅ Arquivo anotado: {args.out}")
    if args.log:
        print(f"📝 Log de não encontrados: {args.log}")


if __name__ == '__main__':
    main()


