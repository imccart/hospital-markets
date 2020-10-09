# Hospital Markets: Defining hospital markets via community detection

I will start by saying that this repository is simply a reorganization of some of  [this repository](https://github.com/graveja0/health-care-markets) by [John Graves](https://www.vumc.org/health-policy/person/john-graves-phd), so a huge thanks to him for writing this code. That said, this README details the relevant code files, where to find the necessary data, and a crosswalk between his code/data files and mine.  If you'd like an explanation of the pitfalls of existing market measures and the benefits of defining markets via community detection, check out the [README](https://github.com/graveja0/health-care-markets/blob/master/README.md) for John's repository. 


The purpose of this code is to use community detection methods to construct hospital markets based on publicly available patient flow data. My research focuses on hospitals, so the repository I've created is limited to this source of care. Additionally, much of his code files are necessary to create maps of the market shares. At this point, my replication focuses simply on recreating the market shares via community detection, and does not yet update/replicate all of the maps. However, some code files do include references to the mapping files, but all of these lines are commented out. All of the relevant data and code files for what I replicate thus far are listed below.

## Crosswalk 
The following tables show the crosswalk between his data and code files and mine. Even if I don't change the name of a file, I include them in the crosswalk for clarity. As mentioned, the repo currently only pulls together the market shares but does not yet reconstruct the map files. However, some of the map files are included in the repo. Those case be ignorned for now. The only files you need to be concerned with are listed below. 

#### Data 
The data are broken into input (i.e. raw, publicly available data) and output (i.e. the .rds files that the code generates) folders. Due to space limitations, I do not upload the public data files to this repo, but instead include links so it's clear where you can access the data. 

##### Inputs
| His Data File Names | 	My Data File Names | Notes  | 
|----|----|----| 
| zcta-to-fips-county.csv	| zcta-to-county.csv |  [Found Here](http://mcdc.missouri.edu/applications/geocorr2014.html) | 
| county-fips-crosswalk.txt |	county-fips-cw.csv | [Found Here](https://data.nber.org/data/ssa-fips-state-county-crosswalk.html) |
|Hospital_Service_Area_File-YEAR.csv | HSAF-YEAR.csv  |[Found Here](https://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Hospital-Service-Area-File/index.html) |
| Cartographic Boundary Shape Files (various suffixes)| Same names; unchanged from download | [Found Here](https://www.census.gov/geographies/mapping-files/2017/geo/carto-boundary-file.html) |

##### Outputs
| His Data File Names | 	My Data File Names | Notes  | 
|----|----|----| 
|hospital-zip-patient-data.rds	| Hosp-zip-data-YEAR.rds | Each of his files are in their own year folder. For mine, the word "YEAR" is replaced with the year.  | 
|01_xw_county-to-fips.rds	| county-fips-cw.rds|  | 
| hospital-county-patient-data.rds	 | hospital-county-patient-data.rds |  | 
	

#### Code
| His Code File Names | 	My Code File Names | Notes  | 
|----|----|----| 
 | manifest.R  |   load_packages.R | in 'support' file | 
| get-geographic-info.R  |   get_geographic_info.R | in 'support' file |
 |  Zip-code-crosswalk.R | 0-zip_code_xw.R  |   | 
  | shared-objects.R  |  0-shared_objects.R  |  | 
 |  Read-and-tidy-cms-hospital-service-areas.R  | 1-Import_and_Clean_CMS_HSAF.R  |  | 
 | construct-rating-area-file-from-cciio-website.R  |  2-county_to_fips_xw.R  |  | 
  | construct-county-map-data.md  |   3-construct_county_map_data.R |  | 
 | Fit-hospital-patient-community-detection  |  4-fit_hospital_patient_community_detection  |  | 

[//]:<> (| map-theme.R  |   map_theme.R | in 'support' file | )
[//]:<> (| move-ak-hi.R  |   move_ak_hi.R | in 'support' file | )
[//]:<> (| get-geographic-info.R  |   get_geographic_info.R | in 'support' file | )
[//]: <> (| get-contiguous-areas.R  |   get_contiguous_areas.R | in 'support' file | )

## File Detail
The repo currently comprises a two folders: Data and Data-Code. The Data file has two subfolders, "Input" and "Output." All of the input data can be found publicly, and the output data is the result of the code files. The Data-Code folder has one subfolder: support. This folder contains files that are not run independently, but are pulled by other code files. The other files in Data-Code are numbered and should be run in the order of those numbers. Any files with the same number prefix can be run in any order, but just make sure that all of the files from "group 0" are run before moving on to files with higher numbers. It's worth noting that once you've run the code files and you have produced the requisite datasets, you do not need to run each of the files again unless there is a change to the underlying input data. 

### support files
At this point, the most relevant file within the support folder is load_packages.R. This installs and loads all of the packages that required for the other code files. This file is called at the beginning of each of the other code files, and as such, does not need to be run independently. The other file that we call in 3-construct_county_map.R is get_geographic_info.R. This supplies the function to pull contiguous county data from the shape file. 

#### 0-shared_objects.R
This file creates objects that other code files pull. For example, the list of capitalized state abbreviations are pulled in file 2-county_to_fips_xw.R, but are already in the environment thanks to this code. Line 85 and beyond refers to mapping code, so I ignore it for now. 

#### 0-zip_code_xw.R
This file pulls the zcta-to-county.csv to reformat the zip code and county data into a crosswalk to use later. It structures the zip and fips codes as numbers and ensures that they are each 5 digits, then creates a subset of this data so that the final dataset consists of the formatted zip code and fips code variables, and the percent of a given zip code in the fips code. In cases where the zip code is in multiple fips codes (i.e. pct_of_zip_in_fips < 1) then the zip code is listed multiple times in the dataframe, corresponding to the fips codes it resides in. This is relevant for splitting patient flows by fips codes later. 

#### 1-Import_and_Clean_CMS_HSAF.R
This code works with the data that I downloaded from [CMS](https://www.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Hospital-Service-Area-File/index.html) for years 2013 through 2018. It modifies the variable names so that each of the files match and then creates .rds files in the Output folder. Then it uses the zcta-to-fips-county.rds file that we created in 0-zip_code_xw.R to allocate the zip code level each patient flow measure to the appropriate county using the fraction of the ZIP code in each county. This final output for this code is hospital-county-patient-data.rds, which contains hospital patient flow measures from each fips code for 2018 (file called df_hosp_serv18_fips.rds).

#### 2-county_to_fips.R
The goal of this code is to connect rating areas to fips codes. This file scrapes [CMS rating area data]("http://www.cms.gov/CCIIO/Programs-and-Initiatives/Health-Insurance-Market-Reforms/STATE-gra.html") to gather the rating areas, and then pulls in [NBER data](https://data.nber.org/data/ssa-fips-state-county-crosswalk.html) that relates county names to their respective fips codes. Using these datasets, the code identifies matches between the rating area data and the county data. For now, we only need the county-fips-cw.rds data to move on to the community detection component, but in order to follow along closely with the initial repository, I left the remaining code here. 

#### 3-construct_county_map.R
As you might suspect from the name, this file also contains mapping elements, however, we need the map shape files to identify contiguous counties in the community detection model. The mapping data can be found [here](https://www.census.gov/geographies/mapping-files/2017/geo/carto-boundary-file.html), and we use these data to create the df_county_info.rds file. At this point, we only need to run the earlier part of the code file; you can ignore the commented out section for now.  

#### 4-construct_county_map.R
Here I import and run the community detection model. Note that there are numerous [community detection models](https://www.nature.com/articles/srep30750), but for now, this code replicates the original repo using the [Cluster Walktrap](https://igraph.org/r/doc/cluster_walktrap.html) algorithm. The code includes a function to convert a dataframe to a bipartite matrix. In our context, a bipartite matrix is a (0,1) matrix that relates fips codes to provider numbers. By multiplying a bipartite matrix by its transpose, we get a unipartite matrix. In this code, we create a unipartite matrix (fips code x fips code), where the values on the main diagonal represent the number of hospitals that patients in that zip code went to, and the off-diagonal values indicate the number of hospitals two zip codes have in common. Using the unipartite matrix, the code applies the cluster walktrap algorithm and produces hospital markets. 

Future updates to this code will include different community detection models, modularity measures, and ensemble clustering.  





