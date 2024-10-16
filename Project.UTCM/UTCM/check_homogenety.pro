;#######################################################
FUNCTION CHECK_HOMOGENETY, Image, ptrBlocks, alpha

   dims = GET_DIMENSIONS(Image)
   Attributes = max([ 1 , dims[0] ])   ;Attributes = dims[0]

   ;Degree of freedom: n for mean vector + n for diagonal of cov matrix + (n*(n-1)/2) for covariances
   n = Attributes
   df = n*(n+3)/2

   blockConditions = INTARR(N_ELEMENTS(ptrBlocks))
   blockDis = FLTARR(N_ELEMENTS(ptrBlocks))

   FOR i = 0L, N_ELEMENTS(ptrBlocks)-1 DO BEGIN
      block = *ptrBlocks[i]

      focus = block.focus
      nFocus = N_ELEMENTS(focus[0,*])
      ParFocus = GET_PARAMETERS_FROM_BLOCK_UNIDIMENSIONAL(Image, focus)
      

      regions = block.regs
      condition = 1
      FOR j = 0L, N_ELEMENTS(regions)-1 DO BEGIN
         reg = *regions[j]
         nReg = N_ELEMENTS(reg[0,*])
         
         ParReg = GET_PARAMETERS_FROM_BLOCK_UNIDIMENSIONAL(Image, reg)

         dis = BHATTACHARYYA_UNIDIMENSIONAL(ParFocus.Mu, ParReg.Mu, ParFocus.Sigma, ParReg.Sigma)

         stat = 8.0*((1.0*nFocus*nReg)/(nFocus+nReg))*dis
         IF ~finite(stat) THEN stat = 10.0^10

         Pr = CHISQR_PDF(stat, df) ;<<< idl's built-in function
         blockDis[i] += dis

         IF (1.0D - Pr) LE alpha THEN BEGIN
            condition = 0
            break
         ENDIF
      ENDFOR

      blockConditions[i] = condition
   ENDFOR

   structImageCondDist = BUILD_IMAGE_DISTS(blockDis, blockConditions, ptrBlocks, Image)

   Return, {imageConditions: structImageCondDist.imageConditions, imageDistances: structImageCondDist.imageDistances, blockConditions: blockConditions}
END




;#####################################################
FUNCTION GET_PARAMETERS_FROM_BLOCK_UNIDIMENSIONAL, Image, Reg

  nLex = N_ELEMENTS(Reg[0,*])
  Samples = DBLARR(nLex)
  FOR ind = 0L, nLex-1 DO Samples[ind] = Image[Reg[0,ind],Reg[1,ind]]

  ;Compute the multivariate gaussian parameters
  mu = mean(Samples)
  sigma = max( [variance(Samples) , 0.000001] )

  Return, {Mu: mu, Sigma: Sigma}
END




;#####################################################
FUNCTION GET_PARAMETERS_FROM_BLOCK, Image, Reg

   nLex = N_ELEMENTS(Reg[0,*])
   Samples = DBLARR(N_ELEMENTS(Image[*,0,0]),nLex)
   FOR ind = 0L, nLex-1 DO Samples[*,ind] = Image[*,Reg[0,ind],Reg[1,ind]]

   ;Compute the multivariate gaussian parameters
   MeanVec = MEAN_VECTOR(Samples)
   SigMatrix = COVARIANCE_MATRIX(Samples)

   InvSigma = INVERT(SigMatrix, Status, /DOUBLE)
   WHILE Status DO BEGIN
      print, 'Singular matrix found... try small changes for conditioning'
      auxxx = RANDOMU(SYSTIME(/SECONDS),N_ELEMENTS(SigMatrix[*,0])) * 0.01
      SigMatrix += (auxxx ## auxxx)
      InvSigma = INVERT(SigMatrix, Status, /DOUBLE)
   ENDWHILE

   Return, {Mu: MeanVec, Sigma: SigMatrix, InvSigma: InvSigma}
END


;#####################################################
FUNCTION BUILD_IMAGE_DISTS, dists, conditions, ptrBlocks, Image

   dims = GET_DIMENSIONS(Image)
   ImgDists = DBLARR(dims[1],dims[2])
   ImgConds = INTARR(dims[1],dims[2])
   FOR i = 0L, N_ELEMENTS(dists)-1 DO BEGIN
      block = *ptrBlocks[i]
      reg = block.focus
      FOR j = 0L, N_ELEMENTS(reg[0,*])-1 DO BEGIN
         ImgDists[reg[0,j],reg[1,j]] = dists[i]
         ImgConds[reg[0,j],reg[1,j]] = conditions[i]
      ENDFOR
   ENDFOR

   Return, {imageConditions: ImgConds, imageDistances: ImgDists}
END
