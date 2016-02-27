
#source("helpers.R")
km_per_meter = 1 / 1000

options( java.parameters = "-Xmx6g" )
.lib<- c("maps", "geosphere", "ggmap","mapdata")

.inst <- .lib %in% installed.packages()
if (length(.lib[!.inst])>0) install.packages(.lib[!.inst])
lapply(.lib, require, character.only=TRUE)



#all_stations <-data.frame(name=d$NUM_STATION, country.etc ="Spain", pop=d$STANDS, lat= d$LAT, long=d$LON, full.name=d$NUM_STATION)
#saveRDS(all_stations,file="all_stations.rds")


selected_cities = function(cities){ #c("44","46","54","61","180")
  cty = subset(all_stations, full.name %in% cities)
  if (nrow(cty) == 0 | identical(sort(cty$full.name), sort(vals$cities$full.name))) return()

 return(cty)
}
  


generate_random_cities = function(n = nrow(all_stations), min_dist = 0) {

  candidates = all_stations
 
  
  cities = candidates[sample(nrow(candidates), 1),]
  candidates = subset(candidates, !(full.name %in% cities$full.name))
  i = 0
  
  while (nrow(cities) < n & i < nrow(all_stations)) {
    candidate = candidates[sample(nrow(candidates), 1),]
    candidate_dist_matrix = distm(rbind(cities, candidate)[, c("long", "lat")]) * km_per_meter
    
    if (min(candidate_dist_matrix[candidate_dist_matrix > 0]) > min_dist) {
      cities = rbind(cities, candidate)
      candidates = subset(candidates, !(candidates$full.name %in% cities$full.name))
    }
    
    i = i + 1
  }
  
  cities = cities[order(cities$full.name),]
  cities$n = 1:nrow(cities)
  
  return(cities)
}

calculate_great_circles = function(cities) {
  great_circles = list()
  if (nrow(cities) == 0) return(great_circles)
  
  pairs = combn(cities$n, 2)
  
  for(i in 1:ncol(pairs)) {
    key = paste(sort(pairs[,i]), collapse="_")
    pair = subset(cities, n %in% pairs[,i])
    pts = gcIntermediate(c(pair$long[1], pair$lat[1]), c(pair$long[2], pair$lat[2]), n=25, addStartEnd=TRUE, breakAtDateLine=TRUE, sp=TRUE)
    
    great_circles[[key]] = pts
  }
  
  return(great_circles)
}

calculate_tour_distance = function(tour, distance_matrix) {
  sum(distance_matrix[embed(c(tour, tour[1]), 2)])
}

current_temperature = function(iter, s_curve_amplitude, s_curve_center, s_curve_width) {
  s_curve_amplitude * s_curve(iter, s_curve_center, s_curve_width)
}

s_curve = function(x, center, width) {
  1 / (1 + exp((x - center) / width))
}

run_intermediate_annealing_process = function(cities, distance_matrix, tour, tour_distance, best_tour, best_distance,
                                              starting_iteration, number_of_iterations,
                                              s_curve_amplitude, s_curve_center, s_curve_width) {
  n_cities = nrow(cities)
  
  for(i in 1:number_of_iterations) {
    iter = starting_iteration + i
    temp = current_temperature(iter, s_curve_amplitude, s_curve_center, s_curve_width)
    
    candidate_tour = tour
    swap = sample(n_cities, 2)
    candidate_tour[swap[1]:swap[2]] = rev(candidate_tour[swap[1]:swap[2]])
    candidate_dist = calculate_tour_distance(candidate_tour, distance_matrix)
    
    if (temp > 0) {
      ratio = exp((tour_distance - candidate_dist) / temp)
    } else {
      ratio = as.numeric(candidate_dist < tour_distance)
    }
    
    if (runif(1) < ratio) {
      tour = candidate_tour
      tour_distance = candidate_dist
      
      if (tour_distance < best_distance) {
        best_tour = tour
        best_distance = tour_distance
        #print(tour_distance)
      }
    }
  }
  
  return(list(tour=tour, tour_distance=tour_distance, best_tour=best_tour, best_distance=best_distance))
}

ensure_between = function(num, min_allowed, max_allowed) {
  max(min(num, max_allowed), min_allowed)
}




run<- function(cities=c(), all=TRUE, iter=100000){
  
  if (!exists("all_stations")) all_stations = readRDS("all_stations.rds")
  
  km_per_meter = 1 / 1000
  
  cty = list()
  vals =list()
  input = list()
  
  input$s_curve_amplitude = 4000
  input$s_curve_center = 0
  input$s_curve_width = 3000
  input$total_iterations = iter
  input$plot_every_iterations = iter
  
  if (all){
    load("dataAllTour.RData")
    cty = c
    cty$n = 1:nrow(cty)
    vals$cities = cty
    dist_mat = dm
    dimnames(dist_mat) = list(vals$cities$name, vals$cities$name)
    vals$distance_matrix = dist_mat
    vals$great_circles = gc
    
  }else{
    cty = selected_cities(cities)
    cty$n = 1:nrow(cty)
    vals$cities = cty
    dist_mat = distm(vals$cities[,c("long", "lat")]) * km_per_meter
    dimnames(dist_mat) = list(vals$cities$name, vals$cities$name)
    vals$distance_matrix = dist_mat
    vals$great_circles = calculate_great_circles(vals$cities)
  }
    
  
  
# dm <- vals$distance_matrix
# gc <- vals$great_circles
# c <- cty
# save(dm,gc,c, file ="dataAllTour.RData")

  #Setup Annealing process
  
  vals$tour = sample(nrow(vals$cities))
  vals$tour_distance = calculate_tour_distance(vals$tour, vals$distance_matrix)
  vals$best_tour = c()
  vals$best_distance = Inf
  
  vals$s_curve_amplitude = ensure_between(input$s_curve_amplitude, 0, 1000000)
  vals$s_curve_center = ensure_between(input$s_curve_center, -1000000, 1000000)
  vals$s_curve_width = ensure_between(input$s_curve_width, 1, 1000000)
  vals$total_iterations = ensure_between(input$total_iterations, 1, 1000000)
  vals$plot_every_iterations = ensure_between(input$plot_every_iterations, 1, 1000000)
  
  vals$number_of_loops = ceiling(vals$total_iterations / vals$plot_every_iterations)
  vals$distances = rep(NA, vals$number_of_loops)
  
  vals$iter = 0
  
  
  intermediate_results = run_intermediate_annealing_process(
    cities = vals$cities,
    distance_matrix = vals$distance_matrix,
    tour = vals$tour,
    tour_distance = vals$tour_distance,
    best_tour = vals$best_tour,
    best_distance = vals$best_distance,
    starting_iteration = vals$iter,
    number_of_iterations = vals$plot_every_iterations,
    s_curve_amplitude = vals$s_curve_amplitude,
    s_curve_center = vals$s_curve_center,
    s_curve_width = vals$s_curve_width
  )
  
#   distNow = intermediate_results$best_distance
#   distPrev = Inf
#   
#   while(distNow < distPrev)
#   {
#     print("entro")
#   intermediate_results = run_intermediate_annealing_process(
#     cities = vals$cities,
#     distance_matrix = vals$distance_matrix,
#     tour = vals$tour,
#     tour_distance = vals$tour_distance,
#     best_tour = vals$best_tour,
#     best_distance = vals$best_distance,
#     starting_iteration = vals$iter,
#     number_of_iterations = vals$plot_every_iterations,
#     s_curve_amplitude = vals$s_curve_amplitude,
#     s_curve_center = vals$s_curve_center,
#     s_curve_width = vals$s_curve_width
#   )
#   distPrev = distNow
#   distNow = intermediate_results$best_distance
#   print(distNow)
#   }
#   
  
  vals$tour = intermediate_results$tour
  vals$tour_distance = intermediate_results$tour_distance
  vals$best_tour = intermediate_results$best_tour
  vals$best_distance = intermediate_results$best_distance
  
  vals$iter = vals$iter + vals$plot_every_iterations
  
  vals$distances[ceiling(vals$iter / vals$plot_every_iterations)] = intermediate_results$tour_distance
  
  vals$best_tour_cities = vals$cities[vals$best_tour,"name"]
  
  csv<- data.frame(s1 = vals$best_tour, s2 = c(vals$best_tour[-1],vals$best_tour[1]))

  for (i in 1:nrow(csv)){
    csv$distance[i] <- vals$distance_matrix[csv$s1[i],csv$s2[i]]

  }
  write.csv(csv,file="BestTour.csv")
  print(vals$best_distance)
  return(vals)
}

#in<-read.csv("inputData.csv")
#run(in$cities[1],in$all, in$iter)


