# Meta --------------------------------------------------------------------
## Title:         Hospital Markets and Community Detection
## Author:        Ian McCarthy
## Date Created:  10/12/2020
## Date Edited:   10/12/2020


# Preliminaries -----------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
pacman::p_load(purrr, here, devtools, rlang, knitr, stringr, rvest, igraph,
               ggraph, ggthemes, rmarkdown, rgeos, rgdal, ggmap, maptools, patchwork,
               sf, piggyback, fs, aws.s3, furrr, ggdendro, httr, rvest, fuzzyjoin, janitor,
               Hmisc, rlang, data.table, tidyverse)

## set paths and run support scripts
source("data-code/support/paths.R")
source("data-code/support/get-geog-info.R")


# Manual objects ----------------------------------------------------------

census_regions <- 
  list(
    "ak_hi" = c("AK","HI"),
    "west_pacific" = c("CA","OR","WA"),
    "west_mountain" = c("MT","ID","WY","UT","CO","NM","AZ","NV"), 
    "midwest_west" = c("ND","SD","MN","NE","IA","KS","MO"),
    "midwest_east" = c("WI","MI","IL","IN","OH"),
    "south_west" = c("TX","OK","AR","LA"),
    "south_central" = c("KY","TN","MS","AL"),
    "south_atlantic" = c("MD","DE","DC","WV","VA","NC","SC","GA","FL"), 
    "northeast_middle"= c("PA","NJ","NY"),
    "northeast_newengland" = c("CT","RI","MA","NH","VT","ME")
  )


states <- c(
  "AK", "AL", "AR", "AZ", "CA", "CO", "CT", "DC", "DE", "FL",
  "GA", "HI", "IA", "ID", "IL", "IN", "KS", "KY", "LA", "MA",
  "MD", "ME", "MI", "MN", "MO", "MS", "MT", "NC", "ND", "NE",
  "NH", "NJ", "NM", "NV", "NY", "OH", "OK", "OR", "PA", "RI",
  "SC", "SD", "TN", "TX", "UT", "VA", "VT", "WA", "WI","WV",
  "WY"
)

shape_types <- c("dbf","prj","shp","shx")


# Create Fuction(s) -------------------------------------------------------

rename_in_list <- function(x,from, to) {
  x %>% rename_at(vars(contains(from)), funs(sub(from, to, .)))
}


# Raw data ----------------------------------------------------------------

source("data-code/0-zip-code-xw.R")  ## creates zip.county object
source("data-code/1-hsaf.R")


