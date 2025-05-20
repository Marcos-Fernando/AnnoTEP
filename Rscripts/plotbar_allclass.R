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

# Criar gráfico com facetas por Element
p <- ggplot(combined_data, aes(x = Metric, y = Value, fill = Source)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(aes(label = round(Value, 4)),
            position = position_dodge(width = 0.8),
            angle = 90, hjust = -0.1, size = 2.8) +
  scale_fill_manual(values = c("AnnoTEP" = "#089108", "EDTA" = "orange")) +
  labs(title = "Performance das Ferramentas por Elemento",
       x = "Métrica", y = "Score") +
  theme_minimal(base_size = 11) +
  ylim(0, 1.15) +  # mais espaço para os rótulos verticais
  facet_wrap(~ Element, ncol = 2) +
  theme(
    strip.text = element_text(size = 12),
    panel.spacing = unit(2, "lines")  # mais espaço entre os gráficos
  )

# Salvar com altura estendida
ggsave("Barplot_AllElements.pdf", plot = p, width = 10, height = 16)
