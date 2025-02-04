% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_sig_similarity.R
\name{get_sig_similarity}
\alias{get_sig_similarity}
\title{Calculate Similarity between Identified Signatures and Reference Signatures}
\usage{
get_sig_similarity(
  Signature,
  Ref = NULL,
  sig_db = "legacy",
  db_type = c("", "human-exome", "human-genome"),
  method = "cosine",
  normalize = c("row", "feature"),
  feature_setting = sigminer::CN.features,
  pattern_to_rm = NULL,
  verbose = TRUE
)
}
\arguments{
\item{Signature}{a \code{Signature} object or a component-by-signature matrix (sum of each column is 1).
More please see examples.}

\item{Ref}{default is \code{NULL}, can be a same object as \code{Signature}.}

\item{sig_db}{can be 'legacy' or 'SBS'. Default 'legacy'.}

\item{db_type}{only used when \code{sig_db} is enabled.
"" for keeping default, "human-exome" for transforming to exome frequency of component,
and "human-genome" for transforming to whole genome frequency of component.}

\item{method}{default is 'cosine' for cosine similarity.}

\item{normalize}{one of "row" and "feature". "row" is typically used
for mutational signatures. "feature" is designed by me to use when input
are copy number signatures.}

\item{feature_setting}{a \code{data.frame} used for classification.
Only used when method is "Wang" ("W").
Default is \link{CN.features}. Users can also set custom input with "feature",
"min" and "max" columns available. Valid features can be printed by
\code{unique(CN.features$feature)}.}

\item{pattern_to_rm}{patterns for removing some features/components in similarity
calculation. A vector of component name is also accepted.
The remove operation will be done after normalization. Default is \code{NULL}.}

\item{verbose}{if \code{TRUE}, print extra info.}
}
\value{
a \code{list} containing smilarities, aetiologies if available, and best match.
}
\description{
The reference signatures can be either a \code{Signature} object specified by \code{Ref} argument
or known COSMIC signatures specified by \code{sig_db} argument.
Two COSMIC databases are used for comparisons - "legacy" which includes 30 signaures,
and "SBS" - which includes updated/refined 65 signatures. This function is modified
from \code{compareSignatures()} in \strong{maftools} package.
}
\examples{
# Load mutational signature
load(system.file("extdata", "toy_mutational_signature.RData",
  package = "sigminer", mustWork = TRUE
))

s1 <- get_sig_similarity(sig2, Ref = sig2)
s1

s2 <- get_sig_similarity(sig2)
s2
s3 <- get_sig_similarity(sig2, sig_db = "SBS")
s3

## Remove some components
## in similarity calculation
s4 <- get_sig_similarity(sig2,
  Ref = sig2,
  pattern_to_rm = c("T[T>G]C", "T[T>G]G", "T[T>G]T")
)
s4
}
\author{
Shixiang Wang \href{mailto:w_shixiang@163.com}{w_shixiang@163.com}
}
