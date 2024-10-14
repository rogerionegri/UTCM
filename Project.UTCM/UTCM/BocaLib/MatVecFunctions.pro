;+
; Compilation procedure.
;
PRO MatVecFunctions
END


;+
; Construct a vector containing the values of each pixel, for each class. 
;
; @returns a array of pointers that contains pixel values of each class.
;
; @param Image {in}{required}{type=numeric matrix} image matrix representation.
;
; @param PtrROIs {in}{required}{type=pointer} pointer of a struct with informations about
;        the samples used on the classification process
;-
FUNCTION GET_LABELED_INFO, Image, PtrROIs

Dims = size(Image,/dimension)
NB = Dims[0]  ;# of bands
NC = Dims[1]  ;# of columns
NL = Dims[2]  ;# of lines

SampleClass = PTRARR(N_ELEMENTS(PtrROIs))

FOR i = 0, N_ELEMENTS(PtrROIs)-1 DO BEGIN
   
   AUX = *PtrROIs[i]
   TEMP = FLTARR(NB,N_ELEMENTS(AUX.RoiLex))
   pos = 0L  
   FOR j = 0L, N_ELEMENTS(AUX.RoiLex)-1 DO BEGIN
      Quoc = AUX.Roilex[j]/NC
      Rest = AUX.Roilex[j] MOD NC
      
      ;IF Rest EQ 0 THEN lin = Quoc - 1 ELSE lin = Quoc
      ;IF Rest EQ 0 THEN col = NC ELSE col = Rest - 1
      col = Rest
      lin = Quoc   
      
      TEMP[*,pos] = Image[*,col,lin]
      pos++
   ENDFOR
   
   SampleClass[i] = PTR_NEW(TEMP)
ENDFOR

Return, SampleClass
END


;+
; Join sample values of each class into a same vector representation. 
;
; @returns a array with values of each pixel, independent of class.
; 
; @param SampleClass {in}{required}{type=pointer} pointer to arrays with informations about
;        the pixels of each sample
;-
FUNCTION GET_LABELED_DATA, SampleClass

AUX = *SampleClass[0]
Dim = SIZE(AUX,/DIMENSION)
LabeledData = FLTARR(Dim[0])
FOR i = 0, N_ELEMENTS(SampleClass)-1 DO LabeledData = [[*SampleClass[i]],[LabeledData]]

LabeledData = LabeledData[*,0:N_ELEMENTS(LabeledData[0,*])-2]

Return, LabeledData
END


;+
; Colapse all pixel of a image into a vector. 
;
; @returns a vector from a image read in lexicographic order.
; 
; @param Image {in}{required}{type=numeric matrix} image matrix representation.
;-
FUNCTION GET_ALL_DATA, Image

Dims = size(Image,/dimension)
NB = Dims[0]  ;# of bands
NC = Dims[1]  ;# of columns
NL = Dims[2]  ;# of lines

AllData = FLTARR(NB,NC*NL)
Count = 0L
FOR j = 0L, NL-1 DO BEGIN
   FOR i = 0L, NC-1 DO BEGIN
      AllData[*,Count] = Image[*,i,j]
      Count++  
   ENDFOR
ENDFOR 

Return, AllData
END

;+
; Compute a n-dimensional mean vector for each class for a given vector os samples.
; Each dimension is a data attribute.  
;
; @returns a matrix (Kxn) with a mean n-dimensional vector about each K class.
; 
; @param SampleClass {in}{required}{type=pointer} pointer to vectors with sample information.
;-
FUNCTION GET_MU_VECTOR, SampleClass
AUX = *SampleClass[0]
Dim = SIZE(AUX,/DIMENSION)
Mu = FLTARR(N_ELEMENTS(SampleClass), Dim[0])
FOR i = 0, N_ELEMENTS(SampleClass)-1 DO BEGIN
   Samples = *SampleClass[i]
   MuTemp = FLTARR(Dim[0])
   FOR j = 0, Dim[0]-1 DO MuTemp[j] = TOTAL(Samples[j,*])/FLOAT(N_ELEMENTS(Samples[j,*])) 
   Mu[i,*] = MuTemp
ENDFOR

Return, Mu
END


;+
; Compute a n-dimensional standard deviation vector for each class for a given vector os samples.
; Each dimension is a data attribute.  
;
; @returns a matrix (Kxn) with a standard deviation n-dimensional vector about each K class.
; 
; @param SampleClass {in}{required}{type=pointer} pointer to vectors with sample information.
;-
FUNCTION GET_SIGMA_VECTOR, SampleClass

Mu = GET_MU_VECTOR(SampleClass)
Dim = SIZE(*SampleClass[0],/DIMENSION)
Sigma = FLTARR(N_ELEMENTS(SampleClass), Dim[0])
FOR i = 0, N_ELEMENTS(SampleClass)-1 DO BEGIN
   Samples = *SampleClass[i]
   SigmaTemp = FLTARR(Dim[0])
   FOR j = 0, Dim[0]-1 DO BEGIN
      FOR k = 0, N_ELEMENTS(Samples[j,*])-1 DO BEGIN
         SigmaTemp[j] += (Samples[j,k] - Mu[i,j])^2
      ENDFOR
      SigmaTemp[j] = SQRT(SigmaTemp[j]/FLOAT(N_ELEMENTS(Samples[j,*])))
   ENDFOR 
   Sigma[i,*] = SigmaTemp
ENDFOR

Return, Sigma
END


;+
; Compute a n-square covariance matrix about the samples.
;
; @returns a n-square covariance matrix (Kxnxn) about the K classes.
; 
; @param SampleClass {in}{required}{type=pointer} pointer to vectors with sample information.
;-
FUNCTION GET_SIGMA_MATRIX, SampleClass
AUX = *SampleClass[0]
Dim = SIZE(AUX,/DIMENSION)
Sigm = DBLARR(Dim[0], Dim[0],N_ELEMENTS(SampleClass))

FOR i = 0L, N_ELEMENTS(SampleClass)-1 DO BEGIN
   Samples = *SampleClass[i]
   MuTemp = DBLARR(Dim[0])
   FOR j = 0L, Dim[0]-1 DO MuTemp[j] = TOTAL(Samples[j,*])/FLOAT(N_ELEMENTS(Samples[j,*]))
   SampleMu = Samples
   SigmTemp = DBLARR(Dim[0],Dim[0])
   FOR j = 0L, N_ELEMENTS(Samples[0,*])-1 DO SampleMu[*,j] = Samples[*,j] - MuTemp[*]
   FOR j = 0L, N_ELEMENTS(Samples[0,*])-1 DO SigmTemp += SampleMu[*,j]##(SampleMu[*,j])
   Sigm[*,*,i] = SigmTemp/FLOAT(N_ELEMENTS(Samples[0,*]))
ENDFOR

Return, Sigm
END


;+
; Transform a vector to matrix.
;
; @returns a nxNCxNL matrix
; 
; @param U {in}{required}{type=numeric}  nx(NC*NL) vector image representation
; @param NC, NL {in}{required}{type=numeric} number of columns an lines of the 
;        image on the matrix representation 
;-
FUNCTION VECTOR_TO_RULEIMAGE, U, NC, NL
;U = (points,attributes)
RuleImage = FLTARR(N_ELEMENTS(U[0,*]),NC,NL)

FOR i = 0L, N_ELEMENTS(U[*,0])-1 DO BEGIN
   lin = FIX(i/NC)
   col = (i MOD NC)   
   RuleImage[*,col,lin] = U[i,*]
ENDFOR

Return, RuleImage
END