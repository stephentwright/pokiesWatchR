library(readxl)
library(stringr)
library(tidyverse)
library(jsonlite)

# read in the xlxs file;
filePath <- 'D:/Repositories/pokies-watch/prototype-html-css-js/resources/premises/'
fileName <- 'premises-list-mar-2022.xlsx'
sheetName <- 'Premises List'
rawVenues <- read_xlsx(path=paste(filePath,fileName,sep=''), sheet=sheetName, skip=3)

# attached the LGA code
load(file=paste(filePath,'lgaNSW.dat',sep=''))
lgaNSW$lgaNameClean <- str_remove_all(lgaNSW$lgaNamesNSW,pattern="( \\s*\\([^\\)]+\\))")
lgaNSW <- lgaNSW %>% select(-lgaNamesNSW)

# clean and merge -- pass 1
rawVenues$lgaNameClean <- str_remove(rawVenues$LGA,'( City Council)|( Shire Council)| Council')

rawVenuesLGA <- left_join(rawVenues,lgaNSW, by="lgaNameClean")

needToClean <- rawVenuesLGA %>% filter(is.na(lgaIDsNSW)) %>% group_by(LGA,lgaNameClean) %>% summarise(n=n())
write.csv(needToClean[,2],file=paste(filePath,'cleanMe.csv',sep=''))
cleanedLGAs <- read.csv(file=paste(filePath,'cleanLGA.csv',sep=''))

# clean and merge -- pass 2
lgaNSW <- rbind(lgaNSW,cleanedLGAs)
rawVenuesLGA <- left_join(rawVenues,lgaNSW, by="lgaNameClean")
needToClean <- rawVenuesLGA %>% filter(is.na(lgaIDsNSW)) %>% group_by(LGA,lgaNameClean) %>% summarise(n=n())
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
                         lgaIDsNSW,
                         EGMs)

# export as JSON -- break into individual files
lgaIDs <- unique(keepVenues$lgaIDsNSW)

for (i in 1:length(lgaIDs)) {
  extract <- keepVenues %>% filter(lgaIDsNSW == lgaIDs[i])
  json <- toJSON(extract)
  write(json, file=paste(filePath,lgaIDs[i],'-venues.json',sep=''))
} 






