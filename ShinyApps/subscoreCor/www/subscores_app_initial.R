# App for subscores

require(mirt)

nitems = 50
nitemsT1 = 25
nscores = 2
nexam = 2000

#create item parameters using IRT model (3PL)
discriminationLB = 1
discriminationUB = 3
guessingLB = 0
guessingUB = .25
difficultyLB = -2
difficultyUB = 2
diffstep = (difficultyUB - difficultyLB)/(nitems-1)

#generate item parameters
guessing = runif(n = nitems, min = guessingLB, max = guessingUB)
discrimination = runif(n = nitems, min = discriminationLB, max = discriminationUB)
difficulty = seq(difficultyLB,difficultyUB,diffstep)

#generate examinee parameters
theta = rnorm(n = nexam,mean = 0, sd = 1)

#generate data
ICC = function(theta, a, b, c){
  prob = c + (1-c)*exp(a*(theta-b))/(1+exp(a*(theta-b)))
  return(prob)
}

IRTdataN1 = function(theta, a, b, c){
  prob = ICC(theta = theta, a = a, b = b, c = c)
  data = matrix(rbinom(n = length(a), size = 1, prob = prob),nrow=1)
  return(data)
}

IRTdataALL = function(theta, a, b, c){
  tdata = sapply(X = theta, FUN = IRTdataN1, simplify = TRUE, discrimination, difficulty, guessing)
  data = t(tdata)
  return(data)
}


panel.cor <- function(x, y, digits = 2, cex.cor, ...){
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(0, 1, 0, 1))
  # correlation coefficient
  r <- cor(x, y)
  txt <- format(c(r, 0.123456789), digits = digits)[1]
  txt <- paste("r= ", txt, sep = "")
  text(0.5, 0.6, txt, cex = 2)
  
  
}
simdata = IRTdataALL(theta = theta, a = discrimination, b = difficulty, c = guessing)
colnames(simdata) = paste0("item", 1:length(discrimination))

#create MIRT object for parameters 
analysis = mirt(simdata, 1, itemtype = "3PL", pars = "values")
analysis$value[analysis$name == "g"] = guessing
analysis$value[analysis$name == "a1"] = discrimination
analysis$value[analysis$name == "d"] = -1*discrimination*difficulty
analysis$est = FALSE

#get overall test scores
scores = mirt(simdata, 1, pars = analysis)
mirt_estimates = fscores(scores, full.scores.SE = TRUE)


#create subtests
subtestItems1 = sample(x = colnames(simdata), size = nitemsT1, replace = FALSE)
subtestItems2 = colnames(simdata)[which(!(colnames(simdata) %in% subtestItems1))]

simdata1 = simdata[,subtestItems1]
simdata2 = simdata[,subtestItems2]

analysis1 = mirt(simdata1, 1, itemtype = "3PL", pars = "values")
analysis2 = mirt(simdata2, 1, itemtype = "3PL", pars = "values")

analysis1$value[analysis1$name == "g"] = guessing[which(colnames(simdata) %in% subtestItems1)]
analysis1$value[analysis1$name == "a1"] = discrimination[which(colnames(simdata) %in% subtestItems1)]
analysis1$value[analysis1$name == "d"] = -1*discrimination[which(colnames(simdata) %in% subtestItems1)]*difficulty[which(colnames(simdata) %in% subtestItems1)]
analysis1$est = FALSE

scores1 = mirt(simdata1, 1, pars = analysis1)
mirt_estimates1 = fscores(scores1, full.scores.SE = TRUE)

analysis2$value[analysis2$name == "g"] = guessing[which(colnames(simdata) %in% subtestItems2)]
analysis2$value[analysis2$name == "a1"] = discrimination[which(colnames(simdata) %in% subtestItems2)]
analysis2$value[analysis2$name == "d"] = -1*discrimination[which(colnames(simdata) %in% subtestItems2)]*difficulty[which(colnames(simdata) %in% subtestItems2)]
analysis2$est = FALSE

scores2 = mirt(simdata2, 1, pars = analysis2)
mirt_estimates2 = fscores(scores2, full.scores.SE = TRUE)

#place IRT scores onto raw score metric using mean and sigma transformation
totalMean = mean(apply(X = simdata, MARGIN = 1, FUN = sum))
totalSD = sd(apply(X = simdata, MARGIN = 1, FUN = sum))

subtest1Mean = mean(apply(X = simdata1, MARGIN = 1, FUN = sum))
subtest2Mean = mean(apply(X = simdata2, MARGIN = 1, FUN = sum))
subtest1SD = sd(apply(X = simdata1, MARGIN = 1, FUN = sum))
subtest2SD = sd(apply(X = simdata2, MARGIN = 1, FUN = sum))


mydata = cbind(totalMean+totalSD*mirt_estimates[,1], subtest1Mean + subtest1SD*mirt_estimates1[,1], subtest2Mean + subtest2SD*mirt_estimates2[,1])
colnames(mydata) = c("Total", "Subscore1", "Subscore2")
mydata = as.data.frame(mydata)

pairs(mydata, upper.panel = panel.cor, main = "Correlation of Total and Subscores")
