##=========================================================================================================
# Script description: Generating 25 contour plots as a single plot

# Overall varying delta p and delta d
# Plot x axis: Delta d
# Plot y axis: Delta p
#
# For each individual contour plot we are varying harvest (1- Adult Survival multiplier) and hunting (highHunting multiplier) levels
# Contour plot x axis: Harvest
# Contour plot y axis: Hunting 

# We are using Brazil nut and Agouti parameter values 
#======================================================================================================================




# Plotting delta (bound on plants' affect on animals) VS. Hunting (Average Hunting)
library(gplots)
filled.legend <-
  function (x = seq(0, 1, length.out = nrow(z)), y = seq(0, 1, 
                                                         length.out = ncol(z)), z, xlim = range(x, finite = TRUE), 
            ylim = range(y, finite = TRUE), zlim = range(z, finite = TRUE), 
            levels = pretty(zlim, nlevels), nlevels = 20, color.palette = cm.colors, 
            col = color.palette(length(levels) - 1), plot.title, plot.axes, 
            key.title, key.axes, asp = NA, xaxs = "i", yaxs = "i", las = 1, 
            axes = TRUE, frame.plot = axes, ...) 
  {
    # modification of filled.contour by Carey McGilliard and Bridget Ferris
    # designed to just plot the legend
    if (missing(z)) {
      if (!missing(x)) {
        if (is.list(x)) {
          z <- x$z
          y <- x$y
          x <- x$x
        }
        else {
          z <- x
          x <- seq.int(0, 1, length.out = nrow(z))
        }
      }
      else stop("no 'z' matrix specified")
    }
    else if (is.list(x)) {
      y <- x$y
      x <- x$x
    }
    if (any(diff(x) <= 0) || any(diff(y) <= 0)) 
      stop("increasing 'x' and 'y' values expected")
    #  mar.orig <- (par.orig <- par(c("mar", "las", "mfrow")))$mar
    #  on.exit(par(par.orig))
    #  w <- (3 + mar.orig[2L]) * par("csi") * 2.54
    #layout(matrix(c(2, 1), ncol = 2L), widths = c(1, lcm(w)))
    #  par(las = las)
    #  mar <- mar.orig
    #  mar[4L] <- mar[2L]
    #  mar[2L] <- 1
    #  par(mar = mar)
    # plot.new()
    plot.window(xlim = c(0, 1), ylim = range(levels), xaxs = "i", 
                yaxs = "i")
    rect(0, levels[-length(levels)], 1, levels[-1L], col = col)
    if (missing(key.axes)) {
      if (axes) 
        axis(4)
    }
    else key.axes
    box()
    
  }


filled.contour3 <-
  function (x = seq(0, 1, length.out = nrow(z)),
            y = seq(0, 1, length.out = ncol(z)), z, xlim = range(x, finite = TRUE), 
            ylim = range(y, finite = TRUE), zlim = range(z, finite = TRUE), 
            levels = pretty(zlim, nlevels), nlevels = 20, color.palette = cm.colors, 
            col = color.palette(length(levels) - 1), plot.title, plot.axes, 
            key.title, key.axes, asp = NA, xaxs = "i", yaxs = "i", las = 1, 
            axes = TRUE, frame.plot = axes,mar, ...) 
  {
    # modification by Ian Taylor of the filled.contour function
    # to remove the key and facilitate overplotting with contour()
    # further modified by Carey McGilliard and Bridget Ferris
    # to allow multiple plots on one page
    
    if (missing(z)) {
      if (!missing(x)) {
        if (is.list(x)) {
          z <- x$z
          y <- x$y
          x <- x$x
        }
        else {
          z <- x
          x <- seq.int(0, 1, length.out = nrow(z))
        }
      }
      else stop("no 'z' matrix specified")
    }
    else if (is.list(x)) {
      y <- x$y
      x <- x$x
    }
    if (any(diff(x) <= 0) || any(diff(y) <= 0)) 
      stop("increasing 'x' and 'y' values expected")
    # mar.orig <- (par.orig <- par(c("mar", "las", "mfrow")))$mar
    # on.exit(par(par.orig))
    # w <- (3 + mar.orig[2]) * par("csi") * 2.54
    # par(las = las)
    # mar <- mar.orig
    plot.new()
    # par(mar=mar)
    plot.window(xlim, ylim, "", xaxs = xaxs, yaxs = yaxs, asp = asp)
    
    if (!is.matrix(z) || nrow(z) <= 1 || ncol(z) <= 1) 
      stop("no proper 'z' matrix specified")
    if (!is.double(z)) 
      storage.mode(z) <- "double"
    .filled.contour(as.double(x), as.double(y), z, as.double(levels), 
                    col = col)
    
    if (missing(plot.axes)) {
      if (axes) {
        title(main = "", xlab = "", ylab = "")
        Axis(x, side = 1)
        Axis(y, side = 2)
      }
    }
    else plot.axes
    if (frame.plot) 
      box()
    if (missing(plot.title)) 
      title(...)
    else plot.title
    invisible()
  }


MakeLetter <- function(a, where="topleft", cex=2)
legend(where, pt.cex=0, bty="n", title=a, cex=cex, legend=NA)

###=======================================================================
### Parameters
###=======================================================================
#install.packages('heatmaply')
#install.packages.2 <- function (pkg) if (!require(pkg)) install.packages(pkg);
#install.packages.2('devtools')
#install.packages("akima")
#install.packages('markovchain')

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

time_end <- 50000 # Length of simulation in years

maxt <- 500
brazilNut <- list(low=plant_mat_low, high=plant_mat_high)

high_harv <- matrix(1, nrow = 17, ncol = 17)


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
#===========================================================================

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
  #Nnext <- R*N*(1-N/(K*(p))) - H*N + N
  Nnext <- (R*N*(1-N/(K*(p))) + N) * (1-H)
  #Nnext <- R*N*(1-H)*(1-N*(1-H)/(K*(p))) - N*(1-H)
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


stoch_growth <- function(delta_d, delta_p)
{
  r <- numeric(maxt)
  plant_mat <- matrix(0, nrow = 17)
  plant_mat[1:4] <- seedlingInit/4   #Setting initial population of seedlings
  plant_mat[5:11] <- saplingInit/7   #Setting initial population of saplings
  plant_mat[12:17] <- adultInit/6  #Setting initial population of adult trees
  
  plant_all <- matrix( c(sum(plant_mat[1:4]), sum(plant_mat[5:11]), sum(plant_mat[12:17])) ) # This will contain the summed plant populations at ALL timesteps
  
  agouti_vec <- c(agoutiCapacity)* (1-delta_d*.99)
  
  harvest_seq <- markovChain()
  
  for (i in 1:maxt)
  {
    h_i <- harvest_seq[i]
    
    if (h_i == "low") 
    {
      pmat <- plant_mat_low
    } 
    
    else 
    {
      pmat <- plant_mat_high
    }
    
      h_off <- highHunting
    
    
    prevN <- sum(plant_mat)
    
    p <- sigmoid(plant_to_AgoutiSteepness, adultCapacity/2, sum(plant_mat[12:17]))*delta_d + (1-delta_d) # bounded between 0.9 and 1.0.... k was 0.1
    agouti_vec[(i+1)] <- LogisticGrowthHunt(agoutiGrowth, agouti_vec[(i)],agoutiCapacity,h_off, p)
    
    if(agouti_vec[(i+1)]<0){
      agouti_vec[(i+1)]=0
    }
    plant_animal_mat <- matrix(1, nrow = 17, ncol = 17)
    plant_animal_mat[1,12:17] <- sigmoid(agouti_to_PlantSteepness, agoutiCapacity/2, agouti_vec[(i)])*delta_p + (1-delta_p) # k was 0.0025
    #  plant_animal_mat[1,12:17] <- linear(m, agouti_vec[(i+1)], b) # A different functional form
    plant_mat <- matrix( c((plant_animal_mat * pmat) %*% plant_mat))
    
    #Summing the stages into 3 categories for better plotting
    plant_mat_sum <- c( sum(plant_mat[1:4]), sum(plant_mat[5:11]), sum(plant_mat[12:17])) 
    plant_all <- cbind(plant_all, plant_mat_sum)
    
    N <- sum(plant_mat)
    r[i] <- log(N / prevN)
    
  }
  
  loglambsim <- mean(r)
  
  return(loglambsim)
}

#===========================================================================
delta_p_seq <- seq(0, 1, 0.25)
delta_d_seq <- seq(0, 1, 0.25)
harvest_seq<- seq(0,1, 0.05)
#harvest_seq<-rev(harvest_seq)

hunt_seq<- seq(0,1,0.05)

stoch_growthArray<- array(0, dim=c(length(harvest_seq),length(hunt_seq), length(delta_p_seq), length(delta_d_seq)))
binary_stoch_growthArray<- array(0, dim=c(length(harvest_seq),length(hunt_seq), length(delta_p_seq), length(delta_d_seq)))

# growthRate_mat<-matrix(0,length(xseq),length(yseq))
# row.names(growthRate_mat) <- paste(yseq)
# colnames(growthRate_mat) <- paste(xseq)
# 
# binary_mat<- matrix(0,length(xseq),length(yseq))
# rownames(binary_mat) <- paste(yseq)
# colnames(binary_mat) <- paste(xseq)

numDelta_p<- 1
numDelta_d<- 1
numRow<-1 
numCol<-1

high_harv[1,12:17] <- highHarvestFecundity 
high_harv[cbind(12:17,12:17)] <- highHarvestSurvival # Multiplier for survival rate of Adult trees

for(i in delta_d_seq){
 
  numDelta_p<- 1
  numRow<-1 
  numCol<-1
  
  
  for(j in delta_p_seq)
    {
    
    numRow<-1 
    numCol<-1
    
    for(k in hunt_seq)
    {
      
      numCol<-1
      highHunting<- k
      
      for(l in harvest_seq)
      {
        
        high_harv[cbind(12:17,12:17)] <- l # Multiplier for survival rate of Adult trees
        plant_mat_low <- plant_S_mat
        plant_mat_high <- plant_S_mat * high_harv
        
        growth_rate <- exp(stoch_growth(i,j))
        stoch_growthArray[numRow,numCol,numDelta_p,numDelta_d]<-growth_rate
        print(stoch_growthArray[numRow,numCol,numDelta_p,numDelta_d])
        
        if((stoch_growthArray[numRow,numCol,numDelta_p,numDelta_d]>1 ||stoch_growthArray[numRow,numCol,numDelta_p,numDelta_d]==1) && (!is.na(stoch_growthArray[numRow,numCol,numDelta_p,numDelta_d])))
        {
          binary_stoch_growthArray[numRow,numCol,numDelta_p,numDelta_d]<-1
        }
        else{
          binary_stoch_growthArray[numRow,numCol,numDelta_p,numDelta_d]<-0
        }
        
        numCol<-numCol+1
        
      }
      
      numRow<- numRow+1
      
    }
    numDelta_p <- numDelta_p+1
    
  }
  
  numDelta_d<- numDelta_d+1
  
}



#==============================================================================================================================================
xcoords = hunt_seq
ycoords = harvest_seq

#plot.new() is necessary if using the modified versions of filled.contour
plot.new()

par(mfrow=c(5,5), par(pty="s"), oma=c(0.5,1,0,0.5),
    mar = c(0,0.5,0,0))
color = function(x)rev(terrain.colors(x)) 
library(colorRamps)
for(i in 1:5){
  for(j in 1:5){
    filled.contour3(xcoords,ycoords,stoch_growthArray[,c(21:1),i,j],color.palette = color, plot.axes=NULL
    )
  }
}

# #Add a legend:
# par(new = "TRUE",plt = c(0.85,0.9,0.25,0.85),las = 1,cex.axis = 1)
# filled.legend(xcoords,ycoords,stoch_growthArray,color.palette = color,xlab = "",ylab = "",xlim = c(min(xintercepts),max(xintercepts)),ylim = c(min(slopes),max(slopes)))
# 
# #Add some figure labels
# par(xpd=NA,cex = 1.3)
# text(x = -16.7,y = 0,"slope",srt = 90,cex = 1.3)
# text(x = -8,y = -1.62,expression(paste(italic(x),"-intercept",sep = "")),cex = 1.3)



