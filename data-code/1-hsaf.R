# This script imports and cleans CMS Hospital Service Area data
# Author: Kaylyn Sanbower; Code based on this repository: 
# https://github.com/graveja0/health-care-markets

# Date: August 26, 2020


# Load Packages -----------------------------------------------------------

suppressWarnings(suppressMessages(source(here::here("/Data-Code/support/load_packages.R"))))



# Create Fuction(s) -------------------------------------------------------

rename_in_list <- function(x,from, to) {
  x %>% rename_at(vars(contains(from)), funs(sub(from, to, .)))
}


# Import Data -------------------------------------------------------------

# Get the CMS Hospital Service Area Data - free to download 
# https://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Hospital-Service-Area-File/index.html


hosp_serv_files <- c("2018" = "/Data/Input/HSAF_2018.csv",
                     "2017" = "/Data/Input/HSAF_2017.csv",
                     "2016" = "/Data/Input/HSAF_2016.csv",
                     "2015" = "/Data/Input/HSAF_2015.csv",
                     "2014" = "/Data/Input/HSAF_2014.csv",
                     "2013" = "/Data/Input/HSAF_2013.csv")

# hosp_serv_files <- hosp_serv_files[1]

df_hosp_serv_zip <- 
  hosp_serv_files %>% 
  map(~(
    data.table::fread(here(.x)) %>%
      tibble::as_tibble() %>% 
      janitor::clean_names()))  %>% 
  set_names(names(hosp_serv_files)) %>% 
  map(~rename_in_list(x = .x, from = "medicare_provider_number", to = "prvnumgrp")) %>% 
  map(~rename_in_list(x = .x, from = "medicare_prov_num", to = "prvnumgrp")) %>% 
  map(~rename_in_list(x = .x, from = "zip_code_of_residence", to = "zip_code"))  %>% 
  map(~rename_in_list(x = .x, from = "zip_cd_of_residence", to = "zip_code"))  %>% 
  map(~(.x %>% 
          mutate(zip_code = str_pad(zip_code, pad = "0",width = 5)) %>% 
          mutate_at(vars(total_days_of_care,total_charges, total_cases), function(x) as.numeric(paste0(x)))
  ))      


names(df_hosp_serv_zip) %>% 
  walk(
    ~write_rds(df_hosp_serv_zip[[.x]],path = here(paste0("/Data/Output/hosp-zip-data-",.x,".rds")))
  )

# JG's comments: 
# We now need to roll these ZIP level data up to the county level. We
# will do this by allocating each patient count / charge / days measure
# using the fraction of the ZIP code in each county. 
# Thus, if 100% of the ZIP is in a county, then 100% of the total_days_of_care
# variable will be attributed to the hospital-county pair. If only 50% is, then
# we only attribute 50%.

df_zip_to_fips <-
  read_rds(here("Data/Output/zcta-to-fips-county.rds"))

df_hosp_serv18_fips <-
  df_hosp_serv_zip[[1]] %>%
  left_join(df_zip_to_fips,"zip_code") %>%
  mutate_at(vars(total_days_of_care,total_charges, total_cases), function(x) x * .$pct_of_zip_in_fips) %>%
  group_by(prvnumgrp,fips_code) %>%
  summarise_at(vars(total_days_of_care,total_charges, total_cases),function(x) sum(x,na.rm=TRUE))

write_rds(df_hosp_serv18_fips,path = here("Data/Output/hospital-county-patient-data.rds"))


