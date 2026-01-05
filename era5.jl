# era5.jl
# support download of ERA5 data from CDS using the python cdsapi
# https://github.com/ecmwf/cdsapi and https://cds.climate.copernicus.eu/how-to-api
# It can also be useful to explore the data using the CDS web interface to get a feel for the data before downloading large amounts of data programmatically.
#
# Start small:
# 1. assume whole days
# 2. assume variables wind, and mean sea level pressure
# 3. assume that ~/.cdsapirc is already there (see https://cds.climate.copernicus.eu/how-to-api)
# Allow selection of:
# 1. date range
# 2. area
#

# Move to this folder if not already there
cd(@__DIR__)

# activate the environment
using Pkg
Pkg.activate(".")
# Load required packages
using PythonCall
using CondaPkg
using Plots
using Dates
using NetCDF
using Zarr
using JSON

# This struct will be a proxy for the CDS API
struct CDS
    has_cdsapirc::Bool
    dataset::String
    cds::Py
    cds_client::Py
    template::Dict
end

function CDS()
    # check for credentials
    has_cdsapirc = check_cdsapirc()
    # check for python packages
    has_conda_packages = check_conda_packages()
    cds=pyimport("cdsapi")
    cds_client=cds.Client()
    # set the default parameters
    dataset = "reanalysis-era5-single-levels"
    template = deepcopy(era_template)
    return CDS(has_cdsapirc, dataset, cds, cds_client, template)
end

function check_cdsapirc()
    if !isfile(joinpath(homedir(), ".cdsapirc"))
        println("You need to have a .cdsapirc file in your home directory to use the CDS API.")
        println("See https://cds.climate.copernicus.eu/api-how-to for more information.")
        return false
    else 
        return true
    end
end

function check_conda_packages(required_pkgs=["cdsapi"])
    # check for python packages
    CondaPkg.resolve()
    dfile = CondaPkg.cur_deps_file()
    pkgs, channels, pippkgs = CondaPkg.read_parsed_deps(dfile)
    pkgnames = [pkg.name for pkg in pkgs]
    for pkg in required_pkgs
        if pkg ∉ pkgnames
            println("Package $pkg is not installed.")
            println("Installing $pkg.")
            CondaPkg.add(pkg)
        end
    end
    return true
end

function daysinmonth_as_stringvector(year::Integer,month::Integer)
    n=Dates.daysinmonth(year,month)
    return [string(i) for i in 1:n]
end

# Example JSON argument for downloading ERA5 surface data
# import cdsapi
# dataset = "reanalysis-era5-single-levels"
# request = {
#     "product_type": ["reanalysis"],
#     "variable": [
#         "10m_u_component_of_wind",
#         "10m_v_component_of_wind"
#     ],
#     "year": ["2025"],
#     "month": ["01"],
#     "day": ["01"],
#     "time": [
#         "00:00", "01:00", "02:00",
#         "03:00", "04:00", "05:00",
#         "06:00", "07:00", "08:00",
#         "09:00", "10:00", "11:00",
#         "12:00", "13:00", "14:00",
#         "15:00", "16:00", "17:00",
#         "18:00", "19:00", "20:00",
#         "21:00", "22:00", "23:00"
#     ],
#     "data_format": "netcdf",
#     "download_format": "unarchived",
#     "area": [65, -15, 40, 15]
# }

# client = cdsapi.Client()
# client.retrieve(dataset, request).download()

# Define standard variable sets
# NOTE: do not mix variables from meteo and waves in one request
standard_variables=Dict(
    "winds"=>["10m_u_component_of_wind","10m_v_component_of_wind","mean_sea_level_pressure"],
    "waves"=>["mean_wave_direction","mean_wave_period","significant_height_of_combined_wind_waves_and_swell"]
)

era_template=Dict(
    "product_type"=>["reanalysis"],
    "data_format"=>"netcdf",
    "download_format"=> "unarchived",
    "variable"=>["10m_u_component_of_wind","10m_v_component_of_wind","mean_sea_level_pressure","mean_wave_direction","mean_wave_period","significant_height_of_combined_wind_waves_and_swell"],
    "area"=>[65, -15, 40, 15],
    "year"=>["2000"],
    "month"=>["03"],
    "day"=>["01"],
    "time"=>[
        "00:00","01:00","02:00",
        "03:00","04:00","05:00",
        "06:00","07:00","08:00",
        "09:00","10:00","11:00",
        "12:00","13:00","14:00",
        "15:00","16:00","17:00",
        "18:00","19:00","20:00",
        "21:00","22:00","23:00"
    ]
)

function get_month_chunk(era5::CDS,folder::String,year::Integer,month::Integer,area::Vector,variable_set="winds")
    era5.template["year"] = [string(year)]
    era5.template["month"] = [string(month)]
    era5.template["day"] = daysinmonth_as_stringvector(year,month)
    area=join(string.(area),"/")
    era5.template["area"] = area
    era5.template["variable"] = standard_variables[variable_set]
    request = JSON.json(era5.template)
    println("request = $(request)")
    json=pyimport("json")
    pydict_request=json.loads(request)
    month_str=lpad(string(month),2,"0")
    filename = joinpath(folder,"era5_$(variable_set)_$(year)$(month_str)_$(replace(area,"/"=>"_")).nc")
    @show filename
    println("Downloading $filename")
    era5.cds_client.retrieve(era5.dataset,pydict_request).download(filename)
    println("Finished download $filename")
    return filename
end

"""
Return next month as a tuple (year,month)

function next_month(year_month::Tuple{Integer,Integer})

Examples:
julia> next_month((2013,12))
(2014,1)   
"""
function next_month(year_month::Tuple{Integer,Integer})
    year,month=year_month
    if month==12
        return (year+1,1)
    else
        return (year,month+1)
    end
end 

"""
Download all months from start_month to end_month from the ERA5 dataset and save them in foldername

function get_all_months(era5::CDS, foldername::String,start_month::Tuple{Integer,Integer}, end_month::Tuple{Integer,Integer}, area::Vector)

Examples:
julia> era5 = CDS()
julia> foldername="temp"
julia> get_all_months(era5,foldername,(2013,12),(2014,1),[48,-5,62,12])
"""
function get_all_months(era5::CDS, foldername::String,start_month::Tuple{Integer,Integer}, end_month::Tuple{Integer,Integer}, area::Vector, variable_set="winds")
    filenames=[]
    this_month=start_month
    while this_month<=end_month
        filename=get_month_chunk(era5,foldername,this_month...,area,variable_set)
        push!(filenames,filename)
        this_month=next_month(this_month)
    end
    return filenames
end

# Test era5 download for a single month
function test1()
    era5 = CDS()
    foldername="temp"
    if isdir(foldername)
        rm(foldername,recursive=true)
    else
        mkdir(foldername)
    end
    filename=get_month_chunk(era5,foldername,2013,12,[40,-15,65,20],"winds")
    filename_waves=get_month_chunk(era5,foldername,2013,12,[40,-15,65,20],"waves")
    @show filename
    d=NetCDF.open(filename)
    @show d
end

# Test era5 download for a range of months
function test2()
    era5 = CDS()
    foldername="temp"
    if isdir(foldername)
        rm(foldername,recursive=true)
    end
    mkdir(foldername)
    filenames=get_all_months(era5,foldername,(2013,12),(2014,1),[48,-5,62,12])
    @show filenames
end

# collect data for North Sea for 2008-1-1 to 2013-1-1
era5 = CDS()
foldername="era5_north_sea_2008_2012"
if isdir(foldername)
    rm(foldername,recursive=true)
end
mkdir(foldername)
filenames=get_all_months(era5,foldername,(2008,1),(2013,12),[48,-5,62,12])

# collect data for entire globe for december 2013
era5 = CDS()
foldername="era5_global_201312"
if isdir(foldername)
    rm(foldername,recursive=true)
end
mkdir(foldername)
filenames=get_all_months(era5,foldername,(2013,12),(2013,12),[-90,-180,90,180])
