

# Assign html paths -------------------------------------------------------
rating.area.year <- as.Date(Sys.Date()) %>% lubridate::year() %>% as.character()
base.url <- "http://www.cms.gov/CCIIO/Programs-and-Initiatives/Health-Insurance-Market-Reforms/STATE-gra.html"
states.lc <- tolower(states)
urls.get <- states.lc %>% map_chr(~gsub("STATE",.x,base.url))



# Scrape the data ---------------------------------------------------------
rating.areas <- list() 
for (.x in urls.get) {
  cat(.x)
  {
    rating.areas[[.x]] <-   
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
      as_tibble()
  } 
  cat("\n")
}


# Clean scraped data ------------------------------------------------------

rating.areas <- 
  rating.areas %>% bind_rows() %>% 
  rename(county = county_name) 

county.fips <-
  read_csv(paste0(geog.path,"/county-fips-cw.csv")) %>% 
  filter(row_number() != 1) %>% 
  mutate(fips = str_pad(fipscounty, 5, pad = "0")) %>%
  mutate(fips = as.character(fips)) %>% 
  as_tibble() %>%
  mutate(county = tolower(county)) %>%
  mutate(county = capitalize(county)) %>%
  select(county, state, fips) %>% data.frame() %>% 
  mutate(fips = ifelse(county =="Shannon" & state == "SD", "46102",fips)) %>% 
  mutate(county = ifelse(county =="Shannon" & state == "SD", "Oglala Lakota",county)) 

write_rds(county.fips,"data/county-fips.rds")

# Note: Oglala Lakota County, SD (FIPS code=46102). Effective May 1, 2015, Shannon County, SD (FIPS code=46113) 
# was renamed Oglala Lakota County and assigned a new FIPS code

# Exact matches by county/state
rating.areas.exact <- 
  rating.areas %>% 
  filter(!is.na(county) & county!="") %>% 
  inner_join(county.fips,c("county","state")) %>% 
  select(starts_with("rating"),county,state,fips) %>% 
  mutate(merge_type = "Exact")

# Unmatched rating areas
rating.areas.unmatched <-
  rating.areas %>% 
  filter(!is.na(county) & county!="") %>% 
  anti_join(county.fips,c("county","state"))

# Use fuzzy matching to get even further
county.fips.nested <- 
  county.fips %>% 
  group_by(state) %>% 
  nest() %>% 
  rename(xw = data)

rating.areas.fuzzy <- 
  rating.areas.unmatched  %>% 
  group_by(state) %>% 
  nest() %>% 
  inner_join(county.fips.nested,"state") %>% 
  mutate(merged = map2(data,xw,~(
    .x %>% stringdist_inner_join(.y,c("county"),max_dist=1) %>% 
      select(starts_with("rating"),county=county.x, fips) %>% 
      mutate(merge_type = "Fuzzy"))
  )) %>% 
  select(state,merged) %>% 
  unnest(cols=c(merged))

rating.areas.unmatched <- 
  rating.areas.unmatched  %>% 
  stringdist_anti_join(county.fips,c("county","state"),max_dist = 1) 

rating.areas.MD <- 
  rating.areas.unmatched %>% 
  filter(state =="MD") %>% 
  mutate(county2 = ifelse(state == "MD", gsub(" County","",county), county)) %>% 
  stringdist_inner_join(county.fips %>% filter(state=="MD"),c("county2" = "county","state"),max_dist = 1) %>% 
  select(starts_with("rating"),county=county.x,state = state.x, fips) %>% 
  mutate(merge_type = "Maryland")

# Combine exact, fuzzy, and MD rating areas
final.rating.areas <- 
  rating.areas.exact %>% 
  bind_rows(rating.areas.fuzzy) %>% 
  bind_rows(rating.areas.MD) %>% 
  rename(rating_area = rating_area_id_for_federal_systems)  %>% 
  mutate(rating_area = gsub("Rating Area ","",rating_area)) %>% 
  mutate(rating_area = paste0(state,str_pad(rating_area,width=2,pad="0")))

write_rds(final.rating.areas,paste0("data/rating-areas-",rating.area.year,".rds"))


