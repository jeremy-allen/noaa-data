scrape_voices_tables <- function() {

  voices_base_url <- "https://voices.nmfs.noaa.gov"

  session <- bow(str_c(voices_base_url, "/search"), delay = 6, verbose = TRUE)
  
  pages <- 1:27

  scrape_page <- function(page_num, polite_session = session) {

    # Construct query parameters including page number and items per page
    query_params <- list(
      search_api_fulltext = "",
      field_collection_name = "All",
      field_interviewer = "All",
      field_city = "All", 
      field_state = "All",
      field_interviewer_s_affiliation = "All",
      field_location = "All",
      field_region = "All",
      page = page_num - 1,  # API uses 0-based indexing
      items_per_page = 100
    )
    
    # Scrape the page
    message(paste0("\nscraping page ", page_num, "\n"))

    tryCatch({
      response <- scrape(polite_session, query = query_params, verbose = TRUE)
    },
    error = function(e) {
      # Log the error
      message(paste("Failed to scrape page", page_num, "\nError:", e$message))
      # Write to a file of failed scrapes
      failed_scrape_info <- sprintf("\nFailed to scrape page: %d\nError: %s\n", page_num, e$message)
      write(failed_scrape_info, "failed_scrapes.txt", append = TRUE)
    
      # Return NULL to indicate failure
      NULL
    })

    if (is.null(response)) {
      return(NULL)  # Exit the function early if scraping failed
    }
    
    interviewee_html_links <- response |>
      html_element("table") |>
      html_elements("tr") |>
      html_elements("td:first-child") |>
      html_elements("a")

    interviewee_links_df <- tibble(
      Interviewee = interviewee_html_links |> html_text(),
      url = interviewee_html_links |> html_attr("href")
    ) |> 
     mutate(Interviewee = str_trim(Interviewee, side = "both")) |> 
     mutate(
      url = str_c(voices_base_url, url),
      id = row_number()
    )
  
    voices_metadata_table <- response |>
      html_element("table") |>
      html_table(trim = TRUE) |> 
      mutate(id = row_number()) |> 
      left_join(
        interviewee_links_df |> select(id, url),
        by = "id"
      ) |> 
      rename(Interviewee_url = url) |> 
      select(Interviewee, Interviewee_url, everything())

    if (nrow(voices_metadata_table) > 0) {
      return(voices_metadata_table)
    } else {
      stop("no rows")
    }
  
  }
  
  # Scrape all pages and combine results and save R object
  responses_df <- map_df(pages, scrape_page)
  saveRDS(responses_df, "data/responses_list.rds")

}
