#' @title Utility functions
#'
#' @param bbox        a `numeric` vector with only features that have a
#' geometry that intersects the bounding box are selected. The bounding box is
#' provided as four or six numbers, depending on whether the coordinate
#' reference system includes a vertical axis (elevation or depth):
#' \itemize{ \item Lower left corner, coordinate axis 1
#'           \item Lower left corner, coordinate axis 2
#'           \item Lower left corner, coordinate axis 3 (optional)
#'           \item Upper right corner, coordinate axis 1
#'           \item Upper right corner, coordinate axis 2
#'           \item Upper right corner, coordinate axis 3 (optional) }
#'
#'
#' @return A `numeric` with the bbox provided,or an error if the supplied
#'   `bbox` does not meet the specifications.
#'
#' @noRd
.parse_bbox <- function(bbox) {

  if (is.character(bbox))
    bbox <- strsplit(bbox, ",")[[1]]

  if (!length(bbox) %in% c(4, 6))
    .error("Param `bbox` must have 4 or 6 numbers, not %s.", length(bbox))

  return(bbox)
}

#' @title Utility functions
#'
#' @param limit       an `integer` defining the maximum number of results
#' to return. If not informed it defaults to the service implementation.
#'
#' @return A `integer` with the limit provided,or an error if the supplied
#'  `limit` has a length different from 1.
#'
#' @noRd
.parse_limit <- function(limit) {

  if (length(limit) != 1)
    .error("Parameter `limit` must be a single value.")

  limit <- as.character(limit)

  limit_int <- suppressWarnings(as.integer(limit))

  if (any(is.na(as.integer(limit))) || as.character(limit_int) != limit)
    .error("Param `limit` must be an integer.")

  return(limit)
}

#' @title Utility functions
#'
#' @param feature_id  a `character` with item id to be fetched.
#' Only works if the `collection_id` is informed. This is equivalent to
#' the endpoint \code{/collections/\{collectionId\}/items/\{featureId\}}.
#'
#' @return A `character` with the parameter provided,or an error if the
#'  supplied `feature_id` has a length different from 1.
#'
#' @noRd
.parse_feature_id <- function(feature_id) {

  if (length(feature_id) != 1)
    .error("Parameter `feature_id` must be a single value.")

  return(feature_id)
}

#' @title Utility functions
#'
#' @param collections a `character` vector of collection IDs to include in
#' the search for items. Only items in one of the provided collections will be
#' searched.
#'
#' @return A `list` of collections.
#'
#' @noRd
.parse_collections <- function(collections) {

  if (is.character(collections))
    collections <- strsplit(collections, ",")[[1]]

  if (length(collections) == 1 && !is.list(collections))
    collections <- list(collections)

  return(collections)
}

#' @title Utility functions
#'
#' @param ids a `character` vector with item IDs. All other filter
#' parameters that further restrict the number of search results are ignored.
#'
#' @return A `list` with the ids.
#'
#' @noRd
.parse_ids <- function(ids) {

  if (is.character(ids))
    ids <- strsplit(ids, ",")[[1]]

  if (length(ids) == 1 && !is.list(ids))
    ids <- list(ids)

  return(ids)
}

#' @title Utility functions
#'
#' @param intersects a `character` value expressing GeoJSON geometries
#' objects as specified in RFC 7946. Only returns items that intersect with
#' the provided polygon.
#'
#' @return A `character` with the validate polygon.
#'
#' @noRd
.parse_geometry <- function(geom) {

  # TODO: validate polygon
  geom
}

#' @title Utility functions
#'
#' @param items a `STACItemCollection` object representing the result
#'  of `/stac/search` or \code{/collections/{collectionId}/items}.
#'
#' @return A `numeric` with the length of a `STACItemCollection`
#'  object.
#'
#' @noRd
.parse_items_size <- function(items) {

  if (items_length(items) != items_matched(items))
    .message(paste("The length of items in your object, does not correspond",
                   "with the total of matched items. Consider using the",
                   "function `items_fetch()`. By default, items_max = %d"),
             items_length(items))

  return(items_length(items))
}


#' @title Utility functions
#'
#' @description Auxiliary function to check whether the date time follows
#' RFC 3339 standard.
#'
#' @param datetime Either a date-time or an interval, open or closed.
#' Date and time expressions adhere to RFC 3339. Open intervals are
#' expressed using double-dots.
#' Examples:
#' \itemize{
#'   \item A date-time: `"2018-02-12T23:20:50Z"`
#'   \item A closed interval: `"2018-02-12T00:00:00Z/2018-03-18T12:31:12Z"`
#'   \item Open intervals: `"2018-02-12T00:00:00Z/.."` or
#'     `"../2018-03-18T12:31:12Z"`
#' }
#'
#' @return An error if the date does not follow the specified standards or the
#'  date time provided as `character`.
#'
#' @noRd
.parse_datetime <- function(datetime) {

  # check if the date time provided is an open interval
  check_interval <-
    grepl("(?=^(\\..\\/.*)).+|(.*/\\..)", datetime, perl = TRUE)

  if (check_interval) {
    # regex to separate the open interval elements
    split_datetime <- strsplit(datetime, "(\\/\\..)|(\\..\\/)", perl = TRUE)
    split_datetime <- split_datetime[[1]][which(unlist(split_datetime) != "")]

    # checking if date time is in the RFC standards
    match_rfc <- .check_rfc_3339(split_datetime)

    if (!match_rfc)
      .error(paste("The interval date time provided is not in RFC format,",
                   "please check the RFC 3339 rules."))

    return(datetime)
  } else {

    # Splits the vector elements with the dates by the backslash
    split_datetime <- strsplit(datetime, "/", perl = TRUE)
    split_datetime <- unlist(split_datetime)

    # In case the vector has two elements it is a closed date time
    if (length(split_datetime) == 2) {
      # Checks if there is FALSE value in vector
      if (!all(.check_rfc_3339(split_datetime)))
        .error(paste0("The date time provided not follow the RFC 3339 format,",
                      "please check the RFC 3339 rules."))

      # formatting the closed date time according to the RFC
      interval_dt <- as.POSIXct(split_datetime,
                                tz = "UTC",
                                tryFormats = c("%Y-%m-%dT%H:%M:%SZ",
                                               "%Y-%m-%d"))

      # Check the interval, if the interval is wrong an error is returned
      if (interval_dt[1] > interval_dt[2]) {
        .error(paste("The closed date time provided is not in correct",
                     "interval, the first date time shold be less than",
                     "second."))
      }

      return(datetime)
    }

    # Check if date time is a fixed interval
    else {
      if (!all(.check_rfc_3339(split_datetime)) || length(split_datetime) != 1)
        .error(paste("The date time provided not follow the RFC 3339 format,",
                     "please check the RFC 3339 rules."))

      return(datetime)
    }
  }
}

#' @title Utility functions
#'
#' @description Auxiliary function to check that the provided date time follows
#' the standards of RFC 3339
#'
#' @param datetime Either a date-time or an interval, open or closed.
#' Date and time expressions adhere to RFC 3339. Open intervals are
#' expressed using double-dots.
#' Examples:
#' \itemize{
#'   \item A date-time: `"2018-02-12T23:20:50Z"`
#'   \item A closed interval: `"2018-02-12T00:00:00Z/2018-03-18T12:31:12Z"`
#'   \item Open intervals: `"2018-02-12T00:00:00Z/.."` or
#'     `"../2018-03-18T12:31:12Z"`
#' }
#'
#' @return A `logical` if TRUE the date time provided is correct,
#' otherwise not.
#'
#' @noRd
.check_rfc_3339 <- function(datetime) {

  # Standard regexp of RFC 3339
  pattern_rfc   <- "^\\d{4}-\\d{2}-\\d{2}?(T\\d{2}:\\d{2}:\\d{2}Z)?$"
  check_pattern <- grepl(pattern_rfc, datetime, perl = TRUE)

  return(check_pattern)
}

#' @title Utility functions
#'
#' @param msg   a `character` string with format error message.
#'
#' @param ...   values to be passed to `msg` parameter.
#'
#' @noRd
.error <- function(msg, ...) {

  stop(sprintf(msg, ...), call. = FALSE)
}

#' @title Utility functions
#'
#' @param msg   a `character` string with format text message.
#'
#' @param ...   values to be passed to `msg` parameter.
#'
#' @noRd
.message <- function(msg, ...) {

  message(sprintf(msg, ...))
}

#' @title Utility functions
#'
#' @param msg   a `character` string with format warning message.
#'
#' @param ...   values to be passed to `msg` parameter.
#'
#' @noRd
.warning <- function(msg, ...) {

  warning(sprintf(msg, ...), call. = FALSE)
}

#' @title Utility functions
#'
#' @param obj       an `object` to compare.
#'
#' @param expected  a `character` with the expected classes.
#'
#' @noRd
.check_obj <- function(obj, expected) {

  obj_name <- as.character(substitute(obj))

  if (missing(obj))
    .error("Param `%s` is missing.", obj_name)

  if (!inherits(obj, expected))
    .error("Invalid %s value in `%s` param.",
           paste0("`", expected, "`", collapse = " or "), obj_name)
}


#' @title uUtility functions
#'
#' @rdname http_request
#'
#' @description
#' `.make_url` is a helper function to generate url. The returned
#' url is formed by appending `endpoint` at the end of base url
#' informed by `url` parameter. If `endpoint` has multiple elements
#' it will be collapsed using `'/'` character.
#'
#' Note that `.make_url` function differs from standards of relative URI
#' path resolution (RFC 3986). Any existing path in base url
#' is maintained in the final url, and a simple string contatenation is made
#' whithout including any character separator. For this reason, this function
#' does not support the query and fragment URI components in the base url.
#'
#' @param url         a `character` informing the base url of a
#' STAC web service.
#'
#' @param endpoint    a `character` a path to be appended in the final
#' url.
#'
#' @param params      a named `list` with all url query parameters to be
#' appended in the url.
#'
#' @return
#' `.make_url` returns an url to access STAC endpoints.
#'
#' @noRd
.make_url <- function(url, endpoint = "", params = list()) {

  # remove trailing '/' char
  if (substring(url, nchar(url)) == "/")
    url <- substring(url, 1, nchar(url) - 1)

  endpoint <- paste0(endpoint, collapse = "/")

  # TODO: URI resolution for previous existing query and fragment URI components
  # in informed url.
  res <- paste0(url, endpoint)

  if (length(params) > 0) {

    if (is.null(names(params)))
      stop("URL query values must be named.", call. = FALSE)
    params <- .querystring_encode(params)
    res <- paste(res, params, sep = "?")
  }

  return(res)
}

#' @title Utility functions
#'
#' @param params a `list` of parameters received from stac objects.
#'
#' @return a `character` representing the encode parameters of the query.
#'
#' @noRd
.querystring_encode <- function(params) {

  if (!is.null(names(params)))
    return(paste(names(params),
                 vapply(unname(params), paste0, collapse = ",", character(1)),
                 sep = "=", collapse = "&"))
  return(paste0(params, collapse = ","))
}

#' @title Utility functions
#'
#' @param querystring a `character` with the query to be decoded.
#'
#' @return a `list` with the query params.
#'
#' @noRd
.querystring_decode <- function(querystring) {

  # first decode and remove all coded spaces
  querystring <- URLdecode(querystring)

  values <- lapply(strsplit(querystring, split = "&")[[1]],
                   function(x) strsplit(x, split = "=")[[1]])

  params <- lapply(values, `[[`, 2)
  names(params) <- vapply(values, `[[`, 1, FUN.VALUE = character(1))

  return(params)
}

#' @title Utility functions
#'
#' @param params a `list` with the parameters of query.
#'
#' @return a `list` with the query parameters.
#'
#' @noRd
.validate_query <- function(params) {

  if (!is.null(params$query) && is.character(params$query)) {
    params$query <- jsonlite::fromJSON(params$query, simplifyVector = FALSE)

    if (is.list(params$query))
      params$query <- list(params$query)
  }

  return(params)
}

#' @title Utility functions
#'
#' @description
#' These function retrieves information about either `rstac` queries
#' (`RSTACQuery` objects) or `rstac` documents
#' (`RSTACDocument` objects).
#'
#' @param x   either a `RSTACQuery` object expressing a STAC query
#' criteria or any `RSTACDocument`.
#'
#' @param ... config parameters to be passed to [GET][httr::GET]
#' method, such as [add_headers][httr::add_headers] or [set_cookies][httr::set_cookies].
#'
#' @return
#' The `stac_version()` function returns a `character` STAC API
#' version.
#'
#' @name utilities
#'
#' @export
stac_version <- function(x, ...) {

  UseMethod("stac_version")
}

#' @title Utility functions
#'
#' @param bbox a `numeric` vector with only features that have a
#' geometry that intersects the bounding box are selected. The bounding box is
#' provided as four or six numbers, depending on whether the coordinate
#' reference system includes a vertical axis (elevation or depth):
#' \itemize{ \item Lower left corner, coordinate axis 1
#'           \item Lower left corner, coordinate axis 2
#'           \item Lower left corner, coordinate axis 3 (optional)
#'           \item Upper right corner, coordinate axis 1
#'           \item Upper right corner, coordinate axis 2
#'           \item Upper right corner, coordinate axis 3 (optional) }.
#'
#' @return A `character` with `bbox` formatted based on min and max
#'  values.
#'
#' @noRd
.format_bbox <- function(bbox) {

  if (!is.null(bbox) & length(bbox) == 4)
    return(paste(c("xmin:", "ymin:", "xmax:", "ymax:"),
                 sprintf("%.5f", bbox), collapse = ", "))

  if (!is.null(bbox) & length(bbox) == 6)
    return(paste(c("xmin:", "ymin:", "zmin:", "xmax:", "ymax:", "zmax:"),
                 sprintf("%.5f", bbox), collapse = ", "))
}

#' @title Utility functions
#'
#' @description Function similar to modifyList of utils, however it is checked
#'  if the left parameter is null.
#'
#' @param x   a `list` to be compared in left side.
#'
#' @param y   a `list` to be compared in right side.
#'
#' @return a `list` with modified values.
#'
#' @noRd
.modify_list <- function(x, y) {

  if (is.null(x))
    x <- list()
  utils::modifyList(x, y, keep.null = TRUE)
}
