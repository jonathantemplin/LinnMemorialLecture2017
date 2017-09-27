
theta = seq(-4,4,.01)
alpha = matrix(data = 0, nrow = 4, ncol = 2)
alpha[2,2] = 1
alpha[3,1] = 1
alpha[4,1:2] = 1

Intercept = -3
Discrimination = 2
ME1 = 1
ME2 = 2
ThetaAlpha1 = -.5
ThetaAlpha2 = -1
Alpha1Alpha2 = 3
ThreeWay = 2

yplot = NULL
xplot = cbind(theta, theta, theta, theta)

for (pattern in 1:dim(alpha)[1]){
  logit = Intercept + Discrimination*theta + ME1*alpha[pattern,1] + ME2*alpha[pattern,2] + ThetaAlpha1*theta*alpha[pattern,1] +
    ThetaAlpha2*theta*alpha[pattern,2] + Alpha1Alpha2*alpha[pattern,1]*alpha[pattern,2] + ThreeWay*theta*alpha[pattern,1]*alpha[pattern,2]
  
  yplot = cbind(yplot,exp(logit)/(1+exp(logit)))
}

matplot(y = yplot, x = xplot, type = "l", lwd=5, col=1:4, lty=1:4, cex.axis = 1.4, cex.lab = 1.4, cex.main = 1.4, 
        xlab = "Content Domain Score", ylab = "Probability of Correct Response", main = "ICCs for Hypothetical Item")
legend(x = 1, y = .2, legend = c("Cross-Concept: NM; Practice: NM", "Cross-Concept: NM; Practice: M",
                                 "Cross-Concept: M; Practice: NM","Cross-Concept: M; Practice: M"), col=1:4, lty=1:4,
       lwd =5)
