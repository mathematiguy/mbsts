
params = list(tickers = c("AAPL", "MSFT", "AMD", "INTL", "GE", "GM", "SHLD"),
              from_date = as.Date("2018-01-01"),
              ar = 2,
              p = 2,
              q = 2,
              s = c(5,20),
              corr_prior = 4,
              periods_to_predict = 30)

library(readr)
library(dplyr)
library(magrittr)
library(ggplot2)
library(rethinking)
library(bayesplot)
library(tidybayes)
library(rstan)
library(ggplot2)
library(forcats)
library(purrr)
library(tidyr)
library(abind)
library(lubridate)
library(pdfetch)

tickers <- c(params$tickers, "SPY", "^VIX")
from <- params$from_date
leave_out <- params$periods_to_predict

data <- pdfetch_YAHOO(tickers, fields="adjclose", from=from, to=Sys.Date()) %>% 
  data.frame() %>%
  mutate(period = 1:n()) %>%
  gather(key="series", value="y", -period)

data %>%
  ggplot(aes(x=period, y=y, color=series)) +
  geom_line() +
  scale_y_log10() +
  theme_minimal()

prices_gathered <- data %>%
  arrange(period, series) %>% 
  mutate(id = 1:n(), weight=1)

predictors <- matrix(0, ncol=1, nrow=max(data$period) - leave_out - 1)

stan_data <- compose_data(
                          # The data
                          prices_gathered %>% 
                            dplyr::select(-id) %>% 
                            dplyr::filter(period < max(data$period) - leave_out), 
                          N_periods = max(data$period) - leave_out - 1,
                          x = predictors,
                          N_features = ncol(predictors),
                          # Parameters controlling the model 
                          periods_to_predict = leave_out, 
                          corr_prior = params$corr_prior,
                          p = params$p, 
                          q = params$q, 
                          ar = params$ar, 
                          period_scale = (max(data$period) / (as.numeric(Sys.Date() - from) / 365)) * 8, 
                          s = array(params$s, dim=length(params$s)),
                          N_seasonality = length(params$s),
                          cyclicality_prior = 250 * 5, 
                          .n_name = n_prefix("N"))

model <- stan_model("./mbsts.stan")
write_rds(model, "mbsts.model")

samples <- sampling(model, data=stan_data, chains=4, iter=2000, cores=4,
                    #control=list(adapt_delta=0.9, max_treedepth=15), 
                    init="0"
                    ) %>% recover_types(prices_gathered)
write_rds(samples, "mbsts.samples")
