# Steps: (Using MONTHLY DATA for models)
# !---------------------------------------------------!
# ---------- 0. Import Dataset, filter etc -----------
# !---------------------------------------------------!
# Load necessary packages
library(readr)
library(dplyr)
library(ggplot2)
library(forecast)
library(lubridate) # For date manipulation
library(tseries) # For the adf.test function
library(uroot)
library(lmtest)


# Load data from CSV file
data <- read_csv("C:/Users/wbrya/OneDrive/Documents/australia_energy_complete_dataset.csv")

# Check for missing values in the entire data frame
print("Total missing values in the data frame:")
print(sum(is.na(data)))

# Check for missing values by column
print("Missing values by column:")
print(colSums(is.na(data)))
# Missing values in columns rainfall and solar_exposure, we will not be using these anyways.

# Drop columns containing "rrp"
noRrp <- data %>%
  select(-contains("rrp"))

# Select date and demand columns
data <- data %>%
  select(matches("date|demand"))

# Ensure date column is in date format
data$date <- as.Date(data$date)

# Create a data frame with dates and demand for the daily time series
daily_df <- data.frame(date = data$date, demand = data$demand)

# Create monthly aggregated dataset
monthly_df <- data %>%
  mutate(month = floor_date(date, "month")) %>%
  group_by(month) %>%
  summarise(demand = sum(demand)) # SUM or MEAN

# Exclude the last month because incomplete
monthly_df <- monthly_df %>% 
  filter(month < max(month) - months(1))

# Print the head of the monthly and daily dataset
print(head(monthly_df))
print(tail(monthly_df))







# !---------------------------------------------------!
# ---------- 1. Time Series plot ---------------------
# !---------------------------------------------------!
# Plot the monthly aggregated time series
ggplot(monthly_df, aes(x = month, y = demand)) +
  geom_line() +
  ggtitle("Monthly Demand Over Time") +
  labs(x = "Date", y = "Energy Demand")







# !---------------------------------------------------!
# ---------- 2. Convert to time series object --------
# !---------------------------------------------------!
ts_data <- ts(monthly_df$demand, start = c(year(min(monthly_df$month)), month(min(monthly_df$month))), frequency = 12)
frequency <- 12

# Decompose the time series
components_dfts <- decompose(ts_data)

# Plot the decomposed components
plot(components_dfts)

# Seasonal Plots:
ggseasonplot(ts_data, year.labels = TRUE, year.labels.left = TRUE) +
  ylab("Energy Demand") +
  ggtitle("Seasonal plot: Australia Energy Demand by Month")

# Plot the seasonal subseries plot using ggsubseriesplot
ggsubseriesplot(ts_data) +
  ylab("Energy Demand") +
  ggtitle("Seasonal subseries plot: Australia Energy Demand by Month")







# !---------------------------------------------------!
# ---------- 3. Data Split ---------------------------
# !---------------------------------------------------!
# Set training data from 2015 to 2019
train_data <- window(ts_data,start=2015,end=c(2019))
test_data <- window(ts_data, start = 2019)
test_length <- length(test_data)
print(test_length) 
nIntoFutures <- test_length







# !---------------------------------------------------!
# ---------- 4. Stationary test: ADF test ------------
# !---------------------------------------------------!
adfTest <- function(dataSet){
  # ADF test
  adf_result <- adf.test(dataSet, alternative = "stationary")
  # Extract the p-value
  p_value <- adf_result$p.value
  # Choose significance level
  alpha <- 0.05
  
  # Compare the p-value
  if (p_value < alpha) {
    print("Reject the null hypothesis: The time series is likely stationary.")
  } else {
    print("Fail to reject the null hypothesis: The time series may have a unit root and is non-stationary.")
  } # for monthly, not stationary
  print(adf_result)
}
adfTest(train_data)







# !---------------------------------------------------!
# ---------- 5. Correlogram and Pacf -----------------
# !---------------------------------------------------!
# Autocorrelation: measures the linear relationship between a time series and its lagged versions.
train_data %>% ggtsdisplay(main="")

# Seasonal differencing with a lag of 12
seasonal_diff <- diff(train_data, lag=12)
seasonal_diff %>% ggtsdisplay(main="")
adfTest(seasonal_diff) # Test non-seasonal

# Non-seasonal differencing with a lag of 1
seasonal_non_diff <- diff(seasonal_diff, lag=1)
seasonal_non_diff %>% ggtsdisplay(main="")
adfTest(seasonal_non_diff) # Test non-seasonal







# !---------------------------------------------------!
# ---------- 6. Manual Arima Fitting -----------------
# !---------------------------------------------------!
evaluate_arima_model <- function(manArima_model, manArima_forecast, test_data) {
  plot(manualArima_forecast)
  lines(test_data, col="red")
  accuracy(manualArima_forecast, test_data)
  
  # Calculate AIC and BIC
  n <- length(manArima_model$residuals)
  k <- length(manArima_model$coef)
  
  aicc <- manArima_model$aic + 2 * k * (n / (n - k - 1) - 1)
  print("AICc value:")
  print(aicc)
  
  print("Residuals: ")
  checkresiduals(manArima_model, plot = TRUE)
  summary(manArima_model)
}
# Based on ACF and PACF ARIMA(p,1,q)(0,1,0)[12]
# Non-seasonal: Look Below 12 lags: p,d,q
# Seasonal: Multiples of 12 lag. : P,D,Q
manArima_model <- arima(train_data, order=c(1, 1, 1), seasonal=list(order=c(0, 1, 0), period=12))
manualArima_forecast <- forecast(manArima_model, h=test_length)
evaluate_arima_model(manArima_model, manArima_forecast, test_data)
manArima_accuracy <- accuracy(manualArima_forecast, test_data)
print(manArima_accuracy)

# Based on trial and error.
# ARIMA(1,1,0)(0,1,1)[12] - AICc = 969  RMSE=3% diff
manArimaW_model <- arima(train_data, order=c(1, 1, 0), seasonal=list(order=c(0, 1, 1), period=12))
manualArimaW_forecast <- forecast(manArimaW_model, h=test_length)
evaluate_arima_model(manArimaW_model, manualArimaW_forecast, test_data)







# !---------------------------------------------------!
# ---------- 7. Other Model fit ----------------------
# !---------------------------------------------------!
# 1. Seasonal Naive
sea_naive_model <- snaive(train_data)
sea_naive_forecast <- forecast(sea_naive_model, h=test_length)

# 2. Fit ARIMA model
arima_model <- auto.arima(train_data, trace = TRUE, ic = "aicc") # based on the AICc criterion.
arima_forecast <- forecast(arima_model, h = test_length)

# 3. Fit Holt-Winters model
holt_winters_model <- HoltWinters(train_data, seasonal = "additive")
holt_winters_forecast <- forecast(holt_winters_model, h = test_length)







# !---------------------------------------------------!
# --- 8. Model Evaluation, RMSE, AICc, ACF Residual ---
# !---------------------------------------------------! 
# Print Values
sea_naive_accuracy <- accuracy(sea_naive_forecast, test_data)
print(sea_naive_accuracy)

print("ARIMA(1,1,1)(0,1,0)[12]:")
#summary(manualArima_forecast)
manArima_accuracy <- accuracy(manualArima_forecast, test_data)
print(manArima_accuracy)

print("ARIMA(1,1,0)(0,1,1)[12]:")
#summary(manualArimaW_forecast)
manArimaW_accuracy <- accuracy(manualArimaW_forecast, test_data)
print(manArimaW_accuracy) 

arima_accuracy <- accuracy(arima_forecast, test_data)
print(arima_accuracy)

holtsWinter_accuracy <- accuracy(holt_winters_forecast, test_data)
print(holtsWinter_accuracy)

# Seasonal Naive Plot
autoplot(sea_naive_forecast) +
  autolayer(test_data, series = "Actual Data", color = "red") +
  ggtitle("Seasonal Naive Forecast vs Actual Data") +
  xlab("Time") +
  ylab("Demand") 

# Manual ARIMA Plot
autoplot(manualArima_forecast) +
  autolayer(test_data, series = "Actual Data", color = "red") +
  ggtitle("ARIMA(1,1,1)(0,1,0)[12] Forecast vs Actual Data") +
  xlab("Time") +
  ylab("Demand") 

# Manual ARIMA W Plot
autoplot(manualArimaW_forecast) +
  autolayer(test_data, series = "Actual Data", color = "red") +
  ggtitle("ARIMA(1,1,0)(0,1,1)[12] Forecast vs Actual Data") +
  xlab("Time") +
  ylab("Demand") 

# ARIMA Plot
autoplot(arima_forecast) +
  autolayer(test_data, series = "Actual Data", color = "red") +
  ggtitle("ARIMA Forecast vs Actual Data") +
  xlab("Time") +
  ylab("Demand") 

# Holt's Winter Plot
autoplot(holt_winters_forecast) +
  autolayer(test_data, series = "Actual Data", color = "red") +
  ggtitle("Holt's Winter Forecast vs Actual Data") +
  xlab("Time") +
  ylab("Demand") 







# !---------------------------------------------------!
# ---------- 9. Best model summary-- -----------------
# !---------------------------------------------------! 
# !!! 1. Best Model: ARIMA(1,1,0)(0,1,1)[12]
summary(manArimaW_model)
checkresiduals(manArimaW_model, plot = TRUE)
print(manArimaW_accuracy) 
# Plot
autoplot(manualArimaW_forecast) +
  autolayer(test_data, series = "Actual Data", color = "red") +
  ggtitle("ARIMA(1,1,0)(0,1,1)[12] Forecast vs Actual Data") +
  xlab("Time") +
  ylab("Demand") +
  guides(colour = guide_legend(title = "Legend"))
