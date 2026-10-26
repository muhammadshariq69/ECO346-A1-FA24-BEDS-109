# 02_distribution.R -- Question 2 (practice copy for FA24-BEDS-109).
# Weighted histogram of annual education spending on a log scale, saved as
# figures/distribution.svg, plus the numbers the question asks for.
# Run from the project root:  Rscript scripts/02_distribution.R

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
# Weighted mean: sum(w*x) / sum(w)
wmean <- function(x, w) sum(w * x) / sum(w)

# Weighted q-th quantile, exactly as defined in the assignment:
# sort by x, take the cumulative share of weight, return the smallest x at
# which that share reaches or exceeds q. (R's quantile() uses another rule.)
wquantile <- function(x, w, q) {
  o <- order(x)
  x <- x[o]
  w <- w[o]
  cw <- cumsum(w) / sum(w)
  x[which(cw >= q)[1]]
}

fmt_rs <- function(x) format(round(x), big.mark = ",", scientific = FALSE, trim = TRUE)

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
  "Education spending must be numeric" = is.numeric(d$ed_total)
)

d <- d[d$prov_code == 2 & d$urban_rural == 2, ]

# --- Students: annual education spending greater than zero -----------------
students <- subset(d, ed_total > 0)
n_students <- nrow(students)

# --- Keep Rs 100 (log10 2.0) to Rs 1,000,000 (log10 6.0) ------------------
log_sp  <- log10(students$ed_total)
in_rng  <- !is.na(log_sp) & log_sp >= 2 & log_sp <= 6
n_excluded <- sum(!in_rng)

sp <- students$ed_total[in_rng]   # rupees
w  <- students$hhweight[in_rng]   # household weight
lx <- log10(sp)                   # log10(rupees)

# --- Statistics on the analysed sample ------------------------------------
w_med   <- wquantile(sp, w, 0.50)
w_p10   <- wquantile(sp, w, 0.10)
w_p90   <- wquantile(sp, w, 0.90)
# Unweighted median uses the assignment quantile rule with equal weights
# (R's median() averages two central values and would not match the key).
u_med   <- wquantile(sp, rep(1, length(sp)), 0.50)
w_mean  <- wmean(sp, w)
ratio   <- w_p90 / w_p10

# Average survey weights below vs above the unweighted sample median
mean_w_below <- mean(w[sp < u_med])
mean_w_above <- mean(w[sp > u_med])

# --- Weighted density per log10 unit in each 0.1-wide bin -----------------
breaks <- seq(2, 6, by = 0.1)
mids   <- (breaks[-1] + breaks[-length(breaks)]) / 2
bin    <- cut(lx, breaks = breaks, include.lowest = TRUE)
w_bin  <- tapply(w, bin, sum)
w_bin[is.na(w_bin)] <- 0
density_log <- as.numeric(w_bin) / (sum(w) * 0.1)     # per log10 unit
dens_df <- data.frame(mid = mids, density = density_log)

# --- The figure -----------------------------------------------------------
title_txt <- sprintf(
  "Weighted median education spending is Rs %s; the top 10%% exceed Rs %s",
  fmt_rs(w_med), fmt_rs(w_p90))
caption_txt <- sprintf(
  paste0("Source: PSLM 2019-20 person and household files (course data repository).\n",
         "Sample: %s students with annual education spending above zero in Punjab urban; ",
         "%s %s outside Rs 100-Rs 1,000,000 %s excluded.\n",
         "Weighted by the household weight (hhweight). Bins are 0.1 log10 units wide."),
  format(n_students, big.mark = ","), format(n_excluded, big.mark = ","),
  if (n_excluded == 1) "student" else "students",
  if (n_excluded == 1) "is" else "are")

ymax <- max(dens_df$density)

p <- ggplot(dens_df, aes(x = mid, y = density)) +
  geom_col(fill = "#3B6FB6", width = 0.1) +
  geom_vline(xintercept = log10(w_med), linetype = "dashed",
             colour = "#C0392B", linewidth = 0.7) +
  geom_vline(xintercept = log10(w_p90), linetype = "dashed",
             colour = "#1E8449", linewidth = 0.7) +
  annotate("text", x = log10(w_med), y = ymax * 0.95,
           label = paste0("Weighted median: Rs ", fmt_rs(w_med)),
           hjust = 1.03, size = 3.4, colour = "#C0392B",
           fontface = "bold") +
  annotate("text", x = log10(w_p90), y = ymax * 0.95,
           label = paste0("90th percentile: Rs ", fmt_rs(w_p90)),
           hjust = -0.03, size = 3.4, colour = "#1E8449",
           fontface = "bold") +
  scale_x_continuous(
    breaks = c(2, 3, 4, 5, 6),
    labels = function(x) format(10^x, big.mark = ",", scientific = FALSE, trim = TRUE)) +
  labs(
    title = title_txt,
    x = "Annual education spending on a student (Rs)",
    y = "Density per log10 unit",
    caption = caption_txt) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.caption = element_text(hjust = 0, size = 8, colour = "grey30"),
    plot.margin = margin(10, 16, 10, 10))

ggsave("figures/distribution.svg", plot = p, device = svglite,
       width = 8, height = 5.5)

# --- The numbers the question asks for ------------------------------------
cat("\n================ QUESTION 2 NUMBERS ================\n")
cat("Students (ed_total > 0), total          :", format(n_students, big.mark = ","), "\n")
cat("Students analysed (Rs 100-Rs 1,000,000) :", format(length(sp), big.mark = ","), "\n")
cat("Students excluded                       :", format(n_excluded, big.mark = ","), "\n")
cat("Weighted median                         : Rs", fmt_rs(w_med), "\n")
cat("Unweighted median                       : Rs", fmt_rs(u_med), "\n")
cat("Weighted mean                           : Rs", fmt_rs(w_mean), "\n")
cat("Weighted 10th percentile                : Rs", fmt_rs(w_p10), "\n")
cat("Weighted 90th percentile                : Rs", fmt_rs(w_p90), "\n")
cat("Ratio P90 / P10 (2 decimals)            :", sprintf("%.2f", ratio), "\n")
cat("Mean weight below unweighted median     :", sprintf("%.1f", mean_w_below), "\n")
cat("Mean weight above unweighted median     :", sprintf("%.1f", mean_w_above), "\n")
cat("====================================================\n")
