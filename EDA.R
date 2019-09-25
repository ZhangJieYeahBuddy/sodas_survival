library(survival)
library(survminer)
library(tidyverse)
library(knowboxr)

# Read data ---------------------------------------------------------------

dat <- readRDS("data/teacher.rds")

# 数据处理
dat1 <- dat %>% 
  inner_join(county_level %>% 
               select(county_id, county_level), by = 'county_id') %>% 
  mutate(
    subject = as.character(subject),
    is_be_invited = as.character(is_be_invited),
    complete_novice_task = as.character(complete_novice_task)
  ) %>% 
  sample_n(5000)


# Kaplan Meier Analysis ---------------------------------------------------

# Bulid the standard survival object
objsurv <- with(dat1, Surv(s_time, status))

# KM estimates of the survival function
km_fit <- survfit(objsurv ~ 1, data = dat1)

ggsurvplot(km_fit)
