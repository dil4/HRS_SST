################################################################################
#                                                                              #
# Project: Population segmentation and transition probability estimation       #
#     using data on health and health-related social service needs from the    # 
#     US Health and Retirement Study                                           #
# Project section: Transition probability estimation                           #
# R version: 4.2.1                                                             #
# File name: 01_transition_probability.R                                       #
# Data required: dataT.RDATA                                                   #
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

packages <- c('msm','gridExtra', 'readr', 'dplyr', 'data.table', 'parallel', 
              'doParallel') 

lapply(packages, function(x)
  if( !require(x, character.only = TRUE)){
    install.packages(x, dependencies = TRUE)
    library(x, character.only = TRUE)
  } else {
    library(x, character.only = TRUE)
  })

rm(packages)

################################################################################
#                                                                              #
# Import data                                                                  #
#                                                                              #
################################################################################

load("C:/Users/LizeDuminy/data/HRS/data/dataT.RData")


#Remove censored data to simplify the model
dataT <- dataT[dataT$HS<100,]


################################################################################
#                                                                              #
# Transition Probabilities                                                     #
#                                                                              #
################################################################################


#===============================================================================
# Define initial Transition Intensity Matrix
#===============================================================================

############### I_0            I_1           II_0          II_1          
################III_0         III_1         IV_0          IV_1          
################V_0            V_1          Dead
Q_HS <- rbind(c(0,             0.005327283,  0.032481626,  0.002885611,  
                0.031889706,  0.007029053,  0.012134366,  0.002589651,  
                0.0025896513,  0.001849751, 0.009322745), #I_0   
              c(0.0196887901,  0,            0.006351223,  0.020323912,  
                0.008891712,  0.045728803,  0.003810734,  0.019053668,  
                0.0025404890,  0.007621467, 0.020323912), #I_1 
              c(0.0059707002,  0.000240754,  0,            0.012567361,  
                0.056962406,  0.017093537,  0.007993034,  0.003707612,  
                0.0014926751,  0.002455691, 0.011893250), #II_0 
              c(0.0009741248,  0.001948250,  0.025814307,  0,            
                0.015585997,  0.069649924,  0.002191781,  0.012907154,  
                0.0004870624,  0.007792998, 0.024109589), #II_1 
              c(0.0000000000,  0.000000000,  0.016490029,  0.002241613,  
                0,            0.040555164,  0.010074377,  0.006467183,  
                0.0096105948,  0.013295086, 0.025611076), #III_0
              c(0.0000000000,  0.000000000,  0.002187768,  0.008705494,  
                0.022196732,  0,            0.003372809,  0.018322559,  
                0.0024612393,  0.033545780, 0.046991439), #III_1   
              c(0.0000000000,  0.000000000,  0.000000000,  0.000000000,  
                0.052727819,  0.019813870,  0,            0.018831364,  
                0.0072050435,  0.010480063, 0.045031522), #IV_0 
              c(0.0000000000,  0.000000000,  0.000000000,  0.000000000,  
                0.011164439,  0.045366610,  0.007265746,  0,            
                0.0023037732,  0.029594625, 0.098885033), #IV_1 
              c(0.0000000000,  0.000000000,  0.000000000,  0.000000000,  
                0.034646549,  0.019478705,  0.004949507,  0.003831876,  
                0,             0.064662915, 0.066259530), #V_0 
              c(0.0000000000,  0.000000000,  0.000000000,  0.000000000,  
                0.005228908,  0.025167713,  0.000861908,  0.008504159,  
                0.0074124086,  0,           0.096648614), #V_1
              c(0.0000000000,  0.000000000,  0.000000000,  0.000000000,  
                0.000000000,  0.000000000,  0.000000000,  0.000000000,  
                0.0000000000,  0.000000000, 0.000000000)) #Dead

################################################################################
#                                                                              #
# Fit msm to GI segments                                                       #
#                                                                              #
################################################################################

# create fnscale variable
# x <- seq(500, 21000, 1000) #if model does not converge, try different fnscales

x <- 30000

# split fnscale variable into lists
x <- split(x, f = x) 

dataT <- as.data.frame(dataT)

f_data_msm_GI <- function(x) {
  print(x)
  return(tryCatch(msm(formula = HS ~ years, subject = hhidpn, data = dataT, 
                      qmatrix = Q_HS,     obstype = obstype, censor = 999, 
                      control = list(fnscale = x, maxit = 10000, trace = 2, 
                                     REPORT = 1))))
  }

# apply function to list
data_msm_GI <- lapply(x, f_data_msm_GI)
# save created variable
save(data_msm_GI, file = "C:/Users/LizeDuminy/data/HRS/data/data_msm_GI.RData")


