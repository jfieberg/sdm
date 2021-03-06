# Author: Babak Naimi, naimi.b@gmail.com
# Date (last update):  July 2017
# Version 1.1
# Licence GPL v3

#-------------
methodInfo <- list(name=c('rpart','RPART'),
                   packages='rpart',
                   modelTypes = c('pa','pb','ab','n'),
                   fitParams = list(formula='standard.formula',data='sdmDataFrame'),
                   fitSettings = list(model=FALSE,x=FALSE,y=FALSE,method='anova'),
                   fitFunction = 'rpart',
                   settingRules = function(x='sdmVariables',f='fitSettings',p='predictSettings') {
                     if (x@distribution == 'poisson') {
                       f[['method']] <- 'poisson'
                     } else if (x@distribution == 'multinomial') {
                       f[['method']] <- 'class'
                       p[['type']] <- 'class'
                     }
                     list(fitSettings=f,predictSettings=p)
                   },
                   tuneParams = NULL,
                   predictParams=list(object='model',newdata='sdmDataFrame'),
                   predictSettings=list(type='vector'),
                   predictFunction='predict',
                   #------ metadata (optional):
                   title='Recursive Partitioning and Regression Trees',
                   creator='Babak Naimi',
                   authors=c('Terry Therneau, Beth Atkinson, Brian Ripley'), # authors of the main method
                   email='naimi.b@gmail.com',
                   url='http://r-gis.net',
                   citation=list(bibentry('book',title = "Classification and Regression Trees",
                                          author = as.person("L. Breiman [aut], J.H. Friedman [aut], R.A. Olshen [aut], C.J. Stone [aut]"),
                                          year='1984',
                                          publisher = "Wadsworth"
                   )
                   ),
                   description="Recursive Partitioning and Regression Trees."
)