# load packages;
library(sf)
library(geojsonsf)

# read file
fnamePath <- "D:/Repositories/pokies-watch/prototype-html-css-js/resources/lga_shapefile/"
fname <- "LGA_2020_AUST.shp"

# generate raw data files for NSW LGA boundaries
lgaData <- st_read(paste(fnamePath,fname,sep=""))
lgaIDs <- lgaData$LGA_CODE20
lgaNames <- lgaData$LGA_NAME20

lgaNSW <- lgaData$STE_NAME16 == "New South Wales"
lgaIDsNSW <- lgaIDs[lgaNSW]
lgaNamesNSW <- lgaNames[lgaNSW]

lgaNSW <- data.frame(lgaIDsNSW,lgaNamesNSW)
save(lgaNSW,
     file='D:\\Repositories\\pokies-watch\\prototype-html-css-js\\resources\\premises\\lgaNSW.dat')

# define a quick subset function
## ToDo: possibly rescale the polygon for smaller foot print;
subset_sf <- function(sf_name, query) {
  rawOutput <- st_read(sf_name, query=query)
  geoJsonOutput <- sf_geojson(rawOutput)
  return(geoJsonOutput)
}

# build an array of query strings to use for the extraction of data
extractQuery <- paste("SELECT * FROM \"",
                      unlist(strsplit(fname, ".", fixed=TRUE))[1],
                      "\" WHERE LGA_CODE20 = '",
                      lgaIDsNSW,
                      "'",sep='')

# define the output path
outPath <- "D:/Repositories/pokies-watch/prototype-html-css-js/resources/geoJSON/"

# loop - extract, convert, output
for (i in 1:length(lgaIDsNSW)) {
  geoJSON <- subset_sf(paste(fnamePath,fname,sep=""),
                       extractQuery[i])
  write(geoJSON,file=paste(outPath,lgaIDsNSW[i],'.geojson',sep=''))
}






working <- "SELECT * FROM \"LGA_2020_AUST\" WHERE LGA_CODE20 = '11650'"
check <- extractQuery[26]


centralCoast <- st_read(paste(fnamePath,fname,sep=""),
                        query = extractQuery[26])

centralCoastGeoJSON <- sf_geojson(centralCoast)
write(centralCoastGeoJSON,file='d:/Repositories/pokies-watch/prototype-html-css-js/resources/centralCoast.json')