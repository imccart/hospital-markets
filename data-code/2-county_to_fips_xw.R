# This script imports and consolidates CCIIO data to make rating area crosswalks
# Author: Kaylyn Sanbower; Code based on this repository: 
# https://github.com/graveja0/health-care-markets

# Date: September 1, 2020

# Load Packages -----------------------------------------------------------

suppressWarnings(suppressMessages(source(here::here("/Data-Code/support/load_packages.R"))))
source(here("Data-Code/0-shared_objects.R"))


# Import Data -------------------------------------------------------------

rating_area_year <- as.Date(Sys.Date()) %>% lubridate::year() %>% as.character()

# Set base url for CMS site
base_url <- "http://www.cms.gov/CCIIO/Programs-and-Initiatives/Health-Insurance-Market-Reforms/STATE-gra.html"

# pull in state two-letter abbreviations from 'shared-objects'
states_lc <- tolower(states)

# list of all state URLs
urls_to_get <- 
  states_lc %>% map_chr(~gsub("STATE",.x,base_url))

# Create empty list 
rating_areas_raw <- list() 

# Scrape the data from the CMS website 
for (.x in urls_to_get) {
  cat(.x)
  {
    rating_areas_raw[[.x]] <-   
      .x %>% 
      read_html() %>% 
      html_nodes("table") %>% 
      html_table(header = TRUE,fill=TRUE) %>% 
      purrr::pluck(1) %>% 
      janitor::clean_names() %>% 
      mutate(state = gsub("http://www.cms.gov/CCIIO/Programs-and-Initiatives/Health-Insurance-Market-Reforms/","",.x)) %>% 
      mutate(state = gsub("-gra.html","",state)) %>% 
      mutate(state = toupper(state)) %>% 
      mutate_all(as.character) %>% 
      tibble::as_tibble()
    
  } 
  cat("\n")
}

# put the scraped data into a dataframe 
df_rating_areas_raw <- 
  rating_areas_raw %>% bind_rows() %>% 
  rename(county = county_name) 

# The data for county-fips-cw.csv comes from here: https://data.nber.org/data/ssa-fips-state-county-crosswalk.html
# This creates the R dataframe in the right format to match with other files

county_to_fips <-
  read.csv(here("Data/Input/county-fips-cw.csv"),header=TRUE) %>% 
  filter(row_number() != 1) %>% 
  mutate(fips_code = stringr::str_pad(fipscounty, 5, pad = "0")) %>%
  mutate(fips_code = as.character(fips_code)) %>% tibble::as_tibble() %>%
  mutate(county = tolower(county)) %>%
  mutate(county = capitalize(county)) %>%
  select(county, state, fips_code) %>% data.frame() %>% 
  #Oglala Lakota County, SD (FIPS code=46102). 
  #Effective May 1, 2015, Shannon County, SD (FIPS code=46113) 
  # was renamed Oglala Lakota County and assigned a new FIPS code
  mutate(fips_code = ifelse(county =="Shannon" & state == "SD", "46102",fips_code)) %>% 
  mutate(county = ifelse(county =="Shannon" & state == "SD", "Oglala Lakota",county)) 

write_rds(county_to_fips,here("Data/Output/county-fips-cw.rds"))


# Finds exacty matches from the rating area data and the county area so that we have
# fips codes and rating areas together 
df_rating_areas_exact <- 
  df_rating_areas_raw %>% 
  filter(!is.na(county) & county!="") %>% 
  inner_join(county_to_fips,c("county","state")) %>% 
  select(starts_with("rating"),county,state,fips_code) %>% 
  mutate(merge_type = "Exact")

# Get the nonmatching ones
df_unmatched_rating_areas <-
  df_rating_areas_raw %>% 
  filter(!is.na(county) & county!="") %>% 
  anti_join(county_to_fips,c("county","state"))

# Use fuzzy matching to get even further
county_to_fips_nested <- 
  county_to_fips %>% 
  group_by(state) %>% 
  nest() %>% 
  rename(xw = data)

df_rating_areas_fuzzy1 <- 
  df_unmatched_rating_areas  %>% 
  group_by(state) %>% 
  nest() %>% 
  inner_join(county_to_fips_nested,"state") %>% 
  mutate(merged = map2(data,xw,~(
    .x %>% stringdist_inner_join(.y,c("county"),max_dist=1) %>% 
      select(starts_with("rating"),county=county.x, fips_code) %>% 
      mutate(merge_type = "Fuzzy"))
  )) %>% 
  select(state,merged) %>% 
  unnest()

still_unmatched_rating_areas <- 
  df_unmatched_rating_areas  %>% 
  stringdist_anti_join(county_to_fips,c("county","state"),max_dist = 1) 

df_rating_areas_MD <- 
  still_unmatched_rating_areas %>% 
  filter(state =="MD") %>% 
  mutate(county2 = ifelse(state == "MD", gsub(" County","",county), county)) %>% 
  stringdist_inner_join(county_to_fips %>% filter(state=="MD"),c("county2" = "county","state"),max_dist = 1) %>% 
  select(starts_with("rating"),county=county.x,state = state.x, fips_code) %>% 
  mutate(merge_type = "Maryland")

# Combine all of the rating areas into one DF and change the rating area name
df_rating_areas_counties <- 
  df_rating_areas_exact %>% 
  bind_rows(df_rating_areas_fuzzy1) %>% 
  bind_rows(df_rating_areas_MD) %>% 
  rename(rating_area = rating_area_id_for_federal_systems)  %>% 
  mutate(rating_area = gsub("Rating Area ","",rating_area)) %>% 
  mutate(rating_area = paste0(state,str_pad(rating_area,width=2,pad="0")))

# Write that df to an R dataset
write_rds(df_rating_areas_counties,here(paste0("Data/Output/01_rating-areas_counties_",rating_area_year,".rds")))

# Create a df to make the relationship between rating area and zip codes (3 digit zip)
df_rating_areas_zip <- 
  df_rating_areas_raw %>% 
  filter(!is.na(x3_digit_zip_code_if_applicable)) %>% 
  select(rating_area = rating_area_id_for_federal_systems, 
         zip_code = x3_digit_zip_code_if_applicable,
         state,) %>% 
  mutate(zip_code = as.numeric(paste0(zip_code))) %>% 
  filter(zip_code!="" & !is.na(zip_code)) %>% 
  mutate(zip_code = str_pad(paste0(zip_code),width=3,pad="0")) %>% 
  mutate(rating_area = gsub("Rating Area ","",rating_area)) %>% 
  mutate(rating_area = paste0(state,str_pad(rating_area,width=2,pad="0")))

# Write that df to an R dataset
write_rds(df_rating_areas_zip,here(paste0("Data/Output/01_rating-areas_zip3_",rating_area_year,".rds")))


