initsstan_optim2d <- function(stanData) {
   attach(stanData)

   modelProb_subj <- array(.25,  c(nSubjects, 3))
   modelProb_subj[,2] <- .5
   modelProb_group <- c(.25, .5, .25)
   
   good <- FALSE
   #plot(c(0.5,18.5), c(-100,100), type='n')
   #abline(h=0, col='red')

   A<- rep(NA, nSubjects)
   for (subj in 1:nSubjects) { 
      A[subj] <- -.5 * (mean(rtHL[subjectHL==subj]) -  mean(rtHH[subjectHH==subj]) + mean(rtLL[subjectLL==subj]) -  mean(rtLH[subjectLH==subj]) )
   }
   A[A>0] <- -1E2

   B<- rep(NA, nSubjects)
   for (subj in 1:nSubjects) { 
      B[subj] <- .5 * (mean(rtLH[subjectLH==subj]) -  mean(rtHH[subjectHH==subj]) + mean(rtLL[subjectLL==subj]) -  mean(rtHL[subjectHL==subj]) )
   }
   B[B<0] <- 1E2

   C<- rep(NA, nSubjects)
   for (subj in 1:nSubjects) { 
      C[subj] <- 2* mean(c(rtHH[subjectHH==subj], rtHL[subjectHL==subj], rtLH[subjectLH==subj], rtLL[subjectLL==subj]))
   }

   while (! good) {
      good <- TRUE
      p_mic <- abs(rnorm(nSubjects,0,1))
      mic <- 100 + 50 * p_mic

      p_A <- (A + 100) / 50 
      p_B <- (B - 100) / 50 
      p_C <- (C - 400) / 100 

      rateHH <- rgamma(nSubjects,1,1);
      rateHL <- rgamma(nSubjects,1,1);
      rateLH <- rgamma(nSubjects,1,1);
      rateLL <- rgamma(nSubjects,1,1);

      muHH_pos <-  .25 * mic + .5 * A - .5 * B + .5 * C
      muHL_pos <- -.25 * mic - .5 * A - .5 * B + .5 * C
      muLH_pos <- -.25 * mic + .5 * A + .5 * B + .5 * C
      muLL_pos <-  .25 * mic - .5 * A + .5 * B + .5 * C
                                                       
      muHH_neg <- -.25 * mic + .5 * A - .5 * B + .5 * C
      muHL_neg <-  .25 * mic - .5 * A - .5 * B + .5 * C
      muLH_neg <-  .25 * mic + .5 * A + .5 * B + .5 * C
      muLL_neg <- -.25 * mic - .5 * A + .5 * B + .5 * C
                                                                                                 
      muHH_0   <-            + .5 * A - .5 * B + .5 * C
      muHL_0   <-            - .5 * A - .5 * B + .5 * C
      muLH_0   <-            + .5 * A + .5 * B + .5 * C
      muLL_0   <-            - .5 * A + .5 * B + .5 * C

      if (any(muHH_pos < 0) | any(muHL_pos < 0) | any(muLH_pos <0) | any(muLL_pos < 0)) { good <- FALSE}
      if (any(muHH_neg < 0) | any(muHL_neg < 0) | any(muLH_neg <0) | any(muLL_neg < 0)) { good <- FALSE}
      if (any(muHH_0 < 0) | any(muHL_0 < 0) | any(muLH_0 <0) | any(muLL_0 < 0)) { good <- FALSE}

      #if (any(muLH_pos - muHH_pos < 0) | any(muLH_neg - muHH_neg < 0) | any(muLH_0 - muHH_0 < 0) ) { good <- FALSE }
      #if (any(muHL_pos - muHH_pos < 0) | any(muHL_neg - muHH_neg < 0) | any(muHL_0 - muHH_0 < 0) ) { good <- FALSE }
      #if (any(muLL_pos - muLH_pos < 0) | any(muLL_neg - muLH_neg < 0) | any(muLL_0 - muLH_0 < 0) ) { good <- FALSE }
      #if (any(muLL_pos - muHL_pos < 0) | any(muLL_neg - muHL_neg < 0) | any(muLL_0 - muHL_0 < 0) ) { good <- FALSE }

      if(!good) { C <- 1.1*C }    
   } 

   detach(stanData)
   return(list(p_mic=p_mic, p_A=p_A, p_B=p_B, p_C=p_C,
               rateHH=rateHH, rateHL=rateHL, rateLH=rateLH, rateLL=rateLL, 
               modelProb_group=modelProb_group,
               modelProb_subj=modelProb_subj))
}

