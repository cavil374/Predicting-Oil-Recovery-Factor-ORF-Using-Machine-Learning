library(knitr)
library(caret)
library(readxl)
library(dplyr)
library(ggplot2)
library(readr)
library(randomForest)
library(rpart)
library(rpart.plot)
library(kableExtra)
library(ggplot2)
library(gridExtra)
library(tibble)

url <- "https://www.data.bsee.gov/GGStudies/Files/2020%20Atlas%20Update.zip" 
download_path <- "2020_Atlas_Update.zip"
unzip_dir <- "2020_Atlas_Update"

# Download and unzip
download.file(url, download_path, mode = "wb")
unzip(download_path, exdir = unzip_dir)

# Identify files
files <- list.files(unzip_dir, recursive = TRUE)
files <- list.files(unzip_dir, recursive = TRUE)
print("Extracted Files:")
print(files)

csv_files <- grep("\\.csv$", files, value = TRUE)
excel_files <- grep("\\.xlsx?$", files, value = TRUE)


if (length(excel_files) > 0) {
  data_file <- file.path(unzip_dir, excel_files[1])
  data <- read_excel(data_file, sheet = 1)
} else if (length(csv_files) > 0) {
  data_file <- file.path(unzip_dir, csv_files[1])
  data <- read_csv(data_file)
} else {
  stop("No suitable data file found.")
}

# Remove NA values
data_cleaned <- na.omit(data)

# Select only numeric columns
numeric_cols <- sapply(data_cleaned, is.numeric)
data_numeric <- data_cleaned[, numeric_cols]

# Ensure ORF column exists
if (!"ORF" %in% colnames(data_numeric)) {
  stop("ORF column not found in dataset.")
}

# Create a filtered dataset where all specified parameters are nonzero
dataset <- data_numeric

parameters <- list(
  "THK" = "Total Net Thickness (feet)",
  "POROSITY" = "Porosity",
  "SW" = "Water Saturation",
  "PERMEABILITY" = "Permeability (mD)",
  "PI" = "Weighted Average Initial Pressure (psi)",
  "API" = "Weighted Average of Oil API Gravity (API units)",
  "GOR" = "Gas-Oil Ratio (Mcf/bbl)",
  "ORF" = "Oil Recovery Factor"
)
# Loop through all parameters and filter out rows where the parameter is zero
for (param in names(parameters)) {
  if (param %in% names(dataset)) {
    dataset <- dataset[dataset[[param]] != 0, , drop = FALSE]
  }
}
# Apply additional filter for GOR to be within (0,10)
if ("GOR" %in% names(dataset)) {
  dataset <- dataset[dataset$GOR > 0 & dataset$GOR < 10,]
}
# Apply additional filter for API to be greater than 5
if ("API" %in% names(dataset)) {
  dataset <- dataset[dataset$API > 5,]
}
nrow(dataset)

selected_predictors <- c("THK", "POROSITY", "SW", "PERMEABILITY", "PI", "API", "GOR")
data_filtered <- dataset[, c(selected_predictors, "ORF")]

set.seed(123)
trainIndex <- createDataPartition(data_filtered$ORF, p = 0.8, list = FALSE)
trainData <- data_filtered[trainIndex, ]
testData <- data_filtered[-trainIndex, ]

rf_trainData <- trainData
rf_testData <- testData

# Step 2: Define 10-Fold Cross-Validation
cv_control <- trainControl(method = "cv", number = 10)

# Step 3: Train Random Forest using 10-fold CV
rf_model <- train(
  ORF ~ ., 
  data = trainData, 
  method = "rf", 
  trControl = cv_control,
  tuneGrid = expand.grid(mtry = seq(2, floor(length(selected_predictors) / 3), by = 2)),
  ntree = 100,
  importance = TRUE,
  metric = "RMSE",
  tuneLength = 5,
  nodesize = 5,
  maxnodes = 30
)


# Linear Regression Model
lm_model <- train(ORF ~ ., data = trainData, method = "lm", trControl = trainControl(method = "cv", number = 5))

# Decision Tree Model
dt_model <- rpart(ORF ~ ., data = trainData, method = "anova", control = rpart.control(cp = 0.01))

# LOESS Model (best predictor selection) - Restrict to selected predictors
correlations <- sapply(selected_predictors, function(col) cor(trainData$ORF, trainData[[col]], use = "complete.obs"))
best_predictor <- names(which.max(abs(correlations)))
loess_model <- loess(as.formula(paste("ORF ~", best_predictor)), data = trainData, span = 0.8)

# Predictions for Train and Test Sets
rf_train_pred <- predict(rf_model, trainData)
rf_test_pred <- predict(rf_model, testData)
lm_train_pred <- predict(lm_model, trainData)
lm_test_pred <- predict(lm_model, testData)
dt_train_pred <- predict(dt_model, trainData)
dt_test_pred <- predict(dt_model, testData)
loess_train_pred <- predict(loess_model, trainData)
loess_test_pred <- predict(loess_model, testData)

# Calculate RMSE for Training and Testing Sets
rf_train_rmse <- RMSE(rf_train_pred, trainData$ORF)
rf_test_rmse <- RMSE(rf_test_pred, testData$ORF)
lm_train_rmse <- RMSE(lm_train_pred, trainData$ORF)
lm_test_rmse <- RMSE(lm_test_pred, testData$ORF)
dt_train_rmse <- RMSE(dt_train_pred, trainData$ORF)
dt_test_rmse <- RMSE(dt_test_pred, testData$ORF)
loess_train_rmse <- RMSE(loess_train_pred, trainData$ORF)
loess_test_rmse <- RMSE(loess_test_pred, testData$ORF)

rf_cv_results <- data.frame(
  Metric = c("RMSE", "R-squared", "MAE"),
  Value = c(
    rf_model$results$RMSE[1], 
    rf_model$results$Rsquared[1], 
    rf_model$results$MAE[1]
  )
)
knitr::kable(rf_cv_results, caption = "Random Forest 10-Fold Cross-Validation Results") %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"))

# Extract coefficients
coef_df <- as.data.frame(coef(summary(lm_model)))
coef_df <- coef_df %>%
  rownames_to_column(var = "Feature")  # Ensure Feature column does not duplicate

# Rename columns for clarity
colnames(coef_df) <- c("Feature", "Estimate", "Std. Error", "T-value", "P-Value")

# Print table in a readable format
knitr::kable(coef_df, format = "html", digits = 4) %>%
  kable_styling(full_width = FALSE, bootstrap_options = c("striped", "hover", "condensed"))

rmse_results <- data.frame(
  Model = c("Random Forest", "Linear Regression", "Decision Tree", "LOESS"),
  Train_RMSE = c(rf_train_rmse, lm_train_rmse, dt_train_rmse, loess_train_rmse),
  Test_RMSE = c(rf_test_rmse, lm_test_rmse, dt_test_rmse, loess_test_rmse)
  
)
knitr::kable(rmse_results, caption = "RMSE Comparison of Different Models")