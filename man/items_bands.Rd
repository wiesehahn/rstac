% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/deprec-funs.R
\name{items_bands}
\alias{items_bands}
\title{STACItemCollection function}
\usage{
items_bands(items)
}
\arguments{
\item{items}{a \code{STACItemCollection} or \code{STACItem} object.}
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}} Use \code{\link{items_assets}()} function
instead.
}
\examples{
\dontrun{

x <- stac("http://brazildatacube.dpi.inpe.br/stac") \%>\%
  stac_search(collections = "CB4_64_16D_STK-1") \%>\%
  stac_search() \%>\%
  get_request()

x \%>\% items_assets()
}

}
