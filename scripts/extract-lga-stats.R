library(readxl)
library(tidyverse)
library(jsonlite)
library(scales)


# load profits per LGA
filePath <- 'dataExtract/clubs/'
fileName <- 'clubs-gaming-machine-lga-report-20201201-to-20210531.xlsx'

rawNetProfit <- read_xlsx(path = paste(filePath,fileName,sep=''),sheet='Clubs', skip = 3)
rawNetProfit <- rawNetProfit %>%
                  arrange(desc(`Net Profit`)) %>%
                    mutate(rank = row_number()-1,
                           profit = dollar(round(`Net Profit`/1000)*1000),
                           tax = dollar(round(Tax/1000)*1000))

# Assign NSW Total
rawNetProfit$`Local Government Area (LGA)`[is.na(rawNetProfit$`Local Government Area (LGA)`)] <- 'NSW'

# Split Rows where boundaries have been colapsed
expandNetProfit <- rawNetProfit %>%
                      mutate(lgaName = strsplit(`Local Government Area (LGA)`, "\r\n")) %>%
                        unnest(lgaName) %>%
                          filter(lgaName != "")

# Add the LGA codes
load(file='./dataExtract/r-data/lgaNSW.dat')
lgaNSW$lgaNameClean <- str_remove_all(lgaNSW$lgaNamesNSW,pattern="( \\s*\\([^\\)]+\\))")
lgaNSW <- lgaNSW %>% select(-lgaNamesNSW)

# Patch names on the Pokies reports
addShire <- c('Greater Hume','Sutherland','The Hills','Upper Hunter','Upper Lachlan','Warrumbungle');
addRegional <- c('Queanbeyan-Palerang','Bathurst','Armidale','Snowy Monaro','Cootamundra-Gundagai')
addValley <- c('Nambucca')
recode <- 'Unincorporated Far West'

expandNetProfit <- expandNetProfit %>%
                      mutate(lgaName = if_else(lgaName %in% addShire,paste(lgaName,'Shire'),lgaName),
                             lgaName = if_else(lgaName %in% addRegional,paste(lgaName,'Regional'),lgaName),
                             lgaName = if_else(lgaName %in% addValley,paste(lgaName,'Valley'),lgaName),
                             lgaName = if_else(lgaName %in% recode,'Unincorporated NSW',lgaName))

# merge on LGA code
expandNetProfit <- left_join(expandNetProfit,lgaNSW, by=c("lgaName"="lgaNameClean"))
expandNetProfit <- expandNetProfit %>%
                    mutate(lgaIdNSW = if_else(lgaName=='NSW','nsw',lgaIdNSW),
                           lgaNameCombine = `Local Government Area (LGA)`)

# load up the Adult population per LGA
load(file='./dataExtract/r-data/adultsLga.dat')
expandNetProfit <- left_join(expandNetProfit,adultsLga,by=c('lgaIdNSW'='lgaCode'))
adultsCombined <- expandNetProfit %>%
                    group_by(`Local Government Area (LGA)`) %>%
                      summarise(popCombine=sum(adults))
expandNetProfit <- left_join(expandNetProfit,adultsCombined)



# calculate the featured statistic;
expandNetProfit <- expandNetProfit %>%
                    mutate(featuredStat=floor(`Net Profit`/popCombine/18))

# Todo: need to fix up the groups for combined.

# prepare data for JSON dump
keepLGAData <- expandNetProfit %>%
               select(lgaIdNSW,
                      lgaName,
                      lgaNameCombine,
                      adults,
                      combineAdults,
                      rank,
                      profit,
                      tax,
                      featuredStat,
                      `Premises Count`,
                      `Electronic Gaming Machine numbers\r\nas at 30 May 2021`) %>%
               rename(EGMs=`Electronic Gaming Machine numbers\r\nas at 30 May 2021`,
                      premisesCount=`Premises Count`);

# export as JSON -- break into individual files
lgaId <- unique(keepLGAData$lgaIdNSW)

for (i in 1:length(lgaId)) {
  extract <- keepLGAData %>% filter(lgaIdNSW == lgaId[i])
  json <- toJSON(extract)
  write(json, file=paste('./dataExtract/web-output/',lgaId[i],'-stats.json',sep=''))
}


