library(readxl)
library(tidyverse)
library(jsonlite)

# load profits per LGA
filePath <- 'D:/Repositories/pokies-watch/prototype-html-css-js/resources/statistics/'
fileName <- 'Clubs-gaming-machine-lga-report-1-Dec-2020-to-31-May-2021.xlsx'

rawNetProfit <- read_xlsx(path = paste(filePath,fileName,sep=''),sheet='Clubs', skip = 3)

# Add the LGA codes
filePath2 <- 'D:/Repositories/pokies-watch/prototype-html-css-js/resources/premises/'
load(file=paste(filePath2,'lgaNSW.dat',sep=''))
lgaNSW$lgaNameClean <- str_remove_all(lgaNSW$lgaNamesNSW,pattern="( \\s*\\([^\\)]+\\))")
lgaNSW <- lgaNSW %>% select(-lgaNamesNSW)

# clean and merge -- pass 1
## ToDo - there is a break character we could use to split out the label into each LGA
##        something to consider later on
rawNetProfit$lgaNameClean <- rawNetProfit$`Local Government Area (LGA)`
rawNetProfitLGA <- left_join(rawNetProfit,lgaNSW, by="lgaNameClean")

# prepare data for JSON dump
keepLGAData <- rawNetProfitLGA %>% 
                filter(!is.na(lgaIDsNSW)) %>%
                  select(lgaIDsNSW,
                         lgaNameClean,
                         `Net Profit`,
                         Tax,
                         `Premises Count`,
                         `Electronic Gaming Machine numbers\r\nas at 30 May 2021`) %>%
                    rename(EGMs=`Electronic Gaming Machine numbers\r\nas at 30 May 2021`)

# export as JSON -- break into individual files
lgaIDs <- unique(keepLGAData$lgaIDsNSW)

for (i in 1:length(lgaIDs)) {
  extract <- keepLGAData %>% filter(lgaIDsNSW == lgaIDs[i])
  json <- toJSON(extract)
  write(json, file=paste(filePath,lgaIDs[i],'-stats.json',sep=''))
} 


