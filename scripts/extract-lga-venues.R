library(readxl)
library(stringr)
library(tidyverse)
library(jsonlite)

# read in the xlxs file;
filePath <- 'dataExtract/premises/'
fileName <- 'premises-list-mar-2022.xlsx'
sheetName <- 'Premises List'
rawVenues <- read_xlsx(path=paste(filePath,fileName,sep=''), sheet=sheetName, skip=3)

# attached the LGA code
load(file='dataExtract/r-data/lgaNSW.dat')
lgaNSW$lgaNameClean <- str_remove_all(lgaNSW$lgaNamesNSW,pattern="( \\s*\\([^\\)]+\\))")
lgaNSW <- lgaNSW %>% select(-lgaNamesNSW)

# clean and merge -- pass 1
rawVenues$lgaNameClean <- str_remove(rawVenues$LGA,'( City Council)|( Shire Council)| Council')

rawVenuesLGA <- left_join(rawVenues,lgaNSW, by="lgaNameClean")

needToClean <- rawVenuesLGA %>% filter(is.na(lgaIdNSW)) %>% group_by(LGA,lgaNameClean) %>% summarise(n=n())
write.csv(needToClean[,2],file=paste(filePath,'cleanMe.csv',sep=''))
cleanedLGAs <- read.csv(file=paste(filePath,'cleanLGA.csv',sep=''))

# clean and merge -- pass 2
lgaNSW <- rbind(lgaNSW,cleanedLGAs)
rawVenuesLGA <- left_join(rawVenues,lgaNSW, by="lgaNameClean")
needToClean <- rawVenuesLGA %>% filter(is.na(lgaIdNSW)) %>% group_by(LGA,lgaNameClean) %>% summarise(n=n())
## only 162 record not merged with an LGA code;

# prep the data for exporting
keepColumns <- c("`Licence number`","`Licence name`")

keepVenues <- rawVenuesLGA %>%
                filter(`Licence type`=='Liquor - club licence', EGMs>0) %>%
                  select(`Licence number`,
                         `Licence name`,
                         Address,
                         Suburb,
                         Postcode,
                         Latitude,
                         Longitude,
                         lgaIdNSW,
                         EGMs)

# export as JSON -- break into individual files
lgaId <- unique(keepVenues$lgaIdNSW)

for (i in 1:length(lgaId)) {
  extract <- keepVenues %>% filter(lgaIdNSW == lgaId[i])
  json <- toJSON(extract)
  write(json, file=paste('dataExtract/web-output/',lgaId[i],'-venues.json',sep=''))
}






