# Load Required Libraries
library(tidyverse)    # Data manipulation and visualization
library(lubridate)    # Date handling
library(skimr)        # Summary statistics
library(scales)       # Formatting
library(corrplot)     # Correlation plots
library(gridExtra)    # Multiple plots
library(knitr)        # Tables

# Set working directory (adjust as needed)
setwd("C:/Users/Fernando/Documents/Data management and visualization/Final Project")

# ============================================================================
# 1. DATA LOADING
# ============================================================================

# Load datasets
rides <- read_csv("Rides_Data.csv")
drivers <- read_csv("Drivers_Data.csv")

# ============================================================================
# 2. INITIAL DATA INSPECTION
# ============================================================================

cat("=== RIDES DATA STRUCTURE ===\n")
glimpse(rides)

cat("\n=== DRIVERS DATA STRUCTURE ===\n")
glimpse(drivers)

# Check for duplicate Ride_IDs and Driver_IDs
cat("Duplicate Ride_IDs:", sum(duplicated(rides$Ride_ID)), "\n")
cat("Duplicate Driver_IDs:", sum(duplicated(drivers$Driver_ID)), "\n")

# ============================================================================
# 3. DATA QUALITY ASSESSMENT
# ============================================================================

# Check missing values in Rides
rides_missing <- rides %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Missing_Count") %>%
  mutate(Percentage = round(Missing_Count / nrow(rides) * 100, 2))

cat("\nMissing Values in Rides Data:\n")
print(rides_missing)

# Check missing values in Drivers
drivers_missing <- drivers %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Missing_Count") %>%
  mutate(Percentage = round(Missing_Count / nrow(drivers) * 100, 2))

cat("\nMissing Values in Drivers Data:\n")
print(drivers_missing)

# ============================================================================
# 4. DATA CLEANING AND TRANSFORMATION
# ============================================================================

#Changing the different promo codes to integers
unique(rides$Promo_Code)


rides <- rides %>%
  mutate(
    discount_value = case_when(
      is.na(Promo_Code) ~ 0,
      Promo_Code == "WELCOME5" ~ 5,
      Promo_Code == "DISCOUNT10" ~ 10,
      Promo_Code == "SAVE20" ~ 20,
      TRUE ~ 0
    )
  )

view(rides)


# Clean Rides Data
rides_clean <- rides %>%
  mutate(
    # Convert Date to proper date format
    Date = as.Date(Date, format = "%m/%d/%Y"),
    # Ensure Rating is within 1-5 range
    Rating = ifelse(Rating < 1 | Rating > 5, NA, Rating),
    # Handle negative values
    Distance_km = ifelse(Distance_km < 0, NA, Distance_km),
    Duration_min = ifelse(Duration_min < 0, NA, Duration_min),
    Fare = ifelse(Fare < 0, NA, Fare),
    # Create additional features
    Day_of_Week = wday(Date, label = TRUE),
    Week_Number = week(Date),
    Speed_kmh = ifelse(Duration_min > 0, (Distance_km / Duration_min) * 60, NA),
    Fare_per_km = ifelse(Distance_km > 0, Fare / Distance_km, NA),
    Fare_per_min = ifelse(Duration_min > 0, Fare / Duration_min, NA),
    Has_Promo = ifelse(Promo_Code == "NO_PROMO", "No", "Yes")
  )
view(rides_clean)


# Clean Drivers Data
drivers_clean <- drivers %>%
  mutate(
    # Ensure ratings are within valid range
    Average_Rating = ifelse(Average_Rating < 1 | Average_Rating > 5, NA, Average_Rating),
    # Handle negative experience years
    Experience_Years = ifelse(Experience_Years < 0, NA, Experience_Years),
    # Age validation (reasonable range 18-80)
    Age = ifelse(Age < 18 | Age > 80, NA, Age),
    # Create age groups
    Age_Group = cut(Age, 
                    breaks = c(0, 25, 35, 45, 55, 100), 
                    labels = c("18-25", "26-35", "36-45", "46-55", "55+"))
  )

view(drivers_clean)

#Checking data after cleaning it.

cat("\nClean Data Summary:\n")
cat("Rides with invalid ratings:", sum(is.na(rides_clean$Rating) & !is.na(rides$Rating)), "\n")
cat("Rides with negative distance:", sum(is.na(rides_clean$Distance_km) & !is.na(rides$Distance_km)), "\n")
cat("Rides with negative duration:", sum(is.na(rides_clean$Duration_min) & !is.na(rides$Duration_min)), "\n")

# ============================================================================
# 5. SUMMARY STATISTICS
# ============================================================================

# SUMMARY STATISTICS - RIDES DATA

rides_summary <- rides_clean %>%
  select(Distance_km, Duration_min, Fare, Rating, Speed_kmh, Fare_per_km) %>%
  summary()

print(rides_summary)

# SUMMARY STATISTICS - DRIVERS DATA

drivers_summary <- drivers_clean %>%
  select(Age, Experience_Years, Average_Rating) %>%
  summary()

print(drivers_summary)

# ============================================================================
# 6. JOIN DATASETS FOR INTEGRATED ANALYSIS
# ============================================================================
rides_with_drivers <- rides_clean %>%
  left_join(drivers_clean, by = "Driver_ID")
#trating Nas
rides_with_drivers <- rides_with_drivers%>%
  mutate(
    Has_Promo = replace_na(Has_Promo, "No"),
    Promo_Code = replace_na(Promo_Code, "No")
  )


# JOINED DATASET 
view(rides_with_drivers)
# ============================================================================
# 7. EXPLORATORY DATA ANALYSIS 
# ============================================================================

# City Performance Analysis

city_performance <- rides_clean %>%
  group_by(City) %>%
  summarise(
    Total_Rides = n(),
    Avg_Fare = mean(Fare, na.rm = TRUE),
    Total_Revenue = sum(Fare, na.rm = TRUE),
    Avg_Distance = mean(Distance_km, na.rm = TRUE),
    Avg_Duration = mean(Duration_min, na.rm = TRUE),
    Avg_Rating = mean(Rating, na.rm = TRUE),
    Promo_Usage_Rate = mean(ifelse(is.na(Has_Promo) | Has_Promo == "No", 0, 1)) * 100
  ) %>%
  arrange(desc(Total_Revenue))

print(city_performance)



#Promotion impact

promo_impact <- rides_with_drivers %>%
  group_by(Has_Promo) %>%
  summarise(
    Total_Rides = n(),
    Avg_Fare = mean(Fare, na.rm = TRUE),
    Avg_Distance = mean(Distance_km, na.rm = TRUE),
    Avg_Rating = mean(Rating, na.rm = TRUE),
    Total_Revenue = sum(Fare, na.rm = TRUE)
  )

print(promo_impact)

# Top promo codes by usage
top_promos <- rides_with_drivers %>%
  filter(Promo_Code != "NO_PROMO") %>%
  group_by(Promo_Code) %>%
  summarise(
    Usage_Count = n(),
    Avg_Fare = mean(Fare, na.rm = TRUE),
    Avg_Rating = mean(Rating, na.rm = TRUE)
  ) %>%
  arrange(desc(Usage_Count)) %>%
  head(10)

print(top_promos)

## INSIGHT 3: Temporal Patterns
cat("\n--- INSIGHT 3: Temporal Patterns ---\n")

# Day of week analysis
dow_analysis <- rides_with_drivers %>%
  group_by(Day_of_Week) %>%
  summarise(
    Total_Rides = n(),
    Avg_Fare = mean(Fare, na.rm = TRUE),
    Total_Revenue = sum(Fare, na.rm = TRUE),
    Avg_Rating = mean(Rating, na.rm = TRUE)
  )

print(dow_analysis)

# Daily trends
daily_trends <- rides_with_drivers %>%
  group_by(Date) %>%
  summarise(
    Total_Rides = n(),
    Total_Revenue = sum(Fare, na.rm = TRUE),
    Avg_Rating = mean(Rating, na.rm = TRUE)
  ) %>%
  arrange(Date)

cat("\nDaily ride volume range:", min(daily_trends$Total_Rides), "-", max(daily_trends$Total_Rides), "\n")

## INSIGHT 4: Driver Performance Analysis

driver_performance <- rides_with_drivers %>%
  group_by(Driver_ID, Name, Experience_Years, Average_Rating, Active_Status) %>%
  summarise(
    Total_Rides = n(),
    Total_Revenue = sum(Fare, na.rm = TRUE),
    Avg_Ride_Rating = mean(Rating, na.rm = TRUE),
    Avg_Distance = mean(Distance_km, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(Total_Rides))

cat("\nTop 10 Drivers by Total Rides:\n")
print(head(driver_performance, 10))

# Driver status comparison
driver_status_comparison <- rides_with_drivers %>%
  group_by(Active_Status) %>%
  summarise(
    Count = n(),
    Avg_Age = mean(Age, na.rm = TRUE),
    Avg_Experience = mean(Experience_Years, na.rm = TRUE),
    Avg_Rating = mean(Average_Rating, na.rm = TRUE)
  )

cat("\nDriver Status Comparison:\n")
print(driver_status_comparison)

## INSIGHT 5: Experience vs Performance

experience_groups <- rides_with_drivers %>%
  mutate(
    Experience_Group = cut(Experience_Years,
                           breaks = c(-Inf, 2, 5, 10, Inf),
                           labels = c("0-2 years", "3-5 years", "6-10 years", "10+ years"))
  ) %>%
  group_by(Experience_Group) %>%
  summarise(
    Driver_Count = n_distinct(Driver_ID),
    Total_Rides = n(),
    Avg_Rating = mean(Rating, na.rm = TRUE),
    Avg_Fare = mean(Fare, na.rm = TRUE)
  )

print(experience_groups)

## INSIGHT 6: Rating Distribution and Factors
cat("\n--- INSIGHT 6: Rating Analysis ---\n")

rating_distribution <- rides_with_drivers %>%
  count(Rating) %>%
  mutate(Percentage = n / sum(n) * 100) %>%
  arrange(desc(Rating))

print(rating_distribution)

# Factors affecting ratings
rating_factors <- rides_with_drivers %>%
  group_by(Rating_Category = cut(Rating, breaks = c(0, 3, 4, 5), labels = c("Low (1-3)", "Medium (3-4)", "High (4-5)"))) %>%
  summarise(
    Count = n(),
    Avg_Distance = mean(Distance_km, na.rm = TRUE),
    Avg_Duration = mean(Duration_min, na.rm = TRUE),
    Avg_Fare = mean(Fare, na.rm = TRUE),
    Promo_Usage = mean(Has_Promo == "Yes") * 100
  )

print(rating_factors)

## INSIGHT 7: Fare Analysis

fare_stats <- rides_with_drivers %>%
  summarise(
    Min_Fare = min(Fare, na.rm = TRUE),
    Q1_Fare = quantile(Fare, 0.25, na.rm = TRUE),
    Median_Fare = median(Fare, na.rm = TRUE),
    Mean_Fare = mean(Fare, na.rm = TRUE),
    Q3_Fare = quantile(Fare, 0.75, na.rm = TRUE),
    Max_Fare = max(Fare, na.rm = TRUE),
    Avg_Fare_per_km = mean(Fare_per_km, na.rm = TRUE),
    Avg_Fare_per_min = mean(Fare_per_min, na.rm = TRUE)
  )

print(fare_stats)

# ============================================================================
# 8. BUSINESS INSIGHTS SUMMARY
# ============================================================================

cat("\n1. REVENUE INSIGHTS:\n")
cat("   - Total Revenue:", dollar(sum(rides_clean$Fare, na.rm = TRUE)), "\n")
cat("   - Average Fare:", dollar(mean(rides_clean$Fare, na.rm = TRUE)), "\n")
cat("   - Total Rides:", nrow(rides_clean), "\n")

cat("\n2. CUSTOMER SATISFACTION:\n")
cat("   - Average Rating:", round(mean(rides_clean$Rating, na.rm = TRUE), 2), "/ 5\n")
cat("   - % of 5-star ratings:", round(mean(rides_clean$Rating == 5, na.rm = TRUE) * 100, 1), "%\n")

cat("\n3. PROMOTIONAL EFFECTIVENESS:\n")
cat("   - Promo Usage Rate:", round(mean(rides_clean$Has_Promo == "Yes") * 100, 1), "%\n")
cat("   - Unique Promo Codes:", length(unique(rides_clean$Promo_Code[rides_clean$Promo_Code != "NO_PROMO"])), "\n")

cat("\n4. OPERATIONAL METRICS:\n")
cat("   - Average Distance:", round(mean(rides_clean$Distance_km, na.rm = TRUE), 2), "km\n")
cat("   - Average Duration:", round(mean(rides_clean$Duration_min, na.rm = TRUE), 2), "minutes\n")
cat("   - Average Speed:", round(mean(rides_clean$Speed_kmh, na.rm = TRUE), 2), "km/h\n")

cat("\n5. DRIVER INSIGHTS:\n")
cat("   - Total Drivers:", nrow(drivers_clean), "\n")
cat("   - Active Drivers:", sum(drivers_clean$Active_Status == "Active", na.rm = TRUE), "\n")
cat("   - Average Driver Experience:", round(mean(drivers_clean$Experience_Years, na.rm = TRUE), 2), "years\n")

# ============================================================================
# 9. EXPORT CLEANED DATA FOR TABLEAU
# ============================================================================

cat("\n=== EXPORTING CLEANED DATA ===\n")

# Export cleaned datasets
write_csv(rides_clean, "Rides_Data_Cleaned.csv")
write_csv(drivers_clean, "Drivers_Data_Cleaned.csv")
write_csv(rides_with_drivers, "Rides_with_Drivers_Complete.csv")

# Export summary tables
write_csv(city_performance, "City_Performance_Summary.csv")
write_csv(driver_performance, "Driver_Performance_Summary.csv")
write_csv(daily_trends, "Daily_Trends.csv")

cat("Cleaned datasets exported successfully!\n")

# ============================================================================
# 12. VISUALIZATION
# ============================================================================

# Create output directory for plots
dir.create("plots", showWarnings = FALSE)

# Plot 1: City Revenue Distribution
p1 <- ggplot(city_performance, aes(x = reorder(City, Total_Revenue), y = Total_Revenue)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  coord_flip() +
  labs(title = "Total Revenue by City", x = "City", y = "Total Revenue ($)") +
  theme_minimal() +
  scale_y_continuous(labels = dollar)
show(p1)

ggsave("plots/01_city_revenue.png", p1, width = 10, height = 6)

# Plot 2: Promotional Impact
p2 <- ggplot(promo_impact, aes(x = Has_Promo, y = Avg_Fare, fill = Has_Promo)) +
  geom_bar(stat = "identity") +
  labs(title = "Average Fare: Promo vs No Promo", x = "Promotional Code Used", y = "Average Fare ($)") +
  theme_minimal() +
  scale_y_continuous(labels = dollar)
show(p2)

ggsave("plots/02_promo_impact.png", p2, width = 8, height = 6)

# Plot 3: Day of Week Patterns
p3 <- ggplot(dow_analysis, aes(x = Day_of_Week, y = Total_Rides)) +
  geom_bar(stat = "identity", fill = "coral") +
  labs(title = "Ride Volume by Day of Week", x = "Day of Week", y = "Total Rides") +
  theme_minimal()
show(p3)

ggsave("plots/03_dow_patterns.png", p3, width = 10, height = 6)

# Plot 4: Rating Distribution
p4 <- ggplot(rides_clean %>% filter(!is.na(Rating)), aes(x = Rating)) +
  geom_histogram(binwidth = 0.5, fill = "darkgreen", color = "white") +
  labs(title = "Distribution of Customer Ratings", x = "Rating", y = "Frequency") +
  theme_minimal()
show(p4)

ggsave("plots/04_rating_distribution.png", p4, width = 8, height = 6)

# Plot 5: Fare vs Distance
p5 <- ggplot(rides_clean %>% sample_n(min(1000, nrow(.))), 
             aes(x = Distance_km, y = Fare)) +
  geom_point(alpha = 0.5, color = "blue") +
  geom_smooth(method = "lm", color = "red") +
  labs(title = "Fare vs Distance Relationship", x = "Distance (km)", y = "Fare ($)") +
  theme_minimal()
show(p5)

ggsave("plots/05_fare_vs_distance.png", p5, width = 8, height = 6)

# Plot 6: Driver Experience vs Rating
p6 <- ggplot(experience_groups, aes(x = Experience_Group, y = Avg_Rating, fill = Experience_Group)) +
  geom_bar(stat = "identity") +
  labs(title = "Average Rating by Driver Experience", 
       x = "Experience Level", y = "Average Rating") +
  theme_minimal() +
  theme(legend.position = "none")
show(p6)

ggsave("plots/06_experience_vs_rating.png", p6, width = 10, height = 6)