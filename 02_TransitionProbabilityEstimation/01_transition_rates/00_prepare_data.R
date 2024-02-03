################################################################################
#                                                                              #
# Project: Population segmentation and transition probability estimation       #
#     using data on health and health-related social service needs from the    # 
#     US Health and Retirement Study                                           #
# Project section: Transition probability estimation                           #
# R version: 4.2.1                                                             #
# File name: 00_prepare_data.R                                                 #
# Data required: data_GI_CF.csv                                                #
# Author: Lize Duminy                                                          #
# Date: 2023.03.19                                                             #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
# STUDY SETUP                                                                  #
#                                                                              #
################################################################################

#===============================================================================
# Clear workspace
#===============================================================================

rm(list=ls())
save.image()
graphics.off()
gc()

#===============================================================================
# Set memory
#===============================================================================

#options(java.parameters = "-Xmx3000m")

#===============================================================================
# Load packages
#===============================================================================

packages <- c('msm','gridExtra', 'readr', 'dplyr', 'data.table') 

lapply(packages, function(x)
  if( !require(x, character.only = TRUE)){
    install.packages(x, dependencies = TRUE)
    library(x, character.only = TRUE)
  } else {
    library(x, character.only = TRUE)
  })

rm(packages)

# Re-assign select to avoid MASS dplyr conflict
select <- dplyr::select


################################################################################
#                                                                              #
# User Interface                                                               #
#                                                                              #
################################################################################

# Select time scale of model: t_scale
#-------------------------------------------------------------------------------
# 1 - time elapsed from first interview
# 2 - time elapsed from first-ever SHARE interview
# 3 - time elapsed from 50th birthday
t_scale <- 2

################################################################################
#                                                                              #
# Prepare data                                                                 #
#                                                                              #
################################################################################
dataT <- NULL
dataT_t_bir_sample <- NULL


data_GI_CF <- read_csv("00_data/data_GI_CF.csv")



#Fetch data
dataT <- data_GI_CF[, c("hhidpn", "wave", "iwyear", "iwmonth", "birthyr", 
                        "birthmo", "knowndeceasedmo", "knowndeceasedyr", 
                        "gender", "GI", "CF", "lastalivemo", "lastaliveyr")]
rm(data_GI_CF)

#Total number of observations
(n1 <- nrow(dataT))


#===============================================================================
# Clean Data
#===============================================================================
#Remove unusable observations

#Everyone with an unknown health state is treated as censored
#since we know that they are alive but do not know their health state
dataT$GI[dataT$GI==-3] <- 999

#Change the "death state" value to 
dataT$GI[dataT$GI==-6] <- 6

#Create HS variable from GI and CF variables
dataT["HS"] <- 0
dataT$HS[dataT$GI==999] <- 999
dataT$HS[dataT$GI==6] <- 11
dataT$HS[dataT$GI==1&(dataT$CF==0|dataT$CF==-3)] <- 1
dataT$HS[dataT$GI==1&dataT$CF==1] <- 2
dataT$HS[dataT$GI==2&(dataT$CF==0|dataT$CF==-3)] <- 3
dataT$HS[dataT$GI==2&dataT$CF==1] <- 4
dataT$HS[dataT$GI==3&(dataT$CF==0|dataT$CF==-3)] <- 5
dataT$HS[dataT$GI==3&dataT$CF==1] <- 6
dataT$HS[dataT$GI==4&(dataT$CF==0|dataT$CF==-3)] <- 7
dataT$HS[dataT$GI==4&dataT$CF==1] <- 8
dataT$HS[dataT$GI==5&(dataT$CF==0|dataT$CF==-3)] <- 9
dataT$HS[dataT$GI==5&dataT$CF==1] <- 10

table(dataT$HS)
table(dataT$GI)


#
# Time of birth
#-------------------------------------------------------------------------------


#Create column for time of birth
dataT$t_bir <- ifelse(dataT$birthyr>0 & dataT$birthmo>0, 
                      dataT$birthyr+(dataT$birthmo-1)/12, NA)
#Number of observations not assigned a time of birth
length(which(is.na(dataT$t_bir)))
#identify rows with known birth year but unknown month 
dataT$known_year <- (is.na(dataT$t_bir)&
                       ((is.na(dataT$birthmo)|dataT$birthmo<0)&
                          (!is.na(dataT$birthyr)&dataT$birthyr>0)))
#Assign time of birth to observations with known birth year but unknown month.
#Assume birth occurs middle of the year
dataT$t_bir[dataT$known_year] <- dataT$birthyr[dataT$known_year] + 0.5
#Number of observations not assigned a time of birth
length(which(is.na(dataT$t_bir)))


#######


#detect inconsistencies in time of birth reported per individual
dataT <- dataT %>%
  group_by(hhidpn) %>%
  arrange(hhidpn, wave) %>%
  mutate(t_bir_unclear = ifelse(lag(t_bir, 
                                    default = first(t_bir))!=t_bir, 1, 0)) %>%
  ungroup()
#assign NAs as 1 since t_bir_unclear is NA if birth year is unknown
dataT$t_bir_unclear[is.na(dataT$t_bir_unclear)] <- 1
#Number of inconsistent times of birth
length(which(dataT$t_bir_unclear==1))

#Create a list of all individuals with inconsistencies in their time of birth 
dataTu <- dataT[dataT$t_bir_unclear==1, "hhidpn"]
dataTu <- as.data.table(unique(dataTu))
#Number of individuals with inconsistent birth times
nrow(dataTu)
#Fraction of total individuals with inconsistent birth times
nrow(dataTu)/nrow(unique(dataT))

#identify all observations of individuals with inconsistencies in time of birth
dataT$t_bir_unclear <- dataT$hhidpn %in% dataTu$hhidpn


#define a list containing all potential times of birth for each individual
dataT_t_bir_sample <- dataT[dataT$t_bir_unclear==TRUE,]
#Number of unique individuals in the sample
length(unique(dataT_t_bir_sample$hhidpn))


#remove all times of birth assigned in previous step
dataT_t_bir_sample <- dataT_t_bir_sample[dataT_t_bir_sample$known_year==FALSE,]
#Number of unique individuals in the sample
length(unique(dataT_t_bir_sample$hhidpn))

#identify the median time of birth
dataT_t_bir_sample <- dataT_t_bir_sample %>%
  group_by(hhidpn) %>%
  arrange(hhidpn, wave) %>%
  summarise(t_bir_median = median(t_bir)) %>%
  ungroup()
nrow(dataT_t_bir_sample)

#add median age into main dataset dataT
dataT <- full_join(dataT, dataT_t_bir_sample, by = c("hhidpn" = "hhidpn"))

#replace time of birth with median time of birth
dataT$t_bir[dataT$t_bir_unclear==TRUE] <- dataT$t_bir_median[dataT$t_bir_unclear
                                                             ==TRUE]


#Filter out all observations without a time of birth
dataT <- dataT[!is.na(dataT$t_bir),]
#Total number of observations
(n4 <- nrow(dataT))
#Number of observations filtered out
#(n3 - n4)


#===============================================================================
# Create "age" Variable
#===============================================================================

#
# Time of interview
#-------------------------------------------------------------------------------

#Create column for time of interview
dataT$t_int <- dataT$iwyear+(dataT$iwmonth-1)/12
#Number of alive observations not assigned a time of interview 
#i.e. did not participate in the end-of-life interview 
#where death date is recorded
length(which(is.na(dataT$t_int)))

#identify the mean interview time per interview wave 
dataT <- dataT %>%
  group_by(wave) %>%
  mutate(t_int_med = median(t_int, na.rm = TRUE)) %>%
  ungroup()

#assign the median interview time per wave per country to interviews with NA
dataT$t_int[which(is.na(dataT$t_int))] <- dataT$t_int_med[which(is.na
                                                                (dataT$t_int))]

#
# Time of death
#-------------------------------------------------------------------------------

#Create column for time of death
dataT$t_dea <- ifelse(dataT$knowndeceasedyr>0 & dataT$knowndeceasedmo>0, 
                      dataT$knowndeceasedyr+(dataT$knowndeceasedmo-1)/12, NA)
#Number of deceased observations not assigned a time of death
length(which(is.na(dataT$t_dea)&dataT$GI==6))

#Check if time of death makes sense (individual must have died after last 
#time they participated in interview)
dataT <- dataT %>%
  group_by(hhidpn) %>%
  arrange(hhidpn, wave) %>%
  mutate(t_dea_check = ifelse(t_dea-lag(t_int)>0,1,0)) %>%
  ungroup()

#Remove illogical death dates
dataT$t_dea[dataT$t_dea_check==0] <- NA
#Number of deceased observations not assigned a time of death
length(which(is.na(dataT$t_dea)&dataT$GI==6))

#
# Create age_years variable
#-------------------------------------------------------------------------------
# 
dataT$age_years <- 0
# dataT$age_years <- dataT$t_int - dataT$t_bir

#Assign all observations the age at time of interview
dataT$age_years[dataT$GI!=6] <- (dataT$t_int[dataT$GI!=6] - 
                                   dataT$t_bir[dataT$GI!=6])

#If deceased and exact death date is known, assign exact age at death
dataT$age_years[(!is.na(dataT$t_dea)
                 &dataT$GI==6)] <- dataT$t_dea[(!is.na(dataT$t_dea)&
                                                  dataT$GI==6)] - 
  dataT$t_bir[(!is.na(dataT$t_dea)&dataT$GI==6)]

#===============================================================================
# Create "years" Variable
#===============================================================================

dataT <- dataT %>%
  group_by(hhidpn) %>%
  arrange(hhidpn, wave) %>%
  mutate(years_int = age_years - first(age_years)) %>%
  ungroup()

dataT$years_cal <- dataT$t_int - min(dataT$t_int)

dataT$years_age <- dataT$age_years



# Select time scale of model: t_scale
#-------------------------------------------------------------------------------
# 1 - time elapsed from first interview of individual
# 2 - time elapsed from first-ever SHARE interview (calendar time)
# 3 - indivdual age

if (t_scale == 1) {
  dataT$years <- dataT$years_int
} else if (t_scale == 2) {
  dataT$years <- dataT$years_cal
} else if (t_scale == 3) {
  dataT$years <- dataT$years_age
  # dataT[dataT$years>=49&dataT$years<50, "years"] <- 50
  # dataT$years_age <- dataT$years
  dataT <- dataT[dataT$years>=50, ]
}

#Filter out all individuals with only one observation
dataT <- dataT %>%
  group_by(hhidpn) %>%
  arrange(hhidpn, wave) %>%
  mutate(obs_group = n()) %>%
  ungroup()
dataT <- dataT[dataT$obs_group!=1,]
#Total number of observations
#(n3 <- nrow(dataT))
#Number of observations filtered out
#(n2 - n3)

#===============================================================================
# Create "age_cat" Variable
#===============================================================================


labs <- c(paste(seq(50, 90 - 10, by = 10), seq(50 + 10 - 1, 90 - 1, by = 10),
                sep = "-"), paste(90, "+", sep = ""))
dataT$age_cat <- cut(dataT$age_years, breaks = c(seq(50, 90, by = 10), Inf), 
                     labels = labs, right = FALSE)
rm(labs)

labs5 <- c(paste(seq(50, 90 - 5, by = 5), seq(50 + 5 - 1, 90 - 1, by = 5),
                 sep = "-"), paste(90, "+", sep = ""))
dataT$age_cat5 <- cut(dataT$age_years, breaks = c(seq(50, 90, by = 5), Inf), 
                      labels = labs5, right = FALSE)
rm(labs5)


#===============================================================================
# Create "firstobs" Variable
#===============================================================================

dataT <- dataT %>%
  group_by(hhidpn) %>%
  arrange(hhidpn, wave) %>%
  mutate(obs_num = row_number()) %>%
  ungroup()
dataT$firstobs <- ifelse(dataT$obs_num==1, 1, 0)


#===============================================================================
# Create "obstype" Variable
#===============================================================================
#Specifying the type of observation scheme. See msm manual for description of 
#obstype options

#Obstype 1: An observation of the process at an arbitrary time (a "snapshot" of 
#the process, or "panel-observed" data). The states are unknown between 
#observation times.

#Start by assigning all entries an obstype 1
dataT$obstype <- 1

length(which(is.na(dataT$t_dea)&dataT$GI==6))
length(which(!is.na(dataT$t_dea)&dataT$GI==6))

#Obstype 3: An exact transition time, but the state at the instant before 
#entering this state is unknown. A common example is death times in studies of 
#chronic diseases.

#Assign individuals where the exact death date is known obstype 3
dataT$obstype[!is.na(dataT$t_dea)&dataT$GI==6] <- 3

#===============================================================================
# Rescale time variable to "montGI" and "days"
#===============================================================================
#To help with convergence 

dataT$age_montGI <- dataT$age_years*12
dataT$montGI <- dataT$years*12

dataT$age_days <- dataT$age_years*365
dataT$days <- dataT$years*365

dataT$age_decades <- dataT$age_years/10
dataT$decades <- dataT$years/10


#===============================================================================
# Final Dataset
#===============================================================================

#Ommit unnecessary columns
dataT <- dataT[, c("hhidpn", "wave", "age_years", "years", "age_cat", 
                   "age_cat5", "age_montGI", "montGI", "age_days", "days", 
                   "decades", "age_decades", "gender", "GI", "HS", "firstobs", 
                   "obstype")]
#Total number of observations
(n5 <- nrow(dataT))         


#===============================================================================
# Save Dataset
#===============================================================================

save(dataT, file = "00_data/dataT.RData")
