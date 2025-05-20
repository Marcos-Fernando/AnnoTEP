# Carregar pacotes
library(fmsb)
library(dplyr)
library(tidyr)

# Ler os dados
annotepe_data <- read.csv("./perfomance_AnnoTEP.csv")
edta_data <- read.csv("./perfomance_EDTA.csv")

# Combinar os dados, garantindo a ordem AnnoTEP primeiro
combined_data <- bind_rows(
  annotepe_data %>% mutate(Source = "AnnoTEP"),
  edta_data %>% mutate(Source = "EDTA")
)

# Lista de elementos (incluindo "Total")
elements <- unique(combined_data$Element)

# Função para criar gráfico de radar
create_radar_plot <- function(element_name, index) {
  # Filtrar e organizar os dados (AnnoTEP primeiro)
  element_data <- combined_data %>% 
    filter(Element == element_name) %>%
    arrange(Source) %>%  # Ordem fixa: AnnoTEP primeiro
    select(-Element) %>%
    pivot_wider(names_from = Metric, values_from = Value) %>%
    select(Source, Sensitivity, Specificity, Accuracy, Precision, FDR, F1)
  
  # Verificação de dados
  if (nrow(element_data) < 2 || any(is.na(element_data))) {
    print(element_data)  # Debug: mostra os dados problemáticos
    warning(paste("Dados inválidos para", element_name))
    return()
  }

  # Configurar PDF (Rplot1.pdf, Rplot2.pdf, etc.)
  pdf(paste0("Rplot", index, "_", element_name, ".pdf"), width = 8, height = 8)
  
  # Preparar dados para o radarchart
  plot_data <- element_data %>%
    select(-Source) %>%
    rbind(rep(1, 6), rep(0, 6), .) %>%
    as.data.frame()
  
  # Cores (AnnoTEP = verde, EDTA = laranja)
  line_colors <- c("#089108", "orange")  # Ordem corresponde aos dados
  fill_colors <- c(NA, NA)           # Sem preenchimento
  
  # Criar o gráfico
  radarchart(
    plot_data,
    axistype = 1,
    pcol = line_colors,
    pfcol = fill_colors,
    plwd = 4,
    plty = 1,
    cglcol = "gray",
    cglty = 1,
    axislabcol = "black",
    caxislabels = seq(0, 1, 0.2),
    # title = paste(element_name, "Performance"),
    vlcex = 1.6
  )

  title(main = paste(element_name, "Performance"), cex.main = 2.6)
  
  # Legenda
  legend(
    "topright",
    legend = c("AnnoTEP", "EDTA"),
    bty = "n",
    lwd = 8,                    # Espessura da linha na legenda
    lty = 1,                    # Tipo de linha (sólida)
    col = c("#089108", "orange"),    # Cores correspondentes
    text.col = "black",         # Cor do texto
    cex = 1,                    # Tamanho do texto
    seg.len = 2                 # Comprimento da linha na legenda
  )
}

# Criar gráficos para cada elemento
for (i in seq_along(elements)) {
  create_radar_plot(elements[i], i)
}