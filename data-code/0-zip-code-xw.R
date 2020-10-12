
# Import county zip crosswalk ---------------------------------------------

zip.county <- fread(paste0(geog.path,"/zcta-to-county.csv"),header=TRUE) %>% 
  filter(row_number() != 1) %>% 
  clean_names() %>% 
  mutate(zip = str_pad(as.numeric(paste0(zcta5)),width = 5, pad="0")) %>% 
  mutate(fips = str_pad(as.numeric(paste0(county)), width = 5, pad = "0")) %>% 
  mutate(pct_zip_fips = as.numeric(paste0(afact))) %>% 
  as_tibble() %>% 
  select(zip,fips,pct_zip_fips)