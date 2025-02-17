#### "ldenseMatrix" - virtual class of logical dense matrices
####  ------------
#### Contains  lge*;  ltr*, ltp*;  lsy*, lsp*;	 ldi*

### NOTA BENE: Much of this is *very* parallel to ./ndenseMatrix.R
###						  ~~~~~~~~~~~~~~~~

## packed <->  non-packed :

setAs("lspMatrix", "lsyMatrix",					##  vv for "l*", 1L for "n*"
      lsp2lsy <- function(from) .Call(lspMatrix_as_lsyMatrix, from, 0L))

setAs("lsyMatrix", "lspMatrix",
      lsy2lsp <- function(from) .Call(lsyMatrix_as_lspMatrix, from, 0L))

setAs("ltpMatrix", "ltrMatrix",
      ltp2ltr <- function(from) .Call(ltpMatrix_as_ltrMatrix, from, 0L))

setAs("ltrMatrix", "ltpMatrix",
      ltr2ltp <- function(from) .Call(ltrMatrix_as_ltpMatrix, from, 0L))


## Logical -> Double {of same structure}:

setAs("lgeMatrix", "dgeMatrix", function(from) l2d_Matrix(from, "lgeMatrix"))
setAs("lsyMatrix", "dsyMatrix", function(from) l2d_Matrix(from, "lsyMatrix"))
setAs("lspMatrix", "dspMatrix", function(from) l2d_Matrix(from, "lspMatrix"))
setAs("ltrMatrix", "dtrMatrix", function(from) l2d_Matrix(from, "ltrMatrix"))
setAs("ltpMatrix", "dtpMatrix", function(from) l2d_Matrix(from, "ltpMatrix"))

## all need be coercable to "lgeMatrix":

setAs("lsyMatrix", "lgeMatrix",
      lsy2lge <- function(from) .Call(lsyMatrix_as_lgeMatrix, from, 0L))
setAs("ltrMatrix", "lgeMatrix",
      ltr2lge <- function(from) .Call(ltrMatrix_as_lgeMatrix, from, 0L))
setAs("ltpMatrix", "lgeMatrix", function(from) ltr2lge(ltp2ltr(from)))
setAs("lspMatrix", "lgeMatrix", function(from) lsy2lge(lsp2lsy(from)))
## and the reverse
setAs("lgeMatrix", "ltpMatrix", function(from) ltr2ltp(as(from, "ltrMatrix")))
setAs("lgeMatrix", "lspMatrix", function(from) lsy2lsp(as(from, "lsyMatrix")))



### -> symmetric :

setAs("lgeMatrix", "lsyMatrix",
      function(from) {
	  if(isSymmetric(from))
	      new("lsyMatrix", x = from@x, Dim = from@Dim,
		  Dimnames = from@Dimnames, factors = from@factors)
	  else
	      stop("not a symmetric matrix; consider forceSymmetric() or symmpart()")
      })

setAs("lgeMatrix", "ltrMatrix",
      function(from) {
	  if(isT <- isTriangular(from))
	      new("ltrMatrix", x = from@x, Dim = from@Dim,
		  Dimnames = from@Dimnames, uplo = attr(isT, "kind") %||% "U")
	  ## TODO: also check 'diag'
	  else stop("not a triangular matrix")
      })


###  ldense* <-> "matrix" :

## 1) "lge* :
setAs("lgeMatrix", "matrix", ge2mat)

setAs("matrix", "lgeMatrix",
      function(from) {
	  new("lgeMatrix",
	      x = as.logical(from),
	      Dim = as.integer(dim(from)),
	      Dimnames = .M.DN(from))
      })

## 2) base others on "lge*":

setAs("matrix", "lsyMatrix",
      function(from) as(as(from, "lgeMatrix"), "lsyMatrix"))
setAs("matrix", "lspMatrix", function(from) lsy2lsp(as(from, "lsyMatrix")))
setAs("matrix", "ltrMatrix",
      function(from) as(as(from, "lgeMatrix"), "ltrMatrix"))
setAs("matrix", "ltpMatrix", function(from) ltr2ltp(as(from, "ltrMatrix")))

## Useful if this was called e.g. for as(*, "lsyMatrix"), but it isn't
setAs("matrix", "ldenseMatrix", function(from) as(from, "lgeMatrix"))

setAs("ldenseMatrix", "matrix", ## uses the above l*M. -> lgeM.
      function(from) as(as(from, "lgeMatrix"), "matrix"))

## dense |-> compressed :

setAs("lgeMatrix", "lgTMatrix",
      function(from) as(.dense2C(from, kind = "gen"), "lgTMatrix"))

setAs("lgeMatrix", "lgCMatrix", # TODO: need as(*, ..) ?
      function(from) as(.dense2C(from, kind = "gen"), "lgCMatrix"))

setMethod("as.logical", signature(x = "ldenseMatrix"),
	  function(x, ...) as(x, "lgeMatrix")@x)

###----------------------------------------------------------------------

setMethod("diag", signature(x = "lgeMatrix"), .mkSpec.diag(quote(lgeMatrix_getDiag)))

setMethod("diag", signature(x = "lsyMatrix"), .mkSpec.diag(quote(lgeMatrix_getDiag)))

setMethod("diag", signature(x = "ltrMatrix"), .mkSpec.diag(quote(ltrMatrix_getDiag)))

for (.x.cl in sprintf("n%sMatrix", c("ge", "sy", "tr"))) {
    setMethod("diag", signature(x = .x.cl),# << the "same"
              function(x, nrow, ncol, names) {
                  diag(as(x, "ldenseMatrix"), names = names)
              })
}
rm(.x.cl)

## MJ: No longer needed ... replacement in ./packedMatrix.R
if (FALSE) {
setMethod("diag", signature(x = "lspMatrix"), .mkSpec.diag(quote(lspMatrix_getDiag)))
setMethod("diag", signature(x = "ltpMatrix"), .mkSpec.diag(quote(ltpMatrix_getDiag)))
## MJ: Still used for unpacked "ndenseMatrix", but no longer for packed!
setMethod("diag", signature(x = "ndenseMatrix"),# << the "same"
          function(x, nrow, ncol) diag(as(x, "ldenseMatrix")))
}

## --- *SETTING* of diagonal :  diag(x) <- value ---------
## --- =====================   faster than default  x[cbind[c(i,i)]] <- value
setMethod("diag<-", signature(x = "lgeMatrix"),
	  function(x, value) .Call(lgeMatrix_setDiag, x, value))
setMethod("diag<-", signature(x = "lsyMatrix"),
	  function(x, value) .Call(lgeMatrix_setDiag, x, value))
.diag.set.ltr <- function(x, value) {
    .Call(ltrMatrix_setDiag,
          if(x@diag == "U") .dense.diagU2N(x, "l", isPacked=FALSE) else x,
          value)
}
setMethod("diag<-", signature(x = "ltrMatrix"), .diag.set.ltr)

## the *same* for the  "ndenseMatrix" elements:
setMethod("diag<-", signature(x = "ngeMatrix"),
	  function(x, value) .Call(lgeMatrix_setDiag, x, value))
setMethod("diag<-", signature(x = "nsyMatrix"),
	  function(x, value) .Call(lgeMatrix_setDiag, x, value))
setMethod("diag<-", signature(x = "ntrMatrix"), .diag.set.ltr)
rm(.diag.set.ltr)


# MJ: No longer needed ... replacement in ./packedMatrix.R
if (FALSE) {
setMethod("diag<-", signature(x = "lspMatrix"),
	  function(x, value) .Call(lspMatrix_setDiag, x, value))
.diag.set.ltp <- function(x, value) {
    .Call(ltpMatrix_setDiag,
          if(x@diag == "U") .dense.diagU2N(x, "l", isPacked=TRUE) else x,
          value)
}
setMethod("diag<-", signature(x = "ltpMatrix"), .diag.set.ltp)
setMethod("diag<-", signature(x = "nspMatrix"),
	  function(x, value) .Call(lspMatrix_setDiag, x, value))
setMethod("diag<-", signature(x = "ntpMatrix"), .diag.set.ltp)
rm(.diag.set.ltp)
}


setMethod("t", signature(x = "lgeMatrix"), t_geMatrix)
setMethod("t", signature(x = "ltrMatrix"), t_trMatrix)
setMethod("t", signature(x = "lsyMatrix"), t_trMatrix)

## MJ: No longer needed ... replacement in ./packedMatrix.R
if (FALSE) {
setMethod("t", signature(x = "ltpMatrix"),
	  function(x) as(t(as(x, "ltrMatrix")), "ltpMatrix"))
setMethod("t", signature(x = "lspMatrix"),
	  function(x) as(t(as(x, "lsyMatrix")), "lspMatrix"))
}

## NOTE:  "&" and "|"  are now in group "Logic" c "Ops" --> ./Ops.R
##        "!" is in ./not.R

setMethod("as.vector", "ldenseMatrix",
	  function(x, mode) as.vector(as(x, "lgeMatrix")@x, mode))

setMethod("norm", signature(x = "ldenseMatrix", type = "character"),
	  function(x, type, ...)
	      if(identical("2", type))
		  norm2(x)
	      else
		  .Call(dgeMatrix_norm, as(as(x,"dMatrix"),"dgeMatrix"), type),
	  valueClass = "numeric")

.rcond_via_d <- function(x, norm, ...)
    rcond(as(as(x, "dMatrix"), "dgeMatrix"), norm=norm, ...)


setMethod("rcond", signature(x = "ldenseMatrix", norm = "character"),
	  .rcond_via_d, valueClass = "numeric")

