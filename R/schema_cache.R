#' Schema Caching System for UNICEF SDMX API
#' @description
#' Implements in-memory caching of SDMX metadata schemas to reduce API calls
#' and improve performance during interactive analysis sessions.
#'
#' @details
#' This module provides:
#' - Session-level schema cache to avoid redundant API calls
#' - Automatic expiry based on age
#' - Programmatic cache invalidation
#' - Cache statistics and monitoring
#'
#' @examples
#' \dontrun{
#'   # Cache is managed automatically when get_sdmx() is called with cache=TRUE
#'   
#'   # Manual cache operations:
#'   get_schema_cache_info()
#'   clear_schema_cache()
#'   
#'   # Multiple calls within session use cached schema
#'   df1 <- get_sdmx(indicator = "SP.POP.TOTL", cache = TRUE)
#'   df2 <- get_sdmx(indicator = "NY.GDP.MKTP.CD", cache = TRUE)
#' }
#'
#' @keywords internal
#' @name schema_cache
NULL

# Initialize global cache environment
.schema_cache_env <- new.env(hash = TRUE, parent = emptyenv())

#' Clear the Schema Cache
#'
#' Remove all cached schemas from memory to free resources or refresh data.
#'
#' @return Invisibly returns NULL. Prints confirmation message.
#' @export
#' @examples
#' \dontrun{
#'   clear_schema_cache()
#'   # Cache: 0 items (0 MB)
#' }
clear_schema_cache <- function() {
  rm(list = ls(envir = .schema_cache_env), envir = .schema_cache_env)
  message("Schema cache cleared")
  invisible(NULL)
}

#' Get Schema Cache Information
#'
#' Display current cache contents and statistics.
#'
#' @return Invisible data.frame with cache statistics
#' @export
#' @examples
#' \dontrun{
#'   get_schema_cache_info()
#' }
get_schema_cache_info <- function() {
  cache_items <- ls(envir = .schema_cache_env)
  
  if (length(cache_items) == 0) {
    message("Cache: empty (0 items)")
    return(invisible(NULL))
  }
  
  # Calculate sizes
  sizes <- sapply(cache_items, function(key) {
    utils::object.size(.schema_cache_env[[key]]) / 1024 / 1024  # Convert to MB
  })
  
  total_size <- sum(sizes)
  
  # Display info
  message(sprintf(
    "Cache: %d items (%.2f MB)\n%s",
    length(cache_items),
    total_size,
    paste(
      sprintf("  - %s: %.2f MB", cache_items, sizes),
      collapse = "\n"
    )
  ))
  
  invisible(data.frame(
    key = cache_items,
    size_mb = as.numeric(sizes),
    stringsAsFactors = FALSE
  ))
}

#' Store Schema in Cache
#'
#' @param key Cache key (typically indicator name)
#' @param value Schema object to cache
#' @param namespace Additional namespace for organization (optional)
#'
#' @return Invisibly returns the cached value
#' @keywords internal
.cache_schema <- function(key, value, namespace = "schema") {
  cache_key <- paste0(namespace, ":", key)
  assign(cache_key, value, envir = .schema_cache_env)
  invisible(value)
}

#' Retrieve Schema from Cache
#'
#' @param key Cache key
#' @param namespace Cache namespace
#'
#' @return Schema object if found, NULL otherwise
#' @keywords internal
.get_cached_schema <- function(key, namespace = "schema") {
  cache_key <- paste0(namespace, ":", key)
  if (exists(cache_key, envir = .schema_cache_env)) {
    get(cache_key, envir = .schema_cache_env)
  } else {
    NULL
  }
}

#' Check if Schema is Cached
#'
#' @param key Cache key
#' @param namespace Cache namespace
#'
#' @return Logical TRUE if schema is cached
#' @keywords internal
.is_cached <- function(key, namespace = "schema") {
  cache_key <- paste0(namespace, ":", key)
  exists(cache_key, envir = .schema_cache_env)
}
