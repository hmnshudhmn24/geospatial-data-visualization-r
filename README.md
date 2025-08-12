# 🌍 Geographic Data Visualization (Geospatial Maps)

## 📌 Overview
This project demonstrates how to visualize **geospatial datasets** in R using powerful libraries such as `leaflet`, `sf`, and `ggplot2`.  
It covers both **interactive** and **static** mapping techniques and can be applied to datasets related to crime, health, or environmental statistics.

We specifically showcase the **North Carolina SIDS dataset** from the `sf` package to illustrate mapping capabilities, including **choropleth maps** and **popup-based interactive visualizations**.



## 🎯 Goal
- Create **beautiful, insightful, and interactive maps** from geospatial data.
- Present data patterns such as regional trends in crime, health, or environmental factors.
- Demonstrate **GIS skills** using R.



## 📂 Dataset
- **Name:** North Carolina SIDS dataset  
- **Source:** Built into the `sf` package in R.
- **Description:**  
  The dataset contains **geographical polygons** representing counties in North Carolina along with health-related statistics.
- **Fields include:** County names, number of SIDS cases, and spatial geometry data.



## 🛠️ Features
✅ Interactive maps with **Leaflet** (pan, zoom, hover, click popups)  
✅ Static maps with **ggplot2** for publications/reports  
✅ Choropleth coloring based on numeric values  
✅ Region-specific popup tooltips for details  
✅ Easily adaptable to other datasets (crime, pollution, etc.)  



## 📦 Requirements
### 🔹 R Version
- R >= 4.0

### 🔹 Install Required Packages
```R
install.packages(c("leaflet", "sf", "ggplot2", "dplyr"))
```



## 🚀 How to Run
1. **Clone or Download** the repository:
```bash
git clone https://github.com/yourusername/geospatial-maps.git
```
2. Open the file `geospatial_visualization.R` in **RStudio**.
3. Run the script — you will see:
   - An **interactive choropleth map** in RStudio’s Viewer pane.
   - A **static ggplot2 choropleth map** saved to `output/` folder.



## 📊 Output
**1. Interactive Map (Leaflet)**  
- Fully navigable with zoom and drag controls.  
- Click a county to view its name and associated SIDS data.  

**2. Static Map (ggplot2)**  
- High-resolution image saved in PNG format.  
- Ideal for presentations or publications.



## 📌 Skills Used
- 🗺️ **GIS Concepts**
- 🎨 **Data Visualization**
- 📊 **Choropleth Mapping**
- 🖥️ **Interactive Map Development**
- 🔍 **Exploratory Spatial Data Analysis (ESDA)**



## 📂 Project Structure
```
geospatial-maps/
│
├── data/
│   └── (optional) your_custom_dataset.csv
│
├── output/
│   └── static_map.png
│
├── geospatial_visualization.R
├── README.md
└── LICENSE
```



## 💡 Future Improvements
- Integrate **real-time datasets** via APIs (e.g., live crime stats).
- Add **time-series animations** for trends over time.
- Implement **heatmaps** for dense point datasets.
- Deploy an **interactive Shiny app** for map exploration.

