# .Rprofile for unicefData-dev project
# Ensures user library is always first in library paths

# Set user library path
userLib <- file.path(Sys.getenv('USERPROFILE'), 'AppData', 'Local', 'R', 'win-library', '4.5')

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
