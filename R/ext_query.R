#' @title Extension functions
#'
#' @description
#' The `ext_query()` is the *exported function* of the STAC API
#' query extension. It can be used after a call to `stac_search()`
#' function. It allows that additional fields and operators other than those
#' defined in `stac_search()` function be used to make a complex filter.
#'
#' The function accepts multiple filter criteria. Each filter entry is an
#' expression formed by `<field> <operator> <value>`, where
#' `<field>` refers to a valid item property. Supported `<fields>`
#' depends on STAC API service implementation. The users must rely on service
#' providers' documentation to know which properties can be used by this
#' extension.
#'
#' The `ext_query()` function allows the following `<operators>`
#' \itemize{
#' \item `==` corresponds to '`eq`'
#' \item `!=` corresponds to '`neq`'
#' \item `<` corresponds to '`lt`'
#' \item `<=` corresponds to '`lte`'
#' \item `>` corresponds to '`gt`'
#' \item `>=` corresponds to '`gte`'
#' \item `\%startsWith\%` corresponds to '`startsWith`' and implements
#' a string prefix search operator.
#' \item `\%endsWith\%` corresponds to '`endsWith`' and implements a
#' string suffix search operator.
#' \item `\%contains\%`: corresponds to '`contains`' and implements a
#' string infix search operator.
#' \item `\%in\%`: corresponds to '`in`' and implements a vector
#' search operator.
#' }
#'
#' Besides this function, the following S3 generic methods were implemented
#' to get things done for this extension:
#' \itemize{
#' \item The `endpoint()` for subclass `ext_query`
#' \item The `before_request()` for subclass `ext_query`
#' \item The `after_response()` for subclass `ext_query`
#' }
#' See source file `ext_query.R` for an example on how implement new
#' extensions.
#'
#' @param q   a `RSTACQuery` object expressing a STAC query
#' criteria.
#'
#' @param ... entries with format `<field> <operator> <value>`.
#'
#' @seealso [stac_search()], [post_request()],
#' [endpoint()], [before_request()],
#' [after_response()], [content_response()]
#'
#' @return
#' A `RSTACQuery` object  with the subclass `ext_query` containing
#'  all request parameters to be passed to `post_request()` function.
#'
#' @examples
#' \donttest{
#' stac("https://brazildatacube.dpi.inpe.br/stac/") %>%
#'   stac_search(collections = "CB4_64_16D_STK-1") %>%
#'   ext_query("bdc:tile" %in% "022024") %>%
#'   post_request()
#' }
#'
#' @export
ext_query <- function(q, ...) {

  # check s parameter
  check_subclass(q, c("search", "ext_query"))

  # get the env parent
  env_parent <- parent.frame()

  params <- list()
  if (!is.null(substitute(list(...))[-1])) {
    dots <- substitute(list(...))[-1]
    tryCatch({
      ops <- lapply(dots, function(x) as.character(x[[1]]))
      keys <- lapply(dots, function(x) as.character(x[[2]]))
      values <- lapply(dots, function(x) eval(x[[3]], env_parent))
    }, error = function(e) {

      .error("Invalid query expression.")
    })
  }

  ops <- lapply(ops, function(op) {
    if (op == "==") return("eq")
    if (op == "!=") return("neq")
    if (op == "<") return("lt")
    if (op == "<=") return("lte")
    if (op == ">") return("gt")
    if (op == ">=") return("gte")
    if (op == "%startsWith%") return("startsWith")
    if (op == "%endsWith%") return("endsWith")
    if (op == "%contains%") return("contains")
    if (op == "%in%") return("in")
    .error("Invalid operator '%s'.", op)
  })

  uniq_keys <- unique(keys)
  entries <- lapply(uniq_keys, function(k) {

    res <- lapply(values[keys == k], c)
    names(res) <- ops[keys == k]

    res <- lapply(names(res), .parse_values_op, res)
    names(res) <- ops[keys == k]
    return(res)
  })

  if (length(entries) == 0)
    return(q)

  names(entries) <- uniq_keys
  params[["query"]] <- entries

  RSTACQuery(version = q$version,
             base_url = q$base_url,
             params = utils::modifyList(q$params, params),
             subclass = "ext_query")
}

#' @export
endpoint.ext_query <- function(q) {

  # using endpoint from search document
  endpoint.search(q)
}

#' @export
before_request.ext_query <- function(q) {

  msg <- paste0("Query extension param is not supported by HTTP GET",
                "method. Try use `post_request()` method instead.")

  check_query_verb(q, verbs = "POST", msg = msg)

  return(q)
}

#' @export
after_response.ext_query <- function(q, res) {

  content <- content_response(res, "200", c("application/geo+json",
                                            "application/json"))

  RSTACDocument(content = content, q = q, subclass = "STACItemCollection")
}

#' @export
parse_params.ext_query <- function(q, params) {

  # call super class
  params <- parse_params.search(q, params)

  params$query <- .parse_values_keys(params$query)

  params
}

#' @title Utility function
#'
#' @param op     a `character` with operation to be searched.
#' @param values a named `list` with all values.
#'
#' @return a `vector` with one operation value.
#'
#' @noRd
.parse_values_op <- function(op, values) {

  if (op == "in") {
    if (length(values[[op]]) == 1)
      return(list(values[[op]]))
    return(values[[op]])
  }

  if (length(values[[op]]) > 1)
    .warning(paste("Only the first value of '%s' operation was considered",
                   "in 'ext_query()' function."), op)
  values[[op]][[1]]
}

#' @title Utility function
#'
#' @param query a `list` with parameters to be provided in requests.
#'
#' @return a `list` with parsed parameters.
#'
#' @noRd
.parse_values_keys <- function(query) {

  uniq_keys <- names(query)

  entries <- lapply(uniq_keys, function(k) {
    ops <- names(query[[k]])

    values <- lapply(ops, function(op){
      query[[k]][[op]]
    })

    names(values) <- ops

    res <- lapply(ops, .parse_values_op, values)
    names(res) <- ops
    return(res)
  })

  names(entries) <- uniq_keys

  entries
}
