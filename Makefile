.PRECIOUS: %.pbf

# List all the source countries we need
WANTED_COUNTRIES := $(shell grep -v "\#" countries.wanted)

# Transform "belgium" to "world/belgium-latest.osm.pbf"
COUNTRIES_PBF := $(addsuffix -latest.osm.pbf,$(addprefix world/,$(WANTED_COUNTRIES)))

# Download the raw source file of a country
world/%.osm.pbf:
	#wget -N -nv -P world/ https://download.geofabrik.de/europe/$*.osm.pbf
	wget -N -nv -P world/ https://download.geofabrik.de/$*.osm.pbf

# Filter a raw country (in world/*) to rail-only data (in filtered/*)
filtered/%.osm.pbf: world/%.osm.pbf filter.params
	osmium tags-filter --expressions=filter.params $< -o $@ --overwrite

# Combine all rail-only data (in filtered/*) into one file
output/filtered.osm.pbf: $(subst world,filtered,$(COUNTRIES_PBF))
	osmium merge $^ -o $@ --overwrite

# Compute the real OSRM data on the combined file
output/filtered.osrm: output/filtered.osm.pbf basic.lua
	/home/blepers/osrm-backend/build/osrm-extract -p basic.lua $<
	/home/blepers/osrm-backend/build/osrm-partition $<
	/home/blepers/osrm-backend/build/osrm-customize $<

all: output/filtered.osrm

serve: output/filtered.osrm basic.lua
	/home/blepers/osrm-backend/build/osrm-routed --algorithm mld $<
