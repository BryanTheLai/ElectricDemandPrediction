## Project Summary
https://docs.google.com/document/d/1Z8qZaa2Mf5WbpNSnLsRMZIhjyCcLEjdxJcbNuTcCA1I/edit?tab=t.0
### Overview
This project involves forecasting energy demand in Australia using monthly data. It covers data preparation, time series analysis, model fitting, and evaluation.

### Data Preparation
- **Loading and Cleaning**: Loaded data from a CSV file, checked for missing values, and dropped irrelevant columns.
- **Aggregation**: Aggregated daily data to monthly sums.
- **Exclusion**: Excluded the last incomplete month.
- **Formatting**: Ensured the date column was in the correct format and created a time series object.

### Time Series Analysis
- **Plotting**: Plotted the monthly aggregated time series to visualize trends.
- **Decomposition**: Decomposed the time series into trend, seasonal, and residual components.
- **Seasonal Plots**: Created seasonal plots to visualize seasonal patterns.

### Data Splitting
- **Training and Testing**: Split the data into training (2015-2019) and testing sets.

### Stationarity Test
- **ADF Test**: Performed Augmented Dickey-Fuller (ADF) tests to check for stationarity. Applied seasonal and non-seasonal differencing as necessary.

### Model Fitting
#### Manual ARIMA
- Manually selected ARIMA model parameters (p, d, q) based on ACF and PACF plots. Fitted models like ARIMA(1,1,1)(0,1,0)[12] and ARIMA(1,1,0)(0,1,1)[12].

#### Other Models
- Fitted Seasonal Naive, Auto-ARIMA, and Holt-Winters models for comparison.

### Model Evaluation
- **Accuracy Metrics**: Calculated RMSE, AICc, and other accuracy metrics for each model.
- **Residual Analysis**: Checked residuals for each model to ensure they were randomly distributed.
- **Visual Comparison**: Plotted forecasts against actual data for visual comparison.

## Key Findings

### Best Model
- The best-performing model was identified as ARIMA(1,1,0)(0,1,1)[12], which had the lowest RMSE and AICc values.

## What Could Have Been Done Differently and Improvements

### Additional Steps
- **Feature Engineering**: Consider adding external factors like weather or economic indicators to improve forecast accuracy.
- **More Advanced Models**: Explore more complex models such as SARIMAX or machine learning approaches like LSTM networks.
- **Hyperparameter Tuning**: Use automated hyperparameter tuning techniques to optimize model parameters.

### Evaluation Metrics
- **Additional Metrics**: Evaluate models using additional metrics such as MAPE (Mean Absolute Percentage Error) or MASE (Mean Absolute Scaled Error).
- **Cross-Validation**: Use cross-validation techniques to ensure robustness of the results.

### Deployment Enhancements
- **Automated Forecasting**: Set up an automated system to generate forecasts regularly using the best-performing model.
- **User Interface**: Develop a user-friendly interface to display forecasts and historical data.

By clicking on this project, you can explore the detailed steps taken in each phase of this energy demand forecasting system. This project demonstrates a comprehensive approach to time series analysis and forecasting using various statistical models.

## Manual Selection of ARIMA Parameters
- The ARIMA parameters (p, d, q) were manually selected based on the analysis of ACF and PACF plots. This involved identifying the appropriate order of autoregression (p), differencing (d), and moving average (q) components to capture both seasonal and non-seasonal patterns in the data. This manual selection allowed for a more tailored approach to modeling the specific characteristics of the energy demand time series.
