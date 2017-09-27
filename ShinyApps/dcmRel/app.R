
library(shiny)
library(polycor)

#generate data
ICBC = function(alpha, int, me){
  prob = exp(int+me*alpha)/(1+exp(int+me*alpha))
  return(prob)
}

DCMdataN1 = function(alpha, int, me){
  prob = ICBC(alpha = alpha, int = int, me = me)
  data = matrix(rbinom(n = length(int), size = 1, prob = prob),nrow=1)
  return(data)
}

DCMdataALL = function(alpha, int, me){
  tdata = sapply(X = alpha, FUN = DCMdataN1, simplify = TRUE, int, me)
  data = t(tdata)
  return(data)
}

DCMclassifyN1 = function(data, int, me, propM){
  alpha0 = 0
  probA0 = ICBC(alpha = alpha0, int = int, me = me)
  likeA0 = prod(dbinom(x = data, size = 1, prob = probA0))
  
  alpha1 = 1
  probA1 = ICBC(alpha = alpha1, int = int, me = me)
  likeA1 = prod(dbinom(x = data, size = 1, prob = probA1))
  
  probMaster = likeA1*propM/(likeA1*propM + likeA0*(1-propM))
  return(probMaster)
}

DCMclassifyALL = function(data, int, me, propM){
  tprob = apply(X = data, MARGIN = 1, FUN = DCMclassifyN1, int, me, propM)
  return(tprob)
}

dec2bin = function(decimal_number, nattributes, basevector){
  dec = decimal_number
  profile = matrix(NA, nrow = 1, ncol = nattributes)
  for (i in nattributes:1){
    profile[1,i] =  dec%%basevector[1,i]
    dec = (dec-dec%%basevector[1,i])/basevector[1,i]
  }
  return(profile)
}

marginalize_attribute_probabilities = function(profile_estimates, natts){
  #create attribute profile matrix
  att_profile = NULL
  for (profile in 0:(2^natts-1)){
    att_profile = rbind(att_profile, dec2bin(decimal_number = profile, nattributes = 3, basevector = matrix(rep(2,3), nrow = 1)))
  }
  
  #marginalize attributes via matrix product
  marginal_estimates = as.matrix(profile_estimates) %*% att_profile
  
  marginal_estimates = data.frame(marginal_estimates)
  colnames(marginal_estimates) = paste("Attribute", 1:natts, sep="")
  return(marginal_estimates)
}

calculate_attribute_reliability = function(marginal_attribute_estimates, nreps){

  #convert to matrix:
  marginal_attribute_estimates = as.matrix(marginal_attribute_estimates)
  
  #draw probabilities with replication:
  sampled_examinees = as.matrix(sample(x = marginal_attribute_estimates, size = nreps, replace = TRUE))
  
  #draw data, twice
  simdata = cbind(rbinom(n=nreps, size=1, prob=sampled_examinees), rbinom(n=nreps, size=1, prob=sampled_examinees))
  
  #calculate tetrachoric correlation between two draws
  reliability = polychor(x = simdata[,1], y = simdata[,2])
  
  return(reliability)
}


allOfIt = function(nexam, int, me, pMasters){
  #generate examinee parameters
  alpha = rbinom(n = nexam, size = 1, prob = pMasters)
  
  #simulate data
  simdata = DCMdataALL(alpha = alpha, int = int, me = me)
  
  #create classifications
  classification = DCMclassifyALL(data = simdata, int = int, me = me, propM = pMasters)
  
  #calculate DCM reliabilities
  reliability = calculate_attribute_reliability(marginal_attribute_estimates = classification, nreps = 10000)
  
  return(reliability)
}

ui = fluidPage(
  # *Input() functions,
  fluidRow(h2("DCM Total and Subscore Marginal Reliabilities", style="text-align: center;")),
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
  fluidRow(a("Link to R script underlying this Shiny App", href = "dcmReliability_app_initial.R", target="_blank"))

)

server = function(input, output){
  
  observeEvent(input$draw, {
    
    nitems = input$totalItem
    nscores  = input$subItem

    nexam = 10000
    #create item parameters using IRT model (3PL)
    mainEffectLB = 1
    mainEffectUB = 2
    interceptLB = -1.5
    interceptUB = 0
    propMastersLB = .4
    propMastersUB = .6
    
    #generate item parameters
    ME = runif(n = nitems, min = mainEffectLB, max = mainEffectUB)
    Int = runif(n = nitems, min = interceptLB, max = interceptUB)
    pMasters = runif(n = 1, min = propMastersLB, max = propMastersUB)
    
    pMastersSub = runif(n = nscores, min = propMastersLB, max = propMastersUB) 
    students = rbinom(n = nexam, size = 1, prob = pMasters)
    

    #calculate overall Reliability
    rel = allOfIt(nexam = nexam, int = Int, me = ME, pMasters = pMasters)
  
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
      
      rel = c(rel, allOfIt(nexam = nexam, int = Int[subtestItems[[test]]], me = ME[subtestItems[[test]]], pMasters = pMastersSub[test]))
    }
    
    names(rel) = c("Total", paste("Subscore", 1:nscores))
    


 output$corrMatrix = renderPlot({
   barplot(rel, ylim = c(0,1), col = c(2,rep(4,nscores)), ylab = "Classification Reliability", xlab = "Score", main = "DCM Reliabilty Comparison of Total and Subscores", 
           cex.lab=1.4, cex.axis = 1.4)
   
   
 })

  })
}

shinyApp(ui = ui, server = server)

