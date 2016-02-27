##############################################
################# LIBRARIES ###################
###############################################
options( java.parameters = "-Xmx6g" )
.lib<- c("RWeka", "sampling", "caret","gbm", "rpart","dplyr","ggplot2","lubridate","e1071","randomForest","foreach","hydroGOF")

.inst <- .lib %in% installed.packages()
if (length(.lib[!.inst])>0) install.packages(.lib[!.inst])
lapply(.lib, require, character.only=TRUE)


# 
# MyUser=
# MyPass = 
# MyHost= 
# MyDataBase=
# 


downloadBikes <- function(){
  data_bikes = NA

  tryCatch(
    data_bikes<-read.csv("http://mapas.valencia.es/lanzadera/opendata/Valenbisi/CSV",sep=";"),error = function(e) return("FAIL DEL 15")
  )
  
  if (!is.na(data_bikes)){
    data_bikes<-data_bikes[complete.cases(data_bikes),]
    data_bikes<-data_bikes[!duplicated(data_bikes$idpm),]
    
    data_bikes$hora_actualizacion <- format(as.POSIXct(data_bikes$hora_actualizacion, format="%H:%M:%S"), format="%H:00:00")
    #newDS <- data.frame(Punto = data_bikes$idpm, 
    #                    FechaHora = ymd_hms(paste(data_bikes$fecha_actualizacion," ",data_bikes$hora_actualizacion),tz="CET"),
    #                    Intensidad = data_bikes$ih)
    
    #mydb = dbConnect(MySQL(), user=MyUser, password=MyPass, host=MyHost, dbname=MyDataBase)
    #dbWriteTable(mydb, value = newDS, name = "hist",  overwrite=TRUE ) 
    #tabla<-fetch(dbSendQuery(mydb, "select * from hist"),n=nrow(data_bikes))
    #fetch(dbSendQuery(mydb, "select COUNT(*) from hist"),n=1)
    
  }
}
  

  
  
  dataStations <- function(){
    
    totStations <- data.frame()
    totStationsHours <- list()
    
    for (i in 1:276){
      data <-tbl_df(read.csv(paste("Valence_",i,".csv",sep="")))
      data$station <- i
      data$wday <- wday(dmy(paste(data$day,data$month,data$year,sep=","), tz="CET"))
      
      #dataMonth <-filter(data, month == m)
      #totStations <- rbind(totStations, dataMonth)
      totStations <- rbind(totStations, data)
    }
    
    ###add 1 hours in advance
    prev1h<-rep(NA,nrow(totStations))
    for (i in 2: nrow(totStations)) prev1h[i]<-totStations$meanbikes[i-1]
    totStations$prev1h<-prev1h
    
    
    ###add 3 hours in advance
    prev3h<-rep(NA,nrow(totStations))
    for (i in 4: nrow(totStations)) prev3h[i]<-totStations$meanbikes[i-3]
    totStations$prev3h<-prev3h
    

    ###add 24 hours in advance
    prev24h<-rep(NA,nrow(totStations))
    for (i in 25: nrow(totStations)) prev24h[i]<-totStations$meanbikes[i-24]
    totStations$prev24h<-prev24h  
    
    
    for (i in 0:23){
      totStationsHours[[i+1]] <- filter(totStations, hour == i)
      print(paste("hour = ",i))
    }
    
    save(totStations,totStationsHours, file="predStations.RData")
    
  }   
  
  
  #Summary meanBikes per stations-wday-hour
  totStations$station <- as.factor(totStations$station)
  totStations$wday <- as.factor(totStations$wday)
  totStations$hour <- as.factor(totStations$hour)
  
  totStations.station.wkday.hour <- group_by(totStations, station, wday, hour)
  summaryBikes<-summarise(totStations.station.wkday.hour, mean.day = mean(meanbikes))
  write.csv(summaryBikes, file="summaryBikes.csv")
  


modelStationHour<- function(){
    
    load("predStations.RData")#totStationsHours
    Fits <- vector(mode = "list", length = 24)
    for(hour in 1:24){
      Fits[[hour]]<-lm(meanbikes ~ station + day + month + year + hour + wday, data = totStationsHours[[hour]]) #add population

    }
    save(Fits, file="modelsBikeHours.RData")
    
    
  }
  
  modelStation <- function(){
    
    Fits <- vector(mode = "list", length = 276)
    for (bikeStat in 1:276){
      Fits[[bikeStat]]<-lm(meanbikes ~ station + day + month + year + hour + wday, data = filter(totStations, station == bikeStat)) 
      
    }
    save(Fits, file="modelsBikeStation.RData")
  }
  
  
  
  
   # bike availability
  generateTestHours <- function(){
    
    load("predStations.RData")
    test <- list()
    for(i in 1:24){
      timeDate <- ymd_hms(Sys.time(),tz="CET") + hms(paste(i,":0:0"))
      temp <- data.frame(station = 1:276,
                         day = day(timeDate), 
                         month = month(timeDate), 
                         year = year(timeDate), 
                         hour=hour(timeDate), 
                         wday = wday(timeDate),
                         meanbikes=NA)#add population
      
      test[[hour(timeDate)+1]]<- temp
    }
    
    results <- data.frame()
      
    load("modelsBikeHours.RData")
    for (hour in 1:24){
        tempResults <- test[[hour]]  
        tempResults$meanbikes<- predict(Fits[[hour]], tempResults)
        results<-rbind(results, tempResults)
    }
      results$pred <- round(results$meanbikes)
      
      save(results, file="testStation.RData")      
      
  }
  
  
generateTestStations <- function(){
    
    load("predStations.RData")
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
    
    load("modelsBikeStation.RData")
    for (sta in 1:276){
      tempResults <- filter(test, station == sta) 
      tempResults$meanbikes<- predict(Fits[[sta]], tempResults)
      results<-rbind(results, tempResults)
    }
    results$pred <- round(results$meanbikes)
    
    save(results, file="testStation.RData")  
    
    
    
  }
  
  uploadRes <- function(){
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
  }
  
  
create_DB <- function(){
    
    library(RMySQL)
    
    #mydb = dbConnect(MySQL(), user='root', password='', host='localhost')
    mydb = dbConnect(MySQL(), user=MyUser, password=MyPass, host=MyHost)
    
    # creating a database using RMySQL in R
    
    dbSendQuery(mydb, "CREATE DATABASE bikesVLC;")
    
    dbSendQuery(mydb, "USE bikesVLC")
    
    #reconnecting to database we just created using following command in R :
    
    #mydb = dbConnect(MySQL(), user='root', password='', host='localhost', dbname='trafficVLC')
    mydb = dbConnect(MySQL(), user=MyUser, password=MyPass, host=MyHost, dbname=MyDataBase)
    
    dbSendQuery(mydb, "drop table if exists predBike, predGrid")
    
    #DATETIME values in 'YYYY-MM-DD HH:MM:SS' format
    dbSendQuery(mydb, "CREATE TABLE predBike (Staion INT, FechaHora DATETIME, Bikes INT);")
    dbSendQuery(mydb, "CREATE TABLE predGrid (Grid INT, FechaHora DATETIME, Bikes INT);")
    
    #dbListTables(mydb)
    #dbSendQuery(mydb, paste("INSERT INTO hist (Punto, FechaHOra, Intensidad) VALUES('100','",Sys.time(),"','2222');")
  }
    
  
  
















dataPopulation <-function(){
  
  popStations <- tbl_df(read.csv("datos_poblacion_estaciones.csv"))
  stationGrid <- tbl_df(read.csv("EstacionesCuadrantes.csv"))
  TypeGrid <- tbl_df(read.csv("tipos_cuadrante.csv", stringsAsFactors = FALSE))
  
  
  i <-1
  for (c in popStations$cuadrante ){
    
    popStations$hood[i] <- filter(TypeGrid, ID == c)[[1,2]]
    i <- i+1
  }  
  popStations$hood <- as.factor(popStations$hood)
  popStations
  
  poptotstations <- tbl_df(merge(totStations,popStations, by.x=c("station"), by.y ="id_estacion"))
  
  save(poptotstations, file = "popTotStations.RData")
  
  
  
  
  
  load("popTotStations.RData")#totStationsHours
  Fits <- vector(mode = "list", length = 24)
  for(h in 1:24){
    Fits[[h]]<-lm(meanbikes ~ pob_0_14 + pob_15_65 + pob_66_mas + hood,  data = filter(poptotstations, hour==h-1)) #add population
    print(paste("Model_StaPop ", h, " trained."))
    
  }
  save(Fits, file="modelsGridHours.RData")
  
  
  
  
  
  
  load("modelsGridHours.RData")
  test <- list()
  for(i in 1:24){
    timeDate <- dmy_hms("1-1-2016 0:0:0",tz="CET") + hms(paste(i,":0:0"))
    
    temp <- data.frame(grid = 1:368,
                       hour=hour(timeDate), 
                       pob_0_14 = 0,
                       pob_15_65= 0, 
                       pob_66_mas = 0,
                       hood = "Estación",
                       meanbikes=NA)#add population
    
    test[[hour(timeDate)+1]]<- temp
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
  
  
  
  mydb = dbConnect(MySQL(), user=MyUser, password=MyPass, host=MyHost, dbname=MyDataBase)
  dbWriteTable(mydb, value = newDS, name = "predGrid",  overwrite=TRUE ) 
  #tabla<-fetch(dbSendQuery(mydb, "select * from pred"),n=4900)
  #fetch(dbSendQuery(mydb, "select COUNT(*) from pred"),n=1)
  
  
  
  
}
  
  





  