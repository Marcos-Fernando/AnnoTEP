#!/usr/bin/env python3
import gzip
import re
import argparse
from collections import defaultdict
from intervaltree import Interval, IntervalTree

# === Argumentos de linha de comando ===
parser = argparse.ArgumentParser(description="Filtra hits do RepeatMasker que estão contidos em outros, com base em coordenadas.")
parser.add_argument('--input', '-in', required=True, help='Arquivo .cat.gz de entrada')
parser.add_argument('--output', '-out', required=True, help='Arquivo .cat.gz de saída')
parser.add_argument('--log', required=True, help='Arquivo de log das remoções')
parser.add_argument('--containment-threshold', type=float, default=1.0,
                    help='Proporção mínima de contenção para considerar um hit redundante (default: 1.0 = 100%% contido)')
args = parser.parse_args()

input_file = args.input
output_file = args.output
log_file = args.log
containment_threshold = args.containment_threshold

# === Regex para capturar cabeçalhos do .cat.gz ===
pattern_header = re.compile(r'^(\d+)\s+([\d\.]+)\s+\S+\s+\S+\s+(\S+)\s+(\d+)\s+(\d+).+?\s+([^\s]+#\S+)')

# === Funções principais ===
def is_contained(a, b, threshold):
    overlap_start = max(a['start'], b['start'])
    overlap_end = min(a['end'], b['end'])
    overlap_len = max(0, overlap_end - overlap_start + 1)

    len_a = a['end'] - a['start'] + 1
    len_b = b['end'] - b['start'] + 1
    min_len = min(len_a, len_b)

    return (overlap_len / min_len) >= threshold

def is_better(a, b):
    if a['score'] > b['score']:
        return True
    elif a['score'] == b['score']:
        if a['divergence'] < b['divergence']:
            return True
        elif a['divergence'] == b['divergence']:
            return (a['end'] - a['start']) > (b['end'] - b['start'])
    return False

# === Estrutura com IntervalTree ===
best_hits = defaultdict(IntervalTree)
removed_hits = []

def add_hit(chrom, new_hit):
    a = new_hit['info']
    tree = best_hits[chrom]
    overlapping = list(tree.overlap(a['start'], a['end'] + 1))

    for region in overlapping:
        b = region.data['info']
        if is_contained(a, b, containment_threshold) or is_contained(b, a, containment_threshold):
            if is_better(a, b):
                removed_hits.append((b, a))
                tree.remove(region)
                tree.add(Interval(a['start'], a['end'] + 1, new_hit))
            else:
                removed_hits.append((a, b))
            return

    tree.add(Interval(a['start'], a['end'] + 1, new_hit))

# === Leitura do arquivo .cat.gz ===
with gzip.open(input_file, 'rt') as fin:
    entry_buffer = []
    entry_info = None

    for line in fin:
        header_match = pattern_header.match(line)
        if header_match:
            if entry_info:
                add_hit(entry_info['chrom'], {'info': entry_info, 'entry': entry_buffer})
            entry_buffer = [line]
            entry_info = {
                'score': int(header_match.group(1)),
                'divergence': float(header_match.group(2)),
                'chrom': header_match.group(3),
                'start': int(header_match.group(4)),
                'end': int(header_match.group(5)),
                'TE_name': header_match.group(6),
                'header': line.strip()
            }
        else:
            entry_buffer.append(line)

    if entry_info:
        add_hit(entry_info['chrom'], {'info': entry_info, 'entry': entry_buffer})

# === Escrita do arquivo filtrado .cat.gz ===
with gzip.open(output_file, 'wt') as fout:
    for chrom in sorted(best_hits):
        intervals = sorted(best_hits[chrom], key=lambda x: x.begin)
        for interval in intervals:
            fout.writelines(interval.data['entry'])

# === Escrita do log ===
with open(log_file, 'w') as log:
    log.write(f"# THRESHOLD DE CONTENÇÃO = {containment_threshold:.2f}\n\n")
    for removed, kept in removed_hits:
        log.write(f"REMOVIDO: {removed['chrom']}:{removed['start']}-{removed['end']} | "
                  f"score={removed['score']}, div={removed['divergence']}, TE={removed['TE_name']}\n")
        log.write(f"  --> CONTIDO EM: {kept['chrom']}:{kept['start']}-{kept['end']} | "
                  f"score={kept['score']}, div={kept['divergence']}, TE={kept['TE_name']}\n\n")

