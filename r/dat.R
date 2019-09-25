library(tidyverse)
library(knowboxr)
library(DBI)


# Reverse proxy -----------------------------------------------------------

proxy <- read_file("proxy.txt")

eval(parse(text = proxy))


# Connect to database -----------------------------------------------------

conn <- est_pgres_conn("octopus_susuan")

tea_query <- read_file("sql/teacher.sql")

teacher <- dbGetQuery(conn, tea_query) %>% as_tibble()


# Disconnect from database ------------------------------------------------

dbDisconnect(conn)


# Save data ---------------------------------------------------------------

teacher %>% write_rds("data/teacher.rds")

