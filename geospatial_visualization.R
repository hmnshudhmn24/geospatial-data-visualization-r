# Geospatial Data Visualization in R
library(leaflet)
library(sf)
library(ggplot2)
library(dplyr)

# Example: Load built-in dataset of North Carolina SIDS data
nc <- st_read(system.file("shape/nc.shp", package = "sf"))

# Create a choropleth map using leaflet
leaflet(data = nc) %>%
  addTiles() %>%
  addPolygons(
    fillColor = ~colorQuantile("YlOrRd", BIR74)(BIR74),
    color = "#BDBDC3",
    weight = 1,
    popup = ~paste("Name:", NAME, "<br>", "Births:", BIR74)
  )

# Using ggplot2 for static map
ggplot(nc) +
  geom_sf(aes(fill = BIR74)) +
  scale_fill_viridis_c() +
  theme_minimal() +
  labs(title = "Births in North Carolina (1974)",
       fill = "Births")
