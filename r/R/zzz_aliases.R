# =============================================================================
# zzz_aliases.R - Lowercase aliases for cross-platform consistency
# =============================================================================
# 
# This file provides lowercase aliases for the main functions to ensure
# consistency with Stata's case-insensitive command syntax.
#
# Usage:
#   R/Python: unicefdata() or unicefData() - both work
#   Stata:    unicefdata - case insensitive
# =============================================================================

#' @rdname unicefData
#' @export
unicefdata <- unicefData

#' @rdname unicefData_raw
#' @export
unicefdata_raw <- unicefData_raw
