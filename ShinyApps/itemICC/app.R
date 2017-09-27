#install.packages("shiny")

library(shiny)

ui = fluidPage(
  # *Input() functions,
  fluidRow(h2("Hypothetical Item Characteristic Curve", style="text-align: center;")),
  fluidRow(column(12,   # *Output() functions
                  plotOutput("corrMatrix"))),
  fluidRow(column(12,h4("Item Parameter Values", style="text-align:center;"))),
  fluidRow(column(6,  sliderInput(inputId = "intercept",
                                label = "Item Intercept",
                                value = -3, min=-4, max=4, step = .1) ,
                      sliderInput(inputId = "discrimination",
                                label = "Domain Discriminiation (Conditional)",
                                value = 2, min=0, max=4, step=.1), 
                  sliderInput(inputId = "me1",
                              label = "Cross-cutting Concept Main Effect (Conditional)",
                              value = 1, min=0, max=4, step=.1), 
                  sliderInput(inputId = "me2",
                              label = "Practice Main Effect (Conditional)",
                              value = 2, min=0, max=4, step=.1)),
           column(6,
                  sliderInput(inputId = "thetaalpha1",
                              label = "Domain-by-Concept Interaction (Conditional)",
                              value = -.5, min=-4, max=4, step=.1), 
                  sliderInput(inputId = "thetaalpha2",
                              label = "Domain-by-Practice Interaction (Conditional)",
                              value = -1, min=-4, max=4, step=.1), 
                  sliderInput(inputId = "alpha1alpha2",
                              label = "Concept-by-Practice Interaction (Conditional)",
                              value = 3, min=-4, max=4, step=.1), 
                  sliderInput(inputId = "threeway",
                              label = "Domain-by-Concept-by-Practice Interaction",
                              value = 2, min=-4, max=4, step=.1))
           ),
  fluidRow(a("Link to R script underlying this Shiny App", href = "itemICC_app_initial.R", target="_blank"))

)

server = function(input, output){
  
  


 output$corrMatrix = renderPlot({
   theta = seq(-4,4,.01)
   alpha = matrix(data = 0, nrow = 4, ncol = 2)
   alpha[2,2] = 1
   alpha[3,1] = 1
   alpha[4,1:2] = 1
   
   
   Intercept = input$intercept
   Discrimination = input$discrimination
   ME1 = input$me1
   ME2 = input$me2
   ThetaAlpha1 = input$thetaalpha1
   ThetaAlpha2 = input$thetaalpha2
   Alpha1Alpha2 = input$alpha1alpha2
   ThreeWay = input$threeway
   
   yplot = NULL
   xplot = cbind(theta, theta, theta, theta)
   
   for (pattern in 1:dim(alpha)[1]){
     logit = Intercept + Discrimination*theta + ME1*alpha[pattern,1] + ME2*alpha[pattern,2] + ThetaAlpha1*theta*alpha[pattern,1] +
       ThetaAlpha2*theta*alpha[pattern,2] + Alpha1Alpha2*alpha[pattern,1]*alpha[pattern,2] + ThreeWay*theta*alpha[pattern,1]*alpha[pattern,2]
     
     yplot = cbind(yplot,exp(logit)/(1+exp(logit)))
   }
   
   matplot(y = yplot, x = xplot, type = "l", lwd=5, col=1:4, lty=1:4, cex.axis = 1.4, cex.lab = 1.4, cex.main = 1.4,
           xlab = "Content Domain Score", ylab = "Probability of Correct Response", main = "ICCs for Hypothetical Item")
   legend(x = 1.5, y = .4, legend = c("Cross-Concept: NM; Practice: NM", "Cross-Concept: NM; Practice: M",
                                    "Cross-Concept: M; Practice: NM","Cross-Concept: M; Practice: M"), col=1:4, lty=1:4,
          lwd =5)
   
 })


}

shinyApp(ui = ui, server = server)

