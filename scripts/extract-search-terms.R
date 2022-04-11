library(readxl)
library(stringr)
library(tidyverse)
library(jsonlite)

# create the list of available search terms to use
filePath = 'D:\\Repositories\\pokies-watch\\prototype-html-css-js\\resources\\correspondences\\'

#postcodes incl suburn names (master list see https://github.com/matthewproctor/australianpostcodes)
fileNamePostcodes = 'australian_postcodes.csv'
rawPostcodes <- read.csv(paste(filePath,fileNamePostcodes,sep=''))
NSWPostcodesNSW <- rawPostcodes %>% filter(state=='NSW') %>% select(postcode,locality)

#lga codes linked to postcodes
fileNamePostcodeLGA <- 'CG_POSTCODE_2019_LGA_2020.xls'
sheetName <- 'Table 3'
rawPostcodeLGA <- read_xls(path=paste(filePath,fileNamePostcodeLGA,sep=''),
                            sheet=sheetName,
                            skip=5)

NSWPostcodeLGA <- rawPostcodeLGA %>% 
                    filter(substr(LGA_CODE_2020,1,1)=='1',
                                  RATIO>0.85) %>%
                      mutate(postcode=as.integer(POSTCODE_2019))
                    

#join files to create the list
searchList <- left_join(NSWPostcodesNSW,NSWPostcodeLGA, by="postcode") %>%
                  filter(!is.na(RATIO)) %>%
                    mutate(lgaClean=str_remove_all(LGA_NAME_2020,pattern="( \\s*\\([^\\)]+\\))"))

#get list of LGAs
searchListLGA <- searchList %>% 
                      group_by(lgaClean, LGA_CODE_2020) %>% summarise(n=n()) %>%
                        rename(searchTerm=lgaClean) %>%
                          mutate(lgaClean=searchTerm)

#get list of Postcode
searchListPostcode <- searchList %>% 
                        group_by(postcode,lgaClean, LGA_CODE_2020) %>% 
                          summarise(n=n()) %>%
                            mutate(postcode=as.character(postcode)) %>%
                              rename(searchTerm=postcode);

#get list of Suburbs
searchListSuburbs <-  searchList %>% 
                        group_by(locality, lgaClean, LGA_CODE_2020) %>% 
                          summarise(n=n()) %>%
                            rename(searchTerm=locality);

## prep data for joining and exporting
data <- rbind(searchListLGA,searchListSuburbs,searchListPostcode) %>% 
          mutate(searchTerm=tolower(searchTerm),LGA_CODE_2020=as.character(LGA_CODE_2020)) %>%
            select(searchTerm,lgaClean,LGA_CODE_2020) %>% distinct()

json <- toJSON(data)
write(json, file=paste(filePath,'searchTerms.json',sep=''))