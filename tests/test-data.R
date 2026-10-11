# Regression checks on the generated data for the Permafrost indicator.
#
#   Rscript tests/test-data.R
#
# The checks below are shape-independent: they hold whatever the reshape in
# R/build_data.R turns each figure into. Value snapshots, which pin the actual
# numbers so a data update fails loudly instead of passing silently, are the
# TODO at the bottom.

setwd(here::here())
source("R/utils/write_stable.R")

# Keeps the dictionary check readable when a meta.yml field is absent altogether.
`%||%` <- function(a, b) if (is.null(a)) b else a

failures <- character()
check <- function(label, ok) {
  ok <- isTRUE(ok)
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) failures <<- c(failures, label)
  invisible(ok)
}

rd <- function(f) {
  readr::read_csv(file.path("data", f),
                  col_types = readr::cols(.default = readr::col_character()),
                  na = character(), progress = FALSE)
}

meta <- yaml::read_yaml("data/meta.yml")

cat("\nData dictionary\n")
check("meta.yml documents 2 dataset(s)", length(meta$datasets) == 2L)
check("meta.yml has no timestamp",
      !any(grepl("\\d{4}-\\d{2}-\\d{2}T|Sys\\.time|generated_at",
                 readLines("data/meta.yml", warn = FALSE))))

for (ds in meta$datasets) {
  df   <- rd(ds$file)
  cols <- vapply(ds$columns, function(x) x$name, character(1))
  check(sprintf("%s: meta.yml lists the columns the file actually has", ds$file),
        identical(cols, names(df)))
  check(sprintf("%s: meta.yml row count matches the file", ds$file),
        identical(as.integer(ds$rows), nrow(df)))
  check(sprintf("%s: every column has a type and a description", ds$file),
        all(vapply(ds$columns, function(x) nzchar(x$type %||% "") && nzchar(x$description %||% ""), logical(1))))
  check(sprintf("%s: source file is still present and unchanged", ds$file),
        identical(file_sha256(file.path("data-raw", ds$source_file)), ds$source_sha256))
  check(sprintf("%s: no blank rows", ds$file), nrow(df) > 0L)
}

cat("\nFile hygiene\n")
for (f in list.files("data", pattern = "[.](csv|yml)$", full.names = TRUE)) {
  check(sprintf("%s is UTF-8, LF, no BOM, no mojibake", basename(f)),
        tryCatch({ assert_clean_output(f); TRUE },
                 error = function(e) { cat("      ", conditionMessage(e), "\n"); FALSE }))
}

cat("\nValue snapshots\n")
# Pinned from data-raw/ as published in December 2024. A legitimate data update
# fails here and says exactly what changed. Values compare as strings so the
# source precision is checked too.
row_is <- function(df, i, ...) {
  want <- list(...)
  identical(unname(unlist(df[i, names(want)])), unname(unlist(want)))
}
at_extreme <- function(df, fn) df[fn(as.numeric(df$value)), ]

t1 <- rd("permafrost_temperatures.csv")
check("temperatures: 490 rows", nrow(t1) == 490L)
check("temperatures: 15 sites", length(unique(t1$site)) == 15L)
check("temperatures: years 1978-2023", identical(range(as.integer(t1$year)), c(1978L, 2023L)))
check("temperatures: first row is 1978 West Dock 13.91",
      row_is(t1, 1, year = "1978", site = "West Dock", value = "13.91"))
check("temperatures: last row is 2023 Qaaktugvik (Kaktovik) 17.8844",
      row_is(t1, nrow(t1), year = "2023", site = "Qaaktugvik (Kaktovik)", value = "17.8844"))
check("temperatures: minimum is 13.91 (West Dock, 1978)",
      row_is(at_extreme(t1, which.min), 1, year = "1978", site = "West Dock", value = "13.91"))
check("temperatures: maximum is 30.8858 (C'uul C'ena' (Gulkana), 2022)",
      row_is(at_extreme(t1, which.max), 1, year = "2022", site = "C'uul C'ena' (Gulkana)", value = "30.8858"))
check("temperatures: no blank values", all(nzchar(t1$value)))

t2 <- rd("permafrost_temperature_trends.csv")
check("trends: 15 rows", nrow(t2) == 15L)
check("trends: 7 Northern and 8 Interior Alaska sites",
      identical(as.integer(table(t2$region)[c("Northern Alaska", "Interior Alaska")]), c(7L, 8L)))
check("trends: first row is Barrow 2 (Utqiagvik) 1.095455357",
      row_is(t2, 1, site = "Barrow 2 (N. Meadow Lake No.2 / NML-2)", native_name = "Utqiagvik",
             depth_m = "16", latitude = "71.309", longitude = "-156.6615", elevation_m = "5", value = "1.095455357"))
check("trends: last row is West Dock 1.267851791",
      row_is(t2, nrow(t2), site = "West Dock", value = "1.267851791"))
check("trends: minimum is -0.005051915 (Livengood)",
      row_is(at_extreme(t2, which.min), 1, site = "Livengood", value = "-0.005051915"))
check("trends: maximum is 1.463160804 (Deadhorse)",
      row_is(at_extreme(t2, which.max), 1, site = "Deadhorse", value = "1.463160804"))

cat("\n")
if (length(failures)) {
  cat(sprintf("%d FAILED:\n", length(failures)))
  for (f in failures) cat("  -", f, "\n")
  quit(status = 1L)
}
cat("All data checks passed.\n")
