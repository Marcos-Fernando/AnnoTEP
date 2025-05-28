#!/bin/env Rscript

# Pacotes
suppressPackageStartupMessages({
  library(ape)
  library(phangorn)
  library(ggplot2)
  library(ggtree)
  library(treeio)
  library(phytools)
  library(ggtreeExtra)
  library(dplyr)
  library(ggnewscale)
  library(ggrepel)
  library(cowplot)
  library(RColorBrewer)
  library(scales)
  library(rlang)
})

# Argumentos
args = commandArgs(T)
treefile = args[1]
mapfile = args[2]
dataplot = args[3]
dataplot2 = args[4]
outfile_prefix = args[5]
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
min_max_norm <- function(x) {
  (x - min(x)) / (max(x) - min(x))
}

# Ler dados
tree <- midpoint(read.tree(file = treefile))
map <- read.table(mapfile, header = TRUE, fill = TRUE, comment.char = '!', sep = "\t")
ring <- read.table(dataplot, sep = "\t")
ring2 <- read.table(dataplot2, sep = "\t")

tree$tip.label <- gsub('\\W+', '_', tree$tip.label)

# Agrupar por Clade
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

# Função para plotar
plot_tree_density <- function(tree_obj, layout_type, branch_length = "none", file_suffix) {
  
  n_taxons <- Ntip(tree_obj)
  
  # Definir top IDs para labels, se árvore for grande
  is_top <- rep(TRUE, n_taxons)  # default: TRUE para árvores pequenas
  if (n_taxons > 700) {
    # Encontrar IDs no top 25% de occurrences
    q_occ <- quantile(ring$V2, 0.99)
    top_occ_ids <- ring$V1[ring$V2 >= q_occ]
    
    # Encontrar IDs no top 25% de size
    q_size <- quantile(ring2$V2, 0.99)
    top_size_ids <- ring2$V1[ring2$V2 >= q_size]
    
    # Unir os IDs únicos
    top_ids <- unique(c(top_occ_ids, top_size_ids))
    
    # Filtrar para manter apenas IDs presentes na árvore
    top_ids <- top_ids[top_ids %in% tree_obj$tip.label]
    
    # Criar vetor lógico is_top
    is_top <- tree_obj$tip.label %in% top_ids
  }
  
  # Criar data.frame auxiliar para merge via %<+%
  df <- data.frame(label = tree_obj$tip.label, is_top = is_top, stringsAsFactors = FALSE)
  
  # Árvore base + merge de dados
  p_tree <- ggtree(tree_obj, aes(color = Clade), layout = layout_type, branch.length = branch_length) %<+% df +
    geom_rootpoint(size = 0.8) +
    geom_tiplab(aes(subset = is_top), size = 1, linesize = 0.15)
  
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
  
  # Bootstrap: só se árvore pequena
  if (n_taxons <= 700) {
    plot_data <- p_tree$data
    has_bootstrap <- "label" %in% colnames(plot_data) &&
      any(!plot_data$isTip & suppressWarnings(!is.na(as.numeric(plot_data$label))))
    
    if (layout_type == "circular" && branch_length == "none" && has_bootstrap) {
      p_tree <- p_tree + geom_text2(
        aes(label = ifelse(!isTip & !is.na(as.numeric(label)) & as.numeric(label) * 100 > 50,
                           round(as.numeric(label) * 100), "")),
        size = 1.8,
        hjust = -0.2,
        color = "black",
        show.legend = FALSE
      )
    }
  }
  
  # Adicionar faixas externas
  p_tree <- p_tree +
    geom_fruit(
      data = ring,
      geom = geom_col,
      mapping = aes(y = V1, x = min_max_norm(V2)),
      fill = "#fb011a",
      alpha = 0.8,
      color = "#8e8b8b",
      size = 0.1,
      offset = 0.45,
      axis.params = list(
        axis = "x",
        text.size = 1,
        hjust = 1,
        vjust = 1.5,
        nbreak = 4
      ),
      grid.params = list()
    ) +
    new_scale_fill() +
    geom_fruit(
      data = ring2,
      geom = geom_col,
      mapping = aes(y = V1, x = min_max_norm(V2)),
      fill = "#7801fb",
      alpha = 0.8,
      color = "#8e8b8b",
      size = 0.1,
      offset = 0.05,
      axis.params = list(
        axis = "x",
        text.size = 1,
        hjust = 1,
        vjust = 1.5,
        nbreak = 4
      ),
      grid.params = list()
    )
  
  # Legenda dos Clades
  p_legend_clades <- cowplot::get_legend(
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
  
  # Legenda para "Occurrences" e "Size"
  p_legend_extra <- ggplot() +
    theme_void() +
    annotate("rect", xmin=0, xmax=0.2, ymin=0.8, ymax=0.9, fill="#fb011a", alpha=0.8) +
    annotate("text", x=0.3, y=0.85, label="Occurrences", hjust=0, size=2.5) +
    annotate("rect", xmin=0, xmax=0.2, ymin=0.6, ymax=0.7, fill="#7801fb", alpha=0.8) +
    annotate("text", x=0.3, y=0.65, label="Size", hjust=0, size=2.5) +
    coord_cartesian(xlim=c(0, 1), ylim=c(0.5, 1)) +
    theme(
      plot.margin = margin(0, 0, 0, 0),
      panel.spacing = unit(0, "lines")
    )
  
  # Montar painel
  final_plot <- cowplot::plot_grid(
    p_tree,
    cowplot::plot_grid(p_legend_clades, p_legend_extra, ncol=1, rel_heights=c(3,1)),
    ncol = 2,
    rel_widths = c(4, 1)
  )
  
  # Exportar
  ggsave(paste0(outfile_prefix, "_", file_suffix, ".pdf"), plot = final_plot, width = 10, height = 7, dpi = 350, units = "in")
  ggsave(paste0(outfile_prefix, "_", file_suffix, ".png"), plot = final_plot, width = 10, height = 7, dpi = 350, units = "in")
}

# Rodar para duas versões:
plot_tree_density(tree3, layout_type = "circular", branch_length = "none", file_suffix = "cladogram_density")
plot_tree_density(tree3, layout_type = "circular", branch_length = "branch.length", file_suffix = "circular_density")

