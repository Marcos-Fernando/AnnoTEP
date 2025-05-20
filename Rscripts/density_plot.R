#!/usr/bin/env Rscript

# Author: Chris Benson (adapted)
# Last Update: 2025-04-26

# ===============================
# Help function
# ===============================

print_help <- function() {
  cat("
Usage: Rscript density_plotter.R <filename> <chrom_string> [merge] <threshold> [no_size_cutoff]

Arguments:
  <filename>        Path to the TE superfamily density table generated using density_table.py
  <chrom_string>    Optional: Pattern to filter chromosomes
  [merge]           Optional: Merge all chromosomes into one figure
  <threshold>       Optional: Minimum density % to keep a repeat type
  [no_size_cutoff]  Optional: Plot small scaffolds without size cutoff

Dependencies: R (>=3.6), ggplot2, dplyr
")
  quit(status = 0)
}

# ===============================
# Parse Arguments
# ===============================

args <- commandArgs(trailingOnly = TRUE)

chrom_string <- NULL
merge_plots <- FALSE
threshold <- NULL
no_size_cutoff <- FALSE 
filename <- NULL

for (arg in args) {
  switch(tolower(arg),
    "merge" = { merge_plots <- TRUE },
    "no_size_cutoff" = { no_size_cutoff <- TRUE },
    {
      if (grepl("^[0-9]+(\\.[0-9]+)?$", arg)) {
        threshold <- as.numeric(arg)
      } else if (is.null(filename)) {
        filename <- arg
      } else {
        chrom_string <- arg
      }
    }
  )
}

if (is.null(filename) || filename == '-h' || filename == '--help') {
  print_help()
}

# ===============================
# Load Libraries
# ===============================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})

# ===============================
# Read Data
# ===============================

header_check <- readLines(filename, n = 1)
has_header <- grepl("chrom", header_check, fixed = TRUE)

repeats <- read.table(filename, sep = '\t', header = has_header, 
                      col.names = if (!has_header) c('chrom', 'coord', 'density', 'type') else NULL)

# ===============================
# Data Preprocessing
# ===============================

# Size cutoff (unless disabled)
if (!no_size_cutoff) {
  chrom_lengths <- repeats %>% group_by(chrom) %>% summarise(coord = max(coord))
  max_length <- max(chrom_lengths$coord)
  threshold_size <- max_length * 0.1
  valid_chroms <- chrom_lengths$chrom[chrom_lengths$coord >= threshold_size]
  repeats <- repeats %>% filter(chrom %in% valid_chroms)
}

# Exclude unwanted types
excluded_types <- c('target_site_duplication', 'repeat_region', 'long_terminal_repeat')
repeats <- repeats %>% filter(!type %in% excluded_types)

# Standardize type names
repeats$type <- repeats$type %>%
  gsub("Copia_LTR_retrotransposon", "LTR/Copia", .) %>%
  gsub("Gypsy_LTR_retrotransposon", "LTR/Gypsy", .) %>%
  gsub("knob", "Knob", .) %>%
  gsub("LINE_element", "LINE/unknown", .) %>%
  gsub("SINE_element", "SINE/unknown", .) %>%
  gsub("rDNA_intergenic_spacer_element", "rDNA intergenic spacer", .) %>%
  gsub("L1_LINE_retrotransposon", "LINE/L1", .) %>%
  gsub("satellite_DNA", "Satellite", .) %>%
  gsub("PIF_Harbinger_TIR_transposon", "TIR/PIF_Harbinger", .) %>%
  gsub("helitron", "Helitron", .) %>%
  gsub("RTE_LINE_retrotransposon", "LINE/RTE", .) %>%
  gsub("LTR_retrotransposon", "LTR/unknown", .) %>%
  gsub("hAT_TIR_transposon", "TIR/hAT", .) %>%
  gsub("CACTA_TIR_transposon", "TIR/CACTA", .) %>%
  gsub("Tc1_Mariner_TIR_transposon", "TIR/Tc1_Mariner", .) %>%
  gsub("subtelomere", "Subtelomere", .) %>%
  gsub("non_LTR_retrotransposon", "nonLTR/unknown", .) %>%
  gsub("Mutator_TIR_transposon", "TIR/Mutator", .) %>%
  gsub("MITE", "TIR/MITE", .) %>%
  gsub("TRIM", "LTR/TRIM", .) %>%
  gsub("BARE-2", "LTR/BARE-2", .) %>%
  gsub("TR_GAG", "LTR/TR_GAG", .) %>%
  gsub("LARD", "LTR/LARD", .)

# Optional: filter by chrom string
if (!is.null(chrom_string)) {
  repeats <- repeats %>% filter(grepl(chrom_string, chrom))
}

# Threshold filter
if (!is.null(threshold)) {
  keep_types <- repeats %>%
    group_by(type) %>%
    summarise(max_density = max(density)) %>%
    filter(max_density * 100 > threshold) %>%
    pull(type)
  
  repeats <- repeats %>% filter(type %in% keep_types)
}

# ===============================
# Define Colors
# ===============================

fixed_colors <- c(
  "LTR/Copia"="#550000", "LTR/Gypsy"="#AA0000", "LTR/TRIM"="#D40000", "LTR/BARE-2"="#FF0000",
  "LTR/TR_GAG"="#FF2B00", "LTR/LARD"="#FF5500", "LTR/unknown"="#FF8000", "nonLTR/unknown"="#FFAA00",
  "LINE/unknown"="#FFD400", "LINE/L1"="#FFFF00", "LINE/RTE"="#D4FF2B", "SINE/unknown"="#AAFF55",
  "TIR/PIF_Harbinger"="#80FF80", "TIR/Mutator"="#55FFAA", "TIR/MITE"="#2BFFD4", "TIR/hAT"="#00FFFF",
  "TIR/CACTA"="#00D4FF", "TIR/Tc1_Mariner"="#00AAFF", "Helitron"="#0080FF", "rDNA intergenic spacer"="#CFCFCF",
  "Knob"="#ADAAAB", "Subtelomere"="#A09D9E", "Satellite"="#989596", "repeat_fragment"="#8C898A",
  "rRNA_gene"="#807C7D", "low_complexity"="#5B5859"
)


# ===============================
# Plot
# ===============================

theme_custom <- theme_light() +
  theme(
    plot.title = element_text(size=14, face="bold"),
    axis.title = element_text(size=12),
    axis.text = element_text(size=10),
    legend.title = element_text(size=10),
    legend.text = element_text(size=8),
    panel.border = element_rect(color="grey", fill=NA, linewidth=0.8),
    plot.margin = margin(10, 10, 10, 10)
  )

if (merge_plots) {
  cat("Generating merged density plot...\n")
  
  p <- ggplot(repeats, aes(x=coord/1e6, y=density*100, color=type)) +
    geom_line() +
    facet_wrap(~ chrom, scales="free_x") +
    scale_color_manual(values=fixed_colors) +
    labs(x="Position on chromosome (Mb)", y="Percent repeat type", color="Type") +
    theme_custom +
    scale_x_continuous(expand=c(0, 0)) +
    scale_y_continuous(expand=expansion(mult=c(0.01, 0.02)))

  # Salvar como PDF
  pdf("chromosome_density_plots_merged.pdf", width=16, height=7, useDingbats=FALSE)
  print(p)
  dev.off()

  # Salvar como PNG
  ggsave("chromosome_density_plots_merged.png", plot=p, width=16, height=7, dpi=300)

} else {
  cat("Generating separate density plots...\n")

  pdf("chromosome_density_plots.pdf", width=12, height=5, useDingbats=FALSE)

  for (chr in unique(repeats$chrom)) {
    sub <- repeats %>% filter(chrom == chr)

    if (nrow(sub) > 1) {
      p <- ggplot(sub, aes(x=coord/1e6, y=density*100, color=type)) +
        geom_line() +
        scale_color_manual(values=fixed_colors) +
        labs(title=paste("Density on", chr), x="Position (Mb)", y="Density (%)", color="Type") +
        theme_custom +
        scale_x_continuous(expand=c(0,0)) +
        scale_y_continuous(expand=expansion(mult=c(0.01, 0.02)))

      print(p)

      # Salvar também PNG de cada cromossomo
      ggsave(filename=paste0("density_plot_", chr, ".png"), plot=p, width=12, height=5, dpi=300)
    }
  }
  dev.off()
}

cat("Finished! PDF and PNG files created.\n")
