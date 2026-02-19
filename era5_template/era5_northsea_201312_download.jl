# era5_north_sea_201312_download.jl
# This script tests the download of ERA5 data for the North Sea region for December 2013.
# It uses the CDS API to fetch the data.
# The script is intended as a template for downloading ERA5 data for specific regions and time periods.

# Move to this folder if not already there
cd(@__DIR__)

# activate the environment
using Pkg
Pkg.activate("..") #Should point to the main project folder for DataCollector.jl, where the Project.toml file is.
using DataCollector

# collect data for North Sea for 2013-12-1 to 2013-1-1
# DCSME area  15° W to 13° E and 43° N to 64° N ie [43,-15,64,13]
area=[43,-15,64,13]
area_name="north_sea"
parameterset="winds" #see Dict standard_variables
first_month=(2013,12)
last_month=(2013,12)
output_folder="era5_$(area_name)_$(parameterset)_$(first_month[1])$(first_month[2])_to_$(last_month[1])$(last_month[2])"
skip_if_exists=true # set to false to force re-download of data even if files already exist
remove_output_folder=true # set to true to remove the output folder if it already exists, set to false to keep existing folder and its contents.

#
# start download
#
era5 = CDS()

# remove, create or keep output folder
if remove_output_folder && isdir(output_folder)
    rm(output_folder,recursive=true)
    mkdir(output_folder)
elseif isdir(output_folder) && !remove_output_folder
    error("Output folder $output_folder already exists, skipping download.")
else !isdir(output_folder)
    mkdir(output_folder)
end

# download data
filenames=get_all_months(era5,output_folder,first_month,last_month,area,parameterset,skip_if_exists)
