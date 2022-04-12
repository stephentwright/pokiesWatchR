library(readxl)
library(tidyverse)
library(jsonlite)
library(scales)

# load profits per LGA
filePath <- './dataExtract/population/'
fileName <- 'erp-age-sex-lga-2020.xls'

population <- read_xls(path = paste(filePath,fileName,sep=''),sheet='Table 3', skip = 7) %>%
                filter(`ASGS 2020` == '1')
dropCols <- c(1,2,4,5,6,7,23)
populationSelect <- population %>%
                      select(-all_of(dropCols)) %>%
                        mutate(`18–19`=as.numeric(`15–19`) * 0.2) %>%
                          select(-`15–19`)

adults <-as.data.frame(populationSelect, char=as.numeric(char)) %>% rename(lgaCode=`...3`)
adults[ , c(2:16)] <- apply(adults[ , c(2:16)], 2, function(x) as.numeric(as.character(x)))
adults$adults <- floor(rowSums(adults[,-1],na.rm = T))
adultsLga <- adults %>% select(lgaCode,adults)
nsw <- data.frame(lgaCode='nsw',adults=sum(adultsLga$adults))

adultsLga <- rbind(adultsLga,nsw)

save(adultsLga,file='./dataExtract/r-data/adultsLga.dat')
