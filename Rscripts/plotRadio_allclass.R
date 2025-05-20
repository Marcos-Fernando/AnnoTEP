library(tidyr)
library(fmsb)


date <- read.csv("perfomance_AnnoTEP.csv")
date_wide <- pivot_wider(date, names_from = Metric, values_from = Value)
date_wide <- as.data.frame(date_wide)

# Define row names as the ‘Element’ column
rownames(date_wide) <- date_wide$Element
date_wide <- date_wide[, -1]  # Remove  "Element" column


# Add value max and min for metric
date_wide <- rbind(rep(1, ncol(date_wide)), rep(0, ncol(date_wide)), date_wide)
colors <- c("LTR" = "#5078ff", "SINE" = "#046304", "LINE" = "#ff4747", "TIR" = "purple", "MITE" = "orange", "Helitron" = "#615d5d", "Total" = "#e6e214", "nonLTR" = "#43f00e" )

radarchart(
  date_wide,
  axistype = 1,
  pcol = colors, 
  pfcol = NA, 
  plwd = 2,  
  cglcol = "#dadada",  
  cglty = 1,  
  axislabcol = "black", 
  caxislabels = seq(0, 1, 0.2),
  title = "AnnoTEP perfomance"
)

# Legend
legend(
  "topright",
  inset = c(0, 0.35),
  legend = rownames(date_wide)[-c(1, 2)],  
  bty = "n",  
  pch = 20,  
  col = colors, 
  text.col = "black",
  cex = 1,  
  pt.cex = 2  
)