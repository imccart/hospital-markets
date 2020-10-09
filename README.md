# Hospital Markets

This repo describes the data and process for configuring hospital markets using community detection algorithms. Huge thanks to [John Graves](https://www.vumc.org/health-policy/person/john-graves-phd) for his [repo](https://github.com/graveja0/health-care-markets) on the same topic and to [Kaylyn Sanbower](https://kaylynrsanbower.netlify.app/) for lots of help organizing and editing John's code for this repo. The sections below detail the raw data sources and relevant code files. 

## Data
There are two general types of datasets used in this analysis:

1. **Patient Flows.** Data on patient flows (i.e., healthcare utilization) come from the [Hospital Service Area Files](https://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Hospital-Service-Area-File/index.html) or HSAF. These data present measures of utilization for each hospital (by Medicare provider number) for different zip codes from which the hospital receives patients, based off of observed care for Medicare patients.

2. **Geographic Files.** For comparison with other definitions of healthcare markets, I follow John's code and employ a handful of different crosswalk files in order to match market definitions to zip codes in the HSAF data. Specific files used in this analysis are:
  - [Cartographic Boundary Shape Files](https://www.census.gov/geographies/mapping-files/2017/geo/carto-boundary-file.html)
  - [Zip code to fips county](http://mcdc.missouri.edu/applications/geocorr2014.html). Note that zip codes are formally referred to as zip census tablulation areas (zcta), so the relevant query is "zcta" to "fips".
  - [SSA to fips county](https://data.nber.org/data/ssa-fips-state-county-crosswalk.html). This is a crosswalk for ssa and fips county measures.


## Code
The code files are organized into two categories. First, there is a set of "support" files which are not run independently but are instead called within different files. These include the following:

  - [map-theme.R](data-code/support/map-theme.R)
  - [move-ak-hi.R](data-code/support/move-ak-hi.R)
  - [get-geog-info.R](data-code/support/get-geog-info.R)
  - [get-contiguous-areas.R](data-code/support/get-contiguous-areas.R)

Next, there is a set of core files that constitute the main analysis, calling the support files where necessary. These files include:

  - [_BuildFinalData.R](data-code/_BuildFinalData.R). This file loads all of the necessary packages and calls all of the files.
  - [0-shared-objects.R](data-code/0-shared-objects.R)
  - [0-zip-code-xw.R](data-code/0-zip-code-xw.R)
  - [1-hsaf.R](data-code/1-hsaf.R). This code organizes the HSAF data. It modifies the variable names so that each of the files match and then creates .rds files in the Output folder. Then it uses the zcta-to-fips-county.rds file that we created in 0-zip_code_xw.R to allocate the zip code level each patient flow measure to the appropriate county using the fraction of the ZIP code in each county. This final output for this code is hospital-county-patient-data.rds, which contains hospital patient flow measures from each fips code for 2018 (file called df_hosp_serv18_fips.rds).
  - [2-county-to-fips.R](data-code/2-county-to-fips.R). The goal of this code is to connect rating areas to fips codes. This file scrapes [CMS rating area data]("http://www.cms.gov/CCIIO/Programs-and-Initiatives/Health-Insurance-Market-Reforms/STATE-gra.html") to gather the rating areas, and then pulls in [NBER data](https://data.nber.org/data/ssa-fips-state-county-crosswalk.html) that relates county names to their respective fips codes. Using these datasets, the code identifies matches between the rating area data and the county data. For now, we only need the county-fips-cw.rds data to move on to the community detection component, but in order to follow along closely with the initial repository, I left the remaining code here. 
  - [3-county-map-data.R](data-code/3-county-map-data.R). This file contains mapping elements, but we need the map shape files to identify contiguous counties in the community detection model. The mapping data can be found [here](https://www.census.gov/geographies/mapping-files/2017/geo/carto-boundary-file.html), and we use these data to create the df_county_info.rds file. 
  - [4-fit-community-detection.R](data-code/4-fit-community-detection.R). Here I import and run the community detection model. Note that there are numerous [community detection models](https://www.nature.com/articles/srep30750), but for now, this code replicates the original repo using the [Cluster Walktrap](https://igraph.org/r/doc/cluster_walktrap.html) algorithm. The code includes a function to convert a dataframe to a bipartite matrix. In our context, a bipartite matrix is a (0,1) matrix that relates fips codes to provider numbers. By multiplying a bipartite matrix by its transpose, we get a unipartite matrix. In this code, we create a unipartite matrix (fips code x fips code), where the values on the main diagonal represent the number of hospitals that patients in that zip code went to, and the off-diagonal values indicate the number of hospitals two zip codes have in common. Using the unipartite matrix, the code applies the cluster walktrap algorithm and produces hospital markets. 

Future updates to this code will include different community detection models, modularity measures, and ensemble clustering.  
