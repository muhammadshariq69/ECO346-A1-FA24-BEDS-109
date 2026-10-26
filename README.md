# PRACTICE-ECO346-FA24-BEDS-109


Data Visualization Techniques for Economists - Assignment 1 (Fall 2026), worked for
registration number **FA24-BEDS-109** so the concepts can be studied separately from the
real submission for FA24-BEDS-105.

| | |
|---|---|
| **Registration number** | FA24-BEDS-109 |
| **Variant** | **1** = Punjab, urban (prov_code 2, urban_rural 2) |
| **Second language (Question 5)** | Python (pandas + matplotlib) |
| **Data** | PSLM 2019-20 person and household files (subset), in `data/` |

The variant is the last two digits of the registration number, `09`, taken modulo 8:
`09 = 1 x 8 + 1`, so variant 1. Every figure and number below uses only persons and
households in **Punjab urban**. Population estimates (means, quantiles, rates, densities)
are weighted by the household weight `hhweight`, attached from the household file by
`hhid`. Sample counts (n) and the unweighted median are reported unweighted to separate
sample size from population estimates.

---

## How to reproduce everything

Install the packages once on a fresh machine:

```r
# In R console / RStudio:
install.packages(c("ggplot2", "svglite"))
```

```bash
# In terminal / Command Prompt (Python). On Windows, use `py` if `python` is not on PATH:
py -m pip install numpy pandas matplotlib
```

Then, from the project root:

```bash
Rscript scripts/run_all.R
```

Individual scripts can also be run in order:

| Script | Question | Output |
|---|---|---|
| `scripts/01_default.R` | 4 (default) | `figures/default.svg` |
| `scripts/02_distribution.R` | 2 | `figures/distribution.svg` |
| `scripts/03_literacy.R` | 3 (redesign) | `figures/literacy.svg` + `scripts/band_table_R.csv` |
| `scripts/04_literacy.py` | 5 | `figures/literacy_python.svg` + `scripts/band_table_python.csv` (automated test against R) |

Every quantile, including the unweighted median, follows the assignment definition
exactly: sort by the variable, accumulate the weight share, and take the smallest value at
which the cumulative share reaches or exceeds *q*. Equal weights are used for the
unweighted median. R's built-in `quantile()` and `median()` are not used.

---

## Question 2 - The distribution of education spending

![Weighted histogram of annual education spending on a student](figures/distribution.svg)

**Reported numbers.**

| Quantity | Value |
|---|---|
| Students (ed_total > 0) | 4,596 |
| Students analysed (Rs 100 - Rs 1,000,000) | 4,594 |
| Students excluded (outside the range) | 2 |
| Weighted median | Rs 15,000 |
| Unweighted median | Rs 14,000 |
| Weighted 10th percentile | Rs 3,500 |
| Weighted 90th percentile | Rs 60,000 |
| Ratio of 90th to 10th percentile | 17.14 |
| Mean survey weight below unweighted median | 282.9 |
| Mean survey weight above unweighted median | 296.1 |

**What it shows (<= 80 words).** Education spending is strongly right-skewed: the weighted
population median is Rs 15,000, while the top tenth exceed Rs 60,000, 17.14 times the 10th
percentile of Rs 3,500. Weighting pulls the centre up from the unweighted sample median of
Rs 14,000 because students above that median have higher average survey weights (296.1 vs
282.9), so higher-spending households carry slightly more of the urban Punjab population.

---

## Question 3 - The relationship between literacy and age

![Weighted literacy rate by age band, men and women](figures/literacy.svg)

**Full band table.** Counts and weighted literacy rates (%) by age band and sex.

| Age band | Men, n | Men, % | Women, n | Women, % |
|---|---|---|---|---|
| 10-14 | 954 | 84.4 | 885 | 88.7 |
| 15-19 | 895 | 86.7 | 838 | 89.4 |
| 20-24 | 785 | 84.1 | 728 | 82.7 |
| 25-29 | 568 | 78.8 | 651 | 76.2 |
| 30-34 | 525 | 82.7 | 539 | 70.5 |
| 35-39 | 477 | 79.8 | 503 | 71.1 |
| 40-44 | 420 | 77.6 | 463 | 60.5 |
| 45-49 | 420 | 71.3 | 378 | 54.4 |
| 50-54 | 367 | 64.1 | 346 | 45.1 |
| 55-59 | 257 | 68.4 | 224 | 42.4 |
| 60-64 | 234 | 72.7 | 175 | 33.4 |

No band-sex cell falls below 30 observations, so no marker is hollow in this variant.

**Reported numbers.**

| Quantity | Value |
|---|---|
| Women aged 15-19 | 89.4 % |
| Men aged 15-19 | 86.7 % |
| Women aged 55-59 | 42.4 % |
| Men aged 55-59 | 68.4 % |
| Band with the largest gap | **60-64** (39.3 points) |

**Interpretation (<= 100 words).** Women have higher literacy than men at ages 10-19, but
men have the higher rate from age 20 onward, and the gap generally widens with age. Women
aged 15-19 have a literacy rate of 89.4% versus 42.4% at ages 55-59; men are at 86.7% and
68.4%. The gap is widest at 60-64 (39.3 points: men 72.7%, women 33.4%). The pattern is
consistent with later cohorts receiving more schooling, especially for women, but a single
cross-section cannot separate cohort effects from ageing or identify causes.

---

## Question 4 - The makeover

The default figure (`figures/default.svg`) is `ggplot(data, aes(age, literate)) +
geom_point()` with R's defaults untouched. The redesign is the Question 3 figure
(`figures/literacy.svg`).

**Explanation of the redesign (<= 150 words).** Three changes, each tied to a principle from
Chapters 1-4. First, the raw scatter is replaced by **conditional means**: the weighted
literacy rate in each five-year band, so the age pattern is no longer buried under thousands
of overlapping 0/1 points (**overplotting**). Second, the redesign keeps **position**, the
highest-ranked channel, for the two continuous quantities - age and the literacy rate - and
uses colour plus direct labels only for the categorical split by sex (**perceptual ranking of
channels**). Third, the legend is dropped in favour of end labels, cutting non-data ink
(**data-ink ratio**). The default figure still shows the actual spread and the discreteness
of the 0/1 outcome, which the redesign hides by plotting one summary value per cell.

---

## Question 5 - A second language (Python)

`scripts/04_literacy.py` recomputes the Question 3 band table, saves it to
`scripts/band_table_python.csv`, and redraws the figure in Python, saved as
`figures/literacy_python.svg`. An automated verification step asserts that the counts and
all eleven age-band weighted literacy rates agree with R within rounding tolerance.

**Reported numbers.** The literacy rate of **women aged 15-19** is **89.4%** from R and
**89.4%** from Python.

**One difference and how it was fixed (<= 80 words).** The default axis range and tick
spacing differed: ggplot expanded the panel around the data, while matplotlib padded the
axes differently, so the two figures would not overlay. I set the same limits in both
scripts (age 9-70, rate 0-100) and the same breaks (age 12, 22, ..., 62; rate 0, 20, ...,
100).

---

## Project structure

```
PRACTICE-ECO346-FA24-BEDS-109/
+-- README.md
+-- data/       pslm_person_subset.csv, pslm_hh_subset.csv
+-- scripts/    01_default.R, 02_distribution.R, 03_literacy.R,
+               04_literacy.py, run_all.R
+-- figures/    default.svg, distribution.svg, literacy.svg, literacy_python.svg
```
