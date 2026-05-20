# 2016 U.S. Election Polling — Margin Variance Over Time

This repository extends the analysis from [nmaccabe/polling-bias-2016-us-election](https://github.com/nmaccabe/polling-bias-2016-us-election) by addressing the central question:

> **How did the variance of polling margins evolve across the 2016 U.S. presidential campaign?**

---

## Methodological Decisions

Two deliberate departures from Nathan's original approach were made before building these visualizations:

- **No pollster-quality weighting.** Grade-based weighting pushes aggregate estimates toward Clinton, as Nathan's repo itself flags. Because the choice of grade cutoff is inherently subjective, all polls are treated equally here.
- **All pollster grades included.** Discarding polls by grade is a subjective call that risks cherry-picking. The full sample is used throughout.

**Margin convention** (maintained from Project 1):
```
adj_margin = adjpoll_clinton − adjpoll_trump
```
Positive = Clinton lead. Negative = Trump lead. Units = FiveThirtyEight-adjusted percentage points.

---

## Repository Structure

```
.
├── polls_us_election_2016.csv          # Raw data (FiveThirtyEight via dslabs)
├── Project1.R                          # Baseline analysis (harmonized convention)
├── task3_definitive_visualizations.R   # This task — all three variance vizzes
└── output/
    └── figures/
        ├── task3_viz1_weekly_sd_over_time.png
        ├── task3_viz2_margin_corridor.png
        └── task3_viz3_sd_by_population.png
```

---

## Visualizations

### Viz 1 — Weekly SD Over Time: National vs State Polls

![Viz 1](output/figures/task3_viz1_weekly_sd_over_time.png)

Computes the **standard deviation of adjusted margins** within each calendar week, separately for national and state polls. Point size encodes the number of polls that week; a LOESS smoother with 95% CI shows the trend.

A rising SD means pollsters disagreed more; a falling SD means convergence. The key question: did national and state polls converge toward election day, or did disagreement persist?

---

### Viz 2 — Mean ± 1 SD Corridor (14-Day Rolling Window)

![Viz 2](output/figures/task3_viz2_margin_corridor.png)

For every poll date, all polls from the **preceding 14 days** are pooled to compute a rolling mean and rolling SD. The shaded ribbon spans mean ± 1 SD — its width is variance made directly visible.

The red dashed line marks zero (the Trump threshold). A ribbon whose lower bound crosses zero signals that the polling consensus, even within its own spread, could not rule out a Trump win.

---

### Viz 3 — Variance by Survey Population: LV vs RV

![Viz 3](output/figures/task3_viz3_sd_by_population.png)

Splits the weekly SD by survey population — **Likely Voters (LV)** vs **Registered Voters (RV)** — to test whether variance evolved differently depending on the sampling frame. Panels share the y-axis so magnitudes are directly comparable.

If LV screens compressed variance faster than RV screens, it implies the likely-voter methodology was imposing structure on the data beyond just filtering respondents — a finding that connects directly to Nathan's house-effects results.

---

## Dependencies

```r
library(tidyverse)
library(lubridate)
```

Data (`polls_us_election_2016.csv`) is included in the repository and is also available via `dslabs::polls_us_election_2016`.

---

## Replication

```r
# Set working directory to the repo root, then:
source("task3_definitive_visualizations.R")
# Figures written to output/figures/
```
