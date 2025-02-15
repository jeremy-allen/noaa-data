# noaa-data

## Download all audio recordings and transcripts of [NOAA's Voices Oral History Archives](https://voices.nmfs.noaa.gov/).

The `voices_resecue.R` file orchestrates the download of two main components:
1. [The table](https://voices.nmfs.noaa.gov/search) of metadata and links to over 2000 interviewees and their files
2. The recordings and transcripts of each interview

The `polite` package is used to politely scrape the data and not overwhelm NOAA's servers. The `rvest` package is used for parsing HTML pages. `fs` handles file management, and the `tidyverse` is used for data wrangling and string ops.

## Data Size and Location

All interview media is over 200GB, so be sure you have the space available before starting. The script will create a folder for each interviewee and place it in the `data` directory, then download their media there. If your local system doesn't have enough storage, consider editing the location of that `data` directory, perhaps to an external drive or cloud storage. 
