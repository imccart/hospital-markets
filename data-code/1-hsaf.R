
# Import HSAF data --------------------------------------------------------

hsaf.files <- c("2018" = paste0(hsaf.path,"/HSAF_2018_SUPPRESS.csv"),
                "2017" = paste0(hsaf.path,"/HSAF_2017_SUPPRESS.csv"),
                "2016" = paste0(hsaf.path,"/HSAF_2016_SUPPRESS.csv"),
                "2015" = paste0(hsaf.path,"/HSAF_2015_SUPPRESS.csv"),
                "2014" = paste0(hsaf.path,"/HSAF_2014_SUPPRESS.csv"),
                "2013" = paste0(hsaf.path,"/HSAF_2013_SUPPRESS.csv"))


hsaf.zip <- 
  hsaf.files %>% 
  map(~(
    fread(.x) %>%
      as_tibble() %>% 
      clean_names()))  %>% 
  set_names(names(hsaf.files)) %>% 
  map(~rename_in_list(x = .x, from = "medicare_provider_number", to = "prvnumgrp")) %>% 
  map(~rename_in_list(x = .x, from = "medicare_prov_num", to = "prvnumgrp")) %>% 
  map(~rename_in_list(x = .x, from = "zip_code_of_residence", to = "zip"))  %>% 
  map(~rename_in_list(x = .x, from = "zip_cd_of_residence", to = "zip"))  %>%
  map(~rename_in_list(x = .x, from = "total_days_of_care", to = "total_days"))  %>%   
  map(~(.x %>% 
          mutate(zip = str_pad(zip, pad = "0",width = 5)) %>% 
          mutate_at(vars(total_days,total_charges, total_cases), function(x) as.numeric(paste0(x)))
  ))      


names(hsaf.zip) %>% 
  walk(
    ~write_rds(hsaf.zip[[.x]],path = here(paste0("/data/hospital-zip-",.x,".rds")))
  )

# Convert to FIPS ---------------------------------------------------------

hsaf.fips <- hsaf.zip %>%
  map(~ .x %>% left_join(zip.county,"zip") %>%
        mutate_at(vars(total_days, total_charges, total_cases), function(x) x * .$pct_zip_fips) %>%
        group_by(prvnumgrp,fips) %>%
        summarise_at(vars(total_days, total_charges, total_cases),function(x) sum(x,na.rm=TRUE)))

names(hsaf.fips) %>% 
  walk(
    ~write_rds(hsaf.fips[[.x]],path = here(paste0("/data/hospital-fips-",.x,".rds")))
  )



