load("bike.RData")

summary(bike)

bike <- bike %>%
  as_tibble() %>%
  rename(
    year = yr,
    month = mnth,
    working_day = workingday,
    weather = weathersit,
    temperature = temp,
    humidity = hum,
    bikes_rented = cnt,
    wind_speed = windspeed
    ) %>%
  mutate(
    season = fct_recode(season,
      "Spring" = "SPRING",
      "Summer" = "SUMMER",
      "Autumn" = "FALL",
      "Winter" = "WINTER"),
    month = fct_recode(month,
      "January" = "JAN",
      "Feburary" = "FEB",
      "March" = "MAR",
      "April" = "APR",
      "May" = "MAY",
      "June" = "JUN",
      "July" = "JUL",
      "August" = "AUG",
      "September" = "SEP",
      "October" = "OKT",
      "November" = "NOV",
      "December" = "DEZ"),
    holiday = fct_recode(holiday,
      "No" = "NO HOLIDAY",
      "Yes" = "HOLIDAY"),
    weekday = fct_recode(weekday,
      "Sunday" = "SUN",
      "Monday" = "MON",
      "Tuesday" = "TUE",
      "Wednesday" = "WED",
      "Thursday" = "THU",
      "Friday" = "FRI",
      "Saturday" = "SAT"),
    working_day = fct_recode(working_day,
      "No" = "NO WORKING DAY",
      "Yes" = "WORKING DAY"),
    weather = fct_recode(weather,
      "Good" = "GOOD",
      "Misty" = "MISTY",
      "Rain/Snow/Storm" = "RAIN/SNOW/STORM")
    )
