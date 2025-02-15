get_media_links <- function(url, base_url = NULL, polite_session = session){

  result <- nod(bow = polite_session, path = url) |>
    scrape()
  
  doc_links <- result |> 
    html_elements("a")

  media_sources <- result |> 
    html_elements("source")

  media_df <- tibble(
    url = media_sources |> html_attr("src"),
    text = media_sources |> html_text(),
    kind = "audio"
  )

  doc_df <- tibble(
    url = doc_links |> html_attr("href"),
    text = doc_links |> html_text()
  ) |> 
    mutate(
      kind = if_else(
        condition = str_extract(url, "[a-z]{3,4}$") %in% c("pdf", "doc", "docx", "txt"),
        true = "document",
        false = "unknown"
      )
    ) |> 
    filter(kind == "document")

  final_df <- bind_rows(media_df, doc_df)
  
  if (!is.null(base_url)) {
    final_df <- final_df |> 
      mutate(url = str_c(base_url, url))
  }

  final_df

}
