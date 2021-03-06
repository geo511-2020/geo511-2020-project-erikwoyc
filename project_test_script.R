library(tidyverse)
library(ggplot2)
library(ggmap)
library(maptools)
library(ggthemes)
library(rgeos)
library(broom)
library(plyr)
library(dplyr)
library(grid)
library(gridExtra)
library(reshape2)
library(scales)
library(sp)
library(sf)
library(rgdal)
library(RColorBrewer)
library(kableExtra)
library(leaflet)
library(tmaptools)


# 2017 - 2019 Buffalo Assessment Roll
Parcel17 <- read.csv(file = "https://raw.githubusercontent.com/geo511-2020/geo511-2020-project-erikwoyc/master/2017-2018_Assessment_Roll.csv")
SingleFam_propclass <- c("210", "215", "240", "241", "250", "270")
Buffalo_17 <- filter(Parcel17, PROPERTY.CLASS %in% SingleFam_propclass)

# 2019 - 2020 Buffalo Assessment Roll
Parcel20 <- read.csv(file = "https://raw.githubusercontent.com/geo511-2020/geo511-2020-project-erikwoyc/master/2019-2020_Assessment_Roll.csv")
SingleFam_propclass <- c("210", "215", "240", "241", "250", "270")
Buffalo_20 <- filter(Parcel20, PROPERTY.CLASS %in% SingleFam_propclass)

# Neighborhood Shapefile
Neighborhood_URL <- "https://data.buffalony.gov/api/geospatial/q9bk-zu3p?method=export&format=GeoJSON"
Buffalo_Neighborhoods <- st_read(dsn = Neighborhood_URL)
Buffalo_sp <- as_Spatial(Buffalo_Neighborhoods)


# 2017 - 2018 Single Family Housing Price Histogram
Plot_2017 <- ggplot(data = Buffalo_17, mapping = aes(x = TOTAL.VALUE)) + 
  geom_histogram() + xlab("Total Property Value($)") + ylab("Count") +
  scale_fill_manual(values="lightblue") + theme_few() +
  labs(x="Total Value($)", y="Count", title="Distribution of Buffalo Home Prices",
       subtitle="Single Family Property Prices (2019 - 2020)", 
       caption="Source: Buffalo Open Data") + scale_x_continuous() + scale_y_continuous()
plot(Plot_2017)

# 2019 - 2020 Single Family Housing Price Histogram
Plot_2019 <- ggplot(data = Buffalo_20, mapping = aes(x = TOTAL.VALUE)) + 
  geom_histogram() + xlab("Total Property Value($)") + ylab("Count") +
  scale_fill_manual(values="lightblue") + theme_few() +
  labs(x="Total Value($)", y="Count", title="Distribution of Buffalo Home Prices",
       subtitle="Single Family Property Prices (2019 - 2020)", 
       caption="Source: Buffalo Open Data") + scale_x_continuous() + scale_y_continuous()
plot(Plot_2019)

#Buffalo Bounding Box
Buffalo_bbox <- Buffalo_sp@bbox

# Download the basemap
basemap <- get_stamenmap(
  bbox = Buffalo_bbox,
  zoom = 13,
  maptype = "toner-lite")

# View Map
BFMap <- ggmap(basemap) + 
  labs(title="Buffalo Basemap")
BFMap


# 2017 - 2018 Assessment Roll Plot
SingleFam17 <- ggmap(basemap) + 
  geom_point(data = Buffalo_17, aes(x = LONGITUDE, y = LATITUDE, color = TOTAL.VALUE), 
             size = .025, alpha = 0.7) +
  scale_color_gradient("Single Family Home Price", low = "light green", high = "dark green", trans="log",
                       labels = scales::dollar_format(prefix = "$")) +
  labs(title="Distribution of Buffalo Home Prices",
       subtitle="Property Prices (2017 - 2018)",
       caption="Open Data Buffalo")
SingleFam17

# 2019 - 2020 Assessment Roll Plot
SingleFam20 <- ggmap(basemap) + 
  geom_point(data = Buffalo_20, aes(x = LONGITUDE, y = LATITUDE, color = TOTAL.VALUE), 
             size = .025, alpha = 0.7) +
  scale_color_gradient("Single Family Home Price", low = "light green", high = "dark green", trans="log",
                       labels = scales::dollar_format(prefix = "$")) +
  labs(title="Distribution of Buffalo Home Prices",
       subtitle="Property Prices (2019 - 2020)",
       caption="Open Data Buffalo")
SingleFam20

# Distribution of Single Family Homes by Year Built
Year_built <- ggplot(data = Buffalo_20, mapping = aes(x = YEAR.BUILT)) + 
  geom_histogram() + xlab("Year Built") + ylab("Number of Homes") +
  scale_fill_manual(values="lightblue") + theme_few() +
  labs(x="Year Built", y="Number of Homes", title="Distribution of Single Family Homes by Year Built", 
       caption="Source: Buffalo Open Data") + scale_x_continuous() + scale_y_continuous()
Year_built

#Year Built Map
age_map <- ggmap(basemap) + 
  geom_point(data = Buffalo_20, aes(x = LONGITUDE, y = LATITUDE, color = YEAR.BUILT), 
             size = .025, alpha = 0.7) +
  labs(title="Year Built for Single Family Homes",
       caption="Open Data Buffalo")
age_map

# Price by Living Area 2017 - 2018
live_price <- ggplot(data = Buffalo_17, aes(x = TOTAL.LIVING.AREA, y = TOTAL.VALUE)) +
     labs(x = "Total Living Area (sqft)", y = "Total Value Single Family Home ($)", title = "Price by Square ft of Living Space") +
  geom_point()
live_price

# Price by Living Area 2019 - 2020
live_price20 <- ggplot(data = Buffalo_20, aes(x = TOTAL.LIVING.AREA, y = TOTAL.VALUE)) +
  labs(x = "Total Living Area (sqft)", y = "Total Value Single Family Home", title = "Price by Square ft of Living Space") +
  geom_point()
live_price20

# Price by Bedrooms  2019 - 2020
bed_price <- ggplot(data = Buffalo_20, aes(x = X..OF.BEDS, y = TOTAL.VALUE)) +
  labs(x = "Number of Bedrooms", y = "Total Value Single Family Home", title = "Price by Number of Bedrooms") +
  geom_col()
bed_price

## Transform Data for Regression
Buffalo_20$log <- log10(Buffalo_20$TOTAL.VALUE)
View(Buffalo_20)

## Multiple Linear Regression
MLR <- lm(log ~ X..OF.BEDS + YEAR.BUILT +
          TOTAL.LIVING.AREA + X..OF.BATHS + NEIGHBORHOOD,
          data = Buffalo_20)
summary(MLR)
summary(MLR)$coefficient

pallete <- colorNumeric("viridis", NULL)

Neighborhood_map <- leaflet() %>%
  setMaxBounds(lng1 = -78.91246, lat1 = 42.82603, lng2 = -78.79504, lat2 = 42.96641) %>%
  addProviderTiles("CartoDB") %>%
  addProviderTiles("Stamen.TonerLines",
                   options = providerTileOptions(opacity = 0.35)) %>%
  addCircles(data = Buffalo_17, lng = Buffalo_17$LONGITUDE, lat = Buffalo_17$LATITUDE, 
             color = ~pallete(log(Buffalo_17$TOTAL.VALUE)),
             radius = .05, opacity = 0.5,
             group = "2017 - 2018") %>%
  addCircles(data = Buffalo_20, lng = Buffalo_20$LONGITUDE, lat = Buffalo_20$LATITUDE, 
             color = ~pallete(log(Buffalo_20$TOTAL.VALUE)),
             radius = .05, opacity = 0.5,
             group = "2019 - 2020")  %>%
  addPolygons(data = Buffalo_sp, fillColor = "transparent", color = "#444444", weight = 2) %>%
  addLayersControl(overlayGroups = c("2017-2018", "2019-2020")) %>%
  addLegend(position = "bottomleft", pal = pallete, values = Buffalo_20$TOTAL.VALUE,
            title = "Single Family Home Value")
Neighborhood_map

# Median Price by Neighborhood
data_20 <- ddply(Buffalo_20, c("NEIGHBORHOOD"), summarise,
                     medianPrice = median(TOTAL.VALUE))
data_17 <- ddply(Buffalo_17, c("NEIGHBORHOOD"), summarise,
                 medianPrice = median(TOTAL.VALUE))
data.neighborhoods <- left_join(data_17, data_20, by = "NEIGHBORHOOD")
colnames(data.neighborhoods)[1] <- "nhbdname"
data.neigh <- data.neighborhoods[-c(1,34), ]
View(data.neigh)

Median_Price <- ggplot(data = data.neigh, mapping = aes(x = nhbdname, y = medianPrice.y)) + 
  geom_col() + theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(x="Neighborhood", y = "Price ($)", title="Median Price Single Family Home",
       subtitle="Median Price by Neighborhood", 
       caption="Source: Buffalo Open Data") + scale_y_continuous(labels=scales::dollar_format())
plot(Median_Price)
