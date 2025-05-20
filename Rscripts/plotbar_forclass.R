# Carregar pacotes
library(dplyr)
library(tidyr)
library(ggplot2)

# Ler os dados
annotepe_data <- read.csv("./perfomance_AnnoTEP.csv")
edta_data <- read.csv("./perfomance_EDTA.csv")

# Adicionar a coluna de origem
annotepe_data <- annotepe_data %>% mutate(Source = "AnnoTEP")
edta_data <- edta_data %>% mutate(Source = "EDTA")

# Combinar os dados
combined_data <- bind_rows(annotepe_data, edta_data)

# Lista de elementos (ex: LTR, TIR, etc.)
elements <- unique(combined_data$Element)

# Função para gerar gráfico por elemento
create_barplot <- function(element_name, index) {
  element_data <- combined_data %>% 
    filter(Element == element_name)

  if (nrow(element_data) == 0 || any(is.na(element_data$Value))) {
    warning(paste("Dados inválidos para", element_name))
    return()
  }

  desired_order <- c("Sensitivity", "Precision", "Specificity", "Accuracy", "F1", "FDR")
  element_data$Metric <- factor(element_data$Metric, levels = desired_order)
  element_data$Value <- as.numeric(element_data$Value)  # Força numérico
  tolerance <- 1e-3
  
  element_data <- element_data %>%
  mutate(
        is_extreme = abs(Value - 0) < tolerance | abs(Value - 1) < tolerance,
        angle = ifelse(is_extreme, 0, 90),
        vjust = ifelse(is_extreme, -0.5, 0.4),
        hjust = ifelse(is_extreme, 0.5, -0.1)
    )

    p <- ggplot(element_data, aes(x = Metric, y = Value, fill = Source)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.6), width = 0.4) +
    geom_text(
        aes(label = round(Value, 4), angle = angle, vjust = vjust, hjust = hjust),
                position = position_dodge(width = 0.6),
                size = 3
        ) +
    scale_fill_manual(values = c("AnnoTEP" = "#089108", "EDTA" = "orange")) +
    scale_y_continuous(limits = c(0, 1.15), breaks = seq(0, 1, by = 0.1)) +
    labs(title = paste("Performance -", element_name),
         x = "", y = "Score") +
    theme_minimal(base_size = 13) +
    theme(
      axis.text.x = element_text(angle = 0, vjust = 1),
      legend.position = "bottom",
      legend.direction = "horizontal"
    ) +
    guides(fill = guide_legend(title = NULL))
    # theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) +
    # ylim(0, 1.15)

  ggsave(paste0("Barplot_", index, "_", element_name, ".pdf"), plot = p, width = 8, height = 6)

  # print(element_data %>% select(Metric, Source, Value, is_extreme, angle))

}


# Criar gráficos para cada elemento
for (i in seq_along(elements)) {
  create_barplot(elements[i], i)
}
