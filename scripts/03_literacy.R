# 03_literacy.R -- Question 3 (and the redesign for Question 4).
# Practice copy for FA24-BEDS-109.
# Weighted literacy rate against age band, women and men as two series, saved
# as figures/literacy.svg.  Also writes the full band table and the numbers
# the question asks for.
# Run from the project root:  Rscript scripts/03_literacy.R

library(ggplot2)
library(svglite)

# --- Path resolution: ensure working directory is project root ------------
args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
if (length(file_arg) > 0) {
  script_dir <- dirname(normalizePath(sub("^--file=", "", file_arg[1])))
  if (basename(script_dir) == "scripts") setwd(dirname(script_dir))
} else if (basename(getwd()) == "scripts") {
  setwd("..")
}

# --- Helpers --------------------------------------------------------------
wmean <- function(x, w) sum(w * x) / sum(w)

# --- Variant 1: Punjab, urban (prov_code 2, urban_rural 2) ----------------
hh  <- read.csv("data/pslm_hh_subset.csv")
per <- read.csv("data/pslm_person_subset.csv")

# Data validation checks
stopifnot(
  "Household file must have unique hhid" = length(unique(hh$hhid)) == nrow(hh),
  "Household weights must be positive and non-missing" = all(!is.na(hh$hhweight) & hh$hhweight > 0)
)

d <- merge(per, hh[, c("hhid", "hhweight", "prov_code", "urban_rural")], by = "hhid")
stopifnot(
  "Merge must preserve person record count" = nrow(d) == nrow(per),
  "Literate column values must be 0, 1, or NA" = all(is.na(d$literate) | d$literate %in% c(0, 1)),
  "Sex column values must be 1 or 2" = all(d$sex %in% c(1, 2))
)

d <- d[d$prov_code == 2 & d$urban_rural == 2, ]

# --- Literacy sample: persons aged 10-64 whose literate value is present ---
lsamp <- subset(d, age >= 10 & age <= 64 & !is.na(literate))

# --- Five-year age bands with midpoints 12, 17, ..., 62 -------------------
brk  <- seq(10, 65, by = 5)                       # 10,15,...,65
lab  <- paste0(brk[-length(brk)], "-", brk[-1] - 1)
band <- cut(lsamp$age, breaks = brk, right = FALSE, labels = lab)
midpoints <- setNames(brk[-length(brk)] + 2, lab)     # midpoint: 12,17,...,62
lsamp$band <- band
lsamp$mid  <- midpoints[as.character(band)]
lsamp$sexf <- factor(lsamp$sex, levels = c(1, 2), labels = c("Men", "Women"))

# --- Weighted literacy rate and count for each band x sex -----------------
keys <- expand.grid(band = factor(lab, levels = lab), sexf = c("Men", "Women"))
rows <- lapply(seq_len(nrow(keys)), function(i) {
  b <- as.character(keys$band[i])
  s <- keys$sexf[i]
  g <- lsamp[lsamp$band == b & lsamp$sexf == s, ]
  data.frame(
    band  = b,
    mid   = unname(midpoints[b]),
    sexf  = s,
    n     = nrow(g),
    rate  = if (nrow(g) > 0) 100 * wmean(g$literate, g$hhweight) else NA)
})
tab <- do.call(rbind, rows)
tab$thin <- tab$n < 30

# --- Print the full band table (n and weighted rate, by sex) --------------
cat("\n================ QUESTION 3 BAND TABLE ================\n")
men   <- tab[tab$sexf == "Men", ]
women <- tab[tab$sexf == "Women", ]
wide <- data.frame(
  band       = men$band,
  men_n      = men$n,
  men_rate   = sprintf("%.1f", men$rate),
  women_n    = women$n,
  women_rate = sprintf("%.1f", women$rate))
print(wide, row.names = FALSE)

# Save the tidy table (numeric, one decimal) so the Python table can be
# compared with it by script.
write.csv(data.frame(
  band       = men$band,
  men_n      = men$n,
  men_rate   = round(men$rate, 1),
  women_n    = women$n,
  women_rate = round(women$rate, 1)),
  "scripts/band_table_R.csv", row.names = FALSE)

# --- The band with the largest gap between men and women ------------------
gap_df    <- data.frame(band = men$band, men = men$rate, women = women$rate)
gap_df$gap <- abs(gap_df$men - gap_df$women)
gap_i     <- which.max(gap_df$gap)
gap_band  <- gap_df$band[gap_i]
gap_value <- gap_df$gap[gap_i]
gap_mid   <- men$mid[gap_i]

# --- Direct end labels ----------------------------------------------------
ends <- do.call(rbind, lapply(c("Men", "Women"), function(s) {
  g <- tab[tab$sexf == s & !is.na(tab$rate), ]
  g[which.max(g$mid), ]
}))

title_txt <- sprintf(
  "The gender gap in literacy is widest at ages %s: %.1f points",
  gap_band, gap_value)
caption_txt <- paste0(
  "Source: PSLM 2019-20 person and household files (course data repository).\n",
  "Sample: persons aged 10-64 with a non-missing literacy value in Punjab urban; ",
  "weighted by the household weight (hhweight).\n",
  "Hollow markers mark thin cells: a band-sex group with fewer than 30 observations.")

# --- The figure -----------------------------------------------------------
# Markers: filled for solid cells, hollow (white fill) for thin cells.
# Lines are solid for both series; colour and the end labels carry the sex.
tab$marker_fill <- ifelse(tab$thin, "white",
                          ifelse(tab$sexf == "Men", "#2C7FB8", "#D95F02"))

p <- ggplot(tab, aes(x = mid, y = rate, colour = sexf, group = sexf)) +
  geom_line(linewidth = 0.8, na.rm = TRUE) +
  geom_point(aes(fill = marker_fill, colour = sexf),
             shape = 21, size = 3, stroke = 0.9, na.rm = TRUE) +
  scale_fill_identity() +
  scale_colour_manual(values = c(Men = "#2C7FB8", Women = "#D95F02")) +
  geom_text(data = ends, aes(label = sexf, x = mid, y = rate),
            hjust = -0.15, vjust = 0.5, size = 3.6, fontface = "bold",
            show.legend = FALSE) +
  annotate("segment", x = gap_mid, xend = gap_mid,
           y = gap_df$men[gap_i], yend = gap_df$women[gap_i],
           colour = "grey35", linewidth = 0.6) +
  annotate("text", x = gap_mid, y = max(gap_df$men[gap_i], gap_df$women[gap_i]) + 4,
           label = sprintf("Largest gap at ages %s: %.1f points",
                           gap_band, gap_value),
           size = 3.3, colour = "grey20", fontface = "bold") +
  scale_x_continuous(breaks = seq(12, 62, by = 10), limits = c(9, 70),
                     expand = expansion(mult = c(0, 0))) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, by = 20),
                     expand = expansion(mult = c(0, 0))) +
  labs(
    title = title_txt,
    x = "Age band midpoint (years)",
    y = "Weighted literacy rate (%)",
    caption = caption_txt) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.caption = element_text(hjust = 0, size = 8, colour = "grey30"),
    plot.margin = margin(10, 28, 10, 10)) +
  coord_cartesian(clip = "off")

ggsave("figures/literacy.svg", plot = p, device = svglite,
       width = 8.5, height = 5.5)

# --- The numbers the question asks for ------------------------------------
get_rate <- function(b, s) {
  r <- tab$rate[tab$band == b & tab$sexf == s]
  if (length(r) == 0) return(NA)
  r
}
cat("\n================ QUESTION 3 KEY NUMBERS ================\n")
cat("Women 15-19 weighted literacy rate      :", sprintf("%.1f", get_rate("15-19", "Women")), "%\n")
cat("Men   15-19 weighted literacy rate      :", sprintf("%.1f", get_rate("15-19", "Men")), "%\n")
cat("Women 55-59 weighted literacy rate      :", sprintf("%.1f", get_rate("55-59", "Women")), "%\n")
cat("Men   55-59 weighted literacy rate      :", sprintf("%.1f", get_rate("55-59", "Men")), "%\n")
cat("Band with the largest gap               :", gap_band, "\n")
cat("Largest gap (points)                    :", sprintf("%.1f", gap_value), "\n")
cat("========================================================\n")
