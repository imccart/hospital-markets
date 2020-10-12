
# Import county map data --------------------------------------------------
county.map <- readOGR(dsn=paste0(geog.path,"/Cartographic Boundary Shapefiles/cb_2017_us_county_5m.shp"),
                      layer = "cb_2017_us_county_5m",verbose = FALSE) 


county.info <- 
  county.map %>% 
  subset(GEOID != "99") %>% 
  get_geographic_info()

write_rds(county.info,"data/county-info.rds")