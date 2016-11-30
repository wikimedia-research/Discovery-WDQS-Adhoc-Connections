sparql_requests <- readr::read_rds("data/sparql_requests.rds")

# % of IPs with N user agents
table(
  sparql_requests[, list(UAs = length(unique(user_agent))), by = "client_ip"]$UAs
)

sparql_requests$agent_type_v3 <- ifelse(sparql_requests$agent_type_v2 == "spider", "bot/tool/proxy", "user")
sparql_requests$date <- as.Date(sparql_requests$timestamp)
sparql_requests$minute <- lubridate::hour(sparql_requests$timestamp) * 60 + lubridate::minute(sparql_requests$timestamp)
sparql_requests$temp_group <- paste(as.character(sparql_requests$date, "%Y-%m-%d"), sparql_requests$agent_type_v3)
sparql_requests$temp_uid <- paste(sparql_requests$user_agent, sparql_requests$client_ip)
cum_reqs <- sparql_requests[order(agent_type_v3, temp_group, timestamp),
                            list(reqs = as.numeric(.N),
                                 users = length(unique(temp_uid)),
                                 IPs = length(unique(client_ip))),
                            by = c("agent_type_v3", "temp_group", "minute")]
med_reqs <- cum_reqs[, list(days = .N,
                            reqs_middle = as.numeric(median(reqs)),
                            reqs_upper = as.numeric(max(reqs)),
                            reqs_upper99 = as.numeric(quantile(reqs, 0.99)),
                            users_middle = as.numeric(median(users)),
                            users_upper = as.numeric(max(users)),
                            users_upper99 = as.numeric(quantile(users, 0.99)),
                            IPs_middle = as.numeric(median(IPs)),
                            IPs_upper = as.numeric(max(IPs)),
                            IPs_upper99 = as.numeric(quantile(IPs, 0.99))),
                     by = c("agent_type_v3", "minute")]
cum_reqs <- cum_reqs[, list(minute = minute, reqs = cumsum(as.numeric(reqs))), by = c("agent_type_v3", "temp_group")]

library(ggplot2)
format_minutes <- function(x, ...) {
  x <- floor(x/60) # Convert minutes to hours
  x[x < 0 & !is.na(x)] <- 24 + x[x < 0 & !is.na(x)]
  return(paste0(sprintf("%02.0f", ifelse(x %% 12 == 0, 12, x %% 12)), ifelse(x < 12, "AM", "PM")))
}
# Median requests/users/IPs per minute
ggplot(med_reqs, aes(x = minute)) +
  # geom_ribbon(aes(ymin = reqs_middle, ymax = reqs_upper99, fill = agent_type_v3), alpha = 0.5, color = NA) +
  geom_line(aes(y = reqs_middle, color = agent_type_v3), alpha = 0.75) +
  geom_smooth(aes(y = reqs_middle, color = agent_type_v3), se = FALSE) +
  scale_color_brewer("Agent type", palette = "Set1") +
  scale_fill_brewer("Agent type", palette = "Set1") +
  facet_wrap(~ agent_type_v3, nrow = 2, strip.position = "right") +
  scale_y_continuous("Requests") +
  # scale_y_log10("Requests (log10 scale)") +
  scale_x_continuous("Time of day (UTC)",
                     breaks = seq(0, 23, 2) * 60,
                     labels = format_minutes,
                     sec.axis = sec_axis(trans = ~ . - (8 * 60),
                                         breaks = seq(0-8, 23-8, 2) * 60,
                                         name = "Time of day (PST)",
                                         labels = format_minutes)) +
  labs(title = "Median SPARQL endpoint requests received over 24 hour period",
       subtitle = "Median taken across days (11/01-11/28)",
       caption = "Bots/tools/proxies tended to be most active around 11AM PST / 7PM UTC during most of November (11/01-11/28)") +
  theme_minimal() +
  theme(legend.position = "bottom",
        strip.background = element_rect(fill = "gray90"),
        panel.border = element_rect(color = "gray30", fill = NA))
ggplot(med_reqs, aes(x = minute)) +
  # geom_ribbon(aes(ymin = users_middle, ymax = users_upper99, fill = agent_type_v3), alpha = 0.5, color = NA) +
  geom_line(aes(y = users_middle, color = agent_type_v3), alpha = 0.5) +
  geom_smooth(aes(y = users_middle, color = agent_type_v3), se = FALSE) +
  scale_color_brewer("Agent type", palette = "Set1") +
  scale_fill_brewer("Agent type", palette = "Set1") +
  facet_wrap(~ agent_type_v3, nrow = 2, scales = "free_y", strip.position = "right") +
  scale_y_continuous("Unique users") +
  scale_x_continuous("Time of day (UTC)",
                     breaks = seq(0, 23, 2) * 60,
                     labels = format_minutes,
                     sec.axis = sec_axis(trans = ~ . - (8 * 60),
                                         breaks = seq(0-8, 23-8, 2) * 60,
                                         name = "Time of day (PST)",
                                         labels = format_minutes)) +
  labs(title = "WDQS users (unique IP+UA combinations) on a minute-by-minute basis over 24 hour period",
       subtitle = "Median taken across 28 days in November (11/01-11/28)",
       caption = "On average, Wikidata Query Service was used by ~15 users and 4-5 bots/tools per minute between 10AM and 7PM UTC") +
  theme_minimal() +
  theme(legend.position = "bottom",
        strip.background = element_rect(fill = "gray90"),
        panel.border = element_rect(color = "gray30", fill = NA))
# Cumulative requests per minute
ggplot(cum_reqs, aes(x = minute, y = reqs, color = agent_type_v3, group = temp_group)) +
  geom_line(alpha = 0.3) +
  scale_color_brewer("Agent type", palette = "Set1") +
  scale_x_continuous("Time of day (UTC)",
                     breaks = seq(0, 24, 2) * 60,
                     labels = format_minutes,
                     sec.axis = sec_axis(trans = ~ . - (8 * 60),
                                         breaks = seq(0-8, 24-8, 2) * 60,
                                         name = "Time of day (PST)",
                                         labels = format_minutes)) +
  scale_y_continuous("HTTP Requests", labels = function(x) {
    x[x == 0] <- 1
    y <- polloi::compress(x)
    y[x == "1"] <- "0"
    return(y)
  }) +
  # scale_y_log10("Requests (log10 scale)", labels = polloi::compress) +
  facet_wrap(~ agent_type_v3, nrow = 2, scales = "free_y", strip.position = "right") +
  labs(title = "Cumulative SPARQL endpoint requests received over 24 hour period",
       subtitle = "WDQS usage data gathered from November 1st through November 28th",
       caption = "On several days, WDQS usage by bots/tools/proxies increases substantially at 10AM UTC / 2AM PST") +
  theme_minimal() +
  theme(legend.position = "bottom",
        strip.background = element_rect(fill = "gray90"),
        panel.border = element_rect(color = "gray30", fill = NA),
        panel.grid.major.x = element_line(color = "gray80"))

rm(cum_reqs, med_reqs)

parallel_requests <- sparql_requests[, list(reqs = .N), by = c("timestamp", "client_ip")][order(reqs, decreasing = TRUE), ]

length(unique(parallel_requests[reqs > 3, ]$client_ip))
length(unique(parallel_requests[reqs > 3, ]$client_ip))/length(unique(sparql_requests$client_ip))

# Out of the IPs that do the above, how many have the same/different user agents (hinting at one tool or proxy serving multiple clients)?
temp <- sparql_requests[sparql_requests$client_ip %in% parallel_requests[reqs > 3, ]$client_ip,
                        list(UAs = length(unique(user_agent))),
                        by = "client_ip"]
data.frame(table(temp$UAs), 100 * prop.table(table(temp$UAs)))
data.frame(table(temp$UAs > 1), 100 * prop.table(table(temp$UAs > 1)))
