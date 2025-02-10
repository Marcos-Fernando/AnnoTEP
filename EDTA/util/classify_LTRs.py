#!/usr/bin/env python3

import argparse
import re

def parse_fasta_ids(fasta_file):
    """Extracts the IDs and sequences from a FASTA file."""
    ids = []
    sequences = {}
    with open(fasta_file, 'r') as f:
        current_id = None
        current_seq = []
        for line in f:
            if line.startswith('>'):
                if current_id:
                    sequences[current_id] = ''.join(current_seq)
                current_id = line.strip()[1:].split('#')[0]  # Extract location (e.g., chr8:1059483..1066052)
                ids.append(current_id)
                current_seq = []
            else:
                current_seq.append(line.strip())
        if current_id:
            sequences[current_id] = ''.join(current_seq)
    return ids, sequences

def parse_tst_file(tst_file, ids):
    """Parses the tst file and extracts relevant data for specific IDs."""
    elements = {}
    with open(tst_file, 'r') as f:
        for line in f:
            if not line.startswith('#') and line.strip():
                fields = line.strip().split('\t')
                ltr_loc = fields[0]
                if ltr_loc in ids:
                    # Extract start and end positions from ltr_loc (e.g., chr8:1059483..1066052)
                    match = re.search(r':(\d+)\.\.(\d+)', ltr_loc)
                    if match:
                        element_start, element_end = map(int, match.groups())
                        internal_region = re.search(r'IN:(\d+)\.\.(\d+)', fields[6])
                        if internal_region:
                            internal_start, internal_end = map(int, internal_region.groups())
                            strand = fields[8]
                            ltr_left = abs(element_start - internal_start)
                            ltr_right = abs(internal_end - element_end)
                            total_size = abs(element_end - element_start)
                            elements[ltr_loc] = (ltr_left, ltr_right, total_size, strand)
    return elements

def classify_and_write_fasta(sequences, elements, output_fasta):
    """Classifies elements and writes the output FASTA with classification."""
    with open(output_fasta, 'w') as out:
        for loc, seq in sequences.items():
            if loc in elements:
                ltr_left, ltr_right, total_size, strand = elements[loc]
                ltr_size = min(ltr_left, ltr_right)  # Use the smaller LTR size
                # Classify as LARD or TRIM
                if ltr_size < 250 and total_size < 3500:
                    classification = "TRIM"
                elif ltr_size >= 250 and total_size >= 3500:
                    classification = "LARD"
                elif total_size < 3500:
                    classification = "TRIM-like"
                elif total_size >= 3500:
                    classification = "LARD-like"
                else:
                    classification = "LTR/Unknown"  # Default to LARD if ambiguous
                # Write the FASTA entry
                out.write(f">{loc}#{classification}\n")
                out.write(f"{seq}\n")

def main():
    parser = argparse.ArgumentParser(description="Classify LTR elements as LARDs or TRIMs and generate a classified FASTA.")
    parser.add_argument('--input', required=True, help='Input FASTA file with LTR element IDs.')
    parser.add_argument('--classfile', required=True, help='Classification file with LTR predictions.')
    parser.add_argument('--output', required=True, help='Output file to save calculated LTR sizes.')
    parser.add_argument('--fasta', required=True, help='Output classified FASTA file.')
    args = parser.parse_args()
    
    # Parse input files
    fasta_ids, sequences = parse_fasta_ids(args.input)
    elements = parse_tst_file(args.classfile, fasta_ids)
    
    # Classify and write FASTA
    classify_and_write_fasta(sequences, elements, args.fasta)

if __name__ == "__main__":
    main()
