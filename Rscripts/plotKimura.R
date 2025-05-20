#############################
###Plot Kimura distance######
#############################

library(reshape)
library(ggplot2)
library(viridis)
library(tidyverse)
library(gridExtra)

# Leitura dos dados
KimuraDistance <- read.csv("./divsum.txt", sep = " ")

# Tamanho do genoma
genomes_size <- _SIZE_GEN_

# Transformação e limpeza
kd_melt <- melt(KimuraDistance, id = "Div")
kd_melt$norm <- kd_melt$value / genomes_size * 100
kd_melt <- kd_melt[!is.na(kd_melt$norm) & kd_melt$norm >= 0 & kd_melt$norm <= 100, ]

# Criar gráfico
p <- ggplot(kd_melt, aes(fill = variable, y = norm, x = Div)) + 
  geom_bar(position = "stack", stat = "identity", color = "black", linewidth = 0.2) +
  scale_fill_viridis(discrete = TRUE, option = "D") +
  scale_x_continuous(breaks = seq(0, 55, by = 5)) +
  scale_y_continuous(breaks = scales::pretty_breaks(n = 8)) +
  xlab("Kimura substitution level") +
  ylab("Percent of the genome") +
  labs(fill = "") +
  guides(fill = guide_legend(
    override.aes = list(size = 2),    # tamanho da caixinha da legenda
    keywidth = 0.4,                   # largura das caixas
    keyheight = 0.4,                  # altura das caixas
    title.position = "top",
    label.theme = element_text(size = 4)  # tamanho do texto da legenda
  )) +
  theme_classic(base_size = 7) +
  theme(
    legend.position = c(0.95, 0.95),
    legend.justification = c("right", "top"),
    legend.background = element_rect(fill = "white", color = "black", size = 0.2),
    legend.text = element_text(size = 4),
    axis.text = element_text(size = 6),
    axis.title = element_text(size = 7),
    plot.title = element_text(size = 8, face = "bold"),
    plot.margin = margin(5, 5, 5, 5),
    panel.grid.major = element_line(color = "gray85", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    panel.background = element_blank()
  )

# Mostrar gráfico
print(p)

# Exportar em PNG
ggsave("kimura_distance_plot.png", p, width = 8, height = 8, units = "cm", dpi = 300)

# Exportar em PDF
ggsave("kimura_distance_plot.pdf", p, width = 8, height = 8, units = "cm")

