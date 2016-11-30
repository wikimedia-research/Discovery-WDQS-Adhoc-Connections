# Step 1: Run data.sh on stat1002

# Step 2: Download files & rename
dir.create("data")
system("scp -r stat2:/home/bearloga/tmp/wdqs_requests/* data/")
old_filenames <- dir("data", pattern = "*.tsv.gz")
new_filenames <- sprintf("2016-11-%02.0f.tsv.gz", as.numeric(gsub(".tsv.gz", "", old_filenames, fixed = TRUE)))
file.rename(file.path("data", old_filenames), file.path("data", new_filenames))

# Step 3: Read into R
sparql_requests <-  data.table::rbindlist(lapply(dir("data", pattern = "*.tsv.gz"), function(new_filename) {
  # Read:
  data <- read.delim(file.path("data", new_filename), sep = "\t", quote = "", as.is = TRUE, header = TRUE, na.strings = "NULL")
  # Clean:
  data <- data[!is.na(data$time_firstbyte), ]
  data$timestamp <- stringr::str_extract(data$timestamp, "([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})")
  data <- data[stringr::str_detect(data$timestamp, "([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})"), ]
  data$timestamp <- anytime::utctime(data$timestamp, tz = "UTC")
  data$user_agent[data$user_agent == "-"] <- NA
  # Output:
  return(data)
}))

# Step 4: Save
readr::write_rds(sparql_requests, "data/sparql_requests.rds", compress = "gz")
