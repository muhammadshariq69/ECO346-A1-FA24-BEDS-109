# 01_default.R -- Question 4 baseline (practice copy for FA24-BEDS-109).
# Draws literate against age with R's defaults untouched and saves figures/default.svg.
# Run from the project root:  Rscript scripts/01_default.R

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
literacy_sample <- subset(d, age >= 10 & age <= 64 & !is.na(literate))

# --- R's defaults, untouched ---------------------------------------------
p <- ggplot(literacy_sample, aes(x = age, y = literate)) + geom_point()

# --- Every figure is saved as SVG by the script that draws it ------------
ggsave("figures/default.svg", plot = p, device = svglite, width = 7, height = 5)
