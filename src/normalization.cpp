// -*- mode: C++; c-indent-level: 4; c-basic-offset: 4; indent-tabs-mode: nil; -*-

#include "../inst/include/RNAseqFunctions.h"
#include <RcppEigen.h>

// [[Rcpp::depends(RcppEigen)]]

using namespace Rcpp;

//' eigen_cpm
//'
//' Calculates counts per million (cpm) using a gene expression counts matrix
//' as input.
//'
//' @name eigen_cpm
//' @rdname eigen_cpm
//' @keywords internal
//' @aliases eigen_cpm
//' @param counts matrix; a numeric matrix of counts.
//' @return A matrix of cpm values.
//' @author Jason T. Serviss
//' @export
// [[Rcpp::export]]

Eigen::MatrixXd eigen_cpm(const Eigen::MatrixXd counts){
  int nr = counts.rows();
  int nc = counts.cols();
  Eigen::MatrixXd cpm(nr, nc);
  Eigen::VectorXd cs = counts.array().colwise().sum();

  for(int i = 0; i < nr; i++) {
    for(int j = 0; j < nc; j++) {
      cpm(i, j) = counts(i, j) / cs[j] * 1000000;
    }
  }
  return(cpm);
}

//' eigen_log2cpm
//'
//' Calculates log2 counts per million (cpm) using a gene expression counts
//' matrix as input.
//'
//' @name eigen_log2cpm
//' @rdname eigen_log2cpm
//' @keywords internal
//' @aliases eigen_log2cpm
//' @param counts matrix; a numeric matrix of counts.
//' @return A matrix of log2(cpm + 1) values.
//' @author Jason T. Serviss
//' @export
// [[Rcpp::export]]

Eigen::MatrixXd eigen_log2cpm(Eigen::MatrixXd counts){
  int nr = counts.rows();
  int nc = counts.cols();
  Eigen::MatrixXd logcpm(nr, nc);
  Eigen::VectorXd cs = counts.array().colwise().sum();

  for(int i = 0; i < nr; i++) {
    for(int j = 0; j < nc; j++) {
      logcpm(i, j) = log2(counts(i, j) / cs[j] * 1000000 + 1);
    }
  }
  return(logcpm);
}

