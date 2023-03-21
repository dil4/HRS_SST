################################################################################
#                                                                              #
# Project: Population segmentation and transition probability estimation       #
#     using data on health and health-related social service needs from the    # 
#     US Health and Retirement Study                                           #
# Project section: Transition probability estimation                           #
# R version: 4.2.1                                                             #
# File name: 02_markov_trace_HS.R                                              #
# Data required: dataT.RData, data_msm_HS.RData                                #
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
load("~/Health_and_Retirement_Study/HRS_markov/00_data/dataT.RData")
 
# Transition probabilities (msm-fitted model)
load("~/Health_and_Retirement_Study/HRS_markov/00_data/data_msm_HS.RData")


################################################################################
#                                                                              #
# Prepare reference dataset (HRS)                                              #
#                                                                              #
################################################################################

#===============================================================================
# Extract target cohort
#===============================================================================


# Look at interview opportunities since target age
###### Select age to investigate

agex <- c(50:120)
int_wavex <- c(9)
HSx <- c(1:10)


#q <- dataT[dataT$HS!=999,]
q <- dataT

#round age to nearest whole number
q$age_round <- floor(q$age_years) 

#identify everyone that were "agex" years old in interview wave "int_wavex" 
q2 <- q[(q$age_round %in% agex) & (q$wave %in% int_wavex) & (q$HS %in% HSx),]


#cut down dataset to include only entries of individuals who were "agex" 
#years old during interview wave "int_wavex"
q <- q[q$hhidpn %in% q2$hhidpn,]
rm(q2)




#-------------------------------------------------------------------------------
# Continue with preparing the data
#-------------------------------------------------------------------------------


#Save the sample size for reporting purposes 
n_sample <- length(unique(q$hhidpn))


q <- q %>%
  filter(wave >= min(int_wavex)) %>% #exclude entries of recorded before 
                                     #interview wave "int_wavex"
  group_by(hhidpn) %>%
  arrange(hhidpn, age_round) %>%
  mutate(int_op = (wave - first(wave))*2) %>% #the number of interview 
                                              #opportunities since agex
  ungroup()


#Save current dataset to be fitted with msm later in the code
dataT2 <- q

q <- q %>%
  group_by(int_op, HS) %>%
  mutate(HS_tot = n()) %>%
  slice(1) %>%
  select(int_op, HS, HS_tot) %>%
  ungroup()

#create new dataset with only deatHS as deatHS need to be reported cumulatively
#and remove deatHS from original dataset
q11 <- q[q$HS==11,]
q <- q[q$HS!=11,]

#create a death row for every single interview opportunity to correctly 
#estimate cumulative deatHS 
q11.2 <- as.data.table(unique(q$int_op))
q11 <- merge(q11, q11.2, by.x = "int_op", by.y = "V1", all = TRUE)
rm(q11.2)
q11[,"HS"] <- 11
q11[is.na(q11$HS_tot),"HS_tot"] <- 0

#calculate the cumulative number of deatHS per age group
q11 <- q11 %>%
  arrange(int_op) %>%
  mutate(HS_tot_cum = cumsum(HS_tot))

#re-assign variable HS_tot the cumulative total
q11$HS_tot <- q11$HS_tot_cum

#drop the variable HS_tot_cum
q11$HS_tot_cum <- NULL


#joint two datasets together
q <- rbind(q, q11)
rm(q11)

#fractional HS per age
q <- q %>%
  group_by(int_op) %>%
  mutate(HS_frac = HS_tot/sum(HS_tot)) %>%
  mutate(group = "Data") %>%
  arrange(int_op, HS) %>%
  filter(HS!=999) %>%
  ungroup() %>%
  select(int_op, HS, HS_frac, group)


#-------------------------------------------------------------------------------
# Ensure only every second interview opportunity is included
#-------------------------------------------------------------------------------

#extract interview opportunities listed in dataset
int_ops <- unique(q$int_op) 

#select every second wave 
#(persons are interviewed in-person only every second wave)
int_ops <- int_ops[seq(1, length(int_ops), 2)]

#constrain results to 
q <- q[q$int_op %in% int_ops,]
rm(int_ops)

################################################################################
#                                                                              #
# Run Markov trace                                                             #
#                                                                              #
################################################################################

#decide to make x-axis calander time with years starting at 0 for 1st interview
dataT2 <- dataT2 %>%
  group_by(hhidpn) %>%
  mutate(years = age_years - first(age_years)) %>%
  ungroup()

# fetch estimated transition probabilities
model <- data_msm_GI[["30000"]]
(pmat.msm <- pmatrix.msm(model, t=1, ci=c("normal"), cl=0.95, B=1000)$estimates)


#Reduce columns
q <- q %>%
  select(int_op, HS, HS_frac, group)


#===============================================================================
# Markov model
#===============================================================================

maxtime <- max(q$int_op)+1
j_init <- q[q$int_op==0,c("HS", "HS_frac")]
j_init2 <- as.data.table(1:11)
j_init <- merge(j_init, j_init2, by.x = "HS", by.y = "V1", all = TRUE)
rm(j_init2)
j_init[is.na(j_init$HS_frac),"HS_frac"] <- 0
j_init <- t(j_init$HS_frac)
#Markov Model: using pmatrix determined by msm to model future health prevalence
j <- NULL
for(i in 1:maxtime) {
  if (i == 1) {
    j <- j_init
  } else {
    iprev <- i-1
    k <- as.double(j[iprev,1:11]) %*% pmat.msm
    j <- rbind(j,k)
  }}
rownames(j) <- 1:nrow(j)
int_op <- nrow(j)-1
int_op <- 0:int_op
j <- cbind(j,int_op) 
rm(j_init, k, iprev, int_op, maxtime)


################################################################################
#                                                                              #
# Plot results                                                                 #
#                                                                              #
################################################################################

#prepare data for database restructuring
j <- as.data.table(j)
q$HS <- as.factor(q$HS)
ylim_max <- ceiling(max(j[,1:11])*10)/10+0.1

#===============================================================================
#State 1: GI I, CF 0
#===============================================================================

j1 <- cbind(j[,"int_op"], 1, j[,"State 1"], rep("Model",nrow(j)))
colnames(j1) <- c("int_op", "HS", "HS_frac", "group")
q1 <- q[q$HS == 1,]
w1 <- rbind(q1,j1)


w1$group <- as.factor(w1$group)
w1$HS_frac <- as.double(w1$HS_frac)
w1$int_op <- as.double(w1$int_op)
p1 <- ggplot(w1, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("GI I, CF 0   ") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p1

#===============================================================================
#State 2: GI I, CF 1
#===============================================================================

j2 <- cbind(j[,"int_op"], 2, j[,"State 2"], rep("Model",nrow(j)))
colnames(j2) <- c("int_op", "HS", "HS_frac", "group")
q2 <- q[q$HS == 2,]
w2 <- rbind(q2,j2)

w2$group <- as.factor(w2$group)
w2$HS_frac <- as.double(w2$HS_frac)
w2$int_op <- as.double(w2$int_op)
p2 <- ggplot(w2, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("GI I, CF 1") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p2

#===============================================================================
#State 3: GI II, CF 0
#===============================================================================

j3 <- cbind(j[,"int_op"], 3, j[,"State 3"], rep("Model",nrow(j)))
colnames(j3) <- c("int_op", "HS", "HS_frac", "group")
q3 <- q[q$HS == 3,]
w3 <- rbind(q3,j3)

w3$group <- as.factor(w3$group)
w3$HS_frac <- as.double(w3$HS_frac)
w3$int_op <- as.double(w3$int_op)
p3 <- ggplot(w3, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("GI II, CF 0") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p3

#===============================================================================
#State 4: GI II, CF 1
#===============================================================================

j4 <- cbind(j[,"int_op"], 4, j[,"State 4"], rep("Model",nrow(j)))
colnames(j4) <- c("int_op", "HS", "HS_frac", "group")
q4 <- q[q$HS == 4,]
w4 <- rbind(q4,j4)

w4$group <- as.factor(w4$group)
w4$HS_frac <- as.double(w4$HS_frac)
w4$int_op <- as.double(w4$int_op)
p4 <- ggplot(w4, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("GI II, CF 1") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p4

#===============================================================================
#State 5: GI III, CF 0
#===============================================================================

j5 <- cbind(j[,"int_op"], 5, j[,"State 5"], rep("Model",nrow(j)))
colnames(j5) <- c("int_op", "HS", "HS_frac", "group")
q5 <- q[q$HS == 5,]
w5 <- rbind(q5,j5)

w5$group <- as.factor(w5$group)
w5$HS_frac <- as.double(w5$HS_frac)
w5$int_op <- as.double(w5$int_op)
p5 <- ggplot(w5, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("GI III, CF 0") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p5

#===============================================================================
#State 6: GI III, CF I
#===============================================================================

j6 <- cbind(j[,"int_op"], 6, j[,"State 6"], rep("Model",nrow(j)))
colnames(j6) <- c("int_op", "HS", "HS_frac", "group")
q6 <- q[q$HS == 6,]
w6 <- rbind(q6,j6)

w6$group <- as.factor(w6$group)
w6$HS_frac <- as.double(w6$HS_frac)
w6$int_op <- as.double(w6$int_op)
p6 <- ggplot(w6, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("GI III, CF I") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p6

#===============================================================================
#State 7: GI IV, CF 0
#===============================================================================

j7 <- cbind(j[,"int_op"], 7, j[,"State 7"], rep("Model",nrow(j)))
colnames(j7) <- c("int_op", "HS", "HS_frac", "group")
q7 <- q[q$HS == 7,]
w7 <- rbind(q7,j7)

w7$group <- as.factor(w7$group)
w7$HS_frac <- as.double(w7$HS_frac)
w7$int_op <- as.double(w7$int_op)
p7 <- ggplot(w7, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("GI IV, CF 0") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p7

#===============================================================================
#State 8: GI IV, CF 1
#===============================================================================

j8 <- cbind(j[,"int_op"], 8, j[,"State 8"], rep("Model",nrow(j)))
colnames(j8) <- c("int_op", "HS", "HS_frac", "group")
q8 <- q[q$HS == 8,]
w8 <- rbind(q8,j8)

w8$group <- as.factor(w8$group)
w8$HS_frac <- as.double(w8$HS_frac)
w8$int_op <- as.double(w8$int_op)
p8 <- ggplot(w8, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("GI IV, CF 1") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p8

#===============================================================================
#State 9: GI V, CF 0
#===============================================================================

j9 <- cbind(j[,"int_op"], 9, j[,"State 9"], rep("Model",nrow(j)))
colnames(j9) <- c("int_op", "HS", "HS_frac", "group")
q9 <- q[q$HS == 9,]
w9 <- rbind(q9,j9)

w9$group <- as.factor(w9$group)
w9$HS_frac <- as.double(w9$HS_frac)
w9$int_op <- as.double(w9$int_op)
p9 <- ggplot(w9, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("GI V, CF 0") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p9

#===============================================================================
#State 10: GI V, CF 1
#===============================================================================

j10 <- cbind(j[,"int_op"], 10, j[,"State 10"], rep("Model",nrow(j)))
colnames(j10) <- c("int_op", "HS", "HS_frac", "group")
q10 <- q[q$HS == 10,]
w10 <- rbind(q10,j10)

w10$group <- as.factor(w10$group)
w10$HS_frac <- as.double(w10$HS_frac)
w10$int_op <- as.double(w10$int_op)
p10 <- ggplot(w10, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("GI V, CF 1") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p10

#===============================================================================
#State 11: Death
#===============================================================================

j11 <- cbind(j[,"int_op"], 11, j[,"State 11"], rep("Model",nrow(j)))
colnames(j11) <- c("int_op", "HS", "HS_frac", "group")
q11 <- q[(q$HS == 11), ] 
w11 <- rbind(q11,j11)

w11$group <- as.factor(w11$group)
w11$HS_frac <- as.double(w11$HS_frac)
w11$int_op <- as.double(w11$int_op)
p11 <- ggplot(w11, aes(x=int_op, y=HS_frac, color = group)) +
  geom_line(aes(color=group), size = 1)+
  geom_point(aes(color=group), size = 1) + 
  ggtitle("Deceased") + 
  xlab("Years") + 
  ylab("Prevalence (%)") +
  theme(legend.position="bottom") +
  ylim(0,ylim_max)
p11


#===============================================================================
# Generate Plot
#===============================================================================

agemin <- min(agex)
agemax <- max(agex)

chart_title <- paste("Cohort aged between ",agemin," and ",agemax," 
                     in interview wave ",int_wavex, ", n = ", n_sample, 
                     sep = "", collapse = NULL)
#Generate file name for plot
chart_name <- paste("02_results/02_traces/HS_age",agemin,"_",agemax,"_int",
                    int_wavex, ".png", sep = "", collapse = NULL)

grid.arrange(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, ncol=4, 
             top = chart_title)
dev.copy(png,filename=chart_name)
dev.off ()
