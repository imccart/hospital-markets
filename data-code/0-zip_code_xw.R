# This file reads in and tidys the ZIP code crosswalk
# file, which is created by mapping ZCTAs to all 
# possible target geographies in the tool at 
# http://mcdc.missouri.edu/applications/geocorr2014.html


# Author: Kaylyn Sanbower; Code based on this repository: 
# https://github.com/graveja0/health-care-markets


# Load Packages -----------------------------------------------------------

suppressWarnings(suppressMessages(source(here::here("/Data-Code/support/load_packages.R"))))


# Import and clean data ---------------------------------------------------


tmp <- data.table::fread("Data/Input/zcta-to-county.csv",header=TRUE) %>% 
  filter(row_number() != 1) %>% 
  janitor::clean_names() %>% 
  mutate(zip_code = str_pad(as.numeric(paste0(zcta5)),width = 5, pad="0")) %>% 
  mutate(fips_code = str_pad(as.numeric(paste0(county)), width = 5, pad = "0")) %>% 
  mutate(pct_of_zip_in_fips = as.numeric(paste0(afact))) %>% 
  tibble::as_tibble() %>% 
  select(zip_code,fips_code,pct_of_zip_in_fips) %>% 
  write_rds(path = here("Data/Output/zcta-to-fips-county.rds"))

