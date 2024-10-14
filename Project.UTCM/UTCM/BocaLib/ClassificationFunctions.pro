;+
; Compilation procedure.
;
PRO ClassificationFunctions
END

;+
; Transform a (KxMxN) rule matrix to a classification image. 
;
; @returns (3xMxN) image classification results.
;
; @param RuleImage {in}{required}{type=numeric matrix} matrix with classification rules
; 
; @param PtrROIs {in}{required}{type=pointer} pointer of a struct with informations about
;        the samples used on the classification process
;-
FUNCTION CLASSIF, RuleImage, PtrROIs

ClaImage = INTARR(3,N_ELEMENTS(RuleImage[0,*,0]),N_ELEMENTS(RuleImage[0,0,*]))

FOR i = 0, N_ELEMENTS(RuleImage[0,*,0])-1 DO BEGIN
   FOR j = 0, N_ELEMENTS(RuleImage[0,0,*])-1 DO BEGIN
      Index = WHERE(RuleImage[*,i,j] EQ MAX(RuleImage[*,i,j]))
      Roi = *PtrROIs[Index[0]]
      ClaImage[*,i,j] = Roi.RoiColor
   ENDFOR
ENDFOR

Return, ClaImage
END

;+
; Transform a classification result (3xMxN), where each element is a 3d-array that define
; the color class, to a index resulr (1xMxN), where each element represent the class index. 
;
; @returns (1xMxN) image classification index.
;
; @param ClaImage {in}{required}{type=numeric matrix} matrix with color classification values 
; 
; @param PtrROIs {in}{required}{type=pointer} pointer of a struct with informations about
;        the samples used on the classification process
;-
FUNCTION CLASSIF_INDEX, ClaImage, PtrROIs

Dim = SIZE(ClaImage,/DIMENSION)
IndexImage = INTARR(Dim[1],Dim[2])

ColorVec = INTARR(3,N_ELEMENTS(PtrROIs))

FOR i = 0, N_ELEMENTS(PtrROIs)-1 DO BEGIN
   AUX = *PtrROIs[i]
   ColorVec[*,i] = AUX.RoiColor
ENDFOR

FOR i = 0, Dim[1]-1 DO BEGIN
   FOR j = 0, Dim[2]-1 DO BEGIN
      Index = -1
      REPEAT BEGIN
         Index++
         Val = NORM(ClaImage[*,i,j] - ColorVec[*,Index])         
      ENDREP UNTIL (Val EQ 0)
      IndexImage[i,j] = Index
   ENDFOR
ENDFOR

Return, IndexImage
END


;+
; Classify a rule image given a threshold produced. Each element is classified as the class 
; with the great rule value, since this value is greater than a threshold.
;
; @returns (3xMxN) image classified
;
; @param RuleImage {in}{required}{type=numeric matrix} matrix with classification rules
; 
; @param PtrROIs {in}{required}{type=pointer} pointer of a struct with informations about
;        the samples used on the classification process
; @param Rate {in}{required}{type=numeric} is a threshold (level of confiance) of classification
;-
FUNCTION CLASSIF_RATE, RuleImage, PtrROIs, Rate

ClaImage = INTARR(3,N_ELEMENTS(RuleImage[0,*,0]),N_ELEMENTS(RuleImage[0,0,*]))

FOR i = 0, N_ELEMENTS(RuleImage[0,*,0])-1 DO BEGIN
   FOR j = 0, N_ELEMENTS(RuleImage[0,0,*])-1 DO BEGIN
      IF(MAX(RuleImage[*,i,j]) LT Rate) THEN ClaImage[*,i,j] = [0,0,0] $
      ELSE BEGIN 
         Index = WHERE(RuleImage[*,i,j] EQ MAX(RuleImage[*,i,j]))
         Roi = *PtrROIs[Index[0]]
         ClaImage[*,i,j] = Roi.RoiColor
      ENDELSE
   ENDFOR
ENDFOR

Return, ClaImage
END


;+
; Classify a rule image (kxMxN) on a unsupervised way (without class informations). Each element
; is classified following the greatest k rule value. The color associated is based on the TEKTRONIX palet.
;
; @returns (3xMxN) image classified
;
; @param RuleImage {in}{required}{type=numeric matrix} matrix with classification rules
; 
; @param Rate {in}{required}{type=numeric} is a threshold (level of confiance) of classification
;-
FUNCTION UNSUPERVISED_FUZZY_CLASSIFICATION, RuleImage, Rate

ClaImage = INTARR(3,N_ELEMENTS(RuleImage[0,*,0]),N_ELEMENTS(RuleImage[0,0,*]))
FOR i = 0, N_ELEMENTS(RuleImage[0,*,0])-1 DO BEGIN
   FOR j = 0, N_ELEMENTS(RuleImage[0,0,*])-1 DO BEGIN
      IF(MAX(RuleImage[*,i,j]) LT Rate) THEN ClaImage[*,i,j] = [0,0,0] $
      ELSE BEGIN 
         Index = WHERE(RuleImage[*,i,j] EQ MAX(RuleImage[*,i,j]))
         if index eq -1 then Index = 0 ;Default value...
         ClaImage[*,i,j] = TEKTRONIX(Index)
      ENDELSE
   ENDFOR
ENDFOR

Return, ClaImage
END



;+
; Build a index image from a Rule Image (kxMxN). The index assigned for each element/pixel is
;         based on the index of the greater value found for that element position in the Rule Image.
;
; @returns (MxN) index image classification.
;
; @param RuleImage {in}{required}{type=numeric matrix} matrix with classification rules
; 
; @param Rate {in}{required}{type=numeric} is a threshold (level of confiance) of classification
;-
FUNCTION UNSUPERVISED_CLASSIFICATION_INDEX, RuleImage

IndexImage = INTARR(N_ELEMENTS(RuleImage[0,*,0]),N_ELEMENTS(RuleImage[0,0,*]))
FOR i = 0, N_ELEMENTS(RuleImage[0,*,0])-1 DO BEGIN
   FOR j = 0, N_ELEMENTS(RuleImage[0,0,*])-1 DO BEGIN
      Index = WHERE(RuleImage[*,i,j] EQ MAX(RuleImage[*,i,j]))
      
      IF N_ELEMENTS(Index) EQ 1 THEN IndexImage[i,j] = Index ELSE BEGIN
         rand = SORT(RANDOMU(LONG(SYSTIME(/SECONDS)*(i+1)*(j+1) MOD 1000000L), N_ELEMENTS(Index))) 
         IndexImage[i,j] = Index[rand[0]]
      ENDELSE     
      
   ENDFOR
ENDFOR

Return, IndexImage
END




;+
; Transform a (1xMxN) index classification matrix into a classification matrix.
;
; @returns (3xMxN) image classification results.
;
; @param IndexImage {in}{required}{type=numeric matrix} matrix with classification index
; 
; @param PtrROIs {in}{required}{type=pointer} pointer of a struct with informations about
;        the samples used on the classification process
;-
FUNCTION COLORIZE_INDEX, IndexImage, PntROIs

Dims = size(IndexImage,/dimension)
NC = Dims[0]
NL = Dims[1]
ClaImage = BYTARR(3,NC,NL)

FOR i = 0, NC-1 DO BEGIN
   FOR j = 0, NL-1 DO BEGIN
      Index = IndexImage[i,j]
      Temp = *PntROIs[INDEX[0]]
      ClaImage[*,i,j] = TEMP.RoiCOLOR
   ENDFOR
ENDFOR

Return, ClaImage
END


;+
; Return a triplet color vector (i.e. 8-bits [RGB] vector) for a given index (0..29), based on
; the TEKTRONIX color palet
;
; @returns 8-bits tridimensional vector.
;
; @param Index {in}{required}{type=numeric integer} palet color index.
;-
FUNCTION TEKTRONIX, Index
;R = [0,100,100,0,0,0,100,100,100,60,0,0,55,100,33,67,100,75,45,17,25,50,75,100,67,40,17,17,17,45,75,90]
;G = [0,100,0,100,0,100,0,100,50,83,100,50,0,0,33,67,100,100,100,100,83,67,55,33,90,90,90,67,50,33,17,9]
;B = [0,100,0,0,100,100,83,0,0,0,60,100,83,55,33,67,33,45,60,75,83,83,83,90,45,55,67,90,100,100,100,100]

R = [100,0,0,0,100,100,100,60,0,0,55,100,33,67,100,75,45,17,25,50,75,100,67,40,17,17,17,45,75,90]
G = [0,100,0,100,0,100,50,83,100,50,0,0,33,67,100,100,100,100,83,67,55,33,90,90,90,67,50,33,17,9]
B = [0,0,100,100,83,0,0,0,60,100,83,55,33,67,33,45,60,75,83,83,83,90,45,55,67,90,100,100,100,100]

Return, [(R[Index]*255)/100, (G[Index]*255)/100, (B[Index]*255)/100]
END


FUNCTION TEKTRONIX_INDEXCOLOR, Index
R = [100,0,0,0,100,100,100,60,0,0,55,100,33,67,100,75,45,17,25,50,75,100,67,40,17,17,17,45,75,90]
G = [0,100,0,100,0,100,50,83,100,50,0,0,33,67,100,100,100,100,83,67,55,33,90,90,90,67,50,33,17,9]
B = [0,0,100,100,83,0,0,0,60,100,83,55,33,67,33,45,60,75,83,83,83,90,45,55,67,90,100,100,100,100]

Return, R[Index] + 256L*G[Index] + (256L*256L)*B[Index]
END


FUNCTION TEKTRONIX_V2, Index
  R = [100,0,0,0,100,100,100,60,0,0,55,100,33,67,100,75,45,17,25,50,75,100,67,40,17,17,17,45,75,90]
  G = [0,100,0,100,0,100,50,83,100,50,0,0,33,67,100,100,100,100,83,67,55,33,90,90,90,67,50,33,17,9]
  B = [0,0,100,100,83,0,0,0,60,100,83,55,33,67,33,45,60,75,83,83,83,90,45,55,67,90,100,100,100,100]

  cla = BYTARR(3,N_ELEMENTS(Index[*,0]),N_ELEMENTS(Index[0,*]))
  cla[0,*,*] = (R[Index]*255)/100
  cla[1,*,*] = (G[Index]*255)/100
  cla[2,*,*] = (B[Index]*255)/100
  
  Return, cla
END



;+
; Transform a classification result (3xMxN), where each element is a 3d-array that define
; the color class, to a index resulr (1xMxN), where each element represent the class index.
; Is a faster version of 'CLASSIF_INDEX'
;
; @returns (1xMxN) image classification index.
;
; @param ClaImage {in}{required}{type=numeric matrix} matrix with color classification values 
; 
; @param PtrROIs {in}{required}{type=pointer} pointer of a struct with informations about
;        the samples used on the classification process
;-
FUNCTION CLASSIMAGE_TO_INDEX, ClaImage, PntROIs 

Dim = GET_DIMENSIONS(ClaImage)
IndexImage = INTARR(Dim[1],Dim[2])

FOR i = 0, N_ELEMENTS(PntROIs)-1 DO BEGIN
   Roi = *PntROIs[i]
   FOR j = 0, Dim[1]-1 DO BEGIN
      FOR k = 0, Dim[2]-1 DO BEGIN
         IF (NORM(ClaImage[*,j,k] - Roi.RoiColor) EQ 0) THEN IndexImage[j,k] = i
      ENDFOR
   ENDFOR
ENDFOR

Return, IndexImage
END


;+
FUNCTION UNSUPERVISED_COLOR_CLASSIFICATION, IndexImage

   Dim = GET_DIMENSIONS(IndexImage)
   ClaImage = BYTARR(3,Dim[1],Dim[2])
  
   FOR j = 0, Dim[1]-1 DO BEGIN
      FOR k = 0, Dim[2]-1 DO ClaImage[*,j,k] = TEKTRONIX_V2(IndexImage[j,k])
   ENDFOR

  Return, ClaImage
END