#!/bin/env Rscript

# Pacotes necessários
suppressPackageStartupMessages({
  library(ape)
  library(phangorn)
  library(ggplot2)
  library(ggtree)
  library(treeio)
  library(phytools)
  library(RColorBrewer)
  library(scales)
  library(dplyr)
  library(cowplot)
})

# Argumentos
args = commandArgs(T)
treefile = args[1]
mapfile = args[2]
outfile_prefix = args[3]
if (is.na(outfile_prefix)) {
  outfile_prefix = sub("\\.nwk$", "", treefile)
}

# Funções auxiliares
split_id <- function(x) strsplit(x, '#')[[1]][1]
format_id <- function(x1, x2, x3, x4) {
  x1 <- sapply(x1, split_id)
  x1 <- gsub('\\W+', '_', x1)
  paste(x1, x2, x3, x4, sep = '_')
}

# Ler dados
tree <- midpoint(read.tree(file = treefile))
map <- read.table(mapfile, header = TRUE, fill = TRUE, comment.char = '!', sep = "\t")
tree$tip.label <- gsub('\\W+', '_', tree$tip.label)

# Agrupar TE_ids por Clade
clades_raw <- map %>%
  filter(Clade != "unknown") %>%
  mutate(formatted = format_id(X.TE, Order, Superfamily, Clade)) %>%
  filter(formatted %in% tree$tip.label)

clade_counts <- clades_raw %>%
  count(Clade) %>%
  arrange(desc(n)) %>%
  mutate(legend_label = paste0(Clade, " (", n, ")"))

grp <- list()
for (clade in unique(clades_raw$Clade)) {
  tips <- clades_raw$formatted[clades_raw$Clade == clade]
  grp[[clade]] <- tips
}

tree3 <- groupOTU(tree, grp, group_name = "Clade")
tree3$Clade <- tree3$group

get_colors <- function(n) {
  if (n <= 8) {
    return(RColorBrewer::brewer.pal(n, "Dark2"))
  } else if (n <= 12) {
    return(RColorBrewer::brewer.pal(n, "Paired"))
  } else {
    return(scales::hue_pal()(n))
  }
}

clade_colors <- setNames(get_colors(length(clade_counts$Clade)), clade_counts$Clade)
legend_labels <- clade_counts$legend_label
names(legend_labels) <- clade_counts$Clade

# Função para plotar árvore + legenda
plot_tree <- function(tree_obj, layout_type, branch_length = "none", file_suffix) {
  
  n_taxons <- Ntip(tree_obj)
  
  # Decidir se plota labels e bootstrap
  plot_labels <- n_taxons <= 700
  plot_bootstrap <- n_taxons <= 700
  
  # Criar a árvore base
  p_tree <- ggtree(tree_obj, aes(color = Clade), layout = layout_type, branch.length = branch_length) +
    geom_rootpoint(size = 0.8)
  
  # Adiciona labels ou só pontos
  if (plot_labels) {
    p_tree <- p_tree + geom_tiplab(size = 1, linesize = 0.15)
  } else {
    p_tree <- p_tree + geom_tippoint(size = 0.3)
  }
  
  # Sempre adiciona pontos invisíveis para legendas
  p_tree <- p_tree + 
    geom_point(aes(color = Clade), size = 0) +
    theme_tree2(base_size = 6) +
    theme(
      legend.position = "none",
      panel.grid = element_blank(),
      axis.text = element_blank(),
      axis.ticks = element_blank()
    ) +
    scale_color_manual(
      values = c("black", clade_colors),
      na.value = "black",
      breaks = clade_counts$Clade,
      labels = legend_labels
    )
  
  # Adicionar bootstrap apenas se for permitido
  plot_data <- p_tree$data
  has_bootstrap <- "label" %in% colnames(plot_data) &&
    any(!plot_data$isTip & suppressWarnings(!is.na(as.numeric(plot_data$label))))
  
  if (plot_bootstrap && layout_type == "circular" && branch_length == "none" && has_bootstrap) {
    p_tree <- p_tree + geom_text2(
      aes(label = ifelse(!isTip & !is.na(as.numeric(label)) & as.numeric(label) * 100 > 50,
                         round(as.numeric(label) * 100), "")),
      size = 1.8,
      hjust = -0.2,
      color = "black",
      show.legend = FALSE
    )
  }
  
  # Criar a legenda separada
  p_legend <- cowplot::get_legend(
    ggtree(tree_obj, aes(color = Clade)) +
      geom_point(aes(color = Clade), size = 3) +
      scale_color_manual(
        values = c("black", clade_colors),
        na.value = "black",
        breaks = clade_counts$Clade,
        labels = legend_labels
      ) +
      guides(color = guide_legend(
        title = NULL,
        override.aes = list(shape = 15, size = 5, linetype = 0),
        ncol = 1
      )) +
      theme(
        legend.position = "right",
        legend.justification = "center",
        legend.text = element_text(size = 6),
        legend.key.size = unit(0.4, "cm"),
        legend.box.margin = margin(0, 10, 0, 0)
      )
  )
  
  # Juntar árvore + legenda
  final_plot <- cowplot::plot_grid(
    p_tree, p_legend,
    ncol = 2,
    rel_widths = c(4, 1)
  )
  
  # Exportar
  ggsave(paste0(outfile_prefix, "_", file_suffix, ".pdf"), plot = final_plot, width = 9, height = 7, dpi = 350, units = "in")
  ggsave(paste0(outfile_prefix, "_", file_suffix, ".png"), plot = final_plot, width = 9, height = 7, dpi = 350, units = "in")
}

# Rodar para as três versões:
plot_tree(tree3, layout_type = "circular", branch_length = "none", file_suffix = "cladogram_circular")
plot_tree(tree3, layout_type = "circular", branch_length = "branch.length", file_suffix = "original_circular")
plot_tree(tree3, layout_type = "radial", branch_length = "branch.length", file_suffix = "radial_circular")

