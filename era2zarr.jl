# era2zarr.jl
# A Julia script to convert ERA5 data files to Zarr format.
# Also quantize and compress the data for efficient storage.
# Multiple netcdf files can be merged into a single Zarr store.

using NCDatasets
using CommonDataModel
using Zarr
using Dates
using TOML

debuglevel = 1  # 0: none, 1: info, 2: debug
chunk_target_size=1000000 # target chunk size in number of array elements

#
# defaults
#
# look for these variables in the ERA5 data files
try_vars = ["10m_u_component_of_wind","10m_v_component_of_wind","mean_sea_level_pressure",
            "mean_wave_direction","mean_wave_period","significant_height_of_combined_wind_waves_and_swell"]
defaults = Dict(
    "10m_u_component_of_wind" => Dict(
        "name" => "10m_u_component_of_wind",
        "scale_factor" => 0.01, #max resolution in data 0.001, 
        "add_offset" => 0.0,
        "data_type" => "Int16",
        "_FillValue" => typemax(Int16) ),
    "10m_v_component_of_wind" => Dict(
        "name" => "10m_v_component_of_wind",
        "scale_factor" => 0.01, #max resolution in data 0.001, 
        "add_offset" => 0.0,
        "data_type" => "Int16",
        "_FillValue" => typemax(Int16) ),
    "mean_sea_level_pressure" => Dict(
        "name" => "mean_sea_level_pressure",
        "scale_factor" => 1.0, #max resolution in data 0.25,
        "add_offset" => 100000.0,
        "data_type" => "Int16",
        "_FillValue" => typemax(Int16) ),
    "mean_wave_direction" => Dict(
        "name" => "mean_wave_direction",
        "scale_factor" => 0.1,
        "add_offset" => 0.0,
        "data_type" => "Int16",
        "_FillValue" => typemax(Int16) ),
    "mean_wave_period" => Dict(
        "name" => "mean_wave_period",
        "scale_factor" => 0.1,
        "add_offset" => 0.0,
        "data_type" => "Int16",
        "_FillValue" => typemax(Int16) ),
    "significant_height_of_combined_wind_waves_and_swell" => Dict(
        "name" => "significant_height_of_combined_wind_waves_and_swell",
        "scale_factor" => 0.01,
        "add_offset" => 0.0,
        "data_type" => "Int16",
        "_FillValue" => typemax(Int16) ),
    "valid_time" => Dict(
        "name" => "valid_time",
        "data_type" => "Int64",
        "_FillValue" => typemax(Int64),
        "scale_factor" => 1,
        "add_offset" => 0 ),
    "longitude" => Dict(
        "name" => "longitude",
        "data_type" => "Float64",
        "_FillValue" => 9999.0,
        "scale_factor" => 1.0,
        "add_offset" => 0.0 ),
    "latitude" => Dict(
        "name" => "latitude",
        "data_type" => "Float64",
        "_FillValue" => -9999.0,
        "scale_factor" => 1.0,
        "add_offset" => 0.0 )
)

# variable names as which the variables will be stored in the NetCDF files
# map the name as we'll use them to possible variable names in the netcdf files
aliases=Dict{String,Vector{String}}(
    "10m_u_component_of_wind" => ["u10"],
    "10m_v_component_of_wind" => ["v10"],
    "mean_sea_level_pressure" => ["msl"],
    "mean_wave_direction" => ["mwd"],
    "mean_wave_period" => ["mwp"],
    "significant_height_of_combined_wind_waves_and_swell" => ["hs","swh"],
    "longitude" => ["longitude","lon"],
    "latitude" => ["latitude","lat"],
    "valid_time" => ["valid_time","time"]
)


#
# supporting functions
#
typeconv = Dict{String,DataType}( #String to DataType conversion
    "Int32" => Int32, 
    "Int16" => Int16, 
    "Int8"  => Int8,
    "Float32" => Float32,
    "Float64" => Float64
)

"""
function open_dataset(filenames::Vector{String})
Open multiple netcdf files as a single dataset using NCDataset with aggregation along valid_time dimension.
Example: nc=open_dataset(["era201313.nc","era201314.nc"])
"""
function open_dataset(filenames::Vector{String})
    for filename in filenames
        if !isfile(filename)
            error("File not found: $(filename)")
        end
    end
    nc=nothing
    try
        nc=NCDataset(filenames;aggdim="valid_time")
    catch
        error("Could not open files as a single dataset: $(filenames)")
    end
    return nc
end

"""
function get_varname(name::String,nc::CommonDataModel.AbstractDataset)
Find name of a variable in an nc dataset using a list of alias values
Example: lon = get_varname("longitude",keys(nc))
returns nothing if variable does not exist on the file
"""
function get_varname(name::String,nc::CommonDataModel.AbstractDataset)
    ncvarnames=keys(nc)
    if !(name in keys(aliases))
        error("unknown variable")
    end
    tempstrs=intersect(aliases[name],ncvarnames)
    if length(tempstrs)==0
        return nothing
    else
        return first(tempstrs)
    end
end

"""
function get_info_for_default_config(netcdffiles::Vector{String})
Example: info=get_info_for_default_config(["test_data/locxxz_map.nc"])
       ymin=info["ymin"]
Extract some info from netcdffiles. The purpose is to collect the
info that is needed for the default config.  
"""
function get_info_for_default_config(netcdffiles::Vector{String})
    firstmap=NCDataset(first(netcdffiles))
    # coordinate names
    lon=firstmap["longitude"]
    if lon===nothing
        error("Could not find x-coordinate variable in $(firstmap)")
    end
    lat=firstmap["latitude"][:]
    if lat===nothing
        error("Could not find y-coordinate variable in $(firstmap)")
    end
    # determine bbox
    xmax=maximum(lon[:])
    xmin=minimum(lon[:])
    ymax=maximum(lat[:])
    ymin=minimum(lat[:])
    # suggest chunking settings
    nxcells=length(lon)
    nycells=length(lat)
    xchunk=nxcells
    ychunk=nycells
    timechunk=24 #assume daily data
    # list of variable names found in file
    varnames=[]
    for varname in try_vars
        ncvar=get_varname(varname,firstmap)
        if !(ncvar===nothing)
            push!(varnames,varname)
        end
    end
    finalize(firstmap)
    return Dict{String,Any}("xmin" => xmin, "ymin" => ymin, "xmax" => xmax, "ymax" => ymax,
                            "xchunk" => xchunk, "ychunk" => ychunk, "timechunk" =>timechunk,"varnames" => varnames)
end


"""
function default_config(netcdffiles::Vector{String})
 Example: conf=default_config("era201313.nc")
"""
function default_config(netcdffiles::Vector{String})
    #firstmap=first(netcdffiles)
    config=Dict{String,Any}()
    globals=Dict{String,Any}()
    globals["netcdf_files"]=netcdffiles
    zarrname=replace(first(netcdffiles), ".nc" => ".zarr")
    zarrname=replace(zarrname, r"_[0-9]+" => s"")
    zarrname=replace(zarrname, r"_-[0-9]+" => s"")
    zarrname=replace(zarrname, r".*/" => s"")
    globals["zarr_file"]=zarrname
    globals["chunk_target_size"]=chunk_target_size
    info=get_info_for_default_config(netcdffiles)
    globals["extent"]=Dict{String,Any}("xmin" => info["xmin"], "xmax" =>info["xmax"],
                                       "ymin" => info["ymin"], "ymax" =>info["ymax"])
    globals["islatlon"]=true
    #propose chunking
    globals["xchunk"]=info["xchunk"]
    globals["ychunk"]=info["ychunk"]
    globals["timechunk"]=info["timechunk"]
    # add globals to config
    config["global"]=globals
    ## variable configurations
    varnames=info["varnames"]
    for varname in varnames
        varconfig=Dict{String,Any}(
            "scale_factor" => defaults[varname]["scale_factor"],
            "add_offset"   => defaults[varname]["add_offset"],
            "data_type"    => defaults[varname]["data_type"],
        )
        config[varname]=varconfig
   end
   return config
end

"""
function varlist(config::Dict{String,Any})
  vars=varlist(config)
"""
function varlist(config::Dict{String,Any})
    vars=Vector{String}()
    for varname in keys(config)
        if !startswith(lowercase(varname),r"global")
            push!(vars,varname)
        end
    end
    return vars
end

"""
function scale_values(in_values,in_dummy,out_type,out_offset,out_scale,out_dummy)
 Scale and quantize input values to output type.
 Example: out_values=scale_values(in_values,in_dummy,out_type,out_offset,out_scale,out_dummy)
"""
function scale_values(in_values,in_dummy,out_type,out_offset,out_scale,out_dummy)
    # optimized version
    out_max=typemax(out_type)
    out_min=typemin(out_type)
    out_values=Array{out_type}(undef,size(in_values))
    for i in eachindex(in_values)
        in_value = in_values[i]
        if isnan(in_value) || (in_value==in_dummy)
            out_value = out_dummy
        else
            temp_value = (in_value - out_offset)/out_scale
            temp_value = min(temp_value,out_max)
            temp_value = max(temp_value,out_min)
            out_value = round(out_type,temp_value)
        end
        out_values[i]=out_value
    end
    return out_values
 end

"""
function copy_var(input::CommonDataModel.AbstractDataset,output,varname,config,y_reversed=true,stop_on_missing=true)
Copy variable from input dataset to output zarr store with scaling and compression.
Example: copy_var(input,output,"10m_u_component_of_wind",config,y_reversed)
"""
function copy_var(input::CommonDataModel.AbstractDataset,output,varname,config,y_reversed=true,stop_on_missing=true)
    compressor=Zarr.BloscCompressor(; cname="lz4hc", clevel=5, shuffle=Zarr.Blosc.BITSHUFFLE)
    # see https://juliaio.github.io/Zarr.jl/stable/reference/#Compressors-1 | lz4 or lz4hc, BITSHUFFLE or SHUFFLE
    # NOTE: currently I see no impact of compressor on file size!
    println("start copying variable name=$(varname)")
    ncname=get_varname(varname,input)
    if (ncname===nothing)
       if stop_on_missing
          error("could not find variable $(varname) in $(input.name).")
       else
          return nothing
       end
    end
    in_var=input[ncname]
    in_atts=in_var.attrib
    in_type=typeof(first(in_var))
    in_dummy=get(in_atts,"_FillValue",9999.0)
    in_size=size(in_var)
    in_rank=length(in_size)
    #output
    if !haskey(config,varname) #create empty one if absent
        config[varname]=Dict{String,Any}()
    end
    out_offset=get(config[varname],"add_offset",defaults[varname]["add_offset"])
    out_scale=get(config[varname],"scale_factor",defaults[varname]["scale_factor"])
    out_dummy=get(config[varname],"_FillValue",defaults[varname]["_FillValue"])
    out_type_str=get(config[varname],"data_type",defaults[varname]["data_type"])
    out_type=typeconv[out_type_str]
    if in_rank==3
        #assume time is the 3rd dimension
        out_chunk_size=(get(config["global"],"xchunk",in_size[1]),
                               get(config["global"],"ychunk",in_size[2]),
                               get(config["global"],"timechunk",in_size[3]) )
    elseif in_rank==2
        out_chunk_size=(get(config["global"],"timechunk",in_size[1]))
    else
        error("Unsupported rank ($(in_rank)) for variable $(varname)")
    end
    out_atts=copy(in_atts)
    out_atts["scale_factor"]=out_scale
    out_atts["add_offset"]=out_offset
    out_atts["_ARRAY_DIMENSIONS"]=reverse(in_var.dimnames) #Xarray likes the python order
    ###DEBUG MVL 
    # println("varname= $(varname)")
    # println("in_dummy = $(in_dummy)")
    # println("out_dummy= $(out_dummy)")
    #create output variable
    out_var = zcreate(out_type, output, varname,in_size...,attrs=out_atts, chunks = out_chunk_size,compressor=compressor)
    println("in_size= $(in_size)")
    println("out_size= $(size(out_var))")
    #copy content
    if in_rank==1
        #in one go 
        in_temp=in_var[:]
        if out_type<:Int
            out_temp=round.(out_type,(in_temp.-out_offset)./out_scale)
            out_temp[in_temp.==in_dummy].=out_dummy
            out_var[:].=out_temp[:]
        else
            out_temp=(in_temp.-out_offset)./out_scale
            out_temp[in_temp.==in_dummy].=out_dummy
            out_var[:].=out_temp[:]    
        end
    elseif in_rank==3
        println("out_chunk_size = $(out_chunk_size)")
        if prod(in_size)==prod(out_chunk_size)
            #in one go 
            in_temp=in_var[:,:,:]
            out_temp=round.(out_type,(in_temp.-out_offset)./out_scale)
            out_temp[in_temp.==in_dummy].=out_dummy
            if y_reversed
                out_var[:, :, :].=out_temp[:, end:-1:1, :] #reverse y
            else
                out_var[:,:,:].=out_temp[:,:,:]
            end
        else #multiple blocks in time
            nblocks=max(div(prod(in_size),prod(out_chunk_size)),1)
            dimlen=in_size[3]
            blockstep=max(1,div(dimlen,nblocks))
            ifirst=1
            while ifirst<dimlen
                println("  processing time indices $(ifirst) to $(min(ifirst+blockstep-1,dimlen)) of $(dimlen)")
                ilast=min(ifirst+blockstep-1,dimlen)
                in_temp=in_var[:,: ,ifirst:ilast]
                out_temp=round.(out_type,(in_temp.-out_offset)./out_scale)
                out_temp[in_temp.==in_dummy].=out_dummy
                if y_reversed
                    out_var[:, :, ifirst:ilast]=out_temp[:, end:-1:1, :] #reverse y
                else
                    out_var[:, :, ifirst:ilast]=out_temp[:, :, :] 
                end
                ifirst+=blockstep
            end
        end
    else
        error("Wrong rank ($(in_rank)) for variable $(varname)")
    end
end

"""
function date_time_to_seconds_since(dt::Vector{DateTime},ref::DateTime)
 Convert DateTime vector to seconds since reference DateTime.
 Example: seconds=date_time_to_seconds_since(dt,ref)
"""
function date_time_to_seconds_since(dt::Vector{DateTime},ref::DateTime)
    # compute millisecond differences for each element, then convert to seconds
    ms = Dates.value.(dt .- ref)
    return Int64.(ms .÷ 1000)
end

#
# main function
#
function main(args)
    # read user input
    n = length(args)
    if n < 1
        println("Usage: julia era2zarr.jl config.toml")
        println("This command will generate a config file:")
        println("julia era2zarr.jl era_folder/*.nc")
    elseif endswith(lowercase(first(args)),r".toml")
        configfile=first(args)
        if !isfile(configfile)
            throw(ArgumentError("File not found: $(configfile)\n"))
        end
        # load configfile
        config=TOML.parsefile(configfile)
        if !haskey(config,"global")
            error("Missing [global] group in config file")
        end
        globals=config["global"]
        if !haskey(globals,"netcdf_files")
            error("Missing keyword netcdf_files in group [global] in config file")
        end 
        map_files=globals["netcdf_files"]
        if !isfile(first(map_files))
            error("Cannot find file: $(first(map_files))")
        end
        outname=""
        if haskey(globals,"zarr_file")
            outname=globals["zarr_file"]
        else
            error("missing key zarr_file in configuration)")
        end
        if ispath(outname)
            error("Output name $(outname) exists. Will not overwrite.")
        end
        # initialize netcdf maps files
        allmaps=open_dataset(map_files)
        # create zarr file and start copying metadata
        globalattrs=Dict(allmaps.attrib)
        output = zgroup(outname,attrs=globalattrs)
        # # output coordinates
        xname=get_varname("longitude",allmaps)
        yname=get_varname("latitude",allmaps)
        xvalues=allmaps[xname][:]
        yvalues=allmaps[yname][:]
        # flip y if needed
        y_reversed=false
        if yvalues[2]<yvalues[1]
            yvalues=reverse(yvalues)
            y_reversed=true
        end
        # write coordinates
        # xatts=firstmap[xname_node].atts 
        xatts=Dict(allmaps[xname].attrib)
        xatts["_ARRAY_DIMENSIONS"]=["x"]
        yatts=Dict(allmaps[yname].attrib)
        yatts["_ARRAY_DIMENSIONS"]=["y"]
        xvar = zcreate(Float64, output, "longitude",length(xvalues),attrs=xatts)
        xvar[:]=xvalues #write data
        yvar = zcreate(Float64, output, "latitude",length(yvalues),attrs=yatts)
        yvar[:]=yvalues #write data
        # time coordinate
        tname=get_varname("valid_time",allmaps)
        tatts=Dict(allmaps[tname].attrib)
        tatts["_ARRAY_DIMENSIONS"]=["valid_time"]
        if !(tatts["units"] == "seconds since 1970-01-01")
            #error("Unexpected time units: $(tatts["units"]). Only 'seconds since 1970-01-01' is supported.")
            #overrule time units
            tatts["units"]="seconds since 1970-01-01"
        end
        tvalues=date_time_to_seconds_since(allmaps[tname][:],DateTime(1970,1,1)) #NOTE doesn't consider metadata time units
        tvar = zcreate(Int64, output, "valid_time",length(tvalues),attrs=tatts)
        tvar[:]=tvalues[:] #write data
        #
        # copy all variables
        #
        vars=varlist(config)
        for varname in vars
            println("Copy and compress for variable $(varname)")
            @time copy_var(allmaps,output,varname,config,y_reversed) #TODO Far too much memory is allocated here!
        end
        # # create consolidate_metadata for faster internet access
        # Zarr.consolidate_metadata(output)
    else # expect list of mapfiles and generate default config
        first_mapfile=first(args)
        if !isfile(first_mapfile)
            throw(ArgumentError("File not found: $(first_mapfile)\n"))
        end
        if !endswith(lowercase(first(args)),r".nc")
            throw(ArgumentError("Expecting an ERA5 netcdf file: $(first_mapfile)\n"))
        end
        configfile="config_era2zarr.toml"
        if isfile(configfile)
            throw(ArgumentError("Existing config file. Will not overwrite: $(configfile)\n"))
        end
        open(configfile, "w") do io
            config=default_config(args)
            TOML.print(io, config)
        end
        if(debuglevel>0)
            TOML.print(config)
        end
        @info "Configuration has been written to $(configfile)"
    end
end
#
# Call main if used as a script, but not if loaded as a module 
#

# some defaults for manual tesing
# args=["test_data/era5_wind_201312_40_-15_65_20.nc"]
# args=["test_data/era5_waves_201312_40_-15_65_20.nc"]
# args=["config_era2zarr.toml"] #TODO these names are not used

# do nothing when called as module
if abspath(PROGRAM_FILE) == @__FILE__
    println("ARGS = $(ARGS)")
    @time main(ARGS)
end

nothing