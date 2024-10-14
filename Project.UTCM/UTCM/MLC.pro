@ascii_read_roi.pro
@ClassificationFunctions.pro
@ImageFunctions.pro
@MatVecFunctions.pro
@MeasureFunctions.pro
@ProbabilityFunctions.pro
;@RoiFunctions.pro


;+
; This function performs classification following the Maximum Likelihood Classification method.
;
; @returns a classification structure (based on SLIC definitions) with the fields:
;          Index -- a byte (KxCxL) matrix, where K, C and L are the number of
;                   classes in PntROIs, columns and lines of Image, respectively.
;
;          Classification -- a byte (3xCxL) matrix representing color classification result. 
;
;          RuleImage -- a floating-point (KxCxL) matrix, where K, C and L are the
;                   number of classes in PntROIs, columns and lines of Image, respectively.
;
; @param Image {in}{required}{type=numeric} is a numeric (BxCxL) matrix, where B, C and L
;          are the number bands, columns and lines, respectively.
;
; @param PntROIs {in}{required}{type=pointer} is a K-component vector of pointers
;          to a sample structure (based on SLIC definitions) with training data informations.
;-
FUNCTION MLC, Image, PntROIs

Dims = GET_DIMENSIONS(Image)

;Classification step
SampleClass = GET_LABELED_INFO(Image, PntROIs)
Mu = GET_MU_VECTOR(SampleClass)
Sigma = GET_SIGMA_MATRIX(SampleClass)

RuleImage = FLTARR(N_ELEMENTS(PntROIs),Dims[1],Dims[2])

FOR i = 0, Dims[1]-1 DO BEGIN
   FOR j = 0, Dims[2]-1 DO BEGIN
      FOR k = 0, N_ELEMENTS(PntROIs)-1 DO RuleImage[k,i,j] = MULTIV_GAUSS(Image[*,i,j], Mu[k,*], Sigma[*,*,k])
      
      RuleImage[*,i,j] /= TOTAL(RuleImage[*,i,j], /DOUBLE)
      FOR k = 0, N_ELEMENTS(PntROIs)-1 DO IF FINITE(RuleImage[k,i,j]) EQ 0 THEN RuleImage[k,i,j] = 0.0 

   ENDFOR
ENDFOR

Index = MAX_RULE_TO_INDEX(RuleImage)
Classification = COLORIZE_INDEX(Index, PntROIs)

Return, {Index: Index, Classification: Classification, RuleImage: FLOAT(RuleImage)}
END


;+
; This is an auxiliar function for MLC function.
;
; @returns a byte (CxL) matrix with the index classification representation in {1,...,K},
;          where K, C and L are the number of classes, columns and lines of the RuleImage, respectively.
;
; @param RuleImage {in}{required}{type=numeric} is a floating-point (KxCxL) matrix, where K, C and L
;          are the number classes, columns and lines in the original classification problem, respectively.
;-
FUNCTION MAX_RULE_TO_INDEX, RuleImage

Dim = GET_DIMENSIONS(RuleImage)
Index = BYTARR(Dim[1],Dim[2])
FOR i = 0, Dim[1]-1 DO BEGIN
   FOR j = 0, Dim[2]-1 DO BEGIN
      ind = BYTE(WHERE(RuleIMage[*,i,j] EQ MAX(RuleIMage[*,i,j])))
      Index[i,j] = ind[0]
   ENDFOR
ENDFOR

Return, Index
END