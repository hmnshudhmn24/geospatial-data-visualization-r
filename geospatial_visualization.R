# geospatial_data_viz_enhanced.R
# Enhanced Geographic Data Visualization in R
# Features:
#  - Choropleth map (leaflet) with legend
#  - Clustered point markers (leaflet)
#  - Layer controls, search, minimap, scale
#  - Static ggplot2 choropleth export
#  - Save interactive map to HTML
#
# NOTES:
#  - Replace the sample data loading sections with your actual GeoJSON / shapefile and CSV files.
#  - The script is written to be flexible: change 'metric_col' to visualize different variables.

### 0) Packages ----------------------------------------------------------------
packages <- c(
  "sf", "leaflet", "leaflet.extras", "htmlwidgets", "RColorBrewer",
  "viridis", "tidyverse", "htmltools", "glue", "mapview", "scales"
)
missing_pkgs <- setdiff(packages, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
  message("Installing missing packages: ", paste(missing_pkgs, collapse = ", "))
  install.packages(missing_pkgs, dependencies = TRUE)
}
lapply(packages, library, character.only = TRUE)

### 1) Parameters & file paths -------------------------------------------------
# shapefile / geojson: set one of the following:
# - If you have a local geojson: shp_path <- "data/regions.geojson"
# - If you have a shapefile folder: shp_path <- "data/shapefile_folder" (use st_read on .shp)
# - Example public GeoJSON (US states) is used if none provided
shp_path <- NULL  # e.g. "data/regions.geojson" OR "data/shapefile/regions.shp"
points_csv <- NULL # e.g. "data/points.csv" (optional) - CSV with lat/lon and attributes
regions_csv <- NULL # e.g. "data/region_metrics.csv" with region identifier + metrics

# If you want to use the example US states GeoJSON available online, set use_example <- TRUE
use_example <- TRUE

# Metric to visualize in choropleth (column name in your region CSV or sf)
metric_col <- "crime_rate"   # change to your metric column name

# Output filenames
output_html <- "interactive_geospatial_map.html"
output_static_png <- "static_choropleth.png"

### 2) Load spatial data ------------------------------------------------------
if (use_example) {
  # Example GeoJSON: US states from PublicaMundi
  example_url <- "https://raw.githubusercontent.com/PublicaMundi/MappingAPI/master/data/geojson/us-states.json"
  tmp_geo <- tempfile(fileext = ".geojson")
  download.file(example_url, tmp_geo, quiet = TRUE, mode = "wb")
  regions_sf <- st_read(tmp_geo, quiet = TRUE)
  # normalize name column if necessary
  if (!"name" %in% names(regions_sf)) {
    # try common name fields
    if ("NAME" %in% names(regions_sf)) regions_sf <- regions_sf %>% rename(name = NAME)
  }
  # create an ID field
  regions_sf$region_id <- seq_len(nrow(regions_sf))
  # Create sample metrics if not provided
  set.seed(123)
  regions_sf$crime_rate <- round(runif(nrow(regions_sf), 100, 800), 1)   # crimes per 100k (simulated)
  regions_sf$pollution_index <- round(runif(nrow(regions_sf), 10, 80), 1) # sample pollution index
} else {
  if (!is.null(shp_path)) {
    # read shapefile or geojson (sf::st_read handles both)
    regions_sf <- st_read(shp_path, quiet = TRUE)
    # you may need to set a region id column; we create one if missing
    if (!"region_id" %in% names(regions_sf)) regions_sf$region_id <- seq_len(nrow(regions_sf))
  } else {
    stop("No shapefile/geojson provided. Set shp_path or enable use_example = TRUE.")
  }
}

### 3) Load region-level metrics (optional) -----------------------------------
# If you have an external CSV with region metrics keyed by region name or ID, load & join:
if (!is.null(regions_csv) && file.exists(regions_csv)) {
  metrics_df <- read_csv(regions_csv, show_col_types = FALSE)
  # You must ensure there's a common key such as 'name' or 'region_id'
  # Example tries to join by 'name' first, then by 'region_id'
  if ("name" %in% names(metrics_df) && "name" %in% names(regions_sf)) {
    regions_sf <- left_join(regions_sf, metrics_df, by = "name")
  } else if ("region_id" %in% names(metrics_df)) {
    regions_sf <- left_join(regions_sf, metrics_df, by = "region_id")
  } else {
    message("Metrics CSV loaded but no matching join key found; skipping join.")
  }
} else {
  message("No external region CSV provided. Using metrics present in spatial data or simulated ones.")
}

### 4) Load point data (optional) ---------------------------------------------
# Points might be incident locations, sensors, hospitals, etc. CSV must contain lat, lon
points_sf <- NULL
if (!is.null(points_csv) && file.exists(points_csv)) {
  pts <- read_csv(points_csv, show_col_types = FALSE)
  if (!all(c("lat", "lon") %in% names(pts))) {
    stop("Point CSV must have 'lat' and 'lon' columns")
  }
  points_sf <- st_as_sf(pts, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
}

### 5) Projection & cleanup ---------------------------------------------------
# Ensure regions_sf is WGS84 lon/lat (leaflet expects EPSG:4326)
if (st_crs(regions_sf)$epsg != 4326 && !is.na(st_crs(regions_sf)$epsg)) {
  regions_sf <- st_transform(regions_sf, crs = 4326)
}

# Inspect data briefly
message("Regions:", nrow(regions_sf), "features")
if (!is.null(points_sf)) message("Points:", nrow(points_sf), "features")

### 6) Prepare choropleth palette & labels -----------------------------------
if (!metric_col %in% names(regions_sf)) {
  stop(glue::glue("Metric column '{metric_col}' not found in regions spatial data. Available columns: {paste(names(regions_sf), collapse = ', ')}"))
}
metric_vals <- regions_sf[[metric_col]]
pal <- colorBin(palette = "YlOrRd", domain = metric_vals, bins = 6, na.color = "transparent")

# Create HTML popup content (with multiple metrics if present)
make_popup <- function(row) {
  # row is a data.frame (single row)
  nm <- if ("name" %in% names(row)) row$name else paste("Region", row$region_id)
  metric_val <- if (!is.na(row[[metric_col]])) formatC(row[[metric_col]], format = "f", digits = 1) else "NA"
  pollution <- if ("pollution_index" %in% names(row)) formatC(row$pollution_index, format = "f", digits = 1) else NULL
  glue::glue(
    "<div style='width:220px;'>",
    "<strong>{nm}</strong><br/>",
    "<strong>{metric_col}:</strong> {metric_val}<br/>",
    if (!is.null(pollution)) glue::glue("<strong>Pollution Index:</strong> {pollution}<br/>") else "",
    "</div>"
  ) %>% as.character()
}

# Precompute popup for each polygon (to improve performance)
popup_list <- purrr::map_chr(seq_len(nrow(regions_sf)), function(i) make_popup(as.data.frame(regions_sf[i, ])))

### 7) Build interactive leaflet map -----------------------------------------
m <- leaflet(options = leafletOptions(zoomControl = TRUE)) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  setView(lng = -96, lat = 37.8, zoom = 4)  # center for US example

# Choropleth polygons layer
m <- m %>%
  addPolygons(
    data = regions_sf,
    fillColor = ~pal(.data[[metric_col]]),
    color = "#444444",
    weight = 1,
    opacity = 1,
    fillOpacity = 0.8,
    highlight = highlightOptions(weight = 3, color = "#666", bringToFront = TRUE),
    label = ~htmltools::htmlEscape(ifelse("name" %in% names(regions_sf), name, region_id)),
    labelOptions = labelOptions(direction = "auto"),
    popup = popup_list,
    group = "Choropleth"
  ) %>%
  addLegend(
    position = "bottomright",
    pal = pal,
    values = metric_vals,
    title = metric_col,
    opacity = 0.8
  )

# Add point layer if available
if (!is.null(points_sf)) {
  # add clustered markers
  m <- m %>%
    addMarkers(data = points_sf,
               popup = ~as.character(glue::glue("<b>{name}</b><br/>{description}")),
               clusterOptions = markerClusterOptions(),
               group = "Points")
}

# Add layer controls, mini-map, search, scale
m <- m %>%
  addLayersControl(
    overlayGroups = c("Choropleth", if (!is.null(points_sf)) "Points"),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  addMiniMap(toggleDisplay = TRUE, position = "bottomleft") %>%
  addScaleBar(position = "bottomleft")

# Add search by region name using leaflet.extras
if ("name" %in% names(regions_sf)) {
  # we add an invisible GeoJSON layer for search to use
  m <- m %>%
    addSearchFeatures(
      targetGroups = "Choropleth",
      options = searchFeaturesOptions(
        zoom = 6, openPopup = TRUE, firstTipSubmit = TRUE, autoCollapse = TRUE,
        hideMarkerOnCollapse = TRUE
      )
    )
}

# Print map to RStudio viewer
m

### 8) Save interactive map to HTML ------------------------------------------
htmlwidgets::saveWidget(m, file = output_html, selfcontained = TRUE)
message("Interactive map saved to: ", output_html)

### 9) Create static ggplot2 choropleth and save --------------------------------
# Convert to a simple dataframe for ggplot
regions_for_plot <- regions_sf %>% st_transform(crs = 3857)  # web mercator for nicer plots sometimes

p <- ggplot(regions_for_plot) +
  geom_sf(aes_string(fill = metric_col), color = "white", size = 0.2) +
  scale_fill_viridis_c(option = "plasma", na.value = "grey80", labels = scales::comma) +
  theme_minimal() +
  labs(title = glue::glue("{metric_col} by region"), fill = metric_col)

ggsave(output_static_png, plot = p, width = 12, height = 8, dpi = 150)
message("Static choropleth saved to: ", output_static_png)

### 10) Extras & export ----------------------------------------------------------------
# Export a CSV of region metrics for downstream work
export_metrics <- regions_sf %>%
  st_set_geometry(NULL) %>%
  as_tibble() %>%
  select(any_of(c("region_id", "name", metric_col, "pollution_index")))

readr::write_csv(export_metrics, "region_metrics_export.csv")
message("Exported region metrics to region_metrics_export.csv")

# done
message("All done. Open the HTML file to explore the interactive map.")
