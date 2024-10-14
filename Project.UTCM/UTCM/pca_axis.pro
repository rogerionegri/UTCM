;-----------------------------------------
FUNCTION PCA_AXIS, Samples
  dims = SIZE(Samples, /DIMENSIONS)

  Psi = DBLARR(dims[0])  ;Mean Vector
  FOR i = 0, dims[0]-1 DO Psi[i] = MEAN(Samples[i,*])

  Sigm = DBLARR(dims[0], dims[0]) ;Covariance Matrix
  FOR i = 0, dims[1]-1 DO Sigm[*,*] +=  (Samples[*,i] - Psi[*]) # (Samples[*,i] - Psi[*])
  Sigm =  (1.0/dims[1])*Sigm

  eval = EIGENQL(Sigm, EIGENVECTORS = evec, RESIDUAL = residual)

  sortEVal = REVERSE(SORT(eval))
  pcaEigVecMatrix = Sigm*0D

  ;Sort the covariance matrix according the most relevant eigenvalues
  FOR i = 0, N_ELEMENTS(sortEVal)-1 DO pcaEigVecMatrix[*,i] = evec[*,sortEVal[i]]

  Return, {eivec: pcaEigVecMatrix, eival: eval[sortEVal], mu: psi, sigm: Sigm}
END