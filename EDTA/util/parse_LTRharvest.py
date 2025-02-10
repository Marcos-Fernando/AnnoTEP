#!/usr/bin/env python3

import argparse

def parse_scn(file_path):
    """Lê um arquivo SCN e retorna o cabeçalho e uma lista de entradas."""
    with open(file_path, 'r') as f:
        lines = f.readlines()
    header = [line for line in lines if line.startswith('#')]
    entries = [line.strip().split() for line in lines if not line.startswith('#')]
    return header, entries

def has_overlap(entry, reference):
    """Verifica se uma entrada tem qualquer tipo de interseção com uma referência."""
    s, e = int(entry[0]), int(entry[1])
    for ref in reference:
        ref_s, ref_e = int(ref[0]), int(ref[1])
        # Qualquer tipo de interseção entre os intervalos
        if not (e < ref_s or s > ref_e):
            return True
    return False

def clean_entries(motif_file, nomotif_file, output_file):
    """Remove entradas de 'nomotif' que possuem interseção com 'motif'."""
    # Parse arquivos
    motif_header, motif_entries = parse_scn(motif_file)
    _, nomotif_entries = parse_scn(nomotif_file)
    
    # Filtrar entradas sem interseção
    filtered_entries = [entry for entry in nomotif_entries if not has_overlap(entry, motif_entries)]
    
    # Escrever arquivo de saída
    with open(output_file, 'w') as out:
        out.writelines(motif_header)
        for entry in filtered_entries:
            out.write(' '.join(entry) + '\n')

def main():
    # Configurar argumentos
    parser = argparse.ArgumentParser(description="Remove entradas de LTRharvest sem motivo baseadas em entradas com motivo.")
    parser.add_argument('-motif', required=True, help='Arquivo de entrada com motivo')
    parser.add_argument('-nomotif', required=True, help='Arquivo de entrada sem motivo')
    parser.add_argument('-out', required=True, help='Arquivo de saída limpo')
    args = parser.parse_args()
    
    # Executar limpeza
    clean_entries(args.motif, args.nomotif, args.out)

if __name__ == "__main__":
    main()

