### Coercion and Methods for Symmetric Packed Matrices

dsp2dsy <- function(from) .Call(dspMatrix_as_dsyMatrix, from)
dsp2C <- function(from) dsy2C(.Call(dspMatrix_as_dsyMatrix, from))
setAs("dspMatrix", "dsyMatrix", dsp2dsy)
## setAs("dspMatrix", "dsCMatrix", dsp2C)
setAs("dspMatrix", "CsparseMatrix", dsp2C)
setAs("dspMatrix", "sparseMatrix", dsp2C)

## dge <--> dsp   via  dsy
.dense2sp <- function(from) .dsy2dsp(.dense2sy(from))
setAs("dgeMatrix", "dspMatrix", .dense2sp)
setAs("matrix", "dspMatrix",
      function(from) .dense2sp(..2dge(from)))
## S3-matrix <--> dsp   via  dsy
setAs("dspMatrix", "matrix", function(from) .dsy2mat(dsp2dsy(from)))



setMethod("rcond", signature(x = "dspMatrix", norm = "character"),
          function(x, norm, ...)
          .Call(dspMatrix_rcond, x, norm),
          valueClass = "numeric")

setMethod("rcond", signature(x = "dspMatrix", norm = "missing"),
          function(x, norm, ...)
          .Call(dspMatrix_rcond, x, "O"),
          valueClass = "numeric")

setMethod("BunchKaufman", signature(x = "dspMatrix"),
	  function(x, ...) .Call(dspMatrix_trf, x))

## Should define multiplication from the right

setMethod("solve", signature(a = "dspMatrix", b = "missing"),
	  function(a, b, ...) .Call(dspMatrix_solve, a),
	  valueClass = "dspMatrix")

setMethod("solve", signature(a = "dspMatrix", b = "matrix"),
	  function(a, b, ...) .Call(dspMatrix_matrix_solve, a, b),
	  valueClass = "dgeMatrix")

setMethod("solve", signature(a = "dspMatrix", b = "ddenseMatrix"),
	  function(a, b, ...) .Call(dspMatrix_matrix_solve, a, b),
	  valueClass = "dgeMatrix")

##setMethod("solve", signature(a = "dspMatrix", b = "numeric"),
##	  function(a, b, ...)
##	  .Call(dspMatrix_matrix_solve, a, as.matrix(b)),
##	  valueClass = "dgeMatrix")

## No longer needed
## setMethod("solve", signature(a = "dspMatrix", b = "integer"),
## 	  function(a, b, ...) {
## 	      storage.mode(b) <- "double"
## 	      .Call(dspMatrix_matrix_solve, a, as.matrix(b))
## 	  }, valueClass = "dgeMatrix")

setMethod("norm", signature(x = "dspMatrix", type = "character"),
	  function(x, type, ...)
	      if(identical("2", type)) norm2(x) else .Call(dspMatrix_norm, x, type),
          valueClass = "numeric")

setMethod("norm", signature(x = "dspMatrix", type = "missing"),
          function(x, type, ...) .Call(dspMatrix_norm, x, "O"),
          valueClass = "numeric")

if(FALSE) { ## MJ: No longer needed ... replacement in ./packedMatrix.R
setMethod("t", signature(x = "dspMatrix"),
          function(x) .dsy2dsp(t(dsp2dsy(x))), # FIXME inefficient
          valueClass = "dspMatrix")

setMethod("diag", signature(x = "dspMatrix"),
	  function(x, nrow, ncol) .Call(dspMatrix_getDiag, x))
setMethod("diag<-", signature(x = "dspMatrix"),
	  function(x, value) .Call(dspMatrix_setDiag, x, value))
}##
