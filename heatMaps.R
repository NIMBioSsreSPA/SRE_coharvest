###=======================================================================
### Parameters
###=======================================================================
#install.packages('heatmaply')
#install.packages.2 <- function (pkg) if (!require(pkg)) install.packages(pkg);
#install.packages.2('devtools')
#install.packages("akima")

# make sure you have Rtools installed first! if not, then run:
#install.packages('installr'); install.Rtools()
#devtools::install_github("ropensci/plotly") 
#devtools::install_github('talgalili/heatmaply')

library(akima)
library("heatmaply")

highHarvestFecundity <- 0.85 # Multiplier for fecundity rate for Adult trees under HIGH harvest
highHarvestSurvival <- 0.9 # Multiplier for survival rate of Adult trees under HIGH harvest
agoutiGrowth <- 1.1 # Growth rate of Agoutis in logistic model

lowHunting <- 0.1 # Percentage of agoutis hunted during LOW hunting
highHunting <- 0.25 # Percentage of agoutis hunted during HIGH hunting

seedlingCapacity <- 5000 # Carrying Capacities. Tree capacities don't matter as much.
saplingCapacity <- 500
adultCapacity <- 100
agoutiCapacity <- 5200
perc <- 0.9
ylimit <- 1 # For plotting

seedlingInit <- perc * seedlingCapacity#5000 # Initial Populations
saplingInit <- perc * saplingCapacity#500
adultInit <- perc * adultCapacity#100
agoutiInit <- perc * agoutiCapacity#5000

m <- 0.05    # m is the desired proportion at which sigmoid(m) = m . Ideally it is small (~0.01-0.05).
agouti_to_PlantSteepness <- -(log(1-m)-log(m))/((m-0.5)*agoutiCapacity) # Steepness needed for sigmoid(m) = m
plant_to_AgoutiSteepness <- -(log(1-m)-log(m))/((m-0.5)*adultCapacity)  # Steepness needed for sigmoid(m) = m
#This formula above is derived from logistic function with "x = m*CAP" , "x0 = .5*CAP" , "y = m" , and solving for k. (CAP = carrying capacity)

time_end <- 1000 # Length of simulation in years

maxt <- 1000
brazilNut <- list(low=plant_mat_low, high=plant_mat_high)

high_harv <- matrix(1, nrow = 17, ncol = 17)

xseq <-seq(0,1,0.05)
low_high_huntseq <- seq(0,0.85,0.05)


##=======The Original 17-Stage Matrix from Zuidema and high-harvest multiplier
plant_S_mat <- matrix( 0, nrow = 17, ncol = 17)
diag(plant_S_mat) <- c(0.455, 0.587, 0.78, 0.821, 0.941, 0.938, 0.961, 0.946, 0.94, 0.937, 0.936, 0.966, 0.968, 0.971, 0.965, 0.967, 0.985)
plant_S_mat[cbind(2:17,1:16)] <- matrix(c(0.091, 0.147, 0.134, 0.167, 0.044, 0.047, 0.034, 0.049, 0.055, 0.058, 0.059, 0.029, 0.027, 0.024, 0.020, 0.018))
plant_S_mat[1,12:17] <- matrix( c(12.3, 14.6, 16.9, 19.3, 22.3, 26.6) )
high_harv[1,12:17] <- highHarvestFecundity 
high_harv[cbind(12:17,12:17)] <- highHarvestSurvival # Multiplier for survival rate of Adult trees
plant_mat_low <- plant_S_mat
plant_mat_high <- plant_S_mat * high_harv


#===========================================================================

#============FUNCTIONS======================================================

sigmoid <- function(k, x0, x) 
{
  1/(1+exp(-k*(x-x0))) #k: steepness #x0 = midpoint
} 


linear <- function(m, x, b)
{
  y <- m*x + b
  return(y)
}


LogisticGrowthHunt<- function(R, N, K, H, p) 
{ # p is how the plant affects carrying capacity of agoutis (from 0 to 1)
  Nnext <- R*N*(1-N/(K*(p))) - H*N + N
  return(Nnext)
}


LogisticGrowthHuntRK<- function(R, N, K, H, p,s,m) 
{ # p is how the plant affects carrying capacity of agoutis (from 0 to 1)
  Nnext <- R*(s)*N*(1-N/((K*(p))*m)) - H*N + N
  return(Nnext)
} 
# Specifying the markov chain
library('markovchain')

markovChain<- function(){
  
  statesNames = c("low","high")
  mcHarvest <- new("markovchain", states = statesNames, 
                   transitionMatrix = matrix(data = c(0.2, 0.8, 0.8, 0.2), byrow = TRUE, 
                                             nrow = 2, dimnames=list(statesNames,statesNames)), name="Harvest")
  # Simulating a discrete time process for harvest
  set.seed(100)
  harvest_seq <- markovchain::rmarkovchain(n=time_end, object = mcHarvest, t0="low")
  return(harvest_seq)
}

harvest_seq <- markovChain()

stoch_growth <- function(){
  r <- numeric(maxt)
  plant_mat <- matrix(0, nrow = 17)
  plant_mat[1:4] <- seedlingInit/4   #Setting initial population of seedlings
  plant_mat[5:11] <- saplingInit/7   #Setting initial population of saplings
  plant_mat[12:17] <- adultInit/6  #Setting initial population of adult trees
  
  plant_all <- matrix( c(seedlingInit, saplingInit, adultInit) ) # This will contain the summed plant populations at ALL timesteps
  
  plant_mat <- plant_mat / sum(plant_mat)
  agouti_vec <- c(agoutiInit)
  
  markovChain()
  
  for (i in 1:maxt)
  {
    h_i <- harvest_seq[i]

    if (h_i == "low") 
    {
      pmat <- plant_mat_low
      h_off <- lowHunting
    } 
    
    else 
    {
      pmat <- plant_mat_high
      h_off <- highHunting
    }
    
    p <- sigmoid(plant_to_AgoutiSteepness, 50, sum(plant_mat[12:17]))*.1 + 0.9 # bounded between 0.9 and 1.0.... k was 0.1
    agouti_vec[(i+1)] <- LogisticGrowthHunt(agoutiGrowth, agouti_vec[(i)],agoutiCapacity,h_off, p)
    plant_animal_mat <- matrix(1, nrow = 17, ncol = 17)
    plant_animal_mat[1,12:17] <- sigmoid(agouti_to_PlantSteepness, agoutiCapacity/2, agouti_vec[(i+1)]) # k was 0.0025
    #  plant_animal_mat[1,12:17] <- linear(m, agouti_vec[(i+1)], b) # A different functional form
    plant_mat <- matrix( c((plant_animal_mat * pmat) %*% plant_mat))
    
    #Summing the stages into 3 categories for better plotting
    plant_mat_sum <- c( sum(plant_mat[1:4]), sum(plant_mat[5:11]), sum(plant_mat[12:17])) 
    plant_all <- cbind(plant_all, plant_mat_sum)
    
    N <- sum(plant_mat)
    r[i] <- log(N)
    plant_mat <- plant_mat / N
  }
  
  loglambsim <- mean(r)
  
  return(loglambsim)
}


stoch_growth_underHighHuntHarv <- function(){
  r <- numeric(maxt)
  plant_mat <- matrix(0, nrow = 17)
  plant_mat[1:4] <- seedlingInit/4   #Setting initial population of seedlings
  plant_mat[5:11] <- saplingInit/7   #Setting initial population of saplings
  plant_mat[12:17] <- adultInit/6  #Setting initial population of adult trees
  
  plant_all <- matrix( c(seedlingInit, saplingInit, adultInit) ) # This will contain the summed plant populations at ALL timesteps
  
  plant_mat <- plant_mat / sum(plant_mat)
  agouti_vec <- c(agoutiInit)
  
  markovChain()
  
  for (i in 1:maxt)
  {
    
    pmat <- plant_mat_high
    h_off <- highHunting
    
    p <- sigmoid(plant_to_AgoutiSteepness, 50, sum(plant_mat[12:17]))*.1 + 0.9 # bounded between 0.9 and 1.0.... k was 0.1
    agouti_vec[(i+1)] <- LogisticGrowthHunt(agoutiGrowth, agouti_vec[(i)],agoutiCapacity,h_off, p)
    plant_animal_mat <- matrix(1, nrow = 17, ncol = 17)
    plant_animal_mat[1,12:17] <- sigmoid(agouti_to_PlantSteepness, agoutiCapacity/2, agouti_vec[(i+1)]) # k was 0.0025
    #  plant_animal_mat[1,12:17] <- linear(m, agouti_vec[(i+1)], b) # A different functional form
    plant_mat <- matrix( c((plant_animal_mat * pmat) %*% plant_mat))
    
    #Summing the stages into 3 categories for better plotting
    plant_mat_sum <- c( sum(plant_mat[1:4]), sum(plant_mat[5:11]), sum(plant_mat[12:17])) 
    plant_all <- cbind(plant_all, plant_mat_sum)
    
    N <- sum(plant_mat)
    r[i] <- log(N)
    plant_mat <- plant_mat / N
  }
  
  loglambsim <- mean(r)
  
  return(loglambsim)
}


agouti_Abundance<- function(s,m){
  
  plant_mat <- matrix(0, nrow = 17)
  plant_mat[1:4] <- seedlingInit/4   #Setting initial population of seedlings
  plant_mat[5:11] <- saplingInit/7   #Setting initial population of saplings
  plant_mat[12:17] <- adultInit/6  #Setting initial population of adult trees
  
  plant_all <- matrix( c(seedlingInit, saplingInit, adultInit) ) # This will contain the summed plant populations at ALL timesteps
  plant_mat <- plant_mat / sum(plant_mat)
  
  agouti_vec <- c(agoutiInit)
  
  markovChain()
  
  for (i in 1:maxt)
  {
    h_i <- harvest_seq[i]
    
    if (h_i=="low") 
    {
      h_off <- lowHunting
    } 
    
    else 
    {
      h_off <- highHunting
    }
    
    p <- sigmoid(plant_to_AgoutiSteepness, 50, sum(plant_mat[12:17]))*.1 + 0.9 # bounded between 0.9 and 1.0.... k was 0.1
    agouti_vec[(i+1)] <- LogisticGrowthHuntRK(agoutiGrowth, agouti_vec[(i)],agoutiCapacity,h_off, p,s,m)
    
  }
  return(agouti_vec[length(agouti_vec)])
}


plant_abundance_underHighHunt<- function(highHunting){
  plant_mat <- matrix(0, nrow = 17)
  plant_mat[1:4] <- seedlingInit/4   #Setting initial population of seedlings
  plant_mat[5:11] <- saplingInit/7   #Setting initial population of saplings
  plant_mat[12:17] <- adultInit/6  #Setting initial population of adult trees
  
  plant_all <- matrix( c(seedlingInit, saplingInit, adultInit) ) # This will contain the summed plant populations at ALL timesteps
  plant_mat <- plant_mat / sum(plant_mat)
  
  agouti_vec <- c(agoutiInit)
  
  for (i in 1:maxt)
  {
    pmat <- plant_mat_high
    h_off <- highHunting 
    
    p <- sigmoid(plant_to_AgoutiSteepness, 50, sum(plant_mat[12:17]))*.1 + 0.9 # bounded between 0.9 and 1.0.... k was 0.1
    agouti_vec[(i+1)] <- LogisticGrowthHunt(agoutiGrowth, agouti_vec[(i)],agoutiCapacity,h_off, p)
    plant_animal_mat <- matrix(1, nrow = 17, ncol = 17)
    plant_animal_mat[1,12:17] <- sigmoid(agouti_to_PlantSteepness, agoutiCapacity/2, agouti_vec[(i+1)]) # k was 0.0025
    #  plant_animal_mat[1,12:17] <- linear(m, agouti_vec[(i+1)], b) # A different functional form
    plant_mat <- matrix( c((plant_animal_mat * pmat) %*% plant_mat))
    
    #Summing the stages into 3 categories for better plotting
    plant_mat_sum <- c( sum(plant_mat[1:4]), sum(plant_mat[5:11]), sum(plant_mat[12:17])) 
    plant_all <- cbind(plant_all, plant_mat_sum)
    
  }
  return(plant_mat_sum)
}


#===================================================================================================================

growthRate_mat<-matrix(0,21,21)
binary_mat<- matrix(0,21,21)
rownames(growthRate_mat) <- paste(xseq)
colnames(growthRate_mat) <- paste(xseq)

rownames(binary_mat) <- paste(xseq)
colnames(binary_mat) <- paste(xseq)

num<-1 
num1<-1
for(i in xseq)
{
  high_harv[1,12:17] <- i # Multiplier for fecundity rate for Adult trees
  num1<-1
  for(j in xseq){

    high_harv[cbind(12:17,12:17)] <- j # Multiplier for survival rate of Adult trees
    plant_mat_low <- plant_S_mat
    plant_mat_high <- plant_S_mat * high_harv
    growth_rate <- exp(stoch_growth())
    growthRate_mat[num,num1]<-growth_rate
    print(growthRate_mat[num,num1])
    if(growthRate_mat[num,num1]>=1)
    {
      binary_mat[num,num1]<-1
    }
    else{
     binary_mat[num,num1]<-0
    }
   
    num1<-num1+1
  }
  num<- num+1
  
}

heatmaply::heatmaply(binary_mat,margins=c(4,4), Rowv=NA, Colv=NA,xlab = "Adult Survival", ylab="Germination")
heatmaply::heatmaply(growthRate_mat,margins = c(4,4), Rowv=NA, Colv=NA,xlab = "Adult Survival", ylab="Germination", scale="none")

#saving these the heatmap as images 
dir.create("heatMaps")
library(heatmaply)
heatmaply(growthRate_mat, file = "heatMaps/heatmaply_plot.png",Rowv=NA, Colv=NA,xlab = "Adult Survival", ylab="Germination")
browseURL("heatMaps/heatmaply_plot.png")


#=====================================================================================================================
#Growth Rate vs animal Population
#=====================================================================================================================
agouti_Growth<- matrix(0, 1, 21)
agouti_pop<- matrix(0, 1, 21)
num<-1
for(i in xseq)
  {
    agouti_Growth[num]<- (i)
    agouti_pop[num]<- agouti_Abundance(agouti_Growth[num],1)
    print(c(agouti_Growth[num], agouti_pop[num]))
    num=num+1
}

plot(agouti_Growth,agouti_pop, xlab="Proportion of the Growth Rate", ylab="Animal Population", col="brown", ylim=c(0,4000), type="l",xlim=c(0,1),xaxs="i") 


#=======================================================================================================================
#Carrying Capacity vs Agouti Population
#=======================================================================================================================
agouti_capacity<- matrix(0, 1, 21)
agouti_pop<- matrix(0, 1, 21)
num<-1
for(i in xseq)
{
  agouti_capacity[num]<-(i)
  agouti_pop[num]<- agouti_Abundance(1,agouti_capacity[num])
  print(c(agouti_capacity[num], agouti_pop[num]))
  num<-num+1
}

plot(agouti_capacity,agouti_pop, xlab="Proportion of the Carrying Capacity", ylab="Animal Population", col="brown", ylim=c(2000,4300), type="l",xlim=c(0.59,1),xaxs="i")


#=========================================================================================================================
#Agouti hunting vs. Plant abundance
#=========================================================================================================================
seedling_hunt_mat<- matrix(0,1,21)
sapling_hunt_mat<- matrix(0,1,21)
adults_hunt_mat<- matrix(0,1,21)

hunting_mat<- matrix(0,1,21)
num<-1
for(i in xseq)
  {
    hunting_mat[num]<-i 
    seedling_hunt_mat[num]<- plant_abundance_underHighHunt(hunting_mat[num])[1]
    sapling_hunt_mat[num]<- plant_abundance_underHighHunt(hunting_mat[num])[2]
    adults_hunt_mat[num]<- plant_abundance_underHighHunt(hunting_mat[num])[3]
    num= num+1
  }

par(mar=c(5,4,1,1),oma=c(0,0,0,0))
plot(hunting_mat, log(seedling_hunt_mat), xlab="Proportion of Animal Hunted", ylab="log(Plant Population)", col="brown", ylim=c(0,35), type="l",xlim=c(0,1),xaxs="i")
lines(hunting_mat,log(sapling_hunt_mat), col="black")
lines(hunting_mat,log(adults_hunt_mat), col="green")
legend(0.1, 5, legend=c("Seedling","Sapling","Adults"),col=c("brown", "black","green"), lty=1:2, cex=0.5)


#=============================================================================================================================
#Contour map Germination and adult Survival 
install.packages("akima")
library(akima)

filled.contour(x = xseq,
              y = xseq,
              z = growthRate_mat,
              color.palette =
                colorRampPalette(c("white", "blue")),
              xlab = "Adult Survival",
              ylab = "Germination",
              key.title = title(main = "Growth Rate", cex.main = 0.5))



#=============================================================================================================================#
#Heatmap projecting variation in hunting and its affect on the adult survival and germination 
#==============================================================================================================================
#1) Only high hunting with respect to germination
growthRate_mat<-matrix(0,length(xseq),length(xseq))
row.names(growthRate_mat) <- paste(xseq)
colnames(growthRate_mat) <- paste(xseq, sep)

binary_mat<- matrix(0,length(xseq),length(xseq))
rownames(binary_mat) <- paste(xseq)
colnames(binary_mat) <- paste(xseq)
highHunting<-0
num<-1 
num1<-1

high_harv[1,12:17] <- highHarvestFecundity 
high_harv[cbind(12:17,12:17)] <- highHarvestSurvival # Multiplier for survival rate of Adult trees

for(i in xseq)
{
  high_harv[1,12:17] <- i # Multiplier for fecundity rate for Adult trees
  num1<-1
  for(j in xseq){
    
    plant_mat_low <- plant_S_mat
    plant_mat_high <- plant_S_mat * high_harv
    highHunting<- j
    growth_rate <- exp(stoch_growth_underHighHuntHarv())
    growthRate_mat[num,num1]<-growth_rate
    print(growthRate_mat[num,num1])
    if(growthRate_mat[num,num1]>1 ||growthRate_mat[num,num1]==1)
    {
      binary_mat[num,num1]<-1
    }
    else{
      binary_mat[num,num1]<-0
    }
    
    num1<-num1+1
  }
  num<- num+1
  
}


library(heatmaply)
heatmaply(growthRate_mat,Rowv=NA, Colv=NA,xlab = "High Hunting", ylab="Germination", labRow = xseq, labCol=xseq )
heatmaply(binary_mat,Rowv=NA, Colv=NA,scale="none",xlab = "High Hunting", ylab="Germination",labRow = xseq, labCol=xseq)



#install.packages("akima")
library(akima)

filled.contour(x = xseq,
               y = xseq,
               z = growthRate_mat,
               color.palette =
                 colorRampPalette(c("white", "blue")),
               xlab = "High Hunting",
               ylab = "Germination",
               key.title = title(main = "Growth Rate", cex.main = 0.5))



#======================================================================================================================
#2 Only High hunting with respect to adult survival
#======================================================================================================================
growthRate_mat<-matrix(0,21,21)
binary_mat<- matrix(0,21,21)
rownames(growthRate_mat) <- paste(xseq)
colnames(growthRate_mat) <- paste(xseq)

rownames(binary_mat) <- paste(xseq)
colnames(binary_mat) <- paste(xseq)


highHunting<-0
num<-1 
num1<-1

high_harv[1,12:17] <- highHarvestFecundity 
high_harv[cbind(12:17,12:17)] <- highHarvestSurvival # Multiplier for survival rate of Adult trees

for(i in xseq)
{
  high_harv[cbind(12:17,12:17)] <- i # Multiplier for survival rate of Adult trees
  num1<-1
  for(j in xseq){
    
    plant_mat_low <- plant_S_mat
    plant_mat_high <- plant_S_mat * high_harv
    highHunting<- j
    growth_rate <- exp(stoch_growth_underHighHuntHarv())
    growthRate_mat[num,num1]<-growth_rate
    print(growthRate_mat[num,num1])
    if(growthRate_mat[num,num1]>1 ||growthRate_mat[num,num1]==1)
    {
      binary_mat[num,num1]<-1
    }
    else{
      binary_mat[num,num1]<-0
    }
    
    num1<-num1+1
  }
  num<- num+1
  
}

heatmaply::heatmaply(binary_mat,margins=c(4,4), Rowv=NA, Colv=NA,xlab = "High Hunting", ylab="Adult Survival",labRow = xseq, labCol=xseq)
heatmaply::heatmaply(growthRate_mat,margins = c(4,4), Rowv=NA, Colv=NA,xlab = "High Hunting", ylab="Adult Survival", scale="none",labRow = xseq, labCol=xseq)

library(akima)

filled.contour(x = xseq,
               y = xseq,
               z = growthRate_mat,
               color.palette =
                 colorRampPalette(c("white", "red")),
               xlab = "High Hunting", ylab="Adult Survival",
               key.title = title(main = "Growth Rate", cex.main = 0.5))


#============================================================================================================================
#Heatmap projection of both high and low hunting with respect to adult survival and germination
#============================================================================================================================
#Changing both high and low hunting with respect to germination
low_high_huntseq<- seq(0,0.85,0.05)
growthRate_mat<-matrix(0,length(low_high_huntseq),length(low_high_huntseq))
binary_mat<- matrix(0,length(low_high_huntseq),length(low_high_huntseq))
rownames(growthRate_mat) <- paste(low_high_huntseq)
colnames(growthRate_mat) <- paste(low_high_huntseq)

rownames(binary_mat) <- paste(low_high_huntseq)
colnames(binary_mat) <- paste(low_high_huntseq)

highHunting<-0
lowHunting<-0

num<-1 
num1<-1

high_harv[1,12:17] <- highHarvestFecundity 
high_harv[cbind(12:17,12:17)] <- highHarvestSurvival # Multiplier for survival rate of Adult trees

for(i in low_high_huntseq)
{
  high_harv[1,12:17] <- i # Multiplier for fecundity rate for Adult trees
  num1<-1
  for(j in low_high_huntseq){
    
    plant_mat_low <- plant_S_mat
    plant_mat_high <- plant_S_mat * high_harv
    lowHunting<-j
    highHunting<- j+0.15
    growth_rate <- exp(stoch_growth())
    growthRate_mat[num,num1]<-growth_rate
    print(growthRate_mat[num,num1])
    if(growthRate_mat[num,num1]>=1 || is.na(growthRate_mat[num,num1]))
    {
      binary_mat[num,num1]<-1
    }
    else{
      binary_mat[num,num1]<-0
    }
    
    num1<-num1+1
  }
  num<- num+1
  
}

heatmaply::heatmaply(binary_mat,margins=c(4,4), Rowv=NA, Colv=NA,xlab = "Hunting(Low/High)", ylab="Germination",labRow = low_high_huntseq, labCol=low_high_huntseq)
heatmaply::heatmaply(growthRate_mat,margins = c(4,4), Rowv=NA, Colv=NA,xlab = "Hunting(Low/High)", ylab="Germination", scale="none",labRow = low_high_huntseq, labCol=low_high_huntseq)

library(akima)

filled.contour(x = low_high_huntseq,
               y = low_high_huntseq,
               z = growthRate_mat,
               color.palette =
                 colorRampPalette(c("white", "red")),
               xlab = "Hunting(low/high)",
               ylab = "Germination",
               key.title = title(main = "Growth Rate", cex.main = 0.5))


#===============================================================================================
#Changing both high and low hunting with respect to adult survival
#==============================================================================================
low_high_huntseq<- seq(0,0.85,0.05)
growthRate_mat<-matrix(0,length(low_high_huntseq),length(low_high_huntseq))
binary_mat<- matrix(0,length(low_high_huntseq),length(low_high_huntseq))
rownames(growthRate_mat) <- paste(low_high_huntseq)
colnames(growthRate_mat) <- paste(low_high_huntseq)

rownames(binary_mat) <- paste(low_high_huntseq)
colnames(binary_mat) <- paste(low_high_huntseq)

highHunting<-0
lowHunting<-0
num<-1 
num1<-1

high_harv[1,12:17] <- highHarvestFecundity 
high_harv[cbind(12:17,12:17)] <- highHarvestSurvival # Multiplier for survival rate of Adult trees

for(i in low_high_huntseq)
{
  high_harv[cbind(12:17,12:17)] <- i # Multiplier for survival rate of Adult trees
  num1<-1
  for(j in low_high_huntseq){
    plant_mat_low <- plant_S_mat
    plant_mat_high <- plant_S_mat * high_harv
    lowHunting<-j
    highHunting<- j+0.15
    growth_rate <- exp(stoch_growth())
    growthRate_mat[num,num1]<-growth_rate
    print(growthRate_mat[num,num1])
    if(growthRate_mat[num,num1]<1 || is.na(growthRate_mat[num,num1]))
    {
      binary_mat[num,num1]<-0
    }
    else{
      binary_mat[num,num1]<-1
    }
    
    num1<-num1+1
  }
  num<- num+1
  
}

heatmaply::heatmaply(binary_mat,margins=c(4,4), Rowv=NA, Colv=NA,xlab = "Hunting(Low/High)", ylab="Adult Survival", labRow = low_high_huntseq, labCol=low_high_huntseq)
heatmaply::heatmaply(growthRate_mat,margins = c(4,4), Rowv=NA, Colv=NA,xlab = "Hunting(Low/High)", ylab="Adult Survival", scale="none",labRow = low_high_huntseq, labCol=low_high_huntseq)

library(akima)

filled.contour(x =  low_high_huntseq,
               y =  low_high_huntseq,
               z = growthRate_mat,
               color.palette =
                 colorRampPalette(c("white", "blue")),
               xlab = "Hunting(low/high)",
               ylab = "Adult Survival",
               key.title = title(main = "Growth Rate", cex.main = 0.5))


#=======================================================================================================================
#High hunting with high/low harvest with respect to Germination
#======================================================================================================================
growthRate_mat<-matrix(0,length(xseq),length(xseq))
row.names(growthRate_mat) <- paste(xseq)
colnames(growthRate_mat) <- paste(xseq, sep)

binary_mat<- matrix(0,length(xseq),length(xseq))
rownames(binary_mat) <- paste(xseq)
colnames(binary_mat) <- paste(xseq)
highHunting<-0
num<-1 
num1<-1

high_harv[1,12:17] <- highHarvestFecundity 
high_harv[cbind(12:17,12:17)] <- highHarvestSurvival # Multiplier for survival rate of Adult trees

for(i in xseq)
{
  high_harv[1,12:17] <- i # Multiplier for fecundity rate for Adult trees
  num1<-1
  for(j in xseq){
    
    plant_mat_low <- plant_S_mat
    plant_mat_high <- plant_S_mat * high_harv
    highHunting<- j
    growth_rate <- exp(stoch_growth())
    growthRate_mat[num,num1]<-growth_rate
    print(growthRate_mat[num,num1])
    if(growthRate_mat[num,num1]>1 ||growthRate_mat[num,num1]==1)
    {
      binary_mat[num,num1]<-1
    }
    else{
      binary_mat[num,num1]<-0
    }
    
    num1<-num1+1
  }
  num<- num+1
  
}

library(heatmaply)
heatmaply(growthRate_mat,Rowv=NA, Colv=NA,xlab = "High Hunting (Constant low hunting)", ylab="Germination", labRow = xseq, labCol=xseq )
heatmaply(binary_mat,Rowv=NA, Colv=NA,scale="none",xlab = "High Hunting (Constant low hunting)", ylab="Germination",labRow = xseq, labCol=xseq)



install.packages("akima")
library(akima)

filled.contour(x = xseq,
               y = xseq,
               z = growthRate_mat,
               color.palette =
                 colorRampPalette(c("white", "blue")),
               xlab = "High Hunting(Constant low hunting)",
               ylab = "Germination",
               key.title = title(main = "Growth Rate", cex.main = 0.5))

#===========================================================================================================================

growthRate_mat<-matrix(0,21,21)
binary_mat<- matrix(0,21,21)
rownames(growthRate_mat) <- paste(xseq)
colnames(growthRate_mat) <- paste(xseq)

rownames(binary_mat) <- paste(xseq)
colnames(binary_mat) <- paste(xseq)


highHunting<-0
num<-1 
num1<-1

high_harv[1,12:17] <- highHarvestFecundity 
high_harv[cbind(12:17,12:17)] <- highHarvestSurvival # Multiplier for survival rate of Adult trees

for(i in xseq)
{
  high_harv[cbind(12:17,12:17)] <- i # Multiplier for survival rate of Adult trees
  num1<-1
  for(j in xseq){
    
    plant_mat_low <- plant_S_mat
    plant_mat_high <- plant_S_mat * high_harv
    highHunting<- j
    growth_rate <- exp(stoch_growth())
    growthRate_mat[num,num1]<-growth_rate
    print(growthRate_mat[num,num1])
    if(growthRate_mat[num,num1]>1 ||growthRate_mat[num,num1]==1)
    {
      binary_mat[num,num1]<-1
    }
    else{
      binary_mat[num,num1]<-0
    }
    
    num1<-num1+1
  }
  num<- num+1
  
}

heatmaply::heatmaply(binary_mat,margins=c(4,4), Rowv=NA, Colv=NA,xlab = "High Hunting (Constant low hunting)", ylab="Adult Survival",labRow = xseq, labCol=xseq)
heatmaply::heatmaply(growthRate_mat,margins = c(4,4), Rowv=NA, Colv=NA,xlab = "High Hunting (Constant low hunting)", ylab="Adult Survival", scale="none",labRow = xseq, labCol=xseq)

library(akima)

filled.contour(x = xseq,
               y = xseq,
               z = growthRate_mat,
               color.palette =
                 colorRampPalette(c("white", "red")),
               xlab = "High Hunting (Constant low hunting)", ylab="Adult Survival",
               key.title = title(main = "Growth Rate", cex.main = 0.5))




