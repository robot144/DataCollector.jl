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
USER=$1
PASS=$2

# 7to3
# wind_locations=("K13a" "F3" "Europlatform" "Gannet platform 1" "A121" "D151" "nsb3")
# wave_locations=("K13a" "Europlatform" "F3" "Vlakte vd Raan" "Huibertgat")
wave_locations=(
"North Cormorant 1"
"A121"
"K13a"
"eurogeul E13"
"L91"
"wadden eierlandse gat"
"Schiermonnikoog Noord"
"ijmuiden munitiestort 1"
"OS11"
"Europlatform"
"F161"
"F3"
)

wind_locations=(
"K13a"
"F3"
"Europlatform"
"Gannet platform 1"
"A121"
"D151"
"nsb3"
"Huibertgat"
"F161"
"Lichteiland Goeree 1"
)

#locations=("K13a" "Europlatform")A121
# sources=("observed" "swan_dcsm_harmonie" "knmi_harmonie40_wind")
wave_sources=("swan_dcsm_harmonie")
wind_sources=("knmi_harmonie40_wind")
# units=("wave_height" "wave_period" "wave_direction" "wind_speed" "wind_direction")
wave_units=("wave_height")
wind_units=("wind_speed" "wind_direction")

# tstart="202101010000"
# tstop="202201010000"
# output_dir="waves_2021"

# tstart="202201010000"
# tstop="202301010000"
# output_dir="waves_2022"

# tstart="202301010000"
# tstop="202401010000"
# output_dir="waves_2023"

tstart="202401010000"
tstop="202501010000"
output_dir="waves_2024"

## In dec 2024 harmonie switched to v43, so use knmi_harmonie winds since then
## tstart="202401010000"
## tstop="202501010000"
## output_dir="waves_2024_harmonie43"
## sources=("knmi_harmonie") # harmonie switched to v43? About a month later than end of harmonie40



# remove old files
rm -f ${output_dir}/*
# create output directory if it does not exist
mkdir -p ${output_dir}

# loop over locations, sources and units
# for waves
for loc in "${wave_locations[@]}"; do
  for source in "${wave_sources[@]}"; do
    for unit in "${wave_units[@]}"; do
      # construct filename
        filename="${output_dir}/${unit}__${source}__${loc}.noos"
        # construct url
        url="${server}${script}?loc=${loc}&source=${source}&unit=${unit}&tstart=${tstart}&tstop=${tstop}"
        # download the data
        wget --user="$USER" --password="$PASS" -O "$filename" "$url" 
        #wget -O "$filename" "$url" #TEST try wothout login
        echo "Downloaded $filename from $url"
        # remove file if empty, i.e. nothing after line 11 with #------------------------------------------------------ 
        if [ ! -s "$filename" ] || [ $(wc -l < "$filename") -le 12 ]; then # account for empty line after header
          echo "File $filename is empty or has no data, removing it."
          rm -f "$filename"
        fi
    done
  done
done
# for wind
for loc in "${wind_locations[@]}"; do
  for source in "${wind_sources[@]}"; do
    for unit in "${wind_units[@]}"; do
      # construct filename
        filename="${output_dir}/${unit}__${source}__${loc}.noos"
        # construct url
        url="${server}${script}?loc=${loc}&source=${source}&unit=${unit}&tstart=${tstart}&tstop=${tstop}"
        # download the data
        wget --user="$USER" --password="$PASS" -O "$filename" "$url" 
        #wget -O "$filename" "$url" #TEST try wothout login
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

# Wave Locations:
# ----------
# A121
# A122
# amelander zeegat, boei 1-1
# amelander zeegat, boei 1-2
# amelander zeegat, boei 2-1
# amelander zeegat, boei 2-2
# amelander zeegat, boei 3-1
# amelander zeegat, boei 3-2
# amelander zeegat, boei 4-1
# amelander zeegat, boei 4-2
# amelander zeegat, boei 5-1
# amelander zeegat, boei 5-2
# amelander zeegat, boei 6-1
# amelander zeegat, boei 6-2
# anasuria
# AWG
# BG2
# borkum
# Borssele Alpha
# Borssele Beta
# BSH03
# buoy, station 62052 (Fr)
# buoy_K5, station 64045 (UK)
# buoy_K7, station 64046 (UK)
# buoy_M1 (Ire)
# buoy_M3 (Ire)
# buoy_M4 (Ire)
# buoy_M5 (Ire)
# buoy_M6 (Ire)
# cadzand boei
# Cadzand meetpaal
# cherbourg
# D151
# deurlo
# domburger rassen
# Eemsboei 11
# Eemsboei 17
# Eemsboei 27
# Eemsboei 30
# Eemsboei 51
# eurogeul DWE
# eurogeul E13
# eurogeul E5
# euromaasgeul_-01km
# euromaasgeul_04km
# euromaasgeul_15km
# euromaasgeul_37km
# euromaasgeul_61km
# Europlatform
# F161
# F3
# FINO1_0m
# Gannet platform 1
# Greenwich Lightship, station 62305
# hoekvanholland stroompaal 1
# Hollandse Kust Noord
# Hollandse Kust West Alpha
# Hollandse Kust West Beta
# Hollandse Kust Zuid Alpha
# Hollandse Kust Zuid Beta
# honte sloehaven
# ij-geul IJ5
# ij-geul stroompaal 1
# ijgeul_04km
# ijgeul_16km
# ijgeul_30km
# ijgeul_40km
# ijmuiden munitiestort 1
# IJmuiden Ver Alpha
# IJmuiden Ver Beta
# IJmuiden Ver Gamma
# J6
# K13a
# klein beerkanaal
# L91
# Lichteiland Goeree 1
# Meetboei PBW1
# Meetboei RZGN1
# Meetboei UHW1
# Meetboei WEO1
# Meetboei WEW1
# Meetpaal Emden
# Nelson platform 1
# North Cormorant 1
# nymindegab
# oosterschelde 04
# OS11
# Platform, station 62145
# platform, station 63113 (UK)
# Q11
# RZGN1_protide
# sandettie lightship, station 62304 (Fr)
# scheur oost
# scheur west
# Schiermonnikoog Noord
# Schiermonnikoog Wadden
# schiermonnikoog westgat
# schouwenbank
# sleipner-a
# Station 62042
# Station 62046
# Station 62047
# Station 62048
# Station 62105
# Station 62116
# Station 62117
# Station 62118
# Station 62119
# Station 62128
# Station 62133
# Station 62143
# Station 62146
# Station 62152
# Station 62170
# Station 62289
# Station 62293
# Station 63055
# Station 63056
# Station 63103
# Station 63108
# Station 63110
# Station 63112
# Station 63115
# stortemelk boei
# stortemelk oost
# Stroommeetpaal Eemshaven
# Terschelling Noordzee
# wadden eierlandse gat
# westhinder
# westkapelle oostgat noord
# wielingen


# Wind Locations:
# ----------
# A121
# Aukfield platform
# AWG
# bergse diepsluis west
# berkhout
# BG2
# Cadzand meetpaal
# D151
# de kooij
# eemshaven
# Europlatform
# F161
# F3
# Gannet platform 1
# german bight
# Grevelingensluis wind
# GWEms
# hansweert
# haringvlietbrug 02
# Haringvlietsluizen Schuif 1
# Helgoland
# Hoek van Holland
# hoek van holland noorderdam
# hoorn-terschelling
# houtribdijk
# Huibertgat
# IJmuiden
# ijmuiden kop pier
# ijmuiden munitiestort 1
# IJsselmeer Midden -b
# IJsselmeer Midden N
# J6
# K13a
# K14
# kats buiten
# Lauwersoog
# Lichteiland Goeree 1
# Marker Wadden
# Markermeer Midden -b
# marknesse
# Nelson platform 1
# nieuw beerta
# Noordwijk meetpost
# North Cormorant 1
# nsb3
# oosterschelde 04
# P11 Platform
# Q11
# RotterdamseHoek
# schaar
# stavenisse
# stavoren
# Stroommeetpaal Eemshaven
# Terneuzen Westsluis
# Terschelling Noordzee
# texel noordzee
# texelhors
# tholen
# valkenburg
# Vlakte vd Raan
# vlieland
# Vlissingen
# Wierumergronden
# wijdenes
# wilhelminadorp
# Zeelandbrug noord

# wave_locations=(
#   "A121"
#   "A122"
#   "amelander zeegat, boei 1-1"
#   "amelander zeegat, boei 1-2"
#   "amelander zeegat, boei 2-1"
#   "amelander zeegat, boei 2-2"
#   "amelander zeegat, boei 3-1"
#   "amelander zeegat, boei 3-2"
#   "amelander zeegat, boei 4-1"
#   "amelander zeegat, boei 4-2"
#   "amelander zeegat, boei 5-1"
#   "amelander zeegat, boei 5-2"
#   "amelander zeegat, boei 6-1"
#   "amelander zeegat, boei 6-2"
#   "anasuria"
#   "AWG"
#   "BG2"
#   "borkum"
#   "Borssele Alpha"
#   "Borssele Beta"
#   "BSH03"
#   "buoy, station 62052 (Fr)"
#   "buoy_K5, station 64045 (UK)"
#   "buoy_K7, station 64046 (UK)"
#   "buoy_M1 (Ire)"
#   "buoy_M3 (Ire)"
#   "buoy_M4 (Ire)"
#   "buoy_M5 (Ire)"
#   "buoy_M6 (Ire)"
#   "cadzand boei"
#   "Cadzand meetpaal"
#   "cherbourg"
#   "D151"
#   "deurlo"
#   "domburger rassen"
#   "Eemsboei 11"
#   "Eemsboei 17"
#   "Eemsboei 27"
#   "Eemsboei 30"
#   "Eemsboei 51"
#   "eurogeul DWE"
#   "eurogeul E13"
#   "eurogeul E5"
#   "euromaasgeul_-01km"
#   "euromaasgeul_04km"
#   "euromaasgeul_15km"
#   "euromaasgeul_37km"
#   "euromaasgeul_61km"
#   "Europlatform"
#   "F161"
#   "F3"
#   "FINO1_0m"
#   "Gannet platform 1"
#   "Greenwich Lightship, station 62305"
#   "hoekvanholland stroompaal 1"
#   "Hollandse Kust Noord"
#   "Hollandse Kust West Alpha"
#   "Hollandse Kust West Beta"
#   "Hollandse Kust Zuid Alpha"
#   "Hollandse Kust Zuid Beta"
#   "honte sloehaven"
#   "ij-geul IJ5"
#   "ij-geul stroompaal 1"
#   "ijgeul_04km"
#   "ijgeul_16km"
#   "ijgeul_30km"
#   "ijgeul_40km"
#   "ijmuiden munitiestort 1"
#   "IJmuiden Ver Alpha"
#   "IJmuiden Ver Beta"
#   "IJmuiden Ver Gamma"
#   "J6"
#   "K13a"
#   "klein beerkanaal"
#   "L91"
#   "Lichteiland Goeree 1"
#   "Meetboei PBW1"
#   "Meetboei RZGN1"
#   "Meetboei UHW1"
#   "Meetboei WEO1"
#   "Meetboei WEW1"
#   "Meetpaal Emden"
#   "Nelson platform 1"
#   "North Cormorant 1"
#   "nymindegab"
#   "oosterschelde 04"
#   "OS11"
#   "Platform, station 62145"
#   "platform, station 63113 (UK)"
#   "Q11"
#   "RZGN1_protide"
#   "sandettie lightship, station 62304 (Fr)"
#   "scheur oost"
#   "scheur west"
#   "Schiermonnikoog Noord"
#   "Schiermonnikoog Wadden"
#   "schiermonnikoog westgat"
#   "schouwenbank"
#   "sleipner-a"
#   "Station 62042"
#   "Station 62046"
#   "Station 62047"
#   "Station 62048"
#   "Station 62105"
#   "Station 62116"
#   "Station 62117"
#   "Station 62118"
#   "Station 62119"
#   "Station 62128"
#   "Station 62133"
#   "Station 62143"
#   "Station 62146"
#   "Station 62152"
#   "Station 62170"
#   "Station 62289"
#   "Station 62293"
#   "Station 63055"
#   "Station 63056"
#   "Station 63103"
#   "Station 63108"
#   "Station 63110"
#   "Station 63112"
#   "Station 63115"
#   "stortemelk boei"
#   "stortemelk oost"
#   "Stroommeetpaal Eemshaven"
#   "Terschelling Noordzee"
#   "wadden eierlandse gat"
#   "westhinder"
#   "westkapelle oostgat noord"
#   "wielingen"
# )

# wind_locations=(
#   "A121"
#   "Aukfield platform"
#   "AWG"
#   "bergse diepsluis west"
#   "berkhout"
#   "BG2"
#   "Cadzand meetpaal"
#   "D151"
#   "de kooij"
#   "eemshaven"
#   "Europlatform"
#   "F161"
#   "F3"
#   "Gannet platform 1"
#   "german bight"
#   "Grevelingensluis wind"
#   "GWEms"
#   "hansweert"
#   "haringvlietbrug 02"
#   "Haringvlietsluizen Schuif 1"
#   "Helgoland"
#   "Hoek van Holland"
#   "hoek van holland noorderdam"
#   "hoorn-terschelling"
#   "houtribdijk"
#   "Huibertgat"
#   "IJmuiden"
#   "ijmuiden kop pier"
#   "ijmuiden munitiestort 1"
#   "IJsselmeer Midden -b"
#   "IJsselmeer Midden N"
#   "J6"
#   "K13a"
#   "K14"
#   "kats buiten"
#   "Lauwersoog"
#   "Lichteiland Goeree 1"
#   "Marker Wadden"
#   "Markermeer Midden -b"
#   "marknesse"
#   "Nelson platform 1"
#   "nieuw beerta"
#   "Noordwijk meetpost"
#   "North Cormorant 1"
#   "nsb3"
#   "oosterschelde 04"
#   "P11 Platform"
#   "Q11"
#   "RotterdamseHoek"
#   "schaar"
#   "stavenisse"
#   "stavoren"
#   "Stroommeetpaal Eemshaven"
#   "Terneuzen Westsluis"
#   "Terschelling Noordzee"
#   "texel noordzee"
#   "texelhors"
#   "tholen"
#   "valkenburg"
#   "Vlakte vd Raan"
#   "vlieland"
#   "Vlissingen"
#   "Wierumergronden"
#   "wijdenes"
#   "wilhelminadorp"
#   "Zeelandbrug noord"
# )
