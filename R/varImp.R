# Author: Babak Naimi, naimi.b@gmail.com
# Date :  July 2016
# Last update :  Fenruary 2020
# Version 3.1
# Licence GPL v3


# for internal use in .workLoad
# pv is pred.par
._varImp <- function(pv,pred,sp,nsim=5) {
  # if the datatype is different than sdmDataFrame, then it should be updated to support...
  ww <- names(pv[[2]])[which(names(pv[[2]]) != sp)]
  dd <- pv[[2]]
  obs <- pv[[2]][,sp]
  d1 <- pred(pv)
  vi <- vj <- rep(NA,nsim)
  varImp1 <- varImp2 <- rep(NA,length(ww))
  names(varImp1) <- names(varImp2) <- ww
  a1 <- .auc(obs,d1)
  for (v in ww) {
    for (i in 1:nsim) {
      pv[[2]][,v] <- dd[sample(nrow(dd)),v]
      d2 <- pred(pv)
      cr <- cor(d1,d2,use="complete.obs")
      if (cr < 0) cr <- 0
      vi[i] <- 1 - cr
      a2 <- .auc(obs,d2)
      a2 <- (a1-a2)*2
      if (a2 > 1) a2 <- 1
      else if (a2 < 0) a2 <- 0
      vj[i] <- a2
    }
    varImp1[v] <- round(mean(vi,na.rm=TRUE),4)
    varImp2[v] <- round(mean(vj,na.rm=TRUE),4)
    pv[[2]] <- dd
  }
  new('.varImportance',variables=ww,varImportance=data.frame(variables=ww,corTest=varImp1,AUCtest=varImp2))
}
#---------

# .getVarImpObject <- function(x,id,wtest) {
#   # stat can be 1 (threshold-independent) OR 2 (threshold-dependent)
#   mi <- x@run.info
#   w <- which(mi$modelID == id)
#   if (length(w) == 1) {
#     if (missing(wtest) || is.null(wtest)) wtest <- colnames(mi)[9:7][which(as.matrix(mi[1,c(9,8,7)]))[1]]
#     else {
#       wtest <- .pmatch(wtest,c('training','test.dep','test.indep'))[1]
#       if (is.na(wtest)) wtest <- colnames(mi)[9:7][which(as.matrix(mi[1,c(9,8,7)]))[1]]
#     }
#     
#     sp <- as.character(mi$species)[w]
#     mo <- as.character(mi$method)[w]
#     i <- as.character(mi$modelID)[w]
#     x@models[[sp]][[mo]][[i]]@varImportance[[wtest]]
#   } 
#   
# }
#--------
.getVarImpObject <- function(x,id,wtest) {
  # stat can be 1 (threshold-independent) OR 2 (threshold-dependent)
  
  mi <- x@run.info[x@run.info$modelID %in% id,]
  
  mi <- mi[mi$success,]
  
  #mi <- x@run.info
  #w <- which(mi$modelID == id)
  
  if (missing(wtest) || is.null(wtest)) wtest <- colnames(mi)[9:7][which(as.matrix(mi[1,c(9,8,7)]))[1]]
  else {
    wtest <- .pmatch(wtest,c('training','test.dep','test.indep'))[1]
    if (is.na(wtest)) wtest <- colnames(mi)[9:7][which(as.matrix(mi[1,c(9,8,7)]))[1]]
  }
  #------------
  if (length(id) == 1) {
    w <- which(mi$modelID == id)
    sp <- as.character(mi$species[w])
    mo <- as.character(mi$method[w])
    .id <- as.character(id)
    return(x@models[[sp]][[mo]][[.id]]@varImportance[[wtest]])
  } else {
    o <- list()
    for (i in id) {
      w <- which(mi$modelID == i)
      sp <- as.character(mi$species[w])
      mo <- as.character(mi$method[w])
      .id <- as.character(i)
      o[[.id]] <- x@models[[sp]][[mo]][[.id]]@varImportance[[wtest]]
    }
    
    if (length(unique(sapply(o,function(x) length(x@variables)))) > 1) stop('The specified models (id) used different set of variables; in case of multiple id, select id for the models that used same predictors')
    
    .n <- length(o[[1]]@variables)
    vi2 <- vi1 <- data.frame(matrix(ncol=.n,nrow=length(o)))
    colnames(vi1) <- colnames(vi2) <- as.character(o[[1]]@varImportance[,1])
    
    for (i in 1:length(o)) {
      vi1[i,] <- o[[i]]@varImportance$corTest
      vi2[i,] <- o[[i]]@varImportance$AUCtest
    }
    
    .m <- apply(vi1,2,mean,na.rm=TRUE)
    .ci <- 1.96 * apply(vi1,2,sd,na.rm=TRUE) / sqrt(.n)
    vi1 <- data.frame(variables=  colnames(vi1),corTest=.m,lower=.m - .ci,upper=.m + .ci)
    
    .m <- apply(vi2,2,mean,na.rm=TRUE)
    .ci <- 1.96 * apply(vi2,2,sd,na.rm=TRUE) / sqrt(.n)
    vi2 <- data.frame(variables=  colnames(vi2),AUCtest=.m,lower=.m - .ci,upper=.m + .ci)
    o <- new('.varImportanceList',variables=as.character(vi1$variables),varImportanceList=o,
              varImportanceMean=list(corTest=vi1,AUCtest=vi2))
   return(o)
  }
}


#--------
if (!isGeneric("getVarImp")) {
  setGeneric("getVarImp", function(x,id, wtest, ...)
    standardGeneric("getVarImp"))
}  

setMethod('getVarImp', signature(x='sdmModels'),
          function(x, id, wtest,...) {
            mi <- x@run.info[x@run.info$success,]
            if (nrow(mi) == 0) stop('No successfully fitted models exist in the sdmModels object!')
            
            if (missing(id) || is.null(id)) {
              id <- getModelId(x, success = TRUE, ...)
              if (length(id) == 0) stop('No successfully fitted models is selected!')
              else if (length(id) > 1 && length(id) == nrow(mi)) cat('\nThe variable importance for all the models are combined (averaged)... \n')
              else cat(paste0('\nThe values of relative variable importance are generated from ', length(id),' models... \n'))
            } else {
              if (!any(id %in% mi$modelID)) stop('No successfully fitted models are corresponding to the specified modelIDs (id)!')
              
              if (!all(id %in% mi$modelID)) {
                id <- id[id %in% mi$modelID]
                if (length(id) == 1) cat(paste0('Only the id  = ',id,' does exist in the list of successfully fitted models. \n'))
                else if (length(id) > 1) cat(paste0('Some of the specified modelIDs (id) are not available; ', length(id),' models are considered...! \n'))
              }
              
              if (length(unique(mi$species)) > 1) {
                warning('Consider that the specified modelIDs in id are related to several species!')
              }
              
              if (length(unique(mi$method)) > 1) {
                warning('Consider that the specified modelIDs in id are related to several methods!')
              }
            }
            #--------------
            if (missing(wtest)) wtest <- NULL
            
            .getVarImpObject(x,id,wtest)
            
          }
)



# setMethod('getVarImp', signature(x='sdmModels'),
#           function(x, id, wtest,...) {
#             if (missing(id)) id <- NULL
#             if (missing(wtest)) wtest <- NULL
#             
#             if (!is.null(id) & length(id) == 1) {
#               .getVarImpObject(x,id,wtest)
#             } else {
#               stop('This version only support extracting the variable importance for 1 model each time!')
#             }
#             
#           }
# )




