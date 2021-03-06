#' namedListToTibble
#'
#' Converts a named list to a long data frame.
#'
#' @name namedListToTibble
#' @rdname namedListToTibble
#' @author Jason T. Serviss
#' @param l List. The list to be converted.
#' @keywords namedListToTibble
#' @examples
#'
#' l <- list(a=LETTERS[1:10], b=letters[1:5])
#' output <- namedListToTibble(l)
#'
#' @export
#' @importFrom tibble tibble

namedListToTibble <- function(l) {
  if (length(names(l)) != length(l)) {
    stop("The list you submitted is not named.")
  }
  if (!is.null(names(l[[1]]))) {
    ni <- gsub(".*\\.(.*)$", "\\1", names(unlist(l)))
    n <- rep(names(l), lengths(l))
    tibble(names = n, inner.names = ni, variables = unname(unlist(l)))
  } else {
    n <- rep(names(l), lengths(l))
    tibble(names = n, variables = unname(unlist(l)))
  }
}

#' matrix_to_tibble
#'
#' Converts a matrix to a tibble without removing rownames.
#'
#' @name matrix_to_tibble
#' @rdname matrix_to_tibble
#' @author Jason T. Serviss
#' @param data matrix; The matrix to be converted.
#' @param rowname character; Length 1 vector indicating the colname that
#'  rownames should have upon tibble conversion.
#' @param drop logical; indicated if rownames should be dropped.
#'  Default = FALSE.
#' @keywords matrix_to_tibble
#' @examples
#'
#' m <- matrix(rnorm(20), ncol = 2, dimnames = list(letters[1:10], LETTERS[1:2]))
#' output <- matrix_to_tibble(m)
#'
#' @export
#' @importFrom tibble as_tibble rownames_to_column
#' @importFrom rlang enquo quo_name "!!" ":="

matrix_to_tibble <- function(data, rowname = "rowname", drop = FALSE) {
  if(!is.matrix(data)) stop("The 'data' argument is not a matrix")
  if(drop) return(as_tibble(data))
  rn.quo <- enquo(rowname)
  rn <- rownames(data)
  if(is.null(rn)) rn <- 1:nrow(data)

  rownames(data) <- NULL

  data %>%
    as.data.frame(stringsAsFactors = FALSE) %>%
    add_column(!! quo_name(rn.quo) := rn, .before = 1) %>%
    as_tibble()
}
