library(tidyverse)
library(polite)
library(rvest)
library(fs)
source("R/get_media_links.R")
source("R/scrape_voices_tables.R")

# get the complete table of interview metadata and links
if (!fs::file_exists("data/responses_list.rds")) {
  message("\nNo data found on disk, attempting to scrape now\n")
  scrape_voices_tables()
}

if (fs::file_exists("data/responses_list.RDS")) {
  message("\ndata found on disk, loading now\n")
  interviewee_meta_df <- readRDS("data/responses_list.rds")
}

voices_base_url <- "https://voices.nmfs.noaa.gov"

session <- bow(str_c(voices_base_url), force = TRUE, delay = 8)
set_rip_delay(8)

# loop through each interviewee and download their media

for (i in seq_along(interviewee_meta_df$Interviewee_url)) {
  
  # sleep
  cat("\n","sleeping between interviewees", "\n")
  Sys.sleep(6)

  cat("attempting", interviewee_meta_df$Interviewee[[i]], "\n")

  my_name <- interviewee_meta_df$Interviewee[[i]] |> 
    str_to_lower() |> 
    str_replace_all("[^A-Za-z\\s]", "") |>
    str_squish() |>
    str_replace_all("\\s", "_") |> 
    str_trunc(18, "right", ellipsis = "_")

  my_url <- interviewee_meta_df$Interviewee_url[[i]]

  if (!dir.exists(my_dir)) {
    dir.create(my_dir)
  }

  # media links
  links_to_download <- get_media_links(my_url) |> 
    pull(url)
  # save links themselves in a file
  write_lines(links_to_download, paste0(my_dir, "/links.text"))
  
  cat("there are", length(links_to_download), "\n")

  download_num <- 1

  # download media from each link
  for (my_file in links_to_download) {

    # sleep
    cat("\n","sleeping between interviewee files", "\n")
    Sys.sleep(6)

    cat("attempting", download_num, "of", length(links_to_download))

    # download the file

    tryCatch({
      polite::rip(
        bow = nod(session, path = my_file, verbose = TRUE),
        path = my_dir,
        overwrite = TRUE,
        timeout = 500
      )
    },
    error = function(e) {
      # Log the error
      cat("Failed to download:", my_file, "\nError:", e$message, "\n")
      to_write <- paste0("\nfor ", i, "\n", "Failed to download:", my_file, "\nError:", e$message, "\n")
      # write to a file of failed downloads
      write(to_write, "failed_downloads.txt", append = TRUE)
    })
    
    # increment the download counter
    download_num <- download_num + 1

  }

}
