library(knitr)
opts_chunk$set(message = FALSE, warning = FALSE, cache = TRUE, cache.lazy = FALSE)
options(width = 100, dplyr.width = 100)
library(ggplot2)
theme_set(theme_light())


library(quantmod)
library(forecast)
library(TTR)
library(tseries)

startDate = as.Date ("2010-06-29")
endDate = as.Date("2018-06-15")


# Get the Telsa Stock information from Yahoo

getSymbols("TSLA",src="yahoo",from = startDate, to = endDate)
plot(TSLA$TSLA.Close)

TeslaStockData <-ts(TSLA[,4], start = c(2010,6,29), end = c(2018,6,15), frequency = 365)


plot.ts(TeslaStockData)

#We need to transform the time series in order to get a transformed time series that can be described using an additive
#model. transform the time series by calculating the natural log of the original data:

logTeslaStockData <- log(TeslaStockData)

plot.ts(logTeslaStockData)

#Decompose Time Series 
#Decomposing a time series means separating it into its constituent components, which are usually a trend component
#and an irregular component, and if it is a seasonal time series, a seasonal component.
# use the “SMA()” function to smooth time series data.

logTeslaStockDataSMA8 <- SMA(logTeslaStockData, n=8)
plot.ts(logTeslaStockDataSMA8)

logTeslaStockDataSMA40 <- SMA(logTeslaStockData, n=40)
plot.ts(logTeslaStockDataSMA40)


#Forecasts using Holt's Exponential Smoothing
#Smoothing is controlled by two parameters, alpha, for the estimate of the level at the current time point, and beta for 
#the estimate of the slope b of the trend component at the current time point.with simple exponential smoothing, the paramters alpha
#and beta have values between 0 and 1, and values that are close to 0 mean that little weight is placed on the most
#recent observations when making forecasts of future values.


logTeslaStockDataForecast <- HoltWinters(logTeslaStockData,beta =FALSE, gamma=FALSE)
plot(logTeslaStockDataForecast$fitted)

plot(logTeslaStockDataForecast)

logTeslaStockDataForecast$SSE

# Forecast the next one year's price
logTeslaStockDataForecast2 <- forecast(logTeslaStockDataForecast, h = 365)
plot(logTeslaStockDataForecast2)


# in other words, if there are correlations between forecast errors for
# successive predictions, it is likely that the simple exponential smoothing forecasts could be improved upon by
# another forecasting technique.

#We can calculate a correlogram of the forecast errors using the “acf()” function in R. To specify the maximum lag
#that we want to look at, we use the “lag.max” parameter in acf().


plot(acf(logTeslaStockDataForecast2$residuals, lag.max=40, na.action = na.pass))


Box.test(logTeslaStockDataForecast2$residuals, lag=40, type="Ljung-Box")


plot.ts(logTeslaStockDataForecast2$residuals)


#To check whether the forecast errors are normally distributed with mean zero, we can plot a histogram of the forecast
#errors, with an overlaid normal curve that has mean zero and the same standard deviation as the distribution
#of forecast errors. To do this, we can define an R function “plotForecastErrors()”, below:

plotForecastErrors <- function(forecasterrors)
{
  # make a histogram of the forecast errors:
  mybinsize <- IQR(forecasterrors)/4
  mysd <- sd(forecasterrors)
  mymin <- min(forecasterrors) - mysd*5
  mymax <- max(forecasterrors) + mysd*3
  # generate normally distributed data with mean 0 and standard deviation mysd
  mynorm <- rnorm(10000, mean=0, sd=mysd)
  mymin2 <- min(mynorm)
  mymax2 <- max(mynorm)
  if (mymin2 < mymin) { mymin <- mymin2 }
  if (mymax2 > mymax) { mymax <- mymax2 }
  # make a red histogram of the forecast errors, with the normally distributed data overlaid:
  mybins <- seq(mymin, mymax, mybinsize)
  hist(forecasterrors, col="red", freq=FALSE, breaks=mybins)
  # freq=FALSE ensures the area under the histogram = 1
  # generate normally distributed data with mean 0 and standard deviation mysd
  myhist <- hist(mynorm, plot=FALSE, breaks=mybins)
  # plot the normal curve as a blue line on top of the histogram of forecast errors:
  points(myhist$mids, myhist$density, type="l", col="blue", lwd=2)
}

logTeslaStockDataForecast2$residuals <- tsclean(logTeslaStockDataForecast2$residuals)

plotForecastErrors(logTeslaStockDataForecast2$residuals)
# it is plausible that the forecast errors are normally distributed with mean zero.The time plot of forecast errors shows 
#that the forecast errors have roughly constant variance over time. 
#The histogram of forecast errors show that it is plausible that the forecast errors are normally distributed with mean
#zero and constant variance.


# ARIMA Model
#While exponential smoothing methods do not make any assumptions about correlations between successive values
#of the time series, in some cases you can make a better predictive model by taking correlations in the data into
#account. Autoregressive Integrated Moving Average (ARIMA) models include an explicit statistical model for the
#irregular component of a time series, that allows for non-zero autocorrelations in the irregular component.

#Stationarized the Time Series
adf.test(logTeslaStockData)

logTeslaStockData_Diff1 <- diff(logTeslaStockData,differences = 1)

adf.test(logTeslaStockData_Diff1)

plot(logTeslaStockData_Diff1)

acf(logTeslaStockData_Diff1, lag.max = 40)
acf(logTeslaStockData_Diff1, lag.max = 40, plot = FALSE)

pacf(logTeslaStockData_Diff1, lag.max = 40)
pacf(logTeslaStockData_Diff1, lag.max = 40, plot = FALSE)

TeslaARIMA <- auto.arima(logTeslaStockData_Diff1)

TeslaARIMA_Forecast <-forecast(TeslaARIMA, h = 365)
plot(TeslaARIMA_Forecast)


plot(TeslaARIMA_Forecast$residuals)
plotForecastErrors(TeslaARIMA_Forecast$residuals)

# White noise problem, choose the ARIMA (0,1,0) instead of auto.arima

TeslaARIMA1 <- arima(logTeslaStockData_Diff1, order = c(0,1,0))
TeslaARIMA1_Forecast <-forecast(TeslaARIMA1, h = 365)

plot(TeslaARIMA1_Forecast)


plot(TeslaARIMA1_Forecast$residuals)
plotForecastErrors(TeslaARIMA1_Forecast$residuals)

library(sarima)
library(stats4)
# whiteNoiseTest(TeslaARIMA1_Forecast,h0= iid)



