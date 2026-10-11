# Provenance

Every file in this directory is reproduced unmodified from EPA's published
indicator page and its per-figure data downloads. To update the data, replace the
file and rerun `Rscript R/build_data.R`.

## Indicator page

- `source-page.html`  \
  <https://19january2025snapshot.epa.gov/climate-indicators/climate-change-indicators-permafrost/index.html>  \
  sha256 `a76c4bda44853dd0176a9f9684c15f7e2e989a2beaf7f4c55fa3bd40d917e7b6`

Technical documentation: <https://19january2025snapshot.epa.gov/system/files/documents/2024-12/permafrost_td.pdf>

## Figure data

- `permafrost_fig-1.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-12/permafrost_fig-1.csv>  \
  sha256 `ed412aaf2f3d6cca20eb27b634a94830fb6fa0bf77002f64a73de58448a07e2a`  \
  encoding UTF-8-BOM, 46 data rows, columns: `Year`, `Livengood`, `C'uul C'ena' (Gulkana)`, `Birch Lake`, `Old Man`, `T'eedrinjik (Chandalar Shelf)`, `Deenaalee (Healy)`, `Troth Yeddha' (College Peat)`, `Coldfoot`, `West Dock`, `Deadhorse`, `Franklin Bluffs`, `Happy Valley`, `Galbraith Lake`, `Utqiagvik (Barrow)`, `Qaaktugvik (Kaktovik)`  \
  title: Figure 1. Permafrost Temperatures in Alaska, 1978–2023  \
  data source: University of Alaska Fairbanks, 2024; web update: December 2024; units: °F

- `permafrost_fig-2.csv`  \
  <https://19january2025snapshot.epa.gov/system/files/other-files/2024-12/permafrost_fig-2.csv>  \
  sha256 `d7a490d5a29b263ffc33a33447b214cd74ef42c7a63a1f94663e97be71b1165b`  \
  encoding windows-1252, 15 data rows, columns: `Region`, `Site name`, `Native Name`, `Depth of measurement`, `Latitude`, `Longitude`, `Elevation`, `Decadal slope`  \
  title: Figure 2. Changes in Permafrost Temperatures in Alaska, 1978–2023  \
  data source: University of Alaska Fairbanks, 2024; web update: December 2024; units: n/a; n/a; meters; degrees; degrees; meters; °F
