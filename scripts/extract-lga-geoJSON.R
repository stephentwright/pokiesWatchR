# load packages;
library(sf)
library(geojsonsf)
library(tidyverse)

# read file
fnamePath <- './dataExtract/shapefiles/raw-sf/'
fname <- "LGA_2020_AUST.shp"

# generate raw data files for NSW LGA boundaries
lgaData <- st_read(paste(fnamePath,fname,sep=""))
lgaId <- lgaData$LGA_CODE20
lgaNames <- lgaData$LGA_NAME20

lgaNSW <- lgaData$STE_NAME16 == "New South Wales"
lgaIdNSW <- lgaId[lgaNSW]
lgaNamesNSW <- lgaNames[lgaNSW]

lgaNSW <- data.frame(lgaIdNSW,lgaNamesNSW)
save(lgaNSW, file='./dataExtract/r-data/lgaNSW.dat')

# define a quick subset function
## ToDo: possibly rescale the polygon for smaller foot print;
subset_sf <- function(sf_name, query) {
  rawOutput <- st_read(sf_name, query=query)

  #compress the polygon for small foot print
  compressOutput <- st_simplify(rawOutput, dTolerance=150)

  #output
  geoJsonOutput <- sf_geojson(compressOutput)

  return(geoJsonOutput)
}

# build an array of query strings to use for the extraction of data
extractQuery <- paste("SELECT * FROM \"",
                      unlist(strsplit(fname, ".", fixed=TRUE))[1],
                      "\" WHERE LGA_CODE20 = '",
                      lgaIdNSW,
                      "'",sep='')

# define the output path
outPath <- "./dataExtract/web-output/"

# loop - extract, convert, output
for (i in 1:length(lgaIdNSW)) {
  geoJSON <- subset_sf(paste(fnamePath,fname,sep=""),
                       extractQuery[i])
  write(geoJSON,file=paste(outPath,lgaIdNSW[i],'.geojson',sep=''))
}

