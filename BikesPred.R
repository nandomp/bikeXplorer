###############################################
################# LIBRARIES ###################
###############################################

options( java.parameters = "-Xmx6g" )
.lib<- c("RWeka", "sampling", "caret","gbm", "rpart","dplyr","ggplot2","lubridate","e1071","randomForest","foreach","RMySQL")

.inst <- .lib %in% installed.packages()
if (length(.lib[!.inst])>0) install.packages(.lib[!.inst])
lapply(.lib, require, character.only=TRUE)

#source("trafficPred.R")

MyUser='admin_airvlc'
MyPass = '41rvlc2016'
MyHost= 'mysql.dsic.upv.es'
MyDataBase='airvlc'



###############################################
############### DATA + MODEL  #################
###############################################

load("predStations.RData")

load("modelsBikeStation.RData")


###############################################
################  PREDICTION  #################
###############################################

test <- data.frame()
for(i in 1:24){
  timeDate <- ymd_hms(Sys.time(),tz="CET") + hms(paste(i,":0:0"))
  temp <- data.frame(station = 1:276,
                     day = day(timeDate), 
                     month = month(timeDate), 
                     year = year(timeDate), 
                     hour=hour(timeDate), 
                     wday = wday(timeDate),
                     meanbikes=NA)#add population
  
  test <- rbind(test,temp)
  test <- tbl_df(test)
}

results <- data.frame()

for (sta in 1:276){
  tempResults <- filter(test, station == sta) 
  tempResults$meanbikes<- predict(Fits[[sta]], tempResults)
  results<-rbind(results, tempResults)
}
results$pred <- round(results$meanbikes)

save(results, file="testStation.RData")  
write.csv(results, file = "Prediction4station.csv")

###############################################
################  DB UPDATE   #################
###############################################

#Mapa INT, Punto INT, Intensidad INT
load("testStation.RData")
timeDate <- ymd_hms(Sys.time(),tz="CET") + hms(paste(i,":0:0"))
newDS <- data.frame(Station=results$Station,
                    FechaHora= dmy_hms(paste(results$day,",",results$month,",",results$year," ",results$hour,":00:00")),
                    Bikes = results$pred)



mydb = dbConnect(MySQL(), user=MyUser, password=MyPass, host=MyHost, dbname=MyDataBase)
dbWriteTable(mydb, value = newDS, name = "predBike",  overwrite=TRUE ) 
#tabla<-fetch(dbSendQuery(mydb, "select * from pred"),n=4900)
#fetch(dbSendQuery(mydb, "select COUNT(*) from pred"),n=1)


