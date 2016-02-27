# bikeXplorer #
bikeXplorer webApp for analysis and prediction of bike-sharing systems.


## Code 
V.1. Scripts in R:
  
* BikesPred.R: Linear Regression models trained with historical data (2015) for predicting the use of an specific station (number of available bikes) the following 24 hours.
* GridPred.R: Linear Regression models traindes with both population and the use of bikes in order to predict the possible use of new station in new locations.
* BestTour.R: Simulated Annealing process to find the best tour (local maxima) between stations. We aim at finding possible new bike routes between actual stations.
* DataWrangling.R: Extraction, transformation, cleaning and modeling functions to generate the data used in the previous scripts.

## Appendix 

### Simulated Annealing Process
  
Start with a random tour through the selected cities. Note that it's probably a very inefficient tour!

1. Pick a new candidate tour at random from all neighbors of the existing tour. This candidate tour might be better or worse compared to the existing tour (i.e. shorter or longer)
2. If the candidate tour is better than the existing tour, accept it as the new tour
3. If the candidate tour is worse than the existing tour, still maybe accept it, according to some probability. The probability of accepting an inferior tour is a function of how much longer the candidate is compared to the current tour, and the temperature of the annealing process. A higher temperature makes you more likely to accept an inferior tour
4. Go back to step 2 and repeat many times, lowering the temperature a bit at each iteration, until you get to a low temperature and arrive at your (hopefully global, possibly local) minimum. If you're not sufficiently satisfied with the result, try the process again, perhaps with a different temperature cooling schedule
5. The key to the simulated annealing 
    
