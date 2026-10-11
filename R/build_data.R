# Build tidy long-format data for the Permafrost indicator.
#
#   Rscript R/build_data.R
#
# Reads EPA's published figure CSVs in data-raw/ and writes data/*.csv plus
# data/meta.yml. Rerunning with unchanged inputs produces byte-identical output.
# Nothing here touches the network.
#
# TO UPDATE THE DATA: drop replacement CSVs into data-raw/ and rerun. Headers
# are asserted, not assumed, so a renamed or reordered column stops the build.

suppressPackageStartupMessages({
  library(dplyr)
})

root <- here::here()
source(file.path(root, "R/utils/epa_csv.R"))
source(file.path(root, "R/utils/write_stable.R"))

raw_dir <- file.path(root, "data-raw")
out_dir <- file.path(root, "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Indicator constants -----------------------------------------------------

INDICATOR <- list(
  name                    = "Permafrost",
  slug                    = "permafrost",
  publisher               = "U.S. Environmental Protection Agency",
  source_page             = "https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-permafrost/index.html",
  technical_documentation = "https://19january2025snapshot.epa.gov/system/files/documents/2024-12/permafrost_td.pdf",
  rights                  = "Public domain, work of the U.S. Government (17 U.S.C. 105)"
)

# ---- Figure 1: Permafrost Temperatures in Alaska, 1978–2023 ----

f1_path <- file.path(raw_dir, "permafrost_fig-1.csv")
f1_meta <- read_epa_preamble(f1_path)
f1_raw  <- read_epa_csv(f1_path)

assert_headers(
  f1_raw,
  id_cols          = "Year",
  expected_headers = c("Livengood", "C'uul C'ena' (Gulkana)", "Birch Lake", "Old Man", "T'eedrinjik (Chandalar Shelf)", "Deenaalee (Healy)", "Troth Yeddha' (College Peat)", "Coldfoot", "West Dock", "Deadhorse", "Franklin Bluffs", "Happy Valley", "Galbraith Lake", "Utqiagvik (Barrow)", "Qaaktugvik (Kaktovik)"),
  what             = "permafrost_fig-1.csv"
)

# One column per borehole site, one row per year. Units: °F. Site names are kept
# exactly as EPA prints them. Blank cells (no measurement that year) are dropped.
# Values stay character so the source digits survive byte for byte.
f1 <- f1_raw |>
  tidyr::pivot_longer(-Year, names_to = "site", values_to = "value") |>
  filter(value != "") |>
  transmute(year = Year, site, value)

write_csv_stable(f1, file.path(out_dir, "permafrost_temperatures.csv"))

# ---- Figure 2: Changes in Permafrost Temperatures in Alaska, 1978–2023 ----

f2_path <- file.path(raw_dir, "permafrost_fig-2.csv")
f2_meta <- read_epa_preamble(f2_path)
f2_raw  <- read_epa_csv(f2_path)

assert_headers(
  f2_raw,
  id_cols          = c("Region", "Site name", "Native Name", "Depth of measurement", "Latitude", "Longitude", "Elevation"),
  expected_headers = "Decadal slope",
  what             = "permafrost_fig-2.csv"
)

# Already one row per site, so no pivot. The Units: line is one unit per column
# (n/a; n/a; meters; degrees; degrees; meters; °F); the site attributes carry
# their unit in the column name, leaving `value` as the only measure: the
# decadal slope of permafrost temperature, in °F per decade.
f2 <- f2_raw |>
  transmute(
    region      = Region,
    site        = `Site name`,
    native_name = `Native Name`,
    depth_m     = `Depth of measurement`,
    latitude    = Latitude,
    longitude   = Longitude,
    elevation_m = Elevation,
    value       = `Decadal slope`
  )

write_csv_stable(f2, file.path(out_dir, "permafrost_temperature_trends.csv"))

# ---- Data dictionary ---------------------------------------------------------

col <- function(name, type, description) {
  list(name = name, type = type, description = description)
}

# One entry per output column, in order, filled from the data frame itself so it
# cannot drift.
describe <- function(df, value_desc) {
  docs <- list(
    year        = c("integer", "Year."),
    site        = c("string", "Borehole site name, as EPA prints it in this figure."),
    region      = c("string", "Region of Alaska: Northern Alaska or Interior Alaska."),
    native_name = c("string", "Alaska Native name of the site, blank where EPA gives none."),
    depth_m     = c("number", "Depth of the temperature measurement, in meters."),
    latitude    = c("number", "Latitude of the site in decimal degrees (north positive)."),
    longitude   = c("number", "Longitude of the site in decimal degrees (west negative)."),
    elevation_m = c("number", "Elevation of the site, in meters."),
    value       = c("number", value_desc)
  )
  lapply(names(df), function(nm) col(nm, docs[[nm]][1], docs[[nm]][2]))
}

meta <- list(
  indicator = INDICATOR,
  datasets = list(
    list(
      file            = "permafrost_temperatures.csv",
      figure          = "Figure 1",
      figure_title    = f1_meta$title,
      source_file     = "permafrost_fig-1.csv",
      source_sha256   = file_sha256(f1_path),
      source_encoding = "UTF-8-BOM",
      data_source     = f1_meta$data_source,
      web_update      = f1_meta$web_update,
      unit            = f1_meta$units,
      rows            = nrow(f1),
      columns         = describe(f1, "Annual mean permafrost temperature at the site, in °F, as published by EPA.")
    ),
    list(
      file            = "permafrost_temperature_trends.csv",
      figure          = "Figure 2",
      figure_title    = f2_meta$title,
      source_file     = "permafrost_fig-2.csv",
      source_sha256   = file_sha256(f2_path),
      source_encoding = "windows-1252",
      data_source     = f2_meta$data_source,
      web_update      = f2_meta$web_update,
      unit            = "°F per decade",
      rows            = nrow(f2),
      columns         = describe(f2, "Decadal slope of permafrost temperature at the site, in °F per decade, as published by EPA.")
    )
  )
)

write_yaml_stable(meta, file.path(out_dir, "meta.yml"))

# ---- Verify what was written -------------------------------------------------

written <- list.files(out_dir, pattern = "[.](csv|yml)$", full.names = TRUE)
invisible(lapply(written, assert_clean_output))

cat("\nWrote:\n")
for (p in written) {
  cat(sprintf("  %-34s %8d bytes  %s\n", basename(p), file.size(p), substr(file_sha256(p), 1, 12)))
}
