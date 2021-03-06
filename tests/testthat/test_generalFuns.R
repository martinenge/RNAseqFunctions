context("generalFuns")

test_that("check that namedListToTibble outputs the expected result", {
  expected <- tibble::tibble(
    names = rep(letters[1:2], each = 10),
    variables = 1:20
  )
  output <- namedListToTibble(list(a = 1:10, b = 11:20))
  expect_identical(output, expected)

  input <- list(A = list(a = 1, b = 2), B = list(c = 3, d = 4))
  expected <- tibble(
    names = rep(c("A", "B"), each = 2),
    inner.names = letters[1:4],
    variables = as.numeric(1:4)
  )
  output <- namedListToTibble(input)
  expect_identical(output, expected)

  input <- list(
    list(a = 1:10, b = 11:20),
    list(c = 21:30, d = 31:40)
  )
  expect_error(namedListToTibble(input))
})

test_that("check that matrix_to_tibble outputs the expected result", {
  input <- matrix(1:10, ncol = 2, dimnames = list(letters[1:5], LETTERS[1:2]))
  expected <- tibble::tibble(rowname = letters[1:5], A = 1:5, B = 6:10)
  output <- matrix_to_tibble(input)
  expect_identical(output, expected)

  input <- matrix(1:10, ncol = 2, dimnames = list(letters[1:5], LETTERS[1:2]))
  expected <- tibble::tibble(A = 1:5, B = 6:10)
  output <- matrix_to_tibble(input, drop = TRUE)
  expect_identical(output, expected)

  input <- matrix(1:10, ncol = 2, dimnames = list(NULL, LETTERS[1:2]))
  expected <- tibble::tibble(rowname = 1:5, A = 1:5, B = 6:10)
  output <- matrix_to_tibble(input)
  expect_identical(output, expected)

  input <- data.frame(A = 1:5, B = 6:10, row.names = letters[1:5])
  expect_error(matrix_to_tibble(input))
})
