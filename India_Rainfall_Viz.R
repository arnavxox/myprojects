# Load required packages
library(ncdf4)
library(ggplot2)
library(gganimate)
library(viridis)
library(maps)
library(dplyr)
library(av)

# Read NetCDF file
ncpath <- "C:/Users/arnav/Downloads/NCDF data/NCDF data/"
ncname <- "RF25_ind2023_rfp25"
ncfile <- paste(ncpath, ncname, ".nc", sep="")

# Open and extract data
nc <- nc_open(ncfile)
print(nc)

lon <- ncvar_get(nc, "LONGITUDE")
lat <- ncvar_get(nc, "LATITUDE")
time <- ncvar_get(nc, "TIME")
rainfall <- ncvar_get(nc, "RAINFALL")

# Convert time to dates
time_dates <- as.Date(time, origin = "1900-12-31")

# Get fill value and close file
fillvalue <- ncatt_get(nc, "RAINFALL", "_FillValue")
nc_close(nc)

# Handle missing values
rainfall[rainfall == fillvalue$value] <- NA

# Create animation data
coords <- expand.grid(longitude = lon, latitude = lat)
anim_data <- data.frame()

cat("Processing 365 days...\n")
for (i in 1:365) {
  daily_rain <- as.vector(rainfall[, , i])
  
  day_data <- data.frame(
    longitude = coords$longitude,
    latitude = coords$latitude,
    rainfall = daily_rain,
    date = time_dates[i],
    date_label = format(time_dates[i], "%B %d, %Y")
  )
  
  # Remove missing/negative values
  day_data <- day_data[!is.na(day_data$rainfall) & day_data$rainfall >= 0, ]
  anim_data <- rbind(anim_data, day_data)
  
  if (i %% 50 == 0) cat("Day", i, "done\n")
}

# Fix date ordering
date_order <- anim_data %>% 
  select(date, date_label) %>% 
  distinct() %>% 
  arrange(date)

anim_data$date_label <- factor(anim_data$date_label, 
                               levels = date_order$date_label, 
                               ordered = TRUE)

# Get India map
india <- map_data("world", region = "India")

# Create plot
p <- ggplot() +
  geom_polygon(data = india, aes(x = long, y = lat, group = group), 
               fill = NA, color = "black", size = 0.5) +
  geom_tile(data = anim_data, aes(x = longitude, y = latitude, fill = rainfall)) +
  scale_fill_viridis_c(
    name = "Rainfall\n(mm)", 
    option = "plasma",
    trans = "sqrt",
    breaks = c(0, 1, 5, 10, 25, 50, 100, 200),
    labels = c("0", "1", "5", "10", "25", "50", "100", "200+"),
    limits = c(0, 200),
    oob = scales::squish,
    na.value = "transparent"
  ) +
  coord_fixed(ratio = 1, xlim = c(68, 98), ylim = c(8, 38)) +
  labs(
    title = "Daily Rainfall Over India - 2023",
    subtitle = "Date: {closest_state}",
    x = "Longitude",
    y = "Latitude",
    caption = "Data: India Meteorological Department"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 18, hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(size = 14, hjust = 0.5, color = "blue"),
    legend.position = "right",
    panel.background = element_rect(fill = "lightblue", color = NA)
  ) +
  transition_states(date_label, transition_length = 1, state_length = 1) +
  ease_aes('linear')

# Render animation
output_file <- "C:/Users/arnav/Desktop/Ind_Daily_Rainfall.mp4"

cat("Creating animation...\n")
anim <- animate(
  p,
  nframes = 365,
  fps = 10,
  width = 1200,
  height = 900,
  res = 150,
  renderer = av_renderer(output_file),
  progress = TRUE
)

# Check result
if (file.exists(output_file)) {
  size_mb <- round(file.info(output_file)$size / 1024 / 1024, 2)
  cat("Done! File saved:", output_file, "(", size_mb, "MB)\n")
  shell.exec(dirname(output_file))
} else {
  cat("Something went wrong\n")
}

# Clean up
rm(rainfall, anim_data, p)
gc()
