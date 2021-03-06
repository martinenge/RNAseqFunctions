#' plotTsne
#'
#' Plots tsne.
#'
#' @name plotTsne
#' @rdname plotTsne
#' @author Jason T. Serviss
#' @param tsne matrix; Output from \code{\link{runTsne}} function.
#' @param counts.log matrix; Matrix of log2 counts per million with samples as
#'  columns and genes as rows.
#' @param markers character; The markers to evaluate. Must be present in
#'  rownames(counts.cpm).
#' @param pal character; A colour palette with length >= length(markers).
#' @param ... additional arguments to pass on.
#' @keywords coloursFromTargets
NULL

#' @rdname plotTsne
#' @export
#' @import ggplot2
#' @importFrom ggthemes theme_few
#' @importFrom dplyr "%>%" rename full_join
#' @importFrom viridis scale_colour_viridis
#' @importFrom rlang .data

plotTsne <- function(tsne, counts.log, markers = NULL, pal = col40()) {

  if(!is.null(markers)) {
    names(pal) <- markers
    pal <- pal[order(names(pal))]
  }

  p <- tsne %>%
  matrix_to_tibble(.) %>%
  rename(
    `t-SNE dim 1` = .data$V1, `t-SNE dim 2` = .data$V2, Sample = .data$rowname
  ) %>%
  #add colors
  full_join(coloursFromTargets(pal, counts.log, markers), by = "Sample") %>%
  #add marker data
  full_join(processMarkers(counts.log, markers), by = "Sample") %>%
  #base plot
  ggplot(aes_string(x = '`t-SNE dim 1`', y = '`t-SNE dim 2`')) +
    theme_few() +
    theme(legend.position = "top")

  if(is.null(markers)) {
    return(p + geom_point())
  } else if(length(markers) == 1) {
    p + geom_point(aes_string(colour = markers)) +
      scale_colour_viridis(option = "E")
  } else {

    p + geom_point(colour = "black", shape = 21) +
      geom_point(aes_string(colour = 'Colour'), alpha = .85) +
      scale_colour_identity(
        "Markers", labels = names(pal), breaks = pal,
        guide = "legend", drop = FALSE
    ) +
    guides(colour = guide_legend(override.aes = list(size = 3)))
  }
}

#' coloursFromTargets
#'
#' Coloring for plotting of multiple gene expression.
#'
#' @name coloursFromTargets
#' @rdname coloursFromTargets
#' @author Jason T. Serviss
#' @param pal character; A colour palette with length = length(markers).
#' @param counts matrix; A matrix containing counts.
#' @param markers character; The markers to evaluate. Must be present in
#'  rownames(counts).
#' @param ... additional arguments to pass on.
#' @keywords coloursFromTargets
NULL

#' @rdname coloursFromTargets
#' @importFrom dplyr "%>%" group_by ungroup mutate arrange summarize select if_else n
#' @importFrom rlang .data
#' @importFrom tibble tibble add_column
#' @importFrom tidyr gather unnest spread
#' @importFrom purrr pmap pmap_chr
#' @importFrom grDevices col2rgb rgb
#' @importFrom readr parse_factor

coloursFromTargets <- function(
  pal,
  counts,
  markers,
  ...
){

  if(is.null(markers) | is.null(pal) | length(markers) == 1) {
    return(tibble('Sample' = colnames(counts)))
  }

  markers <- sort(markers)
  pal <- pal[1:length(markers)]

  counts[rownames(counts) %in% markers, ] %>%
  matrix_to_tibble(., 'geneName') %>%
  gather('Sample', 'count', -.data$geneName) %>%
  #normalize
  group_by(.data$geneName) %>%
  mutate('normalized' = normalizeVec(.data$count)) %>%
  ungroup() %>%
  #calculate fraction
  group_by(.data$Sample) %>%
  mutate('fraction' = .data$normalized / sum(.data$normalized)) %>%
  mutate('fraction' = if_else(is.nan(.data$fraction), 1 / n(), .data$fraction)) %>%
  #setup initial hex colors
  arrange(.data$geneName) %>%
  mutate('colint' = pal) %>%
  ungroup() %>%
  #convert to rgb and calculate new colors
  mutate('rgb' = pmap(
    list(.data$colint, .data$normalized, .data$fraction),
    function(x, y, z) {
      (255 - ((255 - col2rgb(x)) * y)) * z
    }
  )) %>%
  unnest() %>%
  add_column('col' = rep(c("r", "g", "b"), nrow(.) / 3)) %>%
  group_by(.data$Sample, .data$col) %>%
  summarize('sumRGB' = sum(.data$rgb) / 256) %>%
  ungroup() %>%
  spread('col', 'sumRGB') %>%
  #convert back to hex
  mutate('Colour' = pmap_chr(
    list(.data$r, .data$g, .data$b),
    function(x, y, z) {
      rgb(red = x, green = y, blue = z)
    }
  )) %>%
  select(-(.data$b:.data$r)) %>%
  #fix factor levels so ggplot legend will cooperate
  #https://community.rstudio.com/t/drop-false-with-scale-fill-identity/5163/2
  mutate('Colour' = parse_factor(
    .data$Colour,
    levels = unique(c(.data$Colour, pal[!pal %in% .data$Colour]))
  ))
}

#' col40
#'
#' Diverging color palette with 40 colors.
#'
#' @name col40
#' @rdname col40
#' @author Jason T. Serviss
#' @keywords col40
#' @examples
#'
#' col40()
#'
#' @export
NULL

col40 <- function() {
  c(
  "#1c54a8", "#f63b32", "#00C2A0", "#FFDBE5", "#e0c48c", "#63FFAC", "#663000",
  "#e0a81c", "#385438", "#609060", "#6A3D9A", "#548495", "#A30059", "#8FB0FF",
  "#997D87", "#4FC601", "#8ca8c4", "#3B5DFF", "#BA0900", "#DDEFFF", "#7B4F4B",
  "#A1C299", "#0AA6D8", "#00846F", "#FFB500", "#C2FFED", "#A079BF", "#C0B9B2",
  "#C2FF99", "#00489C", "#6F0062", "#EEC3FF", "#922329", "#FFF69F", "#FF8A9A",
  "#B05B6F", "#7900D7", "#BC23FF", "#9B9700", "#0089A3"
  )
}

#' processMarkers
#'
#' Helper function for plotTsne. Gathers and returns data in an expected format.
#'
#' @name processMarkers
#' @rdname processMarkers
#' @author Jason T. Serviss
#' @param counts.log matrix; A matrix containing log2(cpm).
#' @param markers character; The markers to process. Must be present in
#'  rownames(counts.log).
#' @keywords processMarkers
NULL

#' @rdname processMarkers
#' @importFrom dplyr "%>%"
#' @importFrom tibble tibble

processMarkers <- function(counts.log, markers) {

  if(is.null(markers)) {
    return(tibble(Sample = colnames(counts.log)))
  }

  #check that specified markers exist in data
  if(!all(markers %in% rownames(counts.log))) {
    notFound <- markers[!markers %in% rownames(counts.log)]
    notFound <- paste(notFound, collapse = ", ")
    message <- "These markers were not found in the dataset:"
    stop(paste(message, notFound))
  }

  #normalize the marker expression
  markExpress <- t(counts.log[rownames(counts.log) %in% markers, ])

  if(length(markers) == 1) {
    markExpressNorm <- matrix(
      normalizeVec(markExpress),
      ncol = 1,
      dimnames = list(colnames(counts.log), markers)
    )
  } else {
    markExpressNorm <- apply(markExpress, 2, normalizeVec)
  }

  #tidy markers
  matrix_to_tibble(markExpressNorm, rowname = "Sample")
}

#' plotData
#'
#' Returns the data used to build plots for plotTsne.
#'
#' @name plotData
#' @rdname plotData
#' @aliases plotData
#' @param plot A ggplot object of class "gg" "ggplot".
#' @param ... additional arguments to pass on.
#' @return A tibble containing the plot data.
#' @author Jason T. Serviss
#' @keywords plotData
#' @examples
#'
#' #use demo data
#'
NULL

#' @rdname plotData
#' @export
#' @importFrom tibble as_tibble

plotData <-  function(plot, ...){
  as_tibble(plot[[1]])
}

#' plotLowQualityCells
#'
#' Plots histograms of the two metrics evaluated by the
#' \code{\link{detectLowQualityCells}} function.
#'
#' @name plotLowQualityCells
#' @rdname plotLowQualityCells
#' @param counts data.frame; A data frame with counts data with gene names as
#' rownames and sample names as colnames.
#' @param mincount numeric; A minimum colSum for which columns with a higher
#' colSum will be detected. Default = 4e5.
#' @param geneName character; The gene name to use for the quantile cutoff. This
#' must be present in the rownames of the counts argument. Default is ACTB.
#' @param quantileCut numeric; This indicates probability at which the quantile
#' cutoff will be calculated using the normal distribution. Default = 0.01.
#' @return A tibble containing the plot data.
#' @author Jason T. Serviss
#' @examples
#' c <- moveGenesToRownames(testingCounts)[1:12, ]
#' detectLowQualityCells(c, geneName = "ACTB", mincount = 30)
NULL

#' @rdname plotLowQualityCells
#' @export
#' @import ggplot2

plotLowQualityCells <- function(
  counts,
  mincount = 4e5,
  geneName = 'ACTB',
  quantileCut = 0.01
) {
  value <- NULL
  counts <- .matrixCheckingAndCoercion(counts)

  ##check that geneName is in rownames counts
  if(!geneName %in% rownames(counts)) {
    stop("geneName is not found in rownames(counts)")
  }

  #setup output vector
  output <- vector(mode = "logical", length = ncol(counts))
  names(output) <- colnames(counts)

  #colsums check
  colsums <- colSums(counts)
  cs <- colsums > mincount
  output[cs] <- TRUE

  if(sum(cs) < 2) {
    stop("One or less samples passed the colSums check.")
  }

  #house keeping check
  counts.log <- log2cpm(counts[, cs])
  cl.act <- counts.log[geneName, ]
  cl.act.m <- median(cl.act)
  cl.act.sd <- sqrt(
    sum((cl.act[cl.act > cl.act.m] - cl.act.m) ^ 2) /
      (sum(cl.act > cl.act.m) - 1)
  )
  my.cut <- qnorm(p = quantileCut, mean = cl.act.m, sd = cl.act.sd)
  bool <- counts.log[geneName, ] > my.cut
  output[cs] <- cs[cs] & bool

  p <- data.frame(
    test = c(rep("Total counts", length(cs)), rep("Quantile cut", length(cl.act))),
    value = c(colsums, cl.act),
    decision = c(cs, cl.act > my.cut)
  ) %>%
    ggplot() +
    geom_histogram(aes(value)) +
    facet_wrap(~test)

  p
  return(p)
}
