# =============================================================================
# Module 1 Project — Task 3: Definitive Visualizations (Revised)
# STA4320 / MAT5314X — Techniques of Data Analysis
#
# Central question: How did polling margin variance evolve over time?
#
# Revisions:
#   - All three visualizations now address margin variance over time
#   - No pollster-quality weighting; all grades included
#   - Margin: adj_margin = adjpoll_clinton - adjpoll_trump (Project1 convention)
#   - Visual style fully harmonized with Project1
# =============================================================================

library(tidyverse)
library(lubridate)

# ── Setup ──────────────────────────────────────────────────────────────────────
working_directory <- dirname(rstudioapi::documentPath())
setwd(working_directory)

dir.create("../output/figures", recursive = TRUE, showWarnings = FALSE)

# ── Project1 palette ───────────────────────────────────────────────────────────
col_clinton  <- "#3A6EA5"    # blue  (Clinton / positive margin)
col_trump    <- "#C94A30"    # red   (Trump   / negative margin)
col_national <- "#D85A30"    # burnt orange (national polls)
col_state    <- "steelblue"  # state polls

# ── Load & prepare data ────────────────────────────────────────────────────────
polls <- read_csv("polls_us_election_2016.csv") |>
  mutate(
    adj_margin = adjpoll_clinton - adjpoll_trump,
    raw_margin = rawpoll_clinton  - rawpoll_trump,
    enddate    = as.Date(enddate),
    week       = floor_date(enddate, "week")
  ) |>
  filter(!is.na(adj_margin), !is.na(enddate))

election_day <- as.Date("2016-11-08")


# =============================================================================
# VIZ 1 — Weekly Rolling SD: How Spread Did the Polls Get Over Time?
#
# Computes the standard deviation of adjusted margins within each rolling
# 4-week window, separately for national and state polls. High SD = high
# disagreement across pollsters. Shows whether variance compressed as
# election day approached or remained wide to the end.
# =============================================================================

# Compute weekly SD for national and state polls
weekly_sd <- polls |>
  mutate(is_natl = if_else(state == "U.S.", "National", "State")) |>
  group_by(week, is_natl) |>
  summarise(
    sd_margin  = sd(adj_margin, na.rm = TRUE),
    n_polls    = n(),
    .groups    = "drop"
  ) |>
  filter(n_polls >= 3)   # need at least 3 polls for a meaningful SD

p1 <- ggplot(weekly_sd, aes(x = week, y = sd_margin,
                            colour = is_natl, fill = is_natl)) +
  geom_point(aes(size = n_polls), alpha = 0.35, shape = 16) +
  geom_smooth(method = "loess", se = TRUE, linewidth = 1, na.rm = TRUE) +
  geom_vline(xintercept = election_day,
             colour = "grey30", linewidth = 0.5, linetype = "dotted") +
  annotate("text",
           x = election_day + 3, y = Inf, vjust = 1.6, hjust = 0,
           label = "Election\nDay", size = 2.9, colour = "grey30") +
  scale_colour_manual(values = c("National" = col_national,
                                 "State"    = col_state)) +
  scale_fill_manual(values   = c("National" = col_national,
                                 "State"    = col_state)) +
  scale_size_continuous(range = c(1, 5), guide = "none") +
  labs(
    title    = "Polling Margin Variance Over Time: National vs State Polls",
    subtitle = "Weekly standard deviation of adjusted Clinton\u2212Trump margin (all grades).\nPoint size = number of polls that week. LOESS smoother with 95% CI.",
    x        = "Week",
    y        = "SD of adjusted margin (pp)",
    colour   = NULL,
    fill     = NULL,
    caption  = "adj_margin = adjpoll_clinton \u2212 adjpoll_trump  |  All pollster grades  |  Source: polls_us_election_2016"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold"),
    plot.subtitle    = element_text(size = 9, colour = "grey40", lineheight = 1.45),
    plot.caption     = element_text(size = 7, colour = "grey55"),
    panel.grid.minor = element_blank(),
    legend.position  = "top",
    plot.background  = element_rect(fill = "white", color = NA)
  )

ggsave("../output/figures/task3_viz1_weekly_sd_over_time.png",
       p1, width = 9, height = 5.5, dpi = 200)

# =============================================================================
# VIZ 2 — Ribbon Chart: Mean ± 1 SD Corridor Over Time
#
# Shows the evolving center and spread of adjusted margins as a shaded ribbon
# (mean ± 1 SD), computed in 2-week rolling windows. Separate ribbons for
# national and state polls. A narrowing ribbon means pollsters converged;
# a wide persistent ribbon means they never agreed. The zero line (red dashed)
# marks the Trump threshold — does the lower bound cross it toward the end?
# =============================================================================

# 2-week rolling window: for each poll date, compute mean & SD of polls
# in the preceding 14 days
rolling_stats <- polls |>
  mutate(is_natl = if_else(state == "U.S.", "National", "State")) |>
  arrange(is_natl, enddate) |>
  group_by(is_natl) |>
  mutate(
    roll_mean = map_dbl(seq_along(enddate), function(i) {
      w <- adj_margin[enddate >= (enddate[i] - 13) & enddate <= enddate[i]]
      mean(w, na.rm = TRUE)
    }),
    roll_sd = map_dbl(seq_along(enddate), function(i) {
      w <- adj_margin[enddate >= (enddate[i] - 13) & enddate <= enddate[i]]
      if (length(w) < 3) NA_real_ else sd(w, na.rm = TRUE)
    })
  ) |>
  ungroup() |>
  filter(!is.na(roll_sd)) |>
  mutate(
    ymin = roll_mean - roll_sd,
    ymax = roll_mean + roll_sd
  )

p2 <- ggplot(rolling_stats, aes(x = enddate, colour = is_natl, fill = is_natl)) +
  geom_ribbon(aes(ymin = ymin, ymax = ymax), alpha = 0.18, colour = NA) +
  geom_line(aes(y = roll_mean), linewidth = 0.95, na.rm = TRUE) +
  geom_hline(yintercept = 0,
             colour = col_trump, linewidth = 0.7, linetype = "dashed") +
  geom_vline(xintercept = election_day,
             colour = "grey30", linewidth = 0.5, linetype = "dotted") +
  annotate("text",
           x = election_day + 3, y = Inf, vjust = 1.6, hjust = 0,
           label = "Election\nDay", size = 2.9, colour = "grey30") +
  scale_colour_manual(values = c("National" = col_national,
                                 "State"    = col_state)) +
  scale_fill_manual(values   = c("National" = col_national,
                                 "State"    = col_state)) +
  labs(
    title    = "Margin Corridor Over Time: Mean \u00b1 1 SD (14-Day Rolling Window)",
    subtitle = "Shaded band = mean \u00b1 1 SD of adjusted margins across all polls in the preceding 14 days.\nRed dashed line = zero (Trump threshold).",
    x        = "Poll end date",
    y        = "Adjusted Clinton\u2212Trump margin (pp)",
    colour   = NULL,
    fill     = NULL,
    caption  = "adj_margin = adjpoll_clinton \u2212 adjpoll_trump  |  All pollster grades  |  Source: polls_us_election_2016"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold"),
    plot.subtitle    = element_text(size = 9, colour = "grey40", lineheight = 1.45),
    plot.caption     = element_text(size = 7, colour = "grey55"),
    panel.grid.minor = element_blank(),
    legend.position  = "top",
    plot.background  = element_rect(fill = "white", color = NA)
  )

ggsave("../output/figures/task3_viz2_margin_corridor.png",
       p2, width = 9, height = 5.5, dpi = 200)
# =============================================================================
# VIZ 3 — Faceted Variance by Survey Population Over Time
#
# Splits the weekly SD by survey population (lv / rv / a) to test whether
# variance evolved differently depending on who pollsters chose to sample.
# If likely-voter screens narrowed variance faster than registered-voter
# screens, that tells us the LV methodology was imposing additional
# structure — not just a neutral filter. Facets share the y-axis so
# magnitudes are directly comparable.
# =============================================================================

weekly_sd_pop <- polls |>
  filter(population %in% c("lv", "rv")) |>
  mutate(
    pop_label = recode(population,
                       "lv" = "Likely Voters (LV)",
                       "rv" = "Registered Voters (RV)"
                       )
  ) |>
  group_by(week, pop_label) |>
  summarise(
    sd_margin = sd(adj_margin, na.rm = TRUE),
    n_polls   = n(),
    .groups   = "drop"
  ) |>
  filter(n_polls >= 3)

p3 <- ggplot(weekly_sd_pop, aes(x = week, y = sd_margin)) +
  geom_point(aes(size = n_polls), colour = col_clinton, alpha = 0.30, shape = 16) +
  geom_smooth(method = "loess", se = TRUE,
              colour = col_clinton, fill = col_clinton,
              linewidth = 0.95, na.rm = TRUE) +
  geom_vline(xintercept = election_day,
             colour = "grey30", linewidth = 0.5, linetype = "dotted") +
  scale_size_continuous(range = c(1, 4), guide = "none") +
  facet_wrap(~ pop_label, ncol = 1) +
  labs(
    title    = "Did Variance Compress Differently by Survey Population?",
    subtitle = "Weekly SD of adjusted margin per population type (all grades).\nShared y-axis — magnitudes are directly comparable across panels.",
    x        = "Week",
    y        = "SD of adjusted margin (pp)",
    caption  = "adj_margin = adjpoll_clinton \u2212 adjpoll_trump  |  All pollster grades  |  Source: polls_us_election_2016"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold"),
    plot.subtitle    = element_text(size = 9, colour = "grey40", lineheight = 1.45),
    plot.caption     = element_text(size = 7, colour = "grey55"),
    panel.grid.minor = element_blank(),
    strip.text       = element_text(face = "bold", size = 10),
    plot.background  = element_rect(fill = "white", color = NA)
  )

ggsave("../output/figures/task3_viz3_sd_by_population.png",
       p3, width = 9, height = 9, dpi = 200)

