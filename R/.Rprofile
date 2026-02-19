# .Rprofile for unicefData-dev project
# Ensures user library is always first in library paths
# Supports Windows, macOS, and Linux

# Determine user library path based on OS
if (.Platform$OS.type == "windows") {
  # Windows: Use AppData Local directory
  userLib <- file.path(Sys.getenv('USERPROFILE'), 'AppData', 'Local', 'R', 'win-library')
} else {
  # macOS/Linux: Use standard R user library location
  # R_LIBS_USER is typically set by R startup, but we can compute it if needed
  userLib <- Sys.getenv('R_LIBS_USER')
  if (userLib == "") {
    # Fallback: use R's own logic to find user library
    userLib <- file.path(Sys.getenv('HOME'), '.local', 'lib', 'R')
  }
}

# Create if it doesn't exist
if (!file.exists(userLib)) {
  dir.create(userLib, recursive = TRUE, showWarnings = FALSE)
}

# Add to library paths (user library first)
.libPaths(c(userLib, .libPaths()))

# Silent message for debugging (optional)
if (interactive()) {
  message("User R library loaded: ", userLib)
}
