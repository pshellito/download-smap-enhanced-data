# download-smap-enhanced-data
Scripts to download Level 3 NASA SMAP (Soil Moisture Active Passive) enhanced (9km) data 

## File and script descriptions
### callDownloadSmap.m
This script will call the downloadSmapL3E.m function. Edit the script to specify the date range to download. Note that downloading all 2+ years of SMAP data all at once is a lot of data. Each file is ~300 MB, and there is one file per day. If you don't have space to save all the SMAP data you want, then do the following:
1. Download a batch of SMAP data (e.g., one year)
2. Consolidate the data into a .mat file (using consolidateSmapEnhancedData.m)
3. Download another batch of data and consolidate again
4. Repeat step 3 as needed to get all the data onto your computer
### downloadSmapL3E.m
This function reaches out to NASA's servers and uses HTTPS to download SMAP files (CRID #R14010) to your local machine. Is called by callDownloadSmap.m. If you want a different CRID (or 14010 is no longer available), open it up and edit crid on line 75. Also, you will need to have wget installed on your machine. Specify the location of wget in line 69.
### consolidateSmapEnhancedData.m
This script will create a database of SMAP L3 Enhanced (9 km) data over a defined geographic extent. You may specify the geographic extent in lines 39-42. This script uses data downloaded by the callDownloadSmap.m script. It will save the data specified in fieldsToSave.txt. If the SMAP database already exists, it will simply append to it. If the SMAP database does not already exist, it will create a new one. tb_time_utc will be provided as a matlab datenum.
### fieldsToSave.txt
This file specifies which data fields to save in the SMAP database. Uncomment the fields you wish to save. A description of all the fields (and the flags) can be found [here](https://nsidc.org/data/smap/spl3smp_e/data-fields)
### callExtractSmapTimeSeries.m
This script will read a list of requested point locations and use the function, 'extractSmapTimeSeries.m,' to pull out the valid SMAP obesrvations at those locations. It will save each location as a .mat file in the directory, stationTimeSeries.
### extractSmapTimeSeries.m
This function will pull out the SMAP data at one location and only save data that have not been flagged for any of the following: standing water, precip, snow, ice, frozen ground, mountain, or dense vegetation.

The field "idcsNotRec" is a list of the SMAP soil moisture retrievals that were successful but were flagged for one of the above reasons. They are NOT recommended for use.

The field "flaggedBits" tells the user which flag(s) were triggered. A description of which bit refers to which flag can be found [here](https://nsidc.org/data/smap/spl3smp_e/data-fields#surf)
### stationList.txt
This text file contains the station name, lat, and lon to be used by 'callExtractSmapTimeSeries.m'

