###############################################
################# LIBRARIES ###################
###############################################

options( java.parameters = "-Xmx6g" )
.lib<- c("RWeka", "sampling", "caret","gbm", "rpart","dplyr","ggplot2","lubridate","e1071","randomForest","foreach","RMySQL")

.inst <- .lib %in% installed.packages()
if (length(.lib[!.inst])>0) install.packages(.lib[!.inst])
lapply(.lib, require, character.only=TRUE)

#source("trafficPred.R")

#MyUser=
#MyPass = 
#MyHost= 
#MyDataBase=


###############################################
############### DATA + MODEL  #################
###############################################

load("popTotStations.RData")#totStationsHours
poptotstations<-tbl_df(poptotstations)

poptotstations$hood <- as.numeric(poptotstations$hood)


Fits <- vector(mode = "list", length = 24)
for(h in 1:24){
  Fits[[h]]<-lm(meanbikes ~ pob_0_14 + pob_15_65 + pob_66_mas + hood,  data = filter(poptotstations, hour==h-1)) #add population
  print(paste("Model_StaPop ", h, " trained."))
  
}


save(Fits, file="modelsGridHours.RData")


###############################################
################  PREDICTION  #################
###############################################

load("modelsGridHours.RData")
popGrid<-tbl_df(read.csv("poblacion_grid.csv"))
TypeGrid <- tbl_df(read.csv("tipos_cuadrante.csv", stringsAsFactors = FALSE))

i <-1
for (c in popGrid$id ){
  
  popGrid$hood[i] <- filter(TypeGrid, ID == c)[[1,2]]
  i <- i+1
}  
popGrid$hood <- as.factor(popGrid$hood)
popGrid$hood <- as.numeric(popGrid$hood)



test <- list()
for(i in 0:23){
  
  temp <- popGrid
  temp$hour <- i
  
  test[[i+1]]<- temp
}

results <- data.frame()

load("modelsGridHours.RData")
for (hour in 1:24){
  tempResults <- test[[hour]]  
  tempResults$meanbikes<- predict(Fits[[hour]], tempResults)
  results<-rbind(results, tempResults)
}
results$pred <- round(results$meanbikes)

save(results, file="testGridPreds.RData")      



load("testGridPreds.RData")
timeDate <- ymd_hms(Sys.time(),tz="CET") + hms(paste(i,":0:0"))
newDS <- data.frame(Grid=results$grid,
                    FechaHora= dmy_hms(paste("1-1-2016",results$hour,":00:00")),
                    Bikes = results$pred)


#mydb = dbConnect(MySQL(), user=MyUser, password=MyPass, host=MyHost, dbname=MyDataBase)
#dbWriteTable(mydb, value = newDS, name = "predGrid",  overwrite=TRUE ) 
#tabla<-fetch(dbSendQuery(mydb, "select * from pred"),n=4900)
#fetch(dbSendQuery(mydb, "select COUNT(*) from pred"),n=1)