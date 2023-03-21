################################################################################
#                                                                              #
# Project: Population segmentation and transition probability estimation       #
#     using data on health and health-related social service needs from the    # 
#     US Health and Retirement Study                                           #
# Project section: Transition probability estimation                           #
# R version: 4.2.1                                                             #
# File name: 03_HS_statistics.R                                                #
# Data required: data_msm_HS.RDATA                                             #
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

packages <- c('msm','gridExtra', 'grid', 'lattice', 'readr', 'dplyr', 
              'data.table', 'ggplot2') 

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
# Import data                                                                  #
#                                                                              #
################################################################################

# Interview observations (panel data)
#load("~/Health_and_Retirement_Study/HRS_markov/00_data/dataT.RData")

# Transition probabilities (msm-fitted model)
load("~/Health_and_Retirement_Study/HRS_markov/00_data/data_msm_HS.RData")
HS.msm <- data_msm_GI[["30000"]]

################################################################################
#                                                                              #
# Extract statistics                                                           #
#                                                                              #
################################################################################


#===============================================================================
# Q Matrix
#===============================================================================

#-------------------------------------------------------------------------------
# Define initial Transition Intensity Matrix
#-------------------------------------------------------------------------------

############### I_0            I_1           II_0          II_1          
#               III_0         III_1         IV_0          IV_1          
#               V_0            V_1          Dead
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







#-------------------------------------------------------------------------------
# Fit Q-matrix
#-------------------------------------------------------------------------------

(HS_qmat <- qmatrix.msm(HS.msm, ci=c("normal"), cl=0.95, B=1000000, cores=NULL))

# save created variable
save(HS_qmat, file = "00_data/HS_qmat.RData")

# create csv files to save
HS_qmat_estimates <- HS_qmat$estimates
HS_qmat_L <- HS_qmat$L
HS_qmat_U <- HS_qmat$U
HS_qmat_SE <- HS_qmat$SE

# save csv files
write.csv(HS_qmat_estimates, "00_data/HS_qmat_estimates.csv")
write.csv(HS_qmat_L, "00_data/HS_qmat_L.csv")
write.csv(HS_qmat_U, "00_data/HS_qmat_U.csv")
write.csv(HS_qmat_SE, "00_data/HS_qmat_SE.csv")

#-------------------------------------------------------------------------------
# Fit P(t)-matrix: Transition probability matrix
#-------------------------------------------------------------------------------

HS_pmat <- pmatrix.msm(x=HS.msm, t=1, ci=c("normal"), cl=0.95, B=1000000)

# save created R variable
save(HS_pmat, file = "00_data/HS_pmat.RData")

# create csv files to save
HS_pmat_estimates <- HS_pmat$estimates
HS_pmat_L <- HS_pmat$L
HS_pmat_U <- HS_pmat$U
HS_pmat_SE <- HS_pmat$SE

# save csv files
write.csv(HS_pmat_estimates, "00_data/HS_pmat_estimates.csv")
write.csv(HS_pmat_L, "00_data/HS_pmat_L.csv")
write.csv(HS_pmat_U, "00_data/HS_pmat_U.csv")
write.csv(HS_pmat_SE, "00_data/HS_pmat_SE.csv")

#-------------------------------------------------------------------------------
# Hazard
#-------------------------------------------------------------------------------

###complete
#HS.hazard <- hazard.msm(HS.msm, hazard.scale = 1)


#-------------------------------------------------------------------------------
# Probability that each state is next
#-------------------------------------------------------------------------------

HS_pnext <- pnext.msm(HS.msm, ci=c("normal"), cl = 0.95, B=1000000, cores=NULL)

# save created variable
save(HS_pnext, file = "00_data/HS_pnext.RData")

# create csv files to save
HS_pnext_estimates <- HS_pnext$estimates
HS_pnext_L <- HS_pnext$L
HS_pnext_U <- HS_pnext$U
HS_pnext_SE <- HS_pnext$SE

# save csv files
write.csv(HS_pnext_estimates, "00_data/HS_pnext_estimates.csv")
write.csv(HS_pnext_L, "00_data/HS_pnext_L.csv")
write.csv(HS_pnext_U, "00_data/HS_pnext_U.csv")
write.csv(HS_pnext_SE, "00_data/HS_pnext_SE.csv")

#-------------------------------------------------------------------------------
# Sojourn times
#-------------------------------------------------------------------------------

HS_sojourn <- sojourn.msm(HS.msm, ci=c("normal"), cl=0.95, B=1000000)

# save created variable
save(HS_sojourn, file = "00_data/HS_sojourn.RData")

# create csv files to save
HS_sojourn_estimates <- HS_sojourn$estimates
HS_sojourn_L <- HS_sojourn$L
HS_sojourn_U <- HS_sojourn$U
HS_sojourn_SE <- HS_sojourn$SE

# save csv files
write.csv(HS_sojourn_estimates, "00_data/HS_sojourn_estimates.csv")
write.csv(HS_sojourn_L, "00_data/HS_sojourn_L.csv")
write.csv(HS_sojourn_U, "00_data/HS_sojourn_U.csv")
write.csv(HS_sojourn_SE, "00_data/HS_sojourn_SE.csv")
