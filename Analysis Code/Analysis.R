library(sft)
library(ez)
library(BayesFactor)
library(rstan)

#### EXPERIMENTS 1 & 2 ####    (Experiment 3 was conducted after an earlier version of the manuscript with only the first two experiments was reviewed so much of the analysis follows that divide)
{

# Save directory
dump.path <- "Experiment 1 2 Results"
width1 <- 3.25
width2 <- 6.875
aspect.ratio <- .75
mywidth <- 6.875
myheight <- mywidth * aspect.ratio

newStars <- function (ps) { # takes a vector of p-values and returns a vector of the same length with * entries where p < .05
  ret <- c()
  for (i in ps) {
    if (i < .05) {
      ret <- append(ret, "*")
    } else {
      ret <- append(ret, "")
    }
  }
  ret
}



# Load data
{
  behavioral.files.1 <- "Data/Experimen 1/Behavioral"
  behavioral.files.2 <- "DataExperiment 2/Behavioral"
  homdata.b <- data.frame()
  for (i in list.files(path=behavioral.files.1, full.names=T)) {
    homdata.b <- rbind(homdata.b, read.table(i, header=T, sep="\t"))
  }
  hetdata.b <- data.frame()
  for (i in list.files(path=behavioral.files.2, full.names=T)) {
    hetdata.b <- rbind(hetdata.b, read.table(i, header=T, sep="\t"))
  }
  be.data <- rbind(homdata.b,hetdata.b)
  # Make sure Subject IDs are not identical across experiments
  be.data$Subject[be.data$Version==2.7] <- be.data$Subject[be.data$Version==2.7] + 100
  # Remove time out trials
  be.nr <- subset(be.data, RT <= 0); be.data <- subset(be.data, RT > 0)
  # Strip the first day
  be.data <- subset(be.data, Session > 1)
  ## Reformat Capacity Data
  capLL <- rbind(subset(be.data, Condition=="Capacity" & Channel1==1 & Channel2==0), subset(be.data, Condition=="Capacity" & Channel1==0 & Channel2==1), subset(be.data, Condition=="SIC" & Channel1==1 & Channel2==1)); capLL$Condition <- "LL"
  capLH <- rbind(subset(be.data, Condition=="Capacity" & Channel1==1 & Channel2==0), subset(be.data, Condition=="Capacity" & Channel1==0 & Channel2==2), subset(be.data, Condition=="SIC" & Channel1==1 & Channel2==2)); capLH$Condition <- "LH"
  capHL <- rbind(subset(be.data, Condition=="Capacity" & Channel1==2 & Channel2==0), subset(be.data, Condition=="Capacity" & Channel1==0 & Channel2==1), subset(be.data, Condition=="SIC" & Channel1==2 & Channel2==1)); capHL$Condition <- "HL"
  capHH <- rbind(subset(be.data, Condition=="Capacity" & Channel1==2 & Channel2==0), subset(be.data, Condition=="Capacity" & Channel1==0 & Channel2==2), subset(be.data, Condition=="SIC" & Channel1==2 & Channel2==2)); capHH$Condition <- "HH"
  cap.data <- rbind(capLL,capLH,capHL,capHH)
  cap.data$Saliency <- as.factor(cap.data$Condition)
  cap.data$Condition <- as.factor(mapply(paste, cap.data$Version, cap.data$Target, cap.data$Saliency))
  cap.data$RT <- cap.data$RT*1000
  # Easy to understand unique label for trial condition
  be.data$Saliency <- "None"
  be.data$Saliency[be.data$Channel1==2 & be.data$Channel2==2] <- "HH"
  be.data$Saliency[be.data$Channel1==2 & be.data$Channel2==1] <- "HL"
  be.data$Saliency[be.data$Channel1==2 & be.data$Channel2==0] <- "HA"
  be.data$Saliency[be.data$Channel1==1 & be.data$Channel2==2] <- "LH"
  be.data$Saliency[be.data$Channel1==0 & be.data$Channel2==2] <- "AH"
  be.data$Saliency[be.data$Channel1==1 & be.data$Channel2==1] <- "LL"
  be.data$Saliency[be.data$Channel1==1 & be.data$Channel2==0] <- "LA"
  be.data$Saliency[be.data$Channel1==0 & be.data$Channel2==1] <- "AL"
  be.data$Saliency <- as.factor(be.data$Saliency)
  sic.data <- subset(be.data, Condition=="SIC" & Correct==1)
}

# Accuracy
{
  #init.accuracy 
  {
    acc.mat1 <- matrix(data=0,nrow=2,ncol=12); acc.mat2 <- matrix(data=0,nrow=2,ncol=12) # Barplot expects data in a matrix
    sem1 <- matrix(data=0,nrow=2,ncol=12); sem2 <- matrix(data=0,nrow=2,ncol=12) # standard error for each bar
    #### Columns are: Cap[ HA LA AH AL ] DFP [ HH HL LH LL HA LA AH AL]
    #### Rows are: Absent, Present (because that's the way boxplot decided to do the capacity stuff)
    {
      # Exp 1
      # Do Capacity first
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="ABS"&Channel1==2&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,1] <- mean(temp); sem1[1,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="RC"&Channel1==2&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,1] <- mean(temp); sem1[2,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="ABS"&Channel1==1&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,2] <- mean(temp); sem1[1,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="RC"&Channel1==1&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,2] <- mean(temp); sem1[2,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="ABS"&Channel1==0&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,3] <- mean(temp); sem1[1,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="RC"&Channel1==0&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,3] <- mean(temp); sem1[2,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="ABS"&Channel1==0&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,4] <- mean(temp); sem1[1,4] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="RC"&Channel1==0&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,4] <- mean(temp); sem1[2,4] <- sd(temp)/sqrt(length(temp))
      # Now DFP blocks
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,5] <- mean(temp); sem1[1,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,5] <- mean(temp); sem1[2,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,6] <- mean(temp); sem1[1,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,6] <- mean(temp); sem1[2,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,7] <- mean(temp); sem1[1,7] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,7] <- mean(temp); sem1[2,7] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,8] <- mean(temp); sem1[1,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,8] <- mean(temp); sem1[2,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,9] <- mean(temp); sem1[1,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,9] <- mean(temp); sem1[2,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,10] <- mean(temp); sem1[1,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,10] <- mean(temp); sem1[2,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==0&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,11] <- mean(temp); sem1[1,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==0&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,11] <- mean(temp); sem1[2,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==0&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[1,12] <- mean(temp); sem1[1,12] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==0&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat1[2,12] <- mean(temp); sem1[2,12] <- sd(temp)/sqrt(length(temp))
      # Exp 2
      # Do Capacity first
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="ABS"&Channel1==2&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,1] <- mean(temp); sem2[1,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="RC"&Channel1==2&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,1] <- mean(temp); sem2[2,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="ABS"&Channel1==1&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,2] <- mean(temp); sem2[1,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="RC"&Channel1==1&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,2] <- mean(temp); sem2[2,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="ABS"&Channel1==0&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,3] <- mean(temp); sem2[1,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="RC"&Channel1==0&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,3] <- mean(temp); sem2[2,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="ABS"&Channel1==0&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,4] <- mean(temp); sem2[1,4] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="RC"&Channel1==0&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,4] <- mean(temp); sem2[2,4] <- sd(temp)/sqrt(length(temp))
      # Now DFP blocks
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,5] <- mean(temp); sem2[1,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,5] <- mean(temp); sem2[2,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,6] <- mean(temp); sem2[1,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,6] <- mean(temp); sem2[2,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,7] <- mean(temp); sem2[1,7] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,7] <- mean(temp); sem2[2,7] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,8] <- mean(temp); sem2[1,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,8] <- mean(temp); sem2[2,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,9] <- mean(temp); sem2[1,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,9] <- mean(temp); sem2[2,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,10] <- mean(temp); sem2[1,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,10] <- mean(temp); sem2[2,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==0&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,11] <- mean(temp); sem2[1,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==0&Channel2==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,11] <- mean(temp); sem2[2,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==0&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[1,12] <- mean(temp); sem2[1,12] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==0&Channel2==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat2[2,12] <- mean(temp); sem2[2,12] <- sd(temp)/sqrt(length(temp))
    }
    
  }
  
  # plot.accuracy 
  {
    postscript(file=paste(dump.path,"Exp1 Acc.eps",sep=''), width = width2, height = width2, horizontal=F)
    op <- par(oma=c(2,0,0,0)+.1, mar=c(7,4,7,2)+.1)
    barplot(acc.mat1*100,names.arg=c('HA','LA','AH','AL','HH','HL','LH','LL','HA','LA','AH','AL'), legend.text = F, beside=T,horiz=F,col=c('blue','red'),border='black', cex.main=1,cex.axis=1,cex.lab=1,cex.names=1,main="Accuracy for Experiment 1",xlab="Trial Condition",ylab="% Correct",ylim=c(0,100),xpd=F, density=c(15,40))
    arrows(x0=seq(1.5,35.5,1)[-1*seq(3,length(seq(1.5,35.5,1)),3)], y0=100*(acc.mat1-sem1), y1=100*(acc.mat1+sem1), angle=90, code=3, lwd=2, length=.04); par(xpd=NA); lines(x=rep(12.5,2),y=c(-12,114), lty=2,lwd=2)
    text(x=c(6.5,24.5), y=c(110,110), labels=c('Single-Feature Blocks','Two-Feature Blocks'), adj=.5, xpd=NA)
    legend(x=mean(par()$usr[1:2]), y=mean(par()$usr[3]-35.5), legend=c('Target Absent','Target Present'), fill=c('blue','red'), border='black', angle=45, density=c(15,40), bty='n', horiz=T, xjust=.5, yjust=0, xpd=NA)
    dev.off()
    par(op)
    postscript(file=paste(dump.path,"Exp2 Acc.eps",sep=''), width = width2, height = width2, horizontal=F)
    op <- par(oma=c(2,0,0,0)+.1, mar=c(7,4,7,2)+.1)
    barplot(acc.mat2*100,names.arg=c('HA','LA','AH','AL','HH','HL','LH','LL','HA','LA','AH','AL'), legend.text = F, beside=T,horiz=F,col=c('blue','red'),border='black',cex.main=1,cex.axis=1,cex.lab=1,cex.names=1,main="Accuracy for Experiment 2",xlab="Trial Condition",ylab="% Correct",ylim=c(0,100),xpd=F, density=c(15,40))
    arrows(x0=seq(1.5,35.5,1)[-1*seq(3,length(seq(1.5,35.5,1)),3)], y0=100*(acc.mat2-sem2), y1=100*(acc.mat2+sem2), angle=90, code=3, lwd=2, length=.04); par(xpd=NA); lines(x=rep(12.5,2),y=c(-12,114), lty=2,lwd=2)
    text(x=c(6.5,24.5), y=c(110,110), labels=c('Single-Feature Blocks','Two-Feature Blocks'), adj=.5, xpd=NA)
    legend(x=mean(par()$usr[1:2]), y=mean(par()$usr[3]-35.5), legend=c('Target Absent','Target Present'), fill=c('blue','red'), border='black', angle=45, density=c(15,40), bty='n', horiz=T, xjust=.5, yjust=0, xpd=NA)
    dev.off()
    par(op)
  }
}

# RT (bar plots to complement accuracy above)
{
  # init.rt 
  {
    rt.mat1 <- matrix(data=0,nrow=2,ncol=12); rt.mat2 <- matrix(data=0,nrow=2,ncol=12) # Barplot expects data in a matrix
    rt.sem1 <- matrix(data=0,nrow=2,ncol=12); rt.sem2 <- matrix(data=0,nrow=2,ncol=12) # standard error for each bar
    #### Columns are: Cap[ HA LA AH AL ] DFP [ HH HL LH LL HA LA AH AL]
    #### Rows are: Absent, Present (because that's the way boxplot decided to do the capacity stuff)
    {
      # Exp 1
      # Do Capacity first
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="ABS"&Channel1==2&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,1] <- mean(temp); rt.sem1[1,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="RC"&Channel1==2&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,1] <- mean(temp); rt.sem1[2,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="ABS"&Channel1==1&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,2] <- mean(temp); rt.sem1[1,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="RC"&Channel1==1&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,2] <- mean(temp); rt.sem1[2,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="ABS"&Channel1==0&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,3] <- mean(temp); rt.sem1[1,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="RC"&Channel1==0&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,3] <- mean(temp); rt.sem1[2,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="ABS"&Channel1==0&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,4] <- mean(temp); rt.sem1[1,4] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="Capacity"&Target=="RC"&Channel1==0&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,4] <- mean(temp); rt.sem1[2,4] <- sd(temp)/sqrt(length(temp))
      # Now DFP blocks
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,5] <- mean(temp); rt.sem1[1,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,5] <- mean(temp); rt.sem1[2,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,6] <- mean(temp); rt.sem1[1,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,6] <- mean(temp); rt.sem1[2,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,7] <- mean(temp); rt.sem1[1,7] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,7] <- mean(temp); rt.sem1[2,7] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,8] <- mean(temp); rt.sem1[1,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,8] <- mean(temp); rt.sem1[2,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,9] <- mean(temp); rt.sem1[1,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,9] <- mean(temp); rt.sem1[2,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,10] <- mean(temp); rt.sem1[1,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,10] <- mean(temp); rt.sem1[2,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==0&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,11] <- mean(temp); rt.sem1[1,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==0&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,11] <- mean(temp); rt.sem1[2,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="ABS"&Channel1==0&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[1,12] <- mean(temp); rt.sem1[1,12] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==1.7&Condition=="SIC"&Target=="RC"&Channel1==0&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat1[2,12] <- mean(temp); rt.sem1[2,12] <- sd(temp)/sqrt(length(temp))
      # Exp 2
      # Do Capacity first
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="ABS"&Channel1==2&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,1] <- mean(temp); rt.sem2[1,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="RC"&Channel1==2&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,1] <- mean(temp); rt.sem2[2,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="ABS"&Channel1==1&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,2] <- mean(temp); rt.sem2[1,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="RC"&Channel1==1&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,2] <- mean(temp); rt.sem2[2,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="ABS"&Channel1==0&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,3] <- mean(temp); rt.sem2[1,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="RC"&Channel1==0&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,3] <- mean(temp); rt.sem2[2,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="ABS"&Channel1==0&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,4] <- mean(temp); rt.sem2[1,4] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="Capacity"&Target=="RC"&Channel1==0&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,4] <- mean(temp); rt.sem2[2,4] <- sd(temp)/sqrt(length(temp))
      # Now DFP blocks
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,5] <- mean(temp); rt.sem2[1,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,5] <- mean(temp); rt.sem2[2,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,6] <- mean(temp); rt.sem2[1,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,6] <- mean(temp); rt.sem2[2,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,7] <- mean(temp); rt.sem2[1,7] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,7] <- mean(temp); rt.sem2[2,7] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,8] <- mean(temp); rt.sem2[1,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,8] <- mean(temp); rt.sem2[2,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==2&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,9] <- mean(temp); rt.sem2[1,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==2&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,9] <- mean(temp); rt.sem2[2,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==1&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,10] <- mean(temp); rt.sem2[1,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==1&Channel2==0&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,10] <- mean(temp); rt.sem2[2,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==0&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,11] <- mean(temp); rt.sem2[1,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==0&Channel2==2&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,11] <- mean(temp); rt.sem2[2,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="ABS"&Channel1==0&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[1,12] <- mean(temp); rt.sem2[1,12] <- sd(temp)/sqrt(length(temp))
      temp <- subset(be.data, Version==2.7&Condition=="SIC"&Target=="RC"&Channel1==0&Channel2==1&Correct==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat2[2,12] <- mean(temp); rt.sem2[2,12] <- sd(temp)/sqrt(length(temp))
    }
    
  }
  
  # plot.rt 
  {
    postscript(file=paste(dump.path,"Exp1 RT.eps",sep=''), width = width2, height = width2, horizontal=F)
    op <- par(oma=c(2,0,0,0)+.1, mar=c(7,4,3.5,2)+.1)
    barplot(rt.mat1,names.arg=c('HA','LA','AH','AL','HH','HL','LH','LL','HA','LA','AH','AL'), legend.text = F, beside=T,horiz=F,col=c('blue','red'),border='black', cex.main=1,cex.axis=1,cex.lab=1,cex.names=1,main="Search Times for Experiment 1",xlab="Trial Condition",ylab="Mean RT (s)",ylim=c(0,5.5),xpd=F, density=c(15,40))
    arrows(x0=seq(1.5,35.5,1)[-1*seq(3,length(seq(1.5,35.5,1)),3)], y0=(rt.mat1-rt.sem1), y1=(rt.mat1+rt.sem1), angle=90, code=3, lwd=2, length=.04); par(xpd=NA); lines(x=rep(12.5,2),y=c(-.6,5.7), lty=2,lwd=2)
    text(x=c(6.5,24.5), y=c(5.5,5.5), labels=c('Single-Feature Blocks','Two-Feature Blocks'), adj=.5, xpd=NA)
    legend(x=mean(par()$usr[1:2]), y=mean(par()$usr[3]-1.6), legend=c('Target Absent','Target Present'), fill=c('blue','red'), border='black', angle=45, density=c(15,40), bty='n', horiz=T, xjust=.5, yjust=0, xpd=NA)
    dev.off()
    par(op)
    postscript(file=paste(dump.path,"Exp2 RT.eps",sep=''), width = width2, height = width2, horizontal=F)
    op <- par(oma=c(2,0,0,0)+.1, mar=c(7,4,3.5,2)+.1)
    barplot(rt.mat2,names.arg=c('HA','LA','AH','AL','HH','HL','LH','LL','HA','LA','AH','AL'), legend.text = F, beside=T,horiz=F,col=c('blue','red'),border='black', cex.main=1,cex.axis=1,cex.lab=1,cex.names=1,main="Search Times for Experiment 2",xlab="Trial Condition",ylab="Mean RT (s)",ylim=c(0,5.5),xpd=F, density=c(15,40))
    arrows(x0=seq(1.5,35.5,1)[-1*seq(3,length(seq(1.5,35.5,1)),3)], y0=(rt.mat2-rt.sem2), y1=(rt.mat2+rt.sem2), angle=90, code=3, lwd=2, length=.04); par(xpd=NA); lines(x=rep(12.5,2),y=c(-.6,5.7), lty=2,lwd=2)
    text(x=c(6.5,24.5), y=c(5.5,5.5), labels=c('Single-Feature Blocks','Two-Feature Blocks'), adj=.5, xpd=NA)
    legend(x=mean(par()$usr[1:2]), y=mean(par()$usr[3]-1.6), legend=c('Target Absent','Target Present'), fill=c('blue','red'), border='black', angle=45, density=c(15,40), bty='n', horiz=T, xjust=.5, yjust=0, xpd=NA)
    dev.off()
    par(op)
  }
}

# Capacity
{
  #init.capacity 
  {
    cap.out <- capacityGroup(cap.data, stopping.rule = "AND", acc.cutoff = .75, plotCt = F)
    cap.pca <- fPCAcapacity(cap.data, dimensions=3, stopping.rule = "AND", register = "median", plotPCs = T)
    
    cap.testing <- cap.pca$Scores
    cap.testing$Z <- 0
    for (i in 1:length(cap.out$capacity)) {
      if (is.null(cap.out$capacity[[i]])) {
        cap.testing$Z[i] <- NA
      } else {
        cap.testing$Z[i] <- cap.out$capacity[[i]]$Ctest$statistic[[1]]
      }
    }
    cap.testing$Experiment <- ""; for (i in 1:length(cap.testing$Experiment)) cap.testing$Experiment[i] <- strsplit(as.character(cap.testing$Condition[i]), " ")[[1]][1]; cap.testing$Experiment <- as.factor(cap.testing$Experiment)
    cap.testing$Target <- ""; for (i in 1:length(cap.testing$Target)) cap.testing$Target[i] <- strsplit(as.character(cap.testing$Condition[i]), " ")[[1]][2]; cap.testing$Target <- as.factor(cap.testing$Target)
    cap.testing$Saliency <- ""; for (i in 1:length(cap.testing$Saliency)) cap.testing$Saliency[i] <- strsplit(as.character(cap.testing$Condition[i]), " ")[[1]][3]; cap.testing$Saliency <- as.factor(cap.testing$Saliency)
    
    cap.testing$Subject <- as.numeric(levels(cap.testing$Subject)[cap.testing$Subject])
    reduced.cap <- cap.testing
    for (i in unique(c(cap.testing$Subject[is.na(cap.testing$D1)], cap.testing$Subject[is.na(cap.testing$D2)],cap.testing$Subject[is.na(cap.testing$D3)],cap.testing$Subject[is.na(cap.testing$Z)]))) reduced.cap <- subset(reduced.cap, Subject != i)
    cap.testing$Subject <- as.factor(cap.testing$Subject)
    reduced.cap$Subject <- as.factor(reduced.cap$Subject)
    
    reduced.cap$Color <- as.factor(sapply(reduced.cap$Saliency, function (x) if (x=="HH" | x=="HL") 2 else 1))
    reduced.cap$Shape <- as.factor(sapply(reduced.cap$Saliency, function (x) if (x=="HH" | x=="LH") 2 else 1))
    cap1tp.bfanova <- anovaBF(Z ~ Color * Shape + Subject, data = subset(reduced.cap, Experiment == 1.7 & Target == 'RC'), whichRandom = "Subject")
    cap1ta.bfanova <- anovaBF(Z ~ Color * Shape + Subject, data = subset(reduced.cap, Experiment == 1.7 & Target == 'ABS'), whichRandom = "Subject")
    cap2tp.bfanova <- anovaBF(Z ~ Color * Shape + Subject, data = subset(reduced.cap, Experiment == 2.7 & Target == 'RC'), whichRandom = "Subject")
    cap2ta.bfanova <- anovaBF(Z ~ Color * Shape + Subject, data = subset(reduced.cap, Experiment == 2.7 & Target == 'ABS'), whichRandom = "Subject")
    
    #save(cap1tp.bfanova,cap1ta.bfanova,cap2tp.bfanova,cap2ta.bfanova, file='capacity z bfanovas.R')
    
    num.mod <- 4
    temp.mod <- sort(cap2tp.bfanova,decreasing = T)[1:num.mod]
    suppressWarnings(temp.mat <- as.matrix(temp.mod/temp.mod))
    dimnames(temp.mat) <- list(1:num.mod,1:num.mod)
    temp.mod
    temp.mat
    
    
    cap.anova.Z <- ezANOVA(data = reduced.cap, dv = Z, wid=Subject, within=c(Target,Saliency), between=Experiment)
    cap.anova.Z$ANOVA$p <- cap.anova.Z$ANOVA$p * 4; cap.anova.Z$ANOVA$`p<.05` <- newStars(cap.anova.Z$ANOVA$p)
    cap.anova.Z$`Sphericity Corrections`$`p[GG]`<-cap.anova.Z$`Sphericity Corrections`$`p[GG]`*4; cap.anova.Z$`Sphericity Corrections`$`p[GG]<.05`<-newStars(cap.anova.Z$`Sphericity Corrections`$`p[GG]`)
    cap.anova.Z$`Sphericity Corrections`$`p[HF]`<-cap.anova.Z$`Sphericity Corrections`$`p[HF]`*4; cap.anova.Z$`Sphericity Corrections`$`p[HF]<.05`<-newStars(cap.anova.Z$`Sphericity Corrections`$`p[HF]`)
    
    cap.anova.D1 <- ezANOVA(data = reduced.cap, dv = D1, wid=Subject, within=c(Target,Saliency), between=Experiment)
    cap.anova.D1$ANOVA$p <- cap.anova.D1$ANOVA$p * 4; cap.anova.D1$ANOVA$`p<.05` <- newStars(cap.anova.D1$ANOVA$p)
    cap.anova.D1$`Sphericity Corrections`$`p[GG]`<-cap.anova.D1$`Sphericity Corrections`$`p[GG]`*4; cap.anova.D1$`Sphericity Corrections`$`p[GG]<.05`<-newStars(cap.anova.D1$`Sphericity Corrections`$`p[GG]`)
    cap.anova.D1$`Sphericity Corrections`$`p[HF]`<-cap.anova.D1$`Sphericity Corrections`$`p[HF]`*4; cap.anova.D1$`Sphericity Corrections`$`p[HF]<.05`<-newStars(cap.anova.D1$`Sphericity Corrections`$`p[HF]`)
    
    cap.anova.D2 <- ezANOVA(data = reduced.cap, dv = D2, wid=Subject, within=c(Target,Saliency), between=Experiment)
    cap.anova.D2$ANOVA$p <- cap.anova.D2$ANOVA$p * 4; cap.anova.D2$ANOVA$`p<.05` <- newStars(cap.anova.D2$ANOVA$p)
    cap.anova.D2$`Sphericity Corrections`$`p[GG]`<-cap.anova.D2$`Sphericity Corrections`$`p[GG]`*4; cap.anova.D2$`Sphericity Corrections`$`p[GG]<.05`<-newStars(cap.anova.D2$`Sphericity Corrections`$`p[GG]`)
    cap.anova.D2$`Sphericity Corrections`$`p[HF]`<-cap.anova.D2$`Sphericity Corrections`$`p[HF]`*4; cap.anova.D2$`Sphericity Corrections`$`p[HF]<.05`<-newStars(cap.anova.D2$`Sphericity Corrections`$`p[HF]`)
    
    cap.anova.D3 <- ezANOVA(data = reduced.cap, dv = D3, wid=Subject, within=c(Target,Saliency), between=Experiment)
    cap.anova.D3$ANOVA$p <- cap.anova.D3$ANOVA$p * 4; cap.anova.D3$ANOVA$`p<.05` <- newStars(cap.anova.D3$ANOVA$p)
    cap.anova.D3$`Sphericity Corrections`$`p[GG]`<-cap.anova.D3$`Sphericity Corrections`$`p[GG]`*4; cap.anova.D3$`Sphericity Corrections`$`p[GG]<.05`<-newStars(cap.anova.D3$`Sphericity Corrections`$`p[GG]`)
    cap.anova.D3$`Sphericity Corrections`$`p[HF]`<-cap.anova.D3$`Sphericity Corrections`$`p[HF]`*4; cap.anova.D3$`Sphericity Corrections`$`p[HF]<.05`<-newStars(cap.anova.D3$`Sphericity Corrections`$`p[HF]`)
  }
  
  # plot.capacity 
  {
    ## Making some plots of Z-Caps
    postscript(file=paste(dump.path,"Capacity Z scores.eps",sep=''), width = mywidth, height = myheight, horizontal=F)
    boxplot(reduced.cap$Z~reduced.cap$Condition, ylim=c(0,12), main="Capacity (AND) Z-Scores", ylab="Z(C(t))",xaxt='n',cex.main=1,cex.axis=1,cex.lab=1,lwd=1); axis(1,at=0:16,cex.axis=.8, tick=F, labels=c(" ", rep(c("HH","HL","LH","LL"), 4)))
    text(rep(c(2.5,6.5,10.5,14.5),2), c(rep(12,4),rep(11,4)), labels=c(rep("Experiment 1",2),rep("Experiment 2",2),"Target Absent","Target Present","Target Absent","Target Present"), cex=1)
    abline(v=c(4.5,8.5,12.5)); abline(h=0, lty=2,lwd=2); text(12,.4, labels="UCIP Performance", cex=1)
    dev.off()
  
    
    titles <- c('Exp 1 - HH\nTarget Absent','Exp 1 - HL\nTarget Absent','Exp 1 - LH\nTarget Absent','Exp 1 - LL\nTarget Absent',
                'Exp 1 - HH\nTarget Present','Exp 1 - HL\nTarget Present','Exp 1 - LH\nTarget Present','Exp 1 - LL\nTarget Present',
                'Exp 2 - HH\nTarget Absent','Exp 2 - HL\nTarget Absent','Exp 2 - LH\nTarget Absent','Exp 2 - LL\nTarget Absent',
                'Exp 2 - HH\nTarget Present','Exp 2 - HL\nTarget Present','Exp 2 - LH\nTarget Present','Exp 2 - LL\nTarget Present')
    tvec <- 1:max(cap.data$RT)
    for (con in 1:length(unique(cap.data$Condition))) {
      if (con%%4==1) {
        postscript(paste(dump.path,'capacity_',c('Exp1_TA','Exp1_TP','Exp2_TA','Exp2_TP')[(con-1)%/%4+1],'.eps',sep=''),width=width2,height=width2, horizontal=F)
        par(mfrow=c(2,2))
      }
      plot(0,0,type='n',xlim=c(0,10000),ylim=c(0,25),main=c('HH','HL','LH','LL')[(con-1)%%4+1],xlab='t (milliseconds)',ylab='C(t)')
      n <- length(unique(cap.data$Subject[cap.data$Condition==levels(cap.data$Condition)[sort(unique(cap.data$Condition))][con]]))
      for (i in 1:n) {
        this <- subset(cap.data, Condition==levels(cap.data$Condition)[sort(unique(cap.data$Condition))][con] & Subject==sort(unique(cap.data$Subject[cap.data$Condition==levels(cap.data$Condition)[sort(unique(cap.data$Condition))][con]]))[i])
        #this <- as.data.frame(lapply(this, function (x) if (is.factor(x)) factor(x) else x))
        cand <- capacity.and(list(this$RT[this$Channel1>0 & this$Channel2>0], this$RT[this$Channel1>0 & this$Channel2==0], this$RT[this$Channel1==0 & this$Channel2>0]),
                             list(this$Correct[this$Channel1>0 & this$Channel2>0], this$Correct[this$Channel1>0 & this$Channel2==0], this$Correct[this$Channel1==0 & this$Channel2>0]))
        lines(tvec, cand$Ct(tvec), col=rainbow(n)[i])
      }
      abline(h=1,lty=2)
      if (con%%4==0) dev.off()
    }
    par(mfrow=c(1,1))
  }
}

# SIC
{
  sic.analysis <- function (mydata, subject, exp, target) {
    myret <- c(subject, exp, target)
    HH <- subset(mydata, Subject==subject & Version==exp & Target==target & Channel1==2 & Channel2==2 & Correct==1)$RT
    HL <- subset(mydata, Subject==subject & Version==exp & Target==target & Channel1==2 & Channel2==1 & Correct==1)$RT
    LH <- subset(mydata, Subject==subject & Version==exp & Target==target & Channel1==1 & Channel2==2 & Correct==1)$RT
    LL <- subset(mydata, Subject==subject & Version==exp & Target==target & Channel1==1 & Channel2==1 & Correct==1)$RT
    
    # Selective Influence
    sid <- siDominance(HH,HL,LH,LL)
    if (any(sid$p.value[5:8] < .05)) {
      myret <- append(myret, "Fail")
    } else if (all(sid$p.value[1:4] < .05)) {
      myret <- append(myret, "Pass")
    } else {
      myret <- append(myret, "Ambiguous")
    }
    # SIC Testing
    this <- sic.test(HH,HL,LH,LL)
    mic <- mic.test(HH,HL,LH,LL)
    pp <- this$positive$p.value
    np <- this$negative$p.value
    
    if (pp < .33) myret <- append(myret, "Significant") else myret <- append(myret, "Nonsignificant")
    if (np < .33) myret <- append(myret, "Significant") else myret <- append(myret, "Nonsignificant")
    if (mic$statistic[[1]] > 0 & mic$p.value < .33) {
      myret <- append(myret, "Positive")
    } else if (mic$statistic[[1]] < 0 & mic$p.value < .33) {
      myret <- append(myret, "Negative")
    } else {
      myret <- append(myret, "Nonsignificant")
    }
    
    if (pp < .33 & np < .33) {
      if (mic$statistic[[1]] > 0 & mic$p.value < .33) {
        myret <- append(myret, "COACTIVE")
      } else myret <- append(myret, "SERIAL-AND")
    } else if (pp < .33 & np >= .33) {
      myret <- append(myret, "PARALLEL-OR")
    } else if (pp >= .33 & np < .33) {
      myret <- append(myret, "PARALLEL-AND")
    } else if (pp >= .33 & np >= .33) {
      myret <- append(myret, "SERIAL-OR")
    }
    myret
  } # Helper function for SIC
  init.sic <- function (saveTable=F, ...) {
    sic.out <- list()
    for (experiment in unique(sic.data$Version)) {
      this.exp <- subset(sic.data, Version == experiment)
      for (target.presence in unique(this.exp$Target)) {
        this.target <- subset(this.exp, Target == target.presence)
        # Add to SIC summary table (because sicGroup forces alpha = .05 and we want a=.3)
        for (s in sort(unique(this.target$Subject))) sic.out <- rbind(sic.out, sic.analysis(sic.data, s, experiment, target.presence))
      }
    }
    sic.out <- as.data.frame(sic.out)
    names(sic.out) <- c("Subject", "Experiment", "Target", "Selective.Influence", "Positive.SIC", "Negative.SIC", "MIC", "Predicted.by")
    if (saveTable) {
      psic.out <- data.frame(lapply(sic.out, as.character), stringsAsFactors = F)
      write.csv(psic.out, file = myfile)
    }
  }
  # plot.sic 
  {
    tvec <- seq(0,5,.001)
    for (experiment in unique(sic.data$Version)) {
      this.exp <- subset(sic.data, Version == experiment)
      for (target.presence in unique(this.exp$Target)) {
        this.target <- subset(this.exp, Target == target.presence)
        if (target.presence == "RC") tp <- "Present"
        if (target.presence == "ABS") tp <- "Absent"
        
        postscript(file=paste(dump.path,paste('Exp',experiment,'Target', target.presence,'Survivors'),'.eps',sep=''),width=mywidth,height=mywidth, horizontal=F)
        
        opar <- par(); par(mfrow=c(4,4))
        # Do Survivors first
        plot.default(0,0, type='n',xlim=c(0,1),ylim=c(0,1), axes=F, xlab="",ylab=""); text(c(.5,.5,.5),c(.9,.6,.25),cex=1, labels=c(paste("Experiment", substr(as.character(experiment),1,1)), paste("Target:",tp), "Survivor Functions"))#, font="Arial")
        for (s in sort(unique(this.target$Subject))) {
          mydata <- subset(this.target, Subject==s)
          plot(tvec, 1-ecdf(subset(mydata, Channel1==1 & Channel2==1 & Correct==1)$RT)(tvec), col="blue", lwd=1, type="l", cex.main=1,cex.axis=1,cex.lab=1, main=paste("Subject",s),xlab="t (seconds)",ylab="S(t)",ylim=c(0,1))
          lines(tvec, 1-ecdf(subset(mydata, Channel1==1 & Channel2==2 & Correct==1)$RT)(tvec), col="purple", lwd=1)
          lines(tvec, 1-ecdf(subset(mydata, Channel1==2 & Channel2==1 & Correct==1)$RT)(tvec), col="orange", lwd=1)
          lines(tvec, 1-ecdf(subset(mydata, Channel1==2 & Channel2==2 & Correct==1)$RT)(tvec), col="red", lwd=1)
          #abline(h=0,lty=3)
        }
        
        dev.off()
        
        # Do SICs second
        postscript(file=paste(dump.path,paste('Exp',experiment,'Target', target.presence,'SIC'),'.eps',sep=''),width=width1, height=width1, horizontal=F)
        
        par(mfrow=c(1,1))
        plot.default(0,0, type='n',xlim=c(0,5),ylim=c(-.25,1), cex.main=.8,cex.axis=.9,cex.lab=1, main=paste("Experiment", substr(as.character(experiment),1,1), "\nTarget", tp, "SIC"),xlab="t (seconds)",ylab="SIC(t)")
        for (s in 1:length(sort(unique(this.target$Subject)))) {
          mydata <- subset(this.target, Subject==sort(unique(this.target$Subject))[s])
          #plot(tvec, ecdf(subset(mydata, Channel1==1 & Channel2==2 & Correct==1)$RT)(tvec) +
          lines(tvec, ecdf(subset(mydata, Channel1==1 & Channel2==2 & Correct==1)$RT)(tvec) +
                  ecdf(subset(mydata, Channel1==2 & Channel2==1 & Correct==1)$RT)(tvec) -
                  ecdf(subset(mydata, Channel1==1 & Channel2==1 & Correct==1)$RT)(tvec) -
                  ecdf(subset(mydata, Channel1==2 & Channel2==2 & Correct==1)$RT)(tvec), col=rainbow(n=length(unique(this.target$Subject)), alpha=1)[s], lwd=1)
          #type="l", main=paste("Subject",s),xlab="Seconds",ylab="SIC(t)",ylim=c(-.5,1))
          abline(h=0,lty=3)
        }
        
        dev.off()
        #abline(h=0,lty=3)
      }
    }
  }
  
  sic.stats <- data.frame('Experiment'=character(), 'Target'=character(), 'Subject'=character(), 'dp'=numeric(), 'pp'=numeric(), 'dn'=numeric(), 'pn'=numeric())
  for (exp in 1:length(unique(sic.data$Version))) {
    for (tar in 1:length(unique(sic.data$Target))) {
      these <- subset(sic.data, Version==sort(unique(sic.data$Version))[exp] & Target==sort(unique(sic.data$Target))[tar])
      for (s in 1:length(unique(these$Subject))) {
        this <- subset(these, Subject==sort(unique(these$Subject))[s])
        mysic <- sic.test(HH=this$RT[this$Channel1==2 & this$Channel2==2],HL=this$RT[this$Channel1==2 & this$Channel2==1],
                          LH=this$RT[this$Channel1==1 & this$Channel2==2],LL=this$RT[this$Channel1==1 & this$Channel2==1])
        sic.stats <- rbind(sic.stats,list('Experiment'=this$Version[1],'Target'=this$Target[1],'Subject'=this$Subject[1],'dp'=mysic$positive$statistic,'pp'=mysic$positive$p.value,'dn'=mysic$negative$statistic,'pn'=mysic$negative$p.value))
      }
    }
  }
  sic.stats$Target <- levels(sic.stats$Target)[sic.stats$Target]
  sic.stats$Target[is.na(sic.stats$Target)] <- 'RC' # Not sure why this is happening but okay
}

{  
  cap.data$Target <- as.character(levels(cap.data$Target)[cap.data$Target])
  cap.data$Saliency <- as.character(levels(cap.data$Saliency)[cap.data$Saliency])
  cap.stats <- data.frame('Experiment'=numeric(), 'Target'=character(), 'Subject'=numeric(), 'Saliency'=character(), 'Z'=numeric(), 'p'=numeric(), stringsAsFactors = F)
  for (exp in 1:length(unique(cap.data$Version))) {
    for (tar in 1:length(unique(cap.data$Target))) {
      these <- subset(cap.data, Version==sort(unique(cap.data$Version))[exp] & Target==sort(unique(cap.data$Target))[tar])
      for (s in 1:length(unique(these$Subject))) {
        for (sal in 1:length(unique(these$Saliency))) {
          this <- subset(these, Subject==sort(unique(these$Subject))[s] & Saliency==sort(unique(these$Saliency))[sal])
          myct <- capacity.and(RT=list(subset(this, Channel1!=0 & Channel2!=0)$RT, subset(this, Channel1!=0 & Channel2==0)$RT, subset(this, Channel1==0 & Channel2!=0)$RT),
                               CR=list(subset(this, Channel1!=0 & Channel2!=0)$Correct, subset(this, Channel1!=0 & Channel2==0)$Correct, subset(this, Channel1==0 & Channel2!=0)$Correct))
          cap.stats <- rbind(cap.stats, data.frame('Experiment'=this$Version[1],'Target'=this$Target[1],'Subject'=this$Subject[1], 'Saliency'=this$Saliency[1], 'Z'=myct$Ctest$statistic, 'p'=myct$Ctest$p.value, stringsAsFactors = F))
        }
      }
    }
  }
  cap.stats$Capacity <- mapply(function(x,y) if (x < 0 & y < .05) "Limited" else if (x > 0 & y < .05) "Super" else "Unlimited", x=cap.stats$Z, y=cap.stats$p)
  cap.data$Target <- as.factor(cap.data$Target); cap.data$Saliency <- as.factor(cap.data$Saliency)
  cap.stats.sum <- data.frame('Experiment'=c(rep(1.7,8),rep(2.7,8)), 'Target'=rep(c(rep('RC',4),rep('ABS',4)),2), 'Saliency'=rep(c('HH','HL','LH','LL'),4), stringsAsFactors = F)
  cap.stats.sum$Z.min <- mapply(function(x1,x2,x3) min(subset(cap.stats, Experiment==x1 & Target==x2 & Saliency==x3)$Z), cap.stats.sum$Experiment, cap.stats.sum$Target, cap.stats.sum$Saliency)
  cap.stats.sum$Z.max <- mapply(function(x1,x2,x3) max(subset(cap.stats, Experiment==x1 & Target==x2 & Saliency==x3)$Z), cap.stats.sum$Experiment, cap.stats.sum$Target, cap.stats.sum$Saliency)
  cap.stats.sum$p.min <- mapply(function(x1,x2,x3) min(subset(cap.stats, Experiment==x1 & Target==x2 & Saliency==x3)$p), cap.stats.sum$Experiment, cap.stats.sum$Target, cap.stats.sum$Saliency)
  cap.stats.sum$p.max <- mapply(function(x1,x2,x3) max(subset(cap.stats, Experiment==x1 & Target==x2 & Saliency==x3)$p), cap.stats.sum$Experiment, cap.stats.sum$Target, cap.stats.sum$Saliency)
  
  
  
  # Retrying this with an OR rule for the hell of it
  cap.stats.or <- data.frame('Experiment'=numeric(), 'Target'=character(), 'Subject'=numeric(), 'Saliency'=character(), 'Z'=numeric(), 'p'=numeric(), stringsAsFactors = F)
  for (exp in 1:length(unique(cap.data$Version))) {
    for (tar in 1:length(unique(cap.data$Target))) {
      these <- subset(cap.data, Version==sort(unique(cap.data$Version))[exp] & Target==sort(unique(cap.data$Target))[tar])
      for (s in 1:length(unique(these$Subject))) {
        for (sal in 1:length(unique(these$Saliency))) {
          this <- subset(these, Subject==sort(unique(these$Subject))[s] & Saliency==sort(unique(these$Saliency))[sal])
          myct <- capacity.or(RT=list(subset(this, Channel1!=0 & Channel2!=0)$RT, subset(this, Channel1!=0 & Channel2==0)$RT, subset(this, Channel1==0 & Channel2!=0)$RT),
                              CR=list(subset(this, Channel1!=0 & Channel2!=0)$Correct, subset(this, Channel1!=0 & Channel2==0)$Correct, subset(this, Channel1==0 & Channel2!=0)$Correct))
          cap.stats.or <- rbind(cap.stats.or, data.frame('Experiment'=this$Version[1],'Target'=this$Target[1],'Subject'=this$Subject[1], 'Saliency'=this$Saliency[1], 'Z'=myct$Ctest$statistic, 'p'=myct$Ctest$p.value, stringsAsFactors = F))
        }
      }
    }
  }
  cap.stats.or$Capacity <- mapply(function(x,y) if (x < 0 & y < .05) "Limited" else if (x > 0 & y < .05) "Super" else "Unlimited", x=cap.stats.or$Z, y=cap.stats.or$p)
  cap.data$Target <- as.factor(cap.data$Target); cap.data$Saliency <- as.factor(cap.data$Saliency)
  cap.stats.or.sum <- data.frame('Experiment'=c(rep(1.7,8),rep(2.7,8)), 'Target'=rep(c(rep('RC',4),rep('ABS',4)),2), 'Saliency'=rep(c('HH','HL','LH','LL'),4), stringsAsFactors = F)
  cap.stats.or.sum$Z.min <- mapply(function(x1,x2,x3) min(subset(cap.stats.or, Experiment==x1 & Target==x2 & Saliency==x3)$Z), cap.stats.or.sum$Experiment, cap.stats.or.sum$Target, cap.stats.or.sum$Saliency)
  cap.stats.or.sum$Z.max <- mapply(function(x1,x2,x3) max(subset(cap.stats.or, Experiment==x1 & Target==x2 & Saliency==x3)$Z), cap.stats.or.sum$Experiment, cap.stats.or.sum$Target, cap.stats.or.sum$Saliency)
  cap.stats.or.sum$p.min <- mapply(function(x1,x2,x3) min(subset(cap.stats.or, Experiment==x1 & Target==x2 & Saliency==x3)$p), cap.stats.or.sum$Experiment, cap.stats.or.sum$Target, cap.stats.or.sum$Saliency)
  cap.stats.or.sum$p.max <- mapply(function(x1,x2,x3) max(subset(cap.stats.or, Experiment==x1 & Target==x2 & Saliency==x3)$p), cap.stats.or.sum$Experiment, cap.stats.or.sum$Target, cap.stats.or.sum$Saliency)
  cap.stats.or$Condition <- mapply(paste,cap.stats.or$Experiment,cap.stats.or$Target,cap.stats.or$Saliency)

}

# Traditional ANOVAs 
{
  exp1.ss <- subset(be.data, Version==1.7 & (Channel1==0 | Channel2==0))
  exp1.rs <- subset(be.data, Version==1.7 & Channel1!=0 & Channel2!=0)
  exp2.cap.ss <- subset(be.data, Version==2.7 & Condition=='Capacity' & (Channel1==0 | Channel2==0))
  #exp2.cap.rs <- subset(be.data, Version==2.7 & Condition=='Capacity' & Channel1!=0 & Channel2!=0) # These trial conditions do not exist
  exp2.dfp.ss <- subset(be.data, Version==2.7 & Condition=='SIC' & (Channel1==0 | Channel2==0))
  exp2.dfp.rs <- subset(be.data, Version==2.7 & Condition=='SIC' & Channel1!=0 & Channel2!=0)
  # Single source df's need to add two factors to replace Channels - Source and Dissimilarity - Dual source df's can continue to use Channels
  exp1.ss$Source <- mapply(function(x,y) which.max(c(x,y)), x=exp1.ss$Channel1, y=exp1.ss$Channel2)
  exp1.ss$Dissimilarity <- mapply(function(x,y) max(c(x,y)), exp1.ss$Channel1, exp1.ss$Channel2)
  exp2.cap.ss$Source <- mapply(function(x,y) which.max(c(x,y)), x=exp2.cap.ss$Channel1, y=exp2.cap.ss$Channel2)
  exp2.cap.ss$Dissimilarity <- mapply(function(x,y) max(c(x,y)), exp2.cap.ss$Channel1, exp2.cap.ss$Channel2)
  exp2.dfp.ss$Source <- mapply(function(x,y) which.max(c(x,y)), x=exp2.dfp.ss$Channel1, y=exp2.dfp.ss$Channel2)
  exp2.dfp.ss$Dissimilarity <- mapply(function(x,y) max(c(x,y)), exp2.dfp.ss$Channel1, exp2.dfp.ss$Channel2)
  # Convert IVs to factor - EZ will do this automatically but BF will complain
  exp1.ss$Subject <- as.factor(exp1.ss$Subject); exp1.ss$Session <- as.factor(exp1.ss$Session); exp1.ss$Target <- as.factor(exp1.ss$Target); exp1.ss$Source <- as.factor(exp1.ss$Source); exp1.ss$Dissimilarity <- as.factor(exp1.ss$Dissimilarity)
  exp1.rs$Subject <- as.factor(exp1.rs$Subject); exp1.rs$Session <- as.factor(exp1.rs$Session); exp1.rs$Target <- as.factor(exp1.rs$Target); exp1.rs$Channel1 <- as.factor(exp1.rs$Channel1); exp1.rs$Channel2 <- as.factor(exp1.rs$Channel2)
  exp2.cap.ss$Subject <- as.factor(exp2.cap.ss$Subject); exp2.cap.ss$Session <- as.factor(exp2.cap.ss$Session); exp2.cap.ss$Target <- as.factor(exp2.cap.ss$Target); exp2.cap.ss$Source <- as.factor(exp2.cap.ss$Source); exp2.cap.ss$Dissimilarity <- as.factor(exp2.cap.ss$Dissimilarity)
  exp2.dfp.ss$Subject <- as.factor(exp2.dfp.ss$Subject); exp2.dfp.ss$Session <- as.factor(exp2.dfp.ss$Session); exp2.dfp.ss$Target <- as.factor(exp2.dfp.ss$Target); exp2.dfp.ss$Source <- as.factor(exp2.dfp.ss$Source); exp2.dfp.ss$Dissimilarity <- as.factor(exp2.dfp.ss$Dissimilarity)
  exp2.dfp.rs$Subject <- as.factor(exp2.dfp.rs$Subject); exp2.dfp.rs$Session <- as.factor(exp2.dfp.rs$Session); exp2.dfp.rs$Target <- as.factor(exp2.dfp.rs$Target); exp2.dfp.rs$Channel1 <- as.factor(exp2.dfp.rs$Channel1); exp2.dfp.rs$Channel2 <- as.factor(exp2.dfp.rs$Channel2)
  
  acc1ss.tp.anova <- ezANOVA(subset(exp1.ss,Target=="RC"), dv=Correct, wid=Subject, within=.(Session, Source, Dissimilarity))
  acc1ss.ta.anova <- ezANOVA(subset(exp1.ss,Target=="ABS"), dv=Correct, wid=Subject, within=.(Session, Source, Dissimilarity))
  rt1ss.tp.anova <- ezANOVA(subset(exp1.ss,Target=="RC" & Correct==1), dv=RT, wid=Subject, within=.(Session, Source, Dissimilarity))
  rt1ss.ta.anova <- ezANOVA(subset(exp1.ss,Target=="ABS" & Correct==1), dv=RT, wid=Subject, within=.(Session, Source, Dissimilarity))
  acc1rs.tp.anova <- ezANOVA(subset(exp1.rs,Target=="RC"), dv=Correct, wid=Subject, within=.(Session, Channel1, Channel2))
  acc1rs.ta.anova <- ezANOVA(subset(exp1.rs,Target=="ABS"), dv=Correct, wid=Subject, within=.(Session, Channel1, Channel2))
  rt1rs.tp.anova <- ezANOVA(subset(exp1.rs,Target=="RC" & Correct==1), dv=RT, wid=Subject, within=.(Session, Channel1, Channel2))
  rt1rs.ta.anova <- ezANOVA(subset(exp1.rs,Target=="ABS" & Correct==1), dv=RT, wid=Subject, within=.(Session, Channel1, Channel2))
  acc2ss.cap.tp.anova <- ezANOVA(subset(exp2.cap.ss,Target=="RC"), dv=Correct, wid=Subject, within=.(Session, Source, Dissimilarity))
  acc2ss.cap.ta.anova <- ezANOVA(subset(exp2.cap.ss,Target=="ABS"), dv=Correct, wid=Subject, within=.(Session, Source, Dissimilarity))
  rt2ss.cap.tp.anova <- ezANOVA(subset(exp2.cap.ss,Target=="RC" & Correct==1), dv=RT, wid=Subject, within=.(Session, Source, Dissimilarity))
  rt2ss.cap.ta.anova <- ezANOVA(subset(exp2.cap.ss,Target=="ABS" & Correct==1), dv=RT, wid=Subject, within=.(Session, Source, Dissimilarity))
  acc2ss.dfp.tp.anova <- ezANOVA(subset(exp2.dfp.ss,Target=="RC"), dv=Correct, wid=Subject, within=.(Session, Source, Dissimilarity))
  acc2ss.dfp.ta.anova <- ezANOVA(subset(exp2.dfp.ss,Target=="ABS"), dv=Correct, wid=Subject, within=.(Session, Source, Dissimilarity))
  rt2ss.dfp.tp.anova <- ezANOVA(subset(exp2.dfp.ss,Target=="RC" & Correct==1), dv=RT, wid=Subject, within=.(Session, Source, Dissimilarity))
  rt2ss.dfp.ta.anova <- ezANOVA(subset(exp2.dfp.ss,Target=="ABS" & Correct==1), dv=RT, wid=Subject, within=.(Session, Source, Dissimilarity))
  acc2rs.dfp.tp.anova <- ezANOVA(subset(exp2.dfp.rs,Target=="RC"), dv=Correct, wid=Subject, within=.(Session, Channel1, Channel2))
  acc2rs.dfp.ta.anova <- ezANOVA(subset(exp2.dfp.rs,Target=="ABS"), dv=Correct, wid=Subject, within=.(Session, Channel1, Channel2))
  rt2rs.dfp.tp.anova <- ezANOVA(subset(exp2.dfp.rs,Target=="RC" & Correct==1), dv=RT, wid=Subject, within=.(Session, Channel1, Channel2))
  rt2rs.dfp.ta.anova <- ezANOVA(subset(exp2.dfp.rs,Target=="ABS" & Correct==1), dv=RT, wid=Subject, within=.(Session, Channel1, Channel2))
}

# Bayesian ANOVAs
{
  acc1ss.tp.bfanova <- anovaBF(Correct ~ Session * Source * Dissimilarity + Subject, data = subset(exp1.ss,Target=="RC"), whichRandom="Subject")
  acc1ss.ta.bfanova <- anovaBF(Correct ~ Session * Source * Dissimilarity + Subject, data = subset(exp1.ss,Target=="ABS"), whichRandom="Subject")
  rt1ss.tp.bfanova <- anovaBF(RT ~ Session * Source * Dissimilarity + Subject, data = subset(exp1.ss,Target=="RC" & Correct==1), whichRandom="Subject")
  rt1ss.ta.bfanova <- anovaBF(RT ~ Session * Source * Dissimilarity + Subject, data = subset(exp1.ss,Target=="ABS" & Correct==1), whichRandom="Subject")
  acc1rs.tp.bfanova <- anovaBF(Correct ~ Session * Channel1 * Channel2 + Subject, data = subset(exp1.rs,Target=="RC"), whichRandom="Subject")
  acc1rs.ta.bfanova <- anovaBF(Correct ~ Session * Channel1 * Channel2 + Subject, data = subset(exp1.rs,Target=="ABS"), whichRandom="Subject")
  rt1rs.tp.bfanova <- anovaBF(RT ~ Session * Channel1 * Channel2 + Subject, data = subset(exp1.rs,Target=="RC" & Correct==1), whichRandom="Subject")
  rt1rs.ta.bfanova <- anovaBF(RT ~ Session * Channel1 * Channel2 + Subject, data = subset(exp1.rs,Target=="ABS" & Correct==1), whichRandom="Subject")
  acc2ss.cap.tp.bfanova <- anovaBF(Correct ~ Session * Source * Dissimilarity + Subject, data = subset(exp2.cap.ss,Target=="RC"), whichRandom="Subject")
  acc2ss.cap.ta.bfanova <- anovaBF(Correct ~ Session * Source * Dissimilarity + Subject, data = subset(exp2.cap.ss,Target=="ABS"), whichRandom="Subject")
  rt2ss.cap.tp.bfanova <- anovaBF(RT ~ Session * Source * Dissimilarity + Subject, data = subset(exp2.cap.ss,Target=="RC" & Correct==1), whichRandom="Subject")
  rt2ss.cap.ta.bfanova <- anovaBF(RT ~ Session * Source * Dissimilarity + Subject, data = subset(exp2.cap.ss,Target=="ABS" & Correct==1), whichRandom="Subject")
  acc2ss.dfp.tp.bfanova <- anovaBF(Correct ~ Session * Source * Dissimilarity + Subject, data = subset(exp2.dfp.ss,Target=="RC"), whichRandom="Subject")
  acc2ss.dfp.ta.bfanova <- anovaBF(Correct ~ Session * Source * Dissimilarity + Subject, data = subset(exp2.dfp.ss,Target=="ABS"), whichRandom="Subject")
  rt2ss.dfp.tp.bfanova <- anovaBF(RT ~ Session * Source * Dissimilarity + Subject, data = subset(exp2.dfp.ss,Target=="RC" & Correct==1), whichRandom="Subject")
  rt2ss.dfp.ta.bfanova <- anovaBF(RT ~ Session * Source * Dissimilarity + Subject, data = subset(exp2.dfp.ss,Target=="ABS" & Correct==1), whichRandom="Subject")
  acc2rs.dfp.tp.bfanova <- anovaBF(Correct ~ Session * Channel1 * Channel2 + Subject, data = subset(exp2.dfp.rs,Target=="RC"), whichRandom="Subject")
  acc2rs.dfp.ta.bfanova <- anovaBF(Correct ~ Session * Channel1 * Channel2 + Subject, data = subset(exp2.dfp.rs,Target=="ABS"), whichRandom="Subject")
  rt2rs.dfp.tp.bfanova <- anovaBF(RT ~ Session * Channel1 * Channel2 + Subject, data = subset(exp2.dfp.rs,Target=="RC" & Correct==1), whichRandom="Subject")
  rt2rs.dfp.ta.bfanova <- anovaBF(RT ~ Session * Channel1 * Channel2 + Subject, data = subset(exp2.dfp.rs,Target=="ABS" & Correct==1), whichRandom="Subject")
  
  # Print BF ANOVA results
  test.list <- list("acc1ss.tp"=acc1ss.tp.bfanova, "acc1ss.ta"=acc1ss.ta.bfanova, "rt1ss.tp"=rt1ss.tp.bfanova, "rt1ss.ta"=rt1ss.ta.bfanova,
                    "acc1rs.tp"=acc1rs.tp.bfanova, "acc1rs.ta"=acc1rs.ta.bfanova, "rt1rs.tp"=rt1rs.tp.bfanova, "rt1rs.ta"=rt1rs.ta.bfanova,
                    "acc2ss.cap.tp"=acc2ss.cap.tp.bfanova, "acc2ss.cap.ta"=acc2ss.cap.ta.bfanova, "rt2ss.cap.tp"=rt2ss.cap.tp.bfanova,
                    "rt2ss.cap.ta"=rt2ss.cap.ta.bfanova, "acc2ss.dfp.tp"=acc2ss.dfp.tp.bfanova, "acc2ss.dfp.ta"=acc2ss.dfp.ta.bfanova,
                    "rt2ss.dfp.tp"=rt2ss.dfp.tp.bfanova, "rt2ss.dfp.ta"=rt2ss.dfp.ta.bfanova, "acc2rs.dfp.tp"=acc2rs.dfp.tp.bfanova,
                    "acc2rs.dfp.ta"=acc2rs.dfp.ta.bfanova, "rt2rs.dfp.tp"=rt2rs.dfp.tp.bfanova, "rt2rs.dfp.ta"=rt2rs.dfp.ta.bfanova)
  
  save(test.list, file=paste(dump.path, "bfANOVAobjects.R", sep=''))
  transferGmail(paste(dump.path, "bfANOVAobjects.R", sep=''))
  print(load('bfANOVAobjects.R'))
  
  # Print all models with BF <= 100 from the best #### I DON'T THINK THIS ACCOUNTS FOR ALL MODELS BEING WORSE THAT THE NULL
  for (i in 1:length(test.list)) {
    temp <- sort(test.list[[i]],decreasing=T)
    mybf <- extractBF(temp)$bf
    if (mybf[1]>1) { # Best model is not null
      mystop <- min(which(mybf[1]/mybf > 100))
      if (mybf[1] > 100) { # Best model is better than null
        print(names(test.list)[i])
        print(cbind(unname(names(temp)$numerator[1:mystop]), mybf[1]/mybf[1:mystop]))
      } else { # Null model is included in those which are with 100 of Best
        ins <- max(which(mybf[1]/mybf < mybf[1]))
        print(names(test.list)[i])
        print(cbind(append(unname(names(temp)$numerator[1:mystop]), 'Subject', after=ins), append(mybf[1]/mybf[1:mystop], mybf[1], after=ins)))
      }
    } else { # Best model is null so report everything with respect to that
      mybf <- 1/mybf
      mystop <- min(which(mybf > 100))
      #mystop <- min(which(mybf < .01))
      print(names(test.list)[i])
      print(cbind(c('Subject',unname(names(temp)$numerator[1:mystop])), c(1,mybf[1:mystop])))
    }
    print('',quote=F)
  }
  
  # Best model compared to null model
  for (i in 1:length(test.list)) {
    print(names(test.list)[i])
    print(sort(test.list[[i]], decreasing=T)[1])
    print('',quote=F)
  }
  # Best model compared to second best
  for (i in 1:length(test.list)) {
    print(names(test.list)[i])
    print(sort(test.list[[i]], decreasing=T)[1]/sort(test.list[[i]], decreasing=T)[2])
    print('',quote=F)
  }
  
  num.mod <- 3
  temp.mod <- sort(acc2ss.dfp.tp.bfanova,decreasing = T)[1:num.mod]
  suppressWarnings(temp.mat <- as.matrix(temp.mod/temp.mod))
  dimnames(temp.mat) <- list(1:num.mod,1:num.mod)
  temp.mod
  temp.mat
}


# Bayesian MIC
{
  require(rstan)
  rstan_options(auto_write=T) ### Recommended by rstan for multicore CPUs
  options(mc.cores=parallel::detectCores()) ### (like my desktop)
  source("sft2stan.R")
  source("mictest_e.R")
  mic.data.1.tp <- sft2stan(subset(sic.data, Version==1.7 & Target=='RC'))
  mic.data.1.ta <- sft2stan(subset(sic.data, Version==1.7 & Target=='ABS'))
  mic.data.2.tp <- sft2stan(subset(sic.data, Version==2.7 & Target=='RC'))
  mic.data.2.ta <- sft2stan(subset(sic.data, Version==2.7 & Target=='ABS'))
  mic.post.1.tp <- stan(file='micmodel_optim2e.stan', data=mic.data.1.tp, control=list(adapt_delta=.95), iter=20000,
                        init=list(initsstan_optim2d(mic.data.1.tp),initsstan_optim2d(mic.data.1.tp),initsstan_optim2d(mic.data.1.tp),initsstan_optim2d(mic.data.1.tp)))
  mic.post.1.ta <- stan(file='micmodel_optim2e.stan', data=mic.data.1.ta, control=list(adapt_delta=.95), iter=20000,
                        init=list(initsstan_optim2d(mic.data.1.ta),initsstan_optim2d(mic.data.1.ta),initsstan_optim2d(mic.data.1.ta),initsstan_optim2d(mic.data.1.ta)))
  mic.post.2.tp <- stan(file='micmodel_optim2e.stan', data=mic.data.2.tp, control=list(adapt_delta=.95), iter=20000,
                        init=list(initsstan_optim2d(mic.data.2.tp),initsstan_optim2d(mic.data.2.tp),initsstan_optim2d(mic.data.2.tp),initsstan_optim2d(mic.data.2.tp)))
  mic.post.2.ta <- stan(file='micmodel_optim2e.stan', data=mic.data.2.ta, control=list(adapt_delta=.95), iter=20000,
                        init=list(initsstan_optim2d(mic.data.2.ta),initsstan_optim2d(mic.data.2.ta),initsstan_optim2d(mic.data.2.ta),initsstan_optim2d(mic.data.2.ta)))
}  



# Exp 1 DF TA has a 3 way interaction on RT?
par(mfrow=c(2,2))
for (i in unique(be.data$Session[be.data$Version==1.7])) {
  plot(1:2, sapply(1:2, function (x) mean(subset(be.data, Version==2.7 & Condition=='SIC' & Target=='RC' & Session==i & Channel1==x & Channel2==1 & Correct==1)$RT)), type='l',col='red',main=paste('Session',i),xlab='Channel 1',ylab='mean RT', ylim=c(0,4))
  lines(1:2, sapply(1:2, function (x) mean(subset(be.data, Version==2.7 & Condition=='SIC' & Target=='RC' & Session==i & Channel1==x & Channel2==2 & Correct==1)$RT)), col='blue')
  legend('top',horiz=T,legend=c('1','2'),fill=c('red','blue'),bty='n',title='Channel 2')
}
par(mfrow=c(1,1))

# Accuracy/RT mean/SD for each experiment and target condition
for (dv in c(20,15)) {
  for (exp in c(1.7,2.7)) {
    for (tar in c('RC','ABS')) {
      temp <- subset(be.data, Version==exp & Target==tar); temp <- unlist(lapply(split(temp[,dv], temp$Subject), mean))
      print(paste(names(be.data)[dv],exp,tar,mean(temp),sd(temp)),quote=F)
    }
  }
}


# Look at bad subjects in Exp 1&2
{
  bad.data <- data.frame()
  for (myfile in list.files("Data/Experiment 1/Bad Data/", full.names = T)) {
    bad.data <- rbind(bad.data, read.table(myfile, header = T, stringsAsFactors = F, sep="\t"))
  }
  for (myfile in list.files("Data/Experiment 2/Bad Data/", full.names = T)) {
    bad.data <- rbind(bad.data, read.table(myfile, header = T, stringsAsFactors = F, sep="\t"))
  }
  
  for (s in unique(bad.data$Subject)) print(paste(s,mean(bad.data$Correct[bad.data$Subject==s])))
  for (d in unique(bad.data$Distractors[bad.data$Version==1.7])) print(paste(d,mean(bad.data$Correct[bad.data$Subject==6 & bad.data$Distractors==d])))
  for (d in unique(bad.data$Distractors[bad.data$Version==1.7])) print(paste(d,mean(bad.data$Correct[bad.data$Subject==9 & bad.data$Distractors==d])))
  for (d in unique(bad.data$Distractors[bad.data$Version==2.7])) print(paste(d,mean(bad.data$Correct[bad.data$Subject==18 & bad.data$Distractors==d])))
}

}



#### EXPERIMENT 3 ####

{
figdir <- "Experiment 3 Results/Figures/"
results.dir <- "Experiment 3 Results/"

mydata <- data.frame()
for (myfile in list.files("Data/Experiment 3/Behavioral/", full.names=T)) {
  mydata <- rbind(mydata, read.table(myfile, header=T, stringsAsFactors=F))
}

mydata$ColorDif <- mydata$TColor - mydata$DColor
mydata$ShapeDif <- mydata$TShape - mydata$DShape
mydata <- subset(mydata, Session > 1)
sic.data <- subset(mydata, Condition=="SIC" & Correct==1 & Target!="ABS")
sic.data$Channel1 <- abs(sic.data$Channel1); sic.data$Channel2 <- abs(sic.data$Channel2)
sic.data$Channel1[sic.data$Channel1==3] <- 2; sic.data$Channel2[sic.data$Channel2==3] <- 2


# SIC
{
  par(mfrow=c(2,2))
  for (s in sort(unique(sic.data$Subject))) {
    hh <- ecdf(sic.data$RT[sic.data$Subject==s & sic.data$Channel1==2 & sic.data$Channel2==2 & sic.data$Target!="ABS" & sic.data$Correct==1])
    hl <- ecdf(sic.data$RT[sic.data$Subject==s & sic.data$Channel1==2 & sic.data$Channel2==1 & sic.data$Target!="ABS" & sic.data$Correct==1])
    lh <- ecdf(sic.data$RT[sic.data$Subject==s & sic.data$Channel1==1 & sic.data$Channel2==2 & sic.data$Target!="ABS" & sic.data$Correct==1])
    ll <- ecdf(sic.data$RT[sic.data$Subject==s & sic.data$Channel1==1 & sic.data$Channel2==1 & sic.data$Target!="ABS" & sic.data$Correct==1])
    
    tvec <- seq(0,3, .001)
    plot(0,0, type='n', xlab="Time (s)", ylab="S(t)", xlim=range(tvec), ylim=c(0,1), main=paste("Subject",s))
    lines(tvec,1-hh(tvec), col="red")
    lines(tvec,1-hl(tvec), col="orange")
    lines(tvec,1-lh(tvec), col="purple")
    lines(tvec,1-ll(tvec), col="blue")
    
    plot(tvec, ((1-ll(tvec))-(1-lh(tvec)))-((1-hl(tvec))-(1-hh(tvec))), type='l', xlim=range(tvec), ylim=c(-.5,.5), xlab="Time (s)", ylab="SIC(t)", main=paste("Subject",s))
    myn <- 1/(1/length(sic.data$RT[sic.data$Subject==s & sic.data$Target!="ABS" & sic.data$Correct==1 & sic.data$Channel1==2 & sic.data$Channel2==2]) +
                1/length(sic.data$RT[sic.data$Subject==s & sic.data$Target!="ABS" & sic.data$Correct==1 & sic.data$Channel1==2 & sic.data$Channel2==1]) +
                1/length(sic.data$RT[sic.data$Subject==s & sic.data$Target!="ABS" & sic.data$Correct==1 & sic.data$Channel1==1 & sic.data$Channel2==2]) +
                1/length(sic.data$RT[sic.data$Subject==s & sic.data$Target!="ABS" & sic.data$Correct==1 & sic.data$Channel1==1 & sic.data$Channel2==1]))
    dcrit <- sqrt(log(.333)/(-2*myn))
    abline(h=c(dcrit,-dcrit), lty=2)
  }
  par(mfrow=c(1,1))
  
  # Make a single plot of everyone together
  postscript(file=paste(figdir,"Exp_3_TP_SIC.eps",sep=''), width = width1, height = width1, horizontal=F)
  tvec <- seq(0,5, .001)
  plot.default(0,0, type='n',xlim=c(0,5),ylim=c(-.25,1), cex.main=.8,cex.axis=.9,cex.lab=1, main=paste("Experiment 3\nTarget Present SIC"),xlab="t (seconds)",ylab="SIC(t)")
  for (s in 1:length(unique(sic.data$Subject))) {
    hh <- ecdf(sic.data$RT[sic.data$Subject==sort(unique(sic.data$Subject))[s] & sic.data$Channel1==2 & sic.data$Channel2==2 & sic.data$Target!="ABS" & sic.data$Correct==1])
    hl <- ecdf(sic.data$RT[sic.data$Subject==sort(unique(sic.data$Subject))[s] & sic.data$Channel1==2 & sic.data$Channel2==1 & sic.data$Target!="ABS" & sic.data$Correct==1])
    lh <- ecdf(sic.data$RT[sic.data$Subject==sort(unique(sic.data$Subject))[s] & sic.data$Channel1==1 & sic.data$Channel2==2 & sic.data$Target!="ABS" & sic.data$Correct==1])
    ll <- ecdf(sic.data$RT[sic.data$Subject==sort(unique(sic.data$Subject))[s] & sic.data$Channel1==1 & sic.data$Channel2==1 & sic.data$Target!="ABS" & sic.data$Correct==1])
    lines(tvec, ((1-ll(tvec))-(1-lh(tvec)))-((1-hl(tvec))-(1-hh(tvec))), col=rainbow(n=length(unique(sic.data$Subject)), alpha=1)[s], lwd=1)
  }
  abline(h=0,lty=3)
  dev.off()
}

# SIC Stats
{
  # Helper function for SIC
  sic.stats <- function (mydata, subject, con) {
    myret <- c(subject, con)
    HH <- subset(mydata, Subject==subject & Condition==con & Channel1==2 & Channel2==2 & Correct==1)$RT
    HL <- subset(mydata, Subject==subject & Condition==con & Channel1==2 & Channel2==1 & Correct==1)$RT
    LH <- subset(mydata, Subject==subject & Condition==con & Channel1==1 & Channel2==2 & Correct==1)$RT
    LL <- subset(mydata, Subject==subject & Condition==con & Channel1==1 & Channel2==1 & Correct==1)$RT
    # SIC Testing
    this <- sic.test(HH,HL,LH,LL)
    mic <- mic.test(HH,HL,LH,LL)
    pp <- this$positive$p.value
    np <- this$negative$p.value
    myret <- c(myret, this$positive$statistic, pp, this$negative$statistic, np, mic$statistic, mic$p.value)
    if (pp < .333 & np < .333) {
      if (mic$statistic[[1]] > 0 & mic$p.value < .333) {
        myret <- append(myret, "COACTIVE")
      } else myret <- append(myret, "SERIAL-AND")
    } else if (pp < .333 & np >= .333) {
      myret <- append(myret, "PARALLEL-OR")
    } else if (pp >= .333 & np < .333) {
      myret <- append(myret, "PARALLEL-AND")
    } else if (pp >= .333 & np >= .333) {
      myret <- append(myret, "SERIAL-OR")
    }
    myret
  }
  
  # Helper function for SIC
  sic.analysis <- function (mydata, subject, con) {
    myret <- c(subject, con)
    HH <- subset(mydata, Subject==subject & Condition==con & Channel1==2 & Channel2==2 & Correct==1)$RT
    HL <- subset(mydata, Subject==subject & Condition==con & Channel1==2 & Channel2==1 & Correct==1)$RT
    LH <- subset(mydata, Subject==subject & Condition==con & Channel1==1 & Channel2==2 & Correct==1)$RT
    LL <- subset(mydata, Subject==subject & Condition==con & Channel1==1 & Channel2==1 & Correct==1)$RT
    
    # Selective Influence
    sid <- siDominance(HH,HL,LH,LL)
    if (any(sid$p.value[5:8] < .05)) {
      myret <- append(myret, "Fail")
    } else if (all(sid$p.value[1:4] < .05)) {
      myret <- append(myret, "Pass")
    } else {
      myret <- append(myret, "Ambiguous")
    }
    # SIC Testing
    this <- sic.test(HH,HL,LH,LL)
    mic <- mic.test(HH,HL,LH,LL)
    pp <- this$positive$p.value
    np <- this$negative$p.value
    
    if (pp < .333) myret <- append(myret, "Significant") else myret <- append(myret, "Nonsignificant")
    if (np < .333) myret <- append(myret, "Significant") else myret <- append(myret, "Nonsignificant")
    if (mic$statistic[[1]] > 0 & mic$p.value < .333) {
      myret <- append(myret, "Positive")
    } else if (mic$statistic[[1]] < 0 & mic$p.value < .333) {
      myret <- append(myret, "Negative")
    } else {
      myret <- append(myret, "Nonsignificant")
    }
    
    if (pp < .333 & np < .333) {
      if (mic$statistic[[1]] > 0 & mic$p.value < .333) {
        myret <- append(myret, "COACTIVE")
      } else myret <- append(myret, "SERIAL-AND")
    } else if (pp < .333 & np >= .333) {
      myret <- append(myret, "PARALLEL-OR")
    } else if (pp >= .333 & np < .333) {
      myret <- append(myret, "PARALLEL-AND")
    } else if (pp >= .333 & np >= .333) {
      myret <- append(myret, "SERIAL-OR")
    }
    myret
  }
  
  sic.out <- list(); psic.out <- list()
  for (s in sort(unique(sic.data$Subject))) {
    sic.out <- rbind(sic.out, sic.analysis(sic.data, s, "SIC"))
    psic.out <- rbind(psic.out, sic.stats(sic.data, s, "SIC"))
  }
  for (i in 3:8) psic.out[,i] <- signif(as.numeric(psic.out[,i]),3)
  sic.out <- data.frame(sic.out); psic.out <- as.data.frame(psic.out)
  names(sic.out) <- c("Subject", "Condition", "Selective.Influence", "Positive.SIC", "Negative.SIC", "MIC", "Predicted.by")
  names(psic.out) <- c("Subject", "Condition", "D+", "p", "D-", "p", "ART", "p", "Predicted.by")
  for (i in 1:length(sic.out[1,])) sic.out[,i] <- unlist(sic.out[,i]); for (i in 1:length(psic.out[1,])) psic.out[,i] <- unlist(psic.out[,i])
  write.csv(sic.out, file=paste(results.dir,"SIC Summary.csv"))
  write.csv(psic.out, file=paste(results.dir,"SIC Stats.csv"))
}

# Survivors
{
  postscript(file=paste(figdir,"Exp3_Survivors_TP.eps",sep=''),width=mywidth,height=mywidth, horizontal=F)
  par(mfrow=c(4,4))
  # Do Survivors first
  plot.default(0,0, type='n',xlim=c(0,1),ylim=c(0,1), axes=F, xlab="",ylab=""); text(c(.5,.5,.5),c(.9,.6,.25),cex=1, labels=c("Experiment 3", "Target Present", "Survivor Functions"))#, font="Arial")
  for (s in sort(unique(sic.data$Subject))) {
    temp <- subset(sic.data, Subject==s)
    plot(tvec, 1-ecdf(subset(temp, Channel1==1 & Channel2==1 & Correct==1)$RT)(tvec), col="blue", lwd=1, type="l", cex.main=1,cex.axis=1,cex.lab=1, main=paste("Subject",s),xlab="t (seconds)",ylab="S(t)",xlim=c(0,6),ylim=c(0,1))
    lines(tvec, 1-ecdf(subset(temp, Channel1==1 & Channel2==2 & Correct==1)$RT)(tvec), col="purple", lwd=1)
    lines(tvec, 1-ecdf(subset(temp, Channel1==2 & Channel2==1 & Correct==1)$RT)(tvec), col="orange", lwd=1)
    lines(tvec, 1-ecdf(subset(temp, Channel1==2 & Channel2==2 & Correct==1)$RT)(tvec), col="red", lwd=1)
    #abline(h=0,lty=3)
  }
  par(mfrow=c(1,1))
  dev.off()
}

# MIC
{
  require(rstan)
  source("sft2stan.R")
  source("micmodel_inits_vs3.r")
  mic.data <- subset(sic.data, Target!="ABS")
  mic.stan <- sft2stan(mic.data)
  mic.inits <- mic_shiftedwald_inits(mic.stan)
  stan.out <- stan(file="micmodel_vs3.stan", data=mic.stan, init=list(mic.inits,mic.inits,mic.inits,mic.inits), control = list(adapt_delta=.9), iter = 20000)

  #stan.out20k 
  three.stan20k # Saved to here
  #save(three.stan20k, file="Experiment 3 Results/Bayesian MIC.R")
  
  mic.out <- data.frame("Subject"=c("Group",1:15), 
                        "Positive"=summary(three.stan20k)$summary[seq(1,by=3,length.out = 16),1],
                        "Zero"=summary(three.stan20k)$summary[seq(2,by=3,length.out = 16),1],
                        "Negative"=summary(three.stan20k)$summary[seq(3,by=3,length.out = 16),1])
  write.csv(mic.out, file="Experiment 3 Results/Bayesian MIC.csv", row.names = F)
}

# Capacity
{
  
  # CAPACITY FROM EXP 1 & 2
  
  par(mfrow=c(1,3))
  boxplot(reduced.cap$Z~reduced.cap$Condition, ylim=c(-4,12), main="Capacity (AND) Z-Scores", ylab="Z(C(t))",xaxt='n',cex.main=1,cex.axis=1,cex.lab=1,lwd=1); axis(1,at=0:16,cex.axis=.8, tick=F, labels=c(" ", rep(c("HH","HL","LH","LL"), 4)))
  text(rep(c(2.5,6.5,10.5,14.5),2), c(rep(12,4),rep(11,4)), labels=c(rep("Experiment 1",2),rep("Experiment 2",2),"Target Absent","Target Present","Target Absent","Target Present"), cex=1)
  abline(v=c(4.5,8.5,12.5)); abline(h=0, lty=2,lwd=2); text(12,.4, labels="UCIP Performance", cex=1)
  
  # EXPERIMENT 3
  cap.data <- subset(mydata, Target != "ABS")
  cap.data$ColorDif <- cap.data$TColor - cap.data$DColor
  cap.data$ShapeDif <- cap.data$TShape - cap.data$DShape
  cap.data$Salience <- mapply(function (x,y) {
    if (abs(x) > 1 & abs(y) > 1) {
      "HH"
    } else if (abs(x) > 1 & abs(y) == 1) {
      "HL"
    } else if (abs(x) == 1 & abs(y) > 1) {
      "LH"
    } else if (abs(x) == 1 & abs(y) == 1) {
      "LL"
    } else {
      "??"
    } 
  }, x=cap.data$ColorDif, y=cap.data$ShapeDif)
  
  sum.cap <- expand.grid(list("Subject"=sort(unique(cap.data$Subject)), "ColorDif"=sort(unique(cap.data$ColorDif)), "ShapeDif"=sort(unique(cap.data$ShapeDif))))
  sum.cap <- subset(sum.cap, ColorDif!=0 & ShapeDif!=0)
  sum.cap$CapZ <- NA; sum.cap$Capp <- NA
  for (i in 1:length(sum.cap[,1])) {
    temp <- capacity.or(list(subset(cap.data, Subject==sum.cap$Subject[i] & Condition=="SIC" & ColorDif==sum.cap$ColorDif[i] & ShapeDif==sum.cap$ShapeDif[i])$RT,subset(cap.data, Subject==sum.cap$Subject[i] & Condition=="Capacity" & ColorDif==sum.cap$ColorDif[i] & ShapeDif==0)$RT,subset(cap.data, Subject==sum.cap$Subject[i] & Condition=="Capacity" & ColorDif==0 & ShapeDif==sum.cap$ShapeDif[i])$RT),
                        list(subset(cap.data, Subject==sum.cap$Subject[i] & Condition=="SIC" & ColorDif==sum.cap$ColorDif[i] & ShapeDif==sum.cap$ShapeDif[i])$Correct,subset(cap.data, Subject==sum.cap$Subject[i] & Condition=="Capacity" & ColorDif==sum.cap$ColorDif[i] & ShapeDif==0)$Correct,subset(cap.data, Subject==sum.cap$Subject[i] & Condition=="Capacity" & ColorDif==0 & ShapeDif==sum.cap$ShapeDif[i])$Correct))
    sum.cap$CapZ[i] <- temp$Ctest$statistic
    sum.cap$Capp[i] <- temp$Ctest$p.value
  }
  boxplot(CapZ~ColorDif*ShapeDif,data=sum.cap, ylim=c(-4,12), ylab="", main="Capacity (OR) Z-Scores (Experiment 3 - TP)")
  abline(h=0,lty=2,lwd=2)
  
  sum.cap$Salience <- mapply(function (x,y) {
    if (abs(x) > 1 & abs(y) > 1) {
      "HH"
    } else if (abs(x) > 1 & abs(y) == 1) {
      "HL"
    } else if (abs(x) == 1 & abs(y) > 1) {
      "LH"
    } else if (abs(x) == 1 & abs(y) == 1) {
      "LL"
    } else {
      "??"
    } 
  }, x=sum.cap$ColorDif, y=sum.cap$ShapeDif)
  sum.cap$Capacity <- "Unlimited"
  sum.cap$Capacity[sum.cap$CapZ < 0 & sum.cap$Capp < .05] <- "Limited"; sum.cap$Capacity[sum.cap$CapZ > 0 & sum.cap$Capp < .05] <- "Super"
  
  ezANOVA(sum.cap, dv=CapZ, wid=Subject, within=.(ColorDif,ShapeDif))
  sum.cap$ColorDif <- as.factor(sum.cap$ColorDif); sum.cap$ShapeDif <- as.factor(sum.cap$ShapeDif); sum.cap$Subject <- as.factor(sum.cap$Subject); sum.cap$Salience <- as.factor(sum.cap$Salience)
  cap.aov <- anovaBF(CapZ ~ ColorDif * ShapeDif + Subject, data = sum.cap, whichRandom="Subject")
  #write.csv(cap.aov, file="Experiment 3 Results/Exp 3 Cap anovaBF TP.csv")
  #save(cap.aov, file="Experiment 3 Results/Exp 3 Cap anovaBF TP.R")
  
  # Target Absent
  abs.cap.data <- subset(mydata, Target == "ABS")
  abs.sum.cap <- expand.grid(list("Subject"=sort(unique(abs.cap.data$Subject)), "DColor"=sort(unique(abs.cap.data$DColor)), "DShape"=sort(unique(abs.cap.data$DShape))))
  abs.sum.cap <- subset(abs.sum.cap, DColor!=0 & DShape!=0)
  abs.sum.cap$CapZ <- NA; abs.sum.cap$Capp <- NA
  for (i in 1:length(abs.sum.cap[,1])) {
    temp <- capacity.and(list(subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="SIC" & DColor==abs.sum.cap$DColor[i] & DShape==abs.sum.cap$DShape[i])$RT,subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="Capacity" & DColor==abs.sum.cap$DColor[i] & DShape==1)$RT,subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="Capacity" & DColor==1 & DShape==abs.sum.cap$DShape[i])$RT),
                         list(subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="SIC" & DColor==abs.sum.cap$DColor[i] & DShape==abs.sum.cap$DShape[i])$Correct,subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="Capacity" & DColor==abs.sum.cap$DColor[i] & DShape==1)$Correct,subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="Capacity" & DColor==1 & DShape==abs.sum.cap$DShape[i])$Correct))
    abs.sum.cap$CapZ[i] <- temp$Ctest$statistic
    abs.sum.cap$Capp[i] <- temp$Ctest$p.value
  }
  boxplot(CapZ~DColor*DShape,data=abs.sum.cap, ylim=c(-4,12), ylab="", main="Capacity (AND) Z-Scores (Experiment 3 - TA)")
  abline(h=0,lty=2,lwd=2)
  par(mfrow=c(1,1))
  
  abs.sum.cap$Capacity <- "Unlimited"
  abs.sum.cap$Capacity[abs.sum.cap$CapZ < 0 & abs.sum.cap$Capp < .05] <- "Limited"; abs.sum.cap$Capacity[abs.sum.cap$CapZ > 0 & abs.sum.cap$Capp < .05] <- "Super"
  
  
  ezANOVA(abs.sum.cap, dv=CapZ, wid=Subject, within=.(DColor,DShape))
  abs.sum.cap$DColor <- as.factor(abs.sum.cap$DColor); abs.sum.cap$DShape <- as.factor(abs.sum.cap$DShape); abs.sum.cap$Subject <- as.factor(abs.sum.cap$Subject)
  abs.cap.aov <- anovaBF(CapZ ~ DColor * DShape + Subject, data = abs.sum.cap, whichRandom="Subject")
  #write.csv(abs.cap.aov, file="Experiment 3 Results/Exp 3 Cap anovaBF TA.csv")
  #save(abs.cap.aov, file="Experiment 3 Results/Exp 3 Cap anovaBF TA.R")
  
  
  # Collapse some conditions of Exp 3 and add them to the existing capacity figure
  abs.sum.cap$Dummy <- "ALL"
  
  postscript(paste(figdir,"Capacity_Z_scores.eps",sep=""), width = width2, height=width2*aspect.ratio, horizontal = F)
  par(oma=c(0,0,0,0))
  boxplot(Z~Saliency, data=subset(reduced.cap,Experiment=="1.7" & Target=="RC"), xlim=c(1,26), ylim=c(-4,12), main="", xlab="Condition", ylab="Z(C(t))")#,xaxt='n',cex.main=1,cex.axis=1,cex.lab=1,lwd=1)
  boxplot(Z~Saliency, data=subset(reduced.cap,Experiment=="1.7" & Target=="ABS"), add=T, at=6:9)
  boxplot(Z~Saliency, data=subset(reduced.cap,Experiment=="2.7" & Target=="RC"), add=T, at=11:14)
  boxplot(Z~Saliency, data=subset(reduced.cap,Experiment=="2.7" & Target=="ABS"), add=T, at=16:19)
  boxplot(CapZ~Salience, data=sum.cap, add=T, at=21:24)
  boxplot(CapZ~Dummy, data=abs.sum.cap, add=T, at=26); axis(1,at=26, tick=T, labels="ALL")
  abline(v=c(5,10,15,20,25)); abline(h=0, lty=2,lwd=2); text(10,.75, labels="UCIP Performance", cex=1)
  title(main="Capacity Z-Scores", line=-1.5, outer=T, xpd=NA, cex.main=1.25)
  text(x=c(5,15,23.5), y=rep(13.5,3), labels=c("Experiment 1", "Experiment 2", "Experiment 3"), xpd=NA)
  text(x=c(2.5, 7.5, 12.5, 17.5, 22.5, 26), y=rep(11.5,6), labels=c("Target\nPresent", "Target\nAbsent"), cex=.7)
  par(oma=c(0,0,0,0))
  dev.off()
  
  # Plot individual Capacity funcitons
  tvec <- seq(0,10, .001)
  # Target Present
  postscript(paste(figdir,"Exp3_individual_cap_TP.eps",sep=""),width=width2,height=width2, horizontal=F)
  par(mfrow=c(2,2))
  for (con in 1:4) {
    plot(0,0,type='n',xlim=c(0,10),ylim=c(0,5),main=c('HH','HL','LH','LL')[con],xlab='t (s)',ylab='C(t)')
    n <- length(unique(cap.data$Subject))
    for (i in 1:n) {
      this <- subset(cap.data, Subject==sort(unique(cap.data$Subject))[i] & Target!="ABS")
      if (con==1) this <- subset(this, abs(Channel1)!=1 & abs(Channel2)!=1)
      if (con==2) this <- subset(this, abs(Channel1)!=1 & abs(Channel2)<2)
      if (con==3) this <- subset(this, abs(Channel1)<2 & abs(Channel2)!=1)
      if (con==4) this <- subset(this, abs(Channel1)<2 & abs(Channel2)<2)
      cor <- capacity.or(list(this$RT[this$Condition=="SIC" & abs(this$Channel1)>0 & abs(this$Channel2)>0], this$RT[this$Condition=="Capacity" & abs(this$Channel1)>0 & this$Channel2==0], this$RT[this$Condition=="Capacity" & this$Channel1==0 & abs(this$Channel2)>0]),
                         list(this$Correct[this$Condition=="SIC" & abs(this$Channel1)>0 & abs(this$Channel2)>0], this$Correct[this$Condition=="Capacity" & abs(this$Channel1)>0 & this$Channel2==0], this$Correct[this$Condition=="Capacity" & this$Channel1==0 & abs(this$Channel2)>0]))
      lines(tvec, cor$Ct(tvec), col=rainbow(n)[i])
    }
    abline(h=1,lty=2)
  }
  par(mfrow=c(1,1))
  dev.off()
  
  # Target Absent
  postscript(paste(figdir,"Exp3_individual_cap_TA.eps",sep=""),width=width2,height=width2, horizontal=F)
  plot(0,0,type='n',xlim=c(0,10),ylim=c(0,25),main="Experiment 3 (Target Absent) Capacity",xlab='t (s)',ylab='C(t)')
  n <- length(unique(abs.cap.data$Subject))
  for (i in 1:n) {
    this <- subset(abs.cap.data, Subject==sort(unique(abs.cap.data$Subject))[i] & Target=="ABS")
    cand <- capacity.and(list(subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="SIC" & DColor==abs.sum.cap$DColor[i] & DShape==abs.sum.cap$DShape[i])$RT,subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="Capacity" & DColor==abs.sum.cap$DColor[i] & DShape==1)$RT,subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="Capacity" & DColor==1 & DShape==abs.sum.cap$DShape[i])$RT),
                         list(subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="SIC" & DColor==abs.sum.cap$DColor[i] & DShape==abs.sum.cap$DShape[i])$Correct,subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="Capacity" & DColor==abs.sum.cap$DColor[i] & DShape==1)$Correct,subset(abs.cap.data, Subject==abs.sum.cap$Subject[i] & Condition=="Capacity" & DColor==1 & DShape==abs.sum.cap$DShape[i])$Correct))
    lines(tvec, cand$Ct(tvec), col=rainbow(n)[i])
  }
  abline(h=1,lty=2)
  dev.off()
}

# Accuracy
{
  #init.accuracy
  {
    acc.mat3 <- matrix(data=0,nrow=1,ncol=23); acc.mat4 <- matrix(data=0,nrow=1,ncol=61) # Barplot expects data in a matrix
    acc.sem3 <- matrix(data=0,nrow=1,ncol=23); acc.sem4 <- matrix(data=0,nrow=1,ncol=61) # standard error for each bar
    
    # Exp 3 - Target Absent
    {
      # Do Capacity first
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==1&DShape==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,1] <- mean(temp); acc.sem3[1,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==2&DShape==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,2] <- mean(temp); acc.sem3[1,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==3&DShape==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,3] <- mean(temp); acc.sem3[1,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==4&DShape==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,4] <- mean(temp); acc.sem3[1,4] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==1&DShape==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,5] <- mean(temp); acc.sem3[1,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==1&DShape==3); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,6] <- mean(temp); acc.sem3[1,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==1&DShape==4); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,7] <- mean(temp); acc.sem3[1,7] <- sd(temp)/sqrt(length(temp))
      # Now DFP blocks
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==1&DShape==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,8] <- mean(temp); acc.sem3[1,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==2&DShape==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,9] <- mean(temp); acc.sem3[1,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==3&DShape==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,10] <- mean(temp); acc.sem3[1,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==4&DShape==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,11] <- mean(temp); acc.sem3[1,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==1&DShape==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,12] <- mean(temp); acc.sem3[1,12] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==2&DShape==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,13] <- mean(temp); acc.sem3[1,13] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==3&DShape==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,14] <- mean(temp); acc.sem3[1,14] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==4&DShape==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,15] <- mean(temp); acc.sem3[1,15] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==1&DShape==3); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,16] <- mean(temp); acc.sem3[1,16] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==2&DShape==3); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,17] <- mean(temp); acc.sem3[1,17] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==3&DShape==3); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,18] <- mean(temp); acc.sem3[1,18] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==4&DShape==3); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,19] <- mean(temp); acc.sem3[1,19] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==1&DShape==4); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,20] <- mean(temp); acc.sem3[1,20] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==2&DShape==4); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,21] <- mean(temp); acc.sem3[1,21] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==3&DShape==4); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,22] <- mean(temp); acc.sem3[1,22] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==4&DShape==4); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat3[1,23] <- mean(temp); acc.sem3[1,23] <- sd(temp)/sqrt(length(temp))
    }
    # Exp 3 - Target Present
    {
      # Do Capacity first
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==-3&ShapeDif==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,1] <- mean(temp); acc.sem4[1,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==-2&ShapeDif==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,2] <- mean(temp); acc.sem4[1,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==-1&ShapeDif==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,3] <- mean(temp); acc.sem4[1,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==1&ShapeDif==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,4] <- mean(temp); acc.sem4[1,4] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==2&ShapeDif==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,5] <- mean(temp); acc.sem4[1,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==3&ShapeDif==0); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,6] <- mean(temp); acc.sem4[1,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==-3); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,7] <- mean(temp); acc.sem4[1,7] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==-2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,8] <- mean(temp); acc.sem4[1,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==-1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,9] <- mean(temp); acc.sem4[1,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==1); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,10] <- mean(temp); acc.sem4[1,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==2); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,11] <- mean(temp); acc.sem4[1,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==3); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
      acc.mat4[1,12] <- mean(temp); acc.sem4[1,12] <- sd(temp)/sqrt(length(temp))
      # Now DFP blocks
      for (j in 1:length(unique(mydata$ShapeDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))) {
        for (i in 1:length(unique(mydata$ColorDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))) {
          if (!(sort(unique(mydata$ColorDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))[i] == 0 & sort(unique(mydata$ShapeDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))[j] == 0)) {
            temp <- subset(mydata, Condition=="SIC"&Target!="ABS"&ColorDif==sort(unique(mydata$ColorDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))[i]&ShapeDif==sort(unique(mydata$ShapeDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))[j]); temp <- unlist(lapply(split(temp$Correct, temp$Subject), mean))
            acc.mat4[1,12 + (j-1)*length(unique(mydata$ColorDif[mydata$Condition=="SIC" & mydata$Target!="ABS"])) + i] <- mean(temp); acc.sem4[1,12 + (j-1)*length(unique(mydata$ColorDif[mydata$Condition=="SIC" & mydata$Target!="ABS"])) + i] <- sd(temp)/sqrt(length(temp))
          }
        }
      }
      acc.mat4 <- matrix(acc.mat4[,-37], nrow=1); acc.sem4 <- matrix(acc.sem4[,-37], nrow=1)
    }
    
  }
  # plot.accuracy 
  {
 # Target Present
    postscript(paste(figdir,"Exp_3_Target_PRE_ACC.eps",sep=""), width=mywidth*aspect.ratio, height=mywidth, horizontal = F)
    par(oma=c(0,0,2,0), mar=c(3,4,4,2)+.1)#,mfrow=c(2,1))
    layout(matrix(c(0,1,1,1,0,2,2,2,2,2),byrow=T,nrow=2))
    barplot(matrix(acc.mat4[1,1:12],nrow=1)*100, names.arg=c(-3:-1,1:3,rep(0,6)), legend.text=F, beside=T, horiz=F, main="Capacity Trials",xlab="",ylab="% Correct",ylim=c(0,100),xpd=F, angle=c(rep(-45,3),0,rep(45,3))[4+c(rep(0,6),-3:-1,1:3)], density=c(45,25,10,10,10,25,45)[4+c(rep(0,6),-3:-1,1:3)], col="black")
    arrows(x0=seq(1.5,by=2,length.out=length(acc.mat4[1,1:12])), y0=(acc.mat4[1,1:12]-acc.sem4[1,1:12])*100, y1=(acc.mat4[1,1:12]+acc.sem4[1,1:12])*100, angle=90, code=3, lwd=2, length=.02)
    title("Accuracy for Experiment 3 - Target Present",line=.5,cex.main=1.25, outer=T)
    legend(x=mean(par()$usr[2])+6, y=mean(par()$usr[3:4]), legend=c(-3:3), col="black", angle=c(rep(-45,3),0,rep(45,3)), density=c(45,25,10,10,10,25,45), bty='n', ncol=1, xpd=NA, xjust = .5, yjust=.5, x.intersp = .5, title="Shape Dissimilarity")
    par(mar=c(4,4,4,2)+.1)
    barplot(matrix(acc.mat4[1,13:60],nrow=1)*100, names.arg=c(rep(-3:3,7)[-25]), legend.text=F, beside=T, horiz=F, main="DFP Trials",xlab="Color Dissimilarity",ylab="% Correct",ylim=c(0,100),xpd=F, angle=c(rep(-45,3),0,rep(45,3))[4+c(rep(-3:3,each=7)[-25])], density=c(45,25,10,10,10,25,45)[4+c(rep(-3:3,each=7)[-25])], col="black")#, col=c("green","red","blue","black","blue","red","green")[4+c(rep(0,6),-3:-1,1:3,rep(-3:3,each=7)[-25])])
    arrows(x0=seq(1.5,by=2,length.out=length(acc.mat4[1,13:60])), y0=(acc.mat4[1,13:60]-acc.sem4[1,13:60])*100, y1=(acc.mat4[1,13:60]+acc.sem4[1,13:60])*100, angle=90, code=3, lwd=2, length=.02)
    layout(matrix(1))
    par(oma=rep(0,4),mfrow=c(1,1))
    dev.off()
    
    # Target Absent
    postscript(paste(figdir,"Exp_3_Target_ABS_ACC.eps",sep=""), width=mywidth*aspect.ratio, height=mywidth, horizontal = F)
    par(oma=c(0,0,2,0), mar=c(3,4,4,2)+.1)#,mfrow=c(2,1))
    layout(matrix(c(0,1,1,1,0,2,2,2,2,2),byrow=T,nrow=2))
    barplot(matrix(acc.mat3[1,1:7],nrow=1)*100, names.arg=c(1:4,rep(1,3)), legend.text=F, beside=T, horiz=F, main="Capacity Trials",xlab="",ylab="% Correct",ylim=c(0,100),xpd=F, angle=c(rep(-45,2),rep(45,2))[c(rep(1,4),2:4)], density=c(40,15,15,40)[c(rep(1,4),2:4)], col="black")
    arrows(x0=seq(1.5,by=2,length.out=length(acc.mat3[1,1:7])), y0=(acc.mat3[1,1:7]-acc.sem3[1,1:7])*100, y1=(acc.mat3[1,1:7]+acc.sem3[1,1:7])*100, angle=90, code=3, lwd=2, length=.02)
    title("Accuracy for Experiment 3 - Target Absent", line=.5, cex.main=1.25, outer=T)
    legend(x=mean(par()$usr[2])+6, y=mean(par()$usr[3:4]), legend=c(1:4), col="black", angle=c(rep(-45,2),rep(45,2)), density=c(40,15,15,40), bty='n', ncol=1, xpd=NA, xjust = .5, yjust=.5, x.intersp = .5, title="Shape Level")
    par(mar=c(4,4,4,2)+.1)
    barplot(matrix(acc.mat3[1,8:23],nrow=1)*100, names.arg=rep(1:4,4), legend.text=F, beside=T, horiz=F, main="DFP Trials",xlab="Color Level",ylab="% Correct",ylim=c(0,100),xpd=F, angle=c(rep(-45,2),rep(45,2))[rep(1:4,each=4)], density=c(40,15,15,40)[rep(1:4,each=4)], col="black")
    arrows(x0=seq(1.5,by=2,length.out=length(acc.mat3[1,8:23])), y0=(acc.mat3[1,8:23]-acc.sem3[1,8:23])*100, y1=(acc.mat3[1,8:23]+acc.sem3[1,8:23])*100, angle=90, code=3, lwd=2, length=.02)
    layout(matrix(1))
    par(oma=rep(0,4),mfrow=c(1,1))
    dev.off()
  }
  # anova.accuracy 
  {
    # Overall accuracy
    subj.acc.tp <- unlist(lapply(split(mydata$Correct[mydata$Target!="ABS"], mydata$Subject[mydata$Target!="ABS"]), mean))
    subj.acc.ta <- unlist(lapply(split(mydata$Correct[mydata$Target=="ABS"], mydata$Subject[mydata$Target=="ABS"]), mean))
    mean(subj.acc.tp)*100; sd(subj.acc.tp)*100
    mean(subj.acc.ta)*100; sd(subj.acc.ta)*100
    
    
   # Target Present - Separate into one feature different and two features different - using Dif as factors
    exp3.tp.ss <- subset(mydata, Target!="ABS" & (ColorDif==0 | ShapeDif==0))
    exp3.tp.ss$Source <- mapply(function (x,y) which(c(x,y)!=0), x=exp3.tp.ss$ColorDif, y=exp3.tp.ss$ShapeDif)
    exp3.tp.ss$Dissimilarity <- mapply(function (x,y) if (x==0) y else x, x=exp3.tp.ss$ColorDif, y=exp3.tp.ss$ShapeDif)
    exp3.tp.ss$Subject <- as.factor(exp3.tp.ss$Subject); exp3.tp.ss$Session <- as.factor(exp3.tp.ss$Session);  exp3.tp.ss$Source <- as.factor(exp3.tp.ss$Source);  exp3.tp.ss$Dissimilarity <- as.factor(exp3.tp.ss$Dissimilarity) 
    
    acc3.tp.ss.bfanova <- anovaBF(Correct ~ Session * Source * Dissimilarity + Subject, data=exp3.tp.ss, whichRandom = "Subject")
    #write.csv(acc3.tp.ss.bfanova, file="Experiment 3 Results/Exp 3 Accuracy anovaBF TP SS.csv")
    #save(acc3.tp.ss.bfanova, file="Experiment 3 Results/Exp 3 Accuracy anovaBF TP SS.R")
    
    rt3.tp.ss.bfanova <- anovaBF(RT ~ Session * Source * Dissimilarity + Subject, data=subset(exp3.tp.ss, Correct==1), whichRandom = "Subject")
    #write.csv(rt3.tp.ss.bfanova, file="Experiment 3 Results/Exp 3 RT anovaBF TP SS.csv")
    #save(rt3.tp.ss.bfanova, file="Experiment 3 Results/Exp 3 RT anovaBF TP SS.R")
    
    
    exp3.tp.rs <- subset(mydata, Target!="ABS" & ColorDif!=0 & ShapeDif!=0)
    exp3.tp.rs$Subject <- as.factor(exp3.tp.rs$Subject); exp3.tp.rs$Session <- as.factor(exp3.tp.rs$Session);  exp3.tp.rs$ColorDif <- as.factor(exp3.tp.rs$ColorDif);  exp3.tp.rs$ShapeDif <- as.factor(exp3.tp.rs$ShapeDif) 
    
    acc3.tp.rs.bfanova <- anovaBF(Correct ~ Session * ColorDif * ShapeDif + Subject, data=exp3.tp.rs, whichRandom = "Subject")
    #write.csv(acc3.tp.rs.bfanova, file="Experiment 3 Results/Exp 3 Accuracy anovaBF TP RS.csv")
    #save(acc3.tp.rs.bfanova, file="Experiment 3 Results/Exp 3 Accuracy anovaBF TP RS.R")
    
    rt3.tp.rs.bfanova <- anovaBF(RT ~ Session * ColorDif * ShapeDif + Subject, data=subset(exp3.tp.rs, Correct==1), whichRandom = "Subject")
    #write.csv(rt3.tp.rs.bfanova, file="Experiment 3 Results/Exp 3 RT anovaBF TP RS.csv")
    #save(rt3.tp.rs.bfanova, file="Experiment 3 Results/Exp 3 RT anovaBF TP RS.R")
    
    
    # Target Absent - Don't need to separate. Just use DColor/Shape
    exp3.ta <- subset(mydata, Target=="ABS")
    exp3.ta$Subject <- as.factor(exp3.ta$Subject); exp3.ta$Session <- as.factor(exp3.ta$Session);  exp3.ta$DColor <- as.factor(exp3.ta$DColor);  exp3.ta$DShape <- as.factor(exp3.ta$DShape) 
    
    acc3.ta.bfanova <- anovaBF(Correct ~ Session * DColor * DShape + Subject, data=exp3.ta, whichRandom = "Subject")
    #write.csv(acc3.ta.bfanova, file="Experiment 3 Results/Exp 3 Accuracy anovaBF TA.csv")
    #save(acc3.ta.bfanova, file="Experiment 3 Results/Exp 3 Accuracy anovaBF TA.R")
    
    rt3.ta.bfanova <- anovaBF(RT ~ Session * DColor * DShape + Subject, data=subset(exp3.ta, Correct==1), whichRandom = "Subject")
    #write.csv(rt3.ta.bfanova, file="Experiment 3 Results/Exp 3 RT anovaBF TA.csv")
    #save(rt3.ta.bfanova, file="Experiment 3 Results/Exp 3 RT anovaBF TA.R")
  }
}

# Mean RT
{
  #init.RT
  {
    rt.mat3 <- matrix(data=0,nrow=1,ncol=23); rt.mat4 <- matrix(data=0,nrow=1,ncol=61) # Barplot expects data in a matrix
    rt.sem3 <- matrix(data=0,nrow=1,ncol=23); rt.sem4 <- matrix(data=0,nrow=1,ncol=61) # standard error for each bar
    
    # Exp 3 - Target Absent
    {
      # Do Capacity first
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==1&DShape==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,1] <- mean(temp); rt.sem3[1,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==2&DShape==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,2] <- mean(temp); rt.sem3[1,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==3&DShape==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,3] <- mean(temp); rt.sem3[1,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==4&DShape==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,4] <- mean(temp); rt.sem3[1,4] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==1&DShape==2); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,5] <- mean(temp); rt.sem3[1,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==1&DShape==3); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,6] <- mean(temp); rt.sem3[1,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target=="ABS"&DColor==1&DShape==4); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,7] <- mean(temp); rt.sem3[1,7] <- sd(temp)/sqrt(length(temp))
      # Now DFP blocks
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==1&DShape==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,8] <- mean(temp); rt.sem3[1,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==2&DShape==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,9] <- mean(temp); rt.sem3[1,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==3&DShape==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,10] <- mean(temp); rt.sem3[1,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==4&DShape==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,11] <- mean(temp); rt.sem3[1,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==1&DShape==2); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,12] <- mean(temp); rt.sem3[1,12] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==2&DShape==2); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,13] <- mean(temp); rt.sem3[1,13] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==3&DShape==2); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,14] <- mean(temp); rt.sem3[1,14] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==4&DShape==2); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,15] <- mean(temp); rt.sem3[1,15] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==1&DShape==3); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,16] <- mean(temp); rt.sem3[1,16] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==2&DShape==3); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,17] <- mean(temp); rt.sem3[1,17] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==3&DShape==3); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,18] <- mean(temp); rt.sem3[1,18] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==4&DShape==3); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,19] <- mean(temp); rt.sem3[1,19] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==1&DShape==4); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,20] <- mean(temp); rt.sem3[1,20] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==2&DShape==4); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,21] <- mean(temp); rt.sem3[1,21] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==3&DShape==4); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,22] <- mean(temp); rt.sem3[1,22] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="SIC"&Target=="ABS"&DColor==4&DShape==4); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat3[1,23] <- mean(temp); rt.sem3[1,23] <- sd(temp)/sqrt(length(temp))
    }
    # Exp 3 - Target Present
    {
      # Do Capacity first
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==-3&ShapeDif==0); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,1] <- mean(temp); rt.sem4[1,1] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==-2&ShapeDif==0); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,2] <- mean(temp); rt.sem4[1,2] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==-1&ShapeDif==0); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,3] <- mean(temp); rt.sem4[1,3] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==1&ShapeDif==0); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,4] <- mean(temp); rt.sem4[1,4] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==2&ShapeDif==0); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,5] <- mean(temp); rt.sem4[1,5] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==3&ShapeDif==0); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,6] <- mean(temp); rt.sem4[1,6] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==-3); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,7] <- mean(temp); rt.sem4[1,7] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==-2); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,8] <- mean(temp); rt.sem4[1,8] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==-1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,9] <- mean(temp); rt.sem4[1,9] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==1); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,10] <- mean(temp); rt.sem4[1,10] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==2); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,11] <- mean(temp); rt.sem4[1,11] <- sd(temp)/sqrt(length(temp))
      temp <- subset(mydata, Condition=="Capacity"&Target!="ABS"&ColorDif==0&ShapeDif==3); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
      rt.mat4[1,12] <- mean(temp); rt.sem4[1,12] <- sd(temp)/sqrt(length(temp))
      # Now DFP blocks
      for (j in 1:length(unique(mydata$ShapeDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))) {
        for (i in 1:length(unique(mydata$ColorDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))) {
          if (!(sort(unique(mydata$ColorDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))[i] == 0 & sort(unique(mydata$ShapeDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))[j] == 0)) {
            temp <- subset(mydata, Condition=="SIC"&Target!="ABS"&ColorDif==sort(unique(mydata$ColorDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))[i]&ShapeDif==sort(unique(mydata$ShapeDif[mydata$Condition=="SIC" & mydata$Target!="ABS"]))[j]); temp <- unlist(lapply(split(temp$RT, temp$Subject), mean))
            rt.mat4[1,12 + (j-1)*length(unique(mydata$ColorDif[mydata$Condition=="SIC" & mydata$Target!="ABS"])) + i] <- mean(temp); rt.sem4[1,12 + (j-1)*length(unique(mydata$ColorDif[mydata$Condition=="SIC" & mydata$Target!="ABS"])) + i] <- sd(temp)/sqrt(length(temp))
          }
        }
      }
      rt.mat4 <- matrix(rt.mat4[,-37], nrow=1); rt.sem4 <- matrix(rt.sem4[,-37], nrow=1)
    }
    
  }
  # plot.RT 
  {
 # Target Present
    postscript(paste(figdir,"Exp_3_Target_PRE_RT.eps",sep=""), width=mywidth*aspect.ratio, height=mywidth, horizontal = F)
    par(oma=c(0,0,2,0), mar=c(3,4,4,2)+.1)#,mfrow=c(2,1))
    layout(matrix(c(0,1,1,1,0,2,2,2,2,2),byrow=T,nrow=2))
    barplot(matrix(rt.mat4[1,1:12],nrow=1), names.arg=c(-3:-1,1:3,rep(0,6)), legend.text=F, beside=T, horiz=F, main="Capacity Trials",xlab="",ylab="Mean RT (s)",ylim=c(0,3),xpd=F, angle=c(rep(-45,3),0,rep(45,3))[4+c(rep(0,6),-3:-1,1:3)], density=c(45,25,10,10,10,25,45)[4+c(rep(0,6),-3:-1,1:3)], col="black")
    arrows(x0=seq(1.5,by=2,length.out=length(rt.mat4[1,1:12])), y0=(rt.mat4[1,1:12]-rt.sem4[1,1:12]), y1=(rt.mat4[1,1:12]+rt.sem4[1,1:12]), angle=90, code=3, lwd=2, length=.02)
    title("Mean RT for Experiment 3 - Target Present",line=.5,cex.main=1.25, outer=T)
    legend(x=mean(par()$usr[2])+6, y=mean(par()$usr[3:4]), legend=c(-3:3), col="black", angle=c(rep(-45,3),0,rep(45,3)), density=c(45,25,10,10,10,25,45), bty='n', ncol=1, xpd=NA, xjust = .5, yjust=.5, x.intersp = .5, title="Shape Dissimilarity")
    par(mar=c(4,4,4,2)+.1)
    barplot(matrix(rt.mat4[1,13:60],nrow=1), names.arg=c(rep(-3:3,7)[-25]), legend.text=F, beside=T, horiz=F, main="DFP Trials",xlab="Color Dissimilarity",ylab="Mean RT (s)",ylim=c(0,3),xpd=F, angle=c(rep(-45,3),0,rep(45,3))[4+c(rep(-3:3,each=7)[-25])], density=c(45,25,10,10,10,25,45)[4+c(rep(-3:3,each=7)[-25])], col="black")#, col=c("green","red","blue","black","blue","red","green")[4+c(rep(0,6),-3:-1,1:3,rep(-3:3,each=7)[-25])])
    arrows(x0=seq(1.5,by=2,length.out=length(rt.mat4[1,13:60])), y0=(rt.mat4[1,13:60]-rt.sem4[1,13:60]), y1=(rt.mat4[1,13:60]+rt.sem4[1,13:60]), angle=90, code=3, lwd=2, length=.02)
    layout(matrix(1))
    par(oma=rep(0,4),mfrow=c(1,1))
    dev.off()
    
    # Target Absent
    postscript(paste(figdir,"Exp_3_Target_ABS_RT.eps",sep=""), width=mywidth*aspect.ratio, height=mywidth, horizontal = F)
    par(oma=c(0,0,2,0), mar=c(3,4,4,2)+.1)#,mfrow=c(2,1))
    layout(matrix(c(0,1,1,1,0,2,2,2,2,2),byrow=T,nrow=2))
    barplot(matrix(rt.mat3[1,1:7],nrow=1), names.arg=c(1:4,rep(1,3)), legend.text=F, beside=T, horiz=F, main="Capacity Trials",xlab="",ylab="Mean RT (s)",ylim=c(0,6),xpd=F, angle=c(rep(-45,2),rep(45,2))[c(rep(1,4),2:4)], density=c(40,15,15,40)[c(rep(1,4),2:4)], col="black")
    arrows(x0=seq(1.5,by=2,length.out=length(rt.mat3[1,1:7])), y0=(rt.mat3[1,1:7]-rt.sem3[1,1:7]), y1=(rt.mat3[1,1:7]+rt.sem3[1,1:7]), angle=90, code=3, lwd=2, length=.02)
    title("Mean RT for Experiment 3 - Target Absent", line=.5, cex.main=1.25, outer=T)
    legend(x=mean(par()$usr[2])+6, y=mean(par()$usr[3:4]), legend=c(1:4), col="black", angle=c(rep(-45,2),rep(45,2)), density=c(40,15,15,40), bty='n', ncol=1, xpd=NA, xjust = .5, yjust=.5, x.intersp = .5, title="Shape Level")
    par(mar=c(4,4,4,2)+.1)
    barplot(matrix(rt.mat3[1,8:23],nrow=1), names.arg=rep(1:4,4), legend.text=F, beside=T, horiz=F, main="DFP Trials",xlab="Color Level",ylab="Mean RT (s)",ylim=c(0,6),xpd=F, angle=c(rep(-45,2),rep(45,2))[rep(1:4,each=4)], density=c(40,15,15,40)[rep(1:4,each=4)], col="black")
    arrows(x0=seq(1.5,by=2,length.out=length(rt.mat3[1,8:23])), y0=(rt.mat3[1,8:23]-rt.sem3[1,8:23]), y1=(rt.mat3[1,8:23]+rt.sem3[1,8:23]), angle=90, code=3, lwd=2, length=.02)
    layout(matrix(1))
    par(oma=rep(0,4),mfrow=c(1,1))
    dev.off()
    
    
  }
  # ANOVAs are in Accuracy section because they use the same data.frame
}

}