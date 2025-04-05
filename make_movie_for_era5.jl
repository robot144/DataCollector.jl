
# prepare_data_for_surge.jl
#
# The surge component of the ML model is driven by winds and air pressure.
# This scipts prepares data for training, validation, and testing.


# switch to this folder as the working directory if not already here
cd(@__DIR__)
# use the project environment
using Pkg
Pkg.activate(".")
# Pkg.instantiate() #only once

# packages
using NCDatasets
using Dates
using Plots

# parameters
data_folder = "./era5_global_201312"
tstart=DateTime(2013,12,3)
tend=DateTime(2013,12,10)

# Open dataset with wind_stress
files=readdir(data_folder)
files=filter(x->occursin(r"era5_wind_.*.nc",x),files)
file_paths=joinpath.(data_folder,files)
d=NCDataset(file_paths;aggdim="valid_time")
era5_times=d["valid_time"][:]
era5_longitude=d["longitude"][:]
era5_latitude=d["latitude"][:]
# reverse the order of the latitude
era5_latitude=reverse(era5_latitude)

ifirst = findfirst(x->x>=tstart,era5_times)
ilast = findlast(x->x<=tend,era5_times) 
@show ifirst,ilast
# create subsets

# create movie
# Extract the variable you want to visualize (e.g., wind stress)
u10 = d["u10"] # lazy ref
v10 = d["v10"]
msl = d["msl"]


@info "Creating frames for the movie..."
anim = @animate for i in ifirst:ilast
    @show i, ifirst, ilast
    heatmap(
        era5_longitude,
        era5_latitude,
        reverse(msl[:, :, i],dims=2)',
        title="MSL pressure at $(era5_times[i])",
        xlabel="Longitude",
        ylabel="Latitude",
        color=:viridis
    )
end
gif(anim,"era5_pressure.gif", fps=10)
