# Import and restructure necessary data -----------------------------------

# Crosswalk of state fips to state abreviation
fips.state <- read_rds("data/county-fips.rds") %>% 
  mutate(statefp = str_sub(fips,1,2)) %>% 
  select(statefp,state) %>% unique()

# bring in county-fips cw with state and county fips separated
fips.xw <- read_rds("data/county-fips.rds") %>% 
  mutate(
    state_fips = str_sub(fips, 1,2),
    county_fips = str_sub(fips, 3, 5))


# Load the patient flows data
hosp.fips <- read_rds("data/hospital-fips-2018.rds")


# Create function to convert dataframe to bipartite matrix
convert_bp <- function(df,id) {
  id <- enquo(id)
  nn <- df %>% pull(!!id)
  foo <- df %>% select(-!!id) %>%
    as.matrix()
  
  rownames(foo) <- nn
  foo
}


# Need the contiguous county bipartite data frame to restrict CMS data only the fips codes in the map

bp.contig <- read_rds("data/county-info.rds") %>%
  as_tibble() %>%
  mutate(fips = str_pad(paste0(geoid),width=5,pad="0")) %>% 
  select(fips, starts_with("contig_")) %>% 
  gather(key,fips_contig,-fips) %>% 
  filter(!is.na(fips_contig) & !is.na(fips)) %>% 
  select(fips,fips_contig) %>% 
  mutate(contig = 1) %>% 
  spread(fips_contig,contig)


minimum_share = 0.10
minimum_number = 10

bp.hosp.fips <-
  hosp.fips %>%
  group_by(fips) %>%
  mutate(patient_share = total_cases / sum(total_cases, na.rm = TRUE)) %>%
  ungroup() %>% 
  mutate(connected = as.integer(patient_share >= minimum_share))  %>%
  mutate(share = ifelse(connected==1,patient_share,0)) %>% 
  select(fips, prvnumgrp, connected) %>%
  inner_join(bp.contig %>% select(fips),"fips") %>% 
  spread(prvnumgrp, connected) %>%
  convert_bp(id = fips)

bp.hosp.fips[is.na(bp.hosp.fips)] <- 0
bp.hosp.fips[1:10,1:10]

# Create unipartite matrix out of fips x hosp matrix
up.final <- bp.hosp.fips %*% t(bp.hosp.fips)
  


# Graph structure ---------------------------------------------------------

graph.dat <- 
  graph_from_adjacency_matrix(up.final, weighted = TRUE) %>%
  simplify(., remove.loops = TRUE)

# Run cluster_walktrap on this network
initial.communities <-
  walktrap.community(graph.dat,
                     steps = 1,
                     merges = TRUE,
                     modularity = TRUE,
                     membership = TRUE) 

market <- membership(initial.communities)
walktrap.dat <- bind_cols(fips = names(market), mkt = market) %>% 
  mutate(statefp = str_sub(fips,1,2))

walktrap.dat %>% select(mkt) %>% unique() %>% 
  dim()
