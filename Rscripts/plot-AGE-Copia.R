# Carregar pacotes
library(ggplot2)
library(dplyr)
library(scales)
library(ggrepel)

# Ler dados
aa <- read.table("./AGE-Copia.txt", header = FALSE, sep = "\t", stringsAsFactors = FALSE)
colnames(aa) <- c("cluster", "age_raw")

# Converter para milhões de anos (Mya)
aa$age <- aa$age_raw / 1e6

# Calcular estatísticas
media <- mean(aa$age)
mediana <- median(aa$age)
dp <- sd(aa$age)

# Calcular densidade
dens <- density(aa$age, bw = "nrd0", na.rm = TRUE)
dens_df <- data.frame(x = dens$x, y = dens$y)

# Detecção precisa dos picos
peaks_idx <- which(diff(sign(diff(dens_df$y))) == -2) + 1
picos <- dens_df[peaks_idx, ]
picos <- picos[picos$y > max(dens_df$y) * 0.1, ]
picos$label <- paste0(round(picos$x, 1), " Mya")

# Anotação estatística (caixinha no canto superior direito)
anotacao_df <- data.frame(
  x = max(aa$age) * 0.98,
  y = max(dens_df$y) * 0.95,
  label = paste0(
    "Mean: ", round(media, 2), 
    "\nMedian: ", round(mediana, 2), 
    "\nSD: ", round(dp, 2)
  )
)

# Criar gráfico
p <- ggplot(aa, aes(age)) +
  geom_histogram(aes(y = after_stat(density)),
                 binwidth = 0.1,
                 color = "#ffffff",
                 fill = "#e8736b",  # tom salmão
                 linewidth = 0.2) +
  geom_vline(xintercept = media, col = "black", linewidth = 0.3) +
  geom_vline(xintercept = mediana, col = "black", linetype = "dashed", linewidth = 0.3) +
  geom_density(linetype = "dashed", alpha = 0.3, fill = "#e8736b") +
  xlim(0, NA) +
  theme_classic(base_size = 6) +
  labs(
    title = "LTR Copia insertion time",
    x = "Mya",
    y = "Density"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5, size = 6, face = "bold"),
    axis.text = element_text(size = 5),
    axis.title = element_text(size = 6),
    plot.margin = margin(4, 4, 4, 4),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.25),
    panel.grid.minor = element_blank()
  ) +
  # Estatísticas em caixinha
  geom_label(
    data = anotacao_df,
    aes(x = x, y = y, label = label),
    size = 1.8,
    hjust = 1,
    vjust = 1,
    label.size = 0.15,
    fill = "white",
    color = "black"
  ) +
  # Marcar picos com bolinhas
  geom_point(data = picos, aes(x = x, y = y), size = 1.3, shape = 21, fill = "black") +
  # Labels dos picos com repel
  geom_label_repel(
    data = picos,
    aes(x = x, y = y, label = label),
    size = 1.6,
    fill = "white",
    color = "black",
    label.size = 0.1,
    min.segment.length = 0  # sempre desenha segmento
  )

# Exportar em PDF e PNG
ggsave("AGE-Copia.pdf", p, width = 8, height = 5, units = "cm", dpi = 300)
ggsave("AGE-Copia.png", p, width = 8, height = 5, units = "cm", dpi = 300)

# Visualizar (opcional)
#print(p)

