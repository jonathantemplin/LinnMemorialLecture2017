#install.packages("shiny")

library(shiny)

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
  tdata = sapply(X = theta, FUN = IRTdataN1, simplify = TRUE, a, b, c)
  data = t(tdata)
  return(data)
}

IRTtestInfo = function(theta, a, b, c){
  #one theta and all a,b,c
  prob = ICC(theta = theta, a = a, b = b, c = c)
  iteminfo = (a^2)*((prob-c)^2/(1-c)^2)*(1-prob)/prob
  testinfo = sum(iteminfo)
  return(testinfo)
}


ui = fluidPage(
  # *Input() functions,
  fluidRow(h2("Total and Subscore Conditional Reliabilities", style="text-align: center;")),
  fluidRow(column(3,  sliderInput(inputId = "totalItem",
                                label = "Number of Items in Total Score",
                                value = 80, min=6, max=200) ,
                      sliderInput(inputId = "subItem",
                                label = "Number of Subscores",
                                value = 2, min=2, max=10), 
                      actionButton(inputId = "draw", label = "Resample Reliabilities")
                  ),
           column(9,   # *Output() functions
                  plotOutput("corrMatrix"))),
  fluidRow(a("Link to R script underlying this Shiny App", href = "subscoresReliability_app_initial.R", target="_blank"))

)

server = function(input, output){
  
  observeEvent(input$draw, {
    
    nitems = input$totalItem
    nscores  = input$subItem

    nexam = 2000
    
    #create item parameters using IRT model (3PL)
    discriminationLB = 1
    discriminationUB = 2
    guessingLB = .15
    guessingUB = .35
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
    
    IRTtestInfo = function(theta, a, b, c){
      #one theta and all a,b,c
      prob = ICC(theta = theta, a = a, b = b, c = c)
      iteminfo = (a^2)*((prob-c)^2/(1-c)^2)*(1-prob)/prob
      testinfo = sum(iteminfo)
      return(testinfo)
    }
    
    
    
    #create conditional reliabiltiy plot
    theta = seq(-4, 4, .01)
    infocurve = sapply(X = theta, FUN = IRTtestInfo, a = discrimination, b=difficulty, c=guessing)
    VARtheta = 1/infocurve
    thetaRel = 1/(1+VARtheta)
    
    yplot = cbind(thetaRel)
    xplot = cbind(theta)
    remainder = nitems %% nscores
    nitemsSub = rep(nitems %/% nscores, nscores)
    if (remainder > 0){
      for (test in 1:remainder){
        nitemsSub[test] = nitemsSub[test] +1
      }
    }
    
    subtestItems = list()
    ItemsLeft = 1:nitems
    for (test in 1:nscores){
      
      subtestItems[[test]] = sample(x = ItemsLeft, size = nitemsSub[test], replace = FALSE)
      ItemsLeft = ItemsLeft[which(!(ItemsLeft %in% subtestItems[[test]]))]
      
      subtestInfoCurve = sapply(X = theta, FUN=IRTtestInfo, a = discrimination[subtestItems[[test]]], b = difficulty[subtestItems[[test]]],
                                c = guessing[subtestItems[[test]]])
      
      subtestVarTheta = 1/subtestInfoCurve
      subtestThetaRel =  1/(1+subtestVarTheta)
      yplot = cbind(yplot, subtestThetaRel)
      xplot = cbind(xplot, theta)
    }
    
    
    

    


 output$corrMatrix = renderPlot({
   matplot(y = yplot, x = xplot, type="l", lwd=5, ylab = "Conditional Reliability", 
           xlab = "Ability Score", main = "Reliability of Total and Subscores", cex.axis = 1.4, cex.lab = 1.4, cex.main = 1.4, ylim = c(0,1), 
           col = 1:(nscores+1), lty = 1:(nscores+1))
   legend(x = -1, y = .15, legend = c("Total Score"), col = 1, lty = 1, lwd=5)
   #legend(x = -1, y = .15, legend = c("Total Score", paste("Subscore", 1:nscores)), col = 1:(nscores+1), lty = 1:(nscores+1), lwd=5)
   
   
 })

  })
}

shinyApp(ui = ui, server = server)

