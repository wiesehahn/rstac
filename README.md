# rstac <img src="img/logo.png" align="right" width="120" />
R Client Library for SpatioTemporal Asset Catalog (rstac)

[![Travis build status](https://travis-ci.com/OldLipe/stac.R.svg?branch=master)](https://travis-ci.com/OldLipe/stac.R) [![Build status](https://ci.appveyor.com/api/projects/status/73w7h6u46l1587jj?svg=true)](https://ci.appveyor.com/project/OldLipe/stac-r) [![codecov](https://codecov.io/gh/OldLipe/stac.R/branch/master/graph/badge.svg)](https://codecov.io/gh/OldLipe/stac.R)

STAC is a specification of files and web services used to describe geospatial information assets.
The specification can be consulted in [https://stacspec.org/].

R client library for STAC (`Rstac`) was designed to fully support STAC v0.8.0. 
As STAC spec is evolving fast and reaching its maturity, we plan update `Rstac` to support upcoming STAC 1.0.0 version soon.

## installation

To install `rstac` for R, run the following commands 

```R
library(devtools)
install_github("brazil-data-cube/stac.R")
```

## usage

In this version, we only implemented STAC endpoints (`'/stac'` and `'/stac/search'`) functions.

```R
library(rstac)

stac("http://brazildatacube.dpi.inpe.br/bdc-stac/0.8.0")
stac_search(url = "http://brazildatacube.dpi.inpe.br/bdc-stac/0.8.0",
            collections = "MOD13Q1",
            bbox = c(-55.16335, -4.26325, -49.31739, -1.18355))
```
