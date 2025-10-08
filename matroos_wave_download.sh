#! /bin/bash
# download matroos wave data
# use wget to download the data with the servers side php script https://matroos.rws.nl/direct/get_series.php
# with the following parameters (GET):
# loc: station id
# unit: quantity (e.g. wave_height)
# source: data source (e.g. observed, )
#
# Example: https://matroos.rws.nl/direct/get_series.php?loc=&source=observed&unit=wave_height&tstart=2024001010000&tstop=202401020000
# An incomplete call will list the available stations, sources and units as (after some initial ascii text):
# Units:
# ------
# air_pressure
# air_temperature
# ...
#
# Locations:
# ----------
# A121
# A122
# ...
#
# Sources:
# --------
# observed
# rws_prediction
# ...
# 

# server
server="https://matroos.rws.nl"
script="/direct/get_series.php"

# login
USER="svsd"
PASS="n0v2006"

# locations=("K13A" "F3" "Europlatform")
locations=("K13a" "Europlatform")
# sources=("observed" "swan_dcsm_harmonie" "knmi_harmonie40_wind")
sources=("swan_dcsm_harmonie" "knmi_harmonie40_wind")
# units=("wave_height" "wave_period" "wave_direction" "wind_speed" "wind_direction")
units=("wave_height" "wind_speed" "wind_direction")
tstart="2024001010000"
tstop="202401020000"
# tstop="202412312350"
tstart="2024001020000"
tstop="202401030000"
output_dir="waves_20240102"

# remove old files
rm -f ${output_dir}/*
# create output directory if it does not exist
mkdir -p ${output_dir}

# loop over locations, sources and units
for loc in "${locations[@]}"; do
  for source in "${sources[@]}"; do
    for unit in "${units[@]}"; do
      # construct filename
        filename="${output_dir}/${unit}__${source}__${loc}.noos"
        # construct url
        url="${server}${script}?loc=${loc}&source=${source}&unit=${unit}&tstart=${tstart}&tstop=${tstop}"
        # download the data
        wget --user="$USER" --password="$PASS" -O "$filename" "$url" #TEST try wothout login
        #wget -O "$filename" "$url"
        echo "Downloaded $filename from $url"
        # remove file if empty, i.e. nothing after line 11 with #------------------------------------------------------ 
        if [ ! -s "$filename" ] || [ $(wc -l < "$filename") -le 12 ]; then # account for empty line after header
          echo "File $filename is empty or has no data, removing it."
          rm -f "$filename"
        fi
    done
  done
done

#
# info about parameters
#
# Units:
# ------
# airpressure
# air_temperature
# area_of_flow
# chloride
# discharge
# discharge_diurnal
# discharge_hourly
# discharge_in
# discharge_net
# discharge_out
# eastward_wind
# northward_wind
# number_chutes
# opening_height
# precipitation
# pumps_available
# salinity
# swellwave_dir
# swellwave_height_hm0
# velu
# velv
# warning_level_coastal_event
# warning_level_flooding
# warning_level_lake_event
# water_direction
# water_speed
# water_temperature
# water_velocity
# waterlevel
# waterlevel_astro
# waterlevel_astro_1min
# waterlevel_astro_hwlw
# waterlevel_astro_max
# waterlevel_astro_min
# waterlevel_max
# waterlevel_min
# waterlevel_model
# waterlevel_model_max
# waterlevel_model_min
# waterlevel_surge
# waterlevel_threshold_max
# waterlevel_threshold_min
# wave_dir_th0
# wave_direction
# wave_dirspread_s0bh
# wave_height
# wave_height_h1d10
# wave_height_h1d3
# wave_height_h1d50
# wave_height_hm0
# wave_height_hmax
# wave_period
# wave_period_t1d3
# wave_period_th1d3
# wave_period_tm02
# wave_period_tm10
# wave_period_tp
# wave_period_tz
# wind_blast
# wind_direction
# wind_speed
# windstress_u
# windstress_v

