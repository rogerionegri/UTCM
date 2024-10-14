PRO RegionClassificationFunctions
   ;just a caller
END


;#############################
FUNCTION COLOR_REG, ClaIndex, PntROIs

Dims = SIZE(ClaIndex,/DIMENSIONS)  &  NC = Dims[0]  & NL = Dims[1]

ClaImage = INTARR(3,N_ELEMENTS(ClaIndex[*,0]),N_ELEMENTS(ClaIndex[0,*]))

FOR i = 0, NC-1 DO BEGIN
   FOR j = 0, NL-1 DO BEGIN
      Ind = ClaIndex[i,j]
      Roi = *PntROIs[Ind]
      ClaImage[*,i,j] = Roi.RoiColor      
   ENDFOR
ENDFOR

Return, ClaImage
END




;################################
FUNCTION GET_SEG_REG, Image, ImgSEG

Dim = SIZE(Image,/DIMENSION)
NB = Dim[0]   &   NC = Dim[1]   &   NL = Dim[2]
RegIndex = ImgSEG[UNIQ(ImgSEG, SORT(ImgSEG))]

;Vetor de estrutura usado para guardar parametros das regioes a serem classificadas
;VRegs = REPLICATE( {Mu: FLTARR(NB), Sigma: FLTARR(NB,NB), $
;                    InvSigma: FLTARR(NB,NB)} , N_ELEMENTS(RegIndex) )

VRegs = PTRARR(N_ELEMENTS(RegIndex))

FOR i = 0L, N_ELEMENTS(RegIndex)-1 DO BEGIN
   
   ;IF RegIndex[i] GE 0 THEN BEGIN
      Index = RegIndex[i]
      Lex = WHERE(ImgSEG EQ Index)
      nLex = N_ELEMENTS(Lex)
      Samples = DBLARR(NB,nLex)
      FOR j = 0L, nLex-1 DO BEGIN
         lin = LONG(Lex[j]/NC)
         col = LONG(Lex[j] MOD NC)
         ;Samples = [ [Samples] , [Image[*,col,lin]] ]
         Samples[*,j] = Image[*,col,lin]
      ENDFOR
      ;Samples = Samples[*,1:N_ELEMENTS(Samples[0,*])-1]
      
      ;calcular os parametros...
      MeanVec = MEAN_VECTOR(Samples)
      SigMatrix = COVARIANCE_MATRIX(Samples)
   
      if ~finite(MeanVec[0]) then stop
   
      InvSigma = INVERT(SigMatrix, Status, /DOUBLE)
      ;IF Status THEN print, 'Opa! Matriz singular... (get seg reg)'
   
      WHILE Status DO BEGIN
         print, 'Opa! Matriz singular... (compute parameters)', i
      
         auxxx = RANDOMU(SYSTIME(/SECONDS),N_ELEMENTS(SigMatrix[*,0])) * 0.01
         ;SigMatrix += RANDOMU(SYSTIME(/SECONDS),N_ELEMENTS(SigMatrix[*,0]), N_ELEMENTS(SigMatrix[0,*]))
         SigMatrix += (auxxx ## auxxx)
      
         InvSigma = INVERT(SigMatrix, Status, /DOUBLE)
      ENDWHILE 
      
      VRegs[i] = PTR_NEW({Mu: MeanVec, Sigma: SigMatrix, InvSigma: InvSigma})
   ;ENDIF   
      
ENDFOR

Return, VRegs
END


;################################
FUNCTION GET_SEG_DATA, Image, ImgSEG, PntROIs, Wx, Wy, pcmin

Dim = SIZE(Image, /DIMENSION)
NB = Dim[0] & NC = Dim[1] & NL = Dim[2]
AuxIMG = FLTARR(NC,NL)
ClassRegion = PTRARR(N_ELEMENTS(PntROIs))

FOR i = 0 , N_ELEMENTS(PntROIs)-1 DO BEGIN
   
   AuxIMG[*] = 0
   ROI = *PntROIs[i]
   Lex = ROI.RoiLex
   
   ;identificacao das areas
   FOR j = 0, N_ELEMENTS(Lex)-1 DO BEGIN
      lin = FIX(Lex[j]/NC)
      col = (Lex[j] MOD NC) 
      AuxIMG[col,lin] = 1
   ENDFOR
   
   ;passar grade e detectar as amostras...
   ClassList = [PTR_NEW()]
   FOR k = 0, NC-1, Wx DO BEGIN
      FOR l = 0, NL-1, Wy DO BEGIN
         
         List = [0]
         count = 0
         
         FOR m = 0, Wx-1 DO BEGIN
            FOR n = 0, Wy-1 DO BEGIN
               
               IF ( (k+m)LE(NC-1) )AND( (l+n)LE(NL-1) ) THEN BEGIN
                  
                  IF AuxIMG[(k+m),(l+n)] EQ 1 THEN BEGIN
                     lxpos = (l+n)*NC + (k+m)
                     List = [List,lxpos]
                     count++                  
                  ENDIF
                                 
               ENDIF
            
            ENDFOR
         ENDFOR
         
         ;verifica a porcentagem de cobertura dentro da celula...
         IF count/FLOAT(Wx*Wy) GE pcmin THEN $
            ClassList = [ClassList,PTR_NEW(List[1:N_ELEMENTS(List)-1])]      
      
      ENDFOR
   ENDFOR
   
   IF N_ELEMENTS(ClassList) GT 1 THEN BEGIN
      ClassList = ClassList[1:N_ELEMENTS(ClassList)-1]
      ClassRegion[i] = PTR_NEW(ClassList)
   ENDIF

ENDFOR

Return, ClassRegion
END



;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION GET_INDEX_SEGM, ImgSEG, ClaIndex

IndexImg = ImgSEG

FOR i = 0, N_ELEMENTS(ClaIndex)-1 DO BEGIN
   Lex = WHERE(ImgSEG EQ i+1)
   IF Lex[0] NE -1 THEN IndexImg[Lex] = ClaIndex[i]
ENDFOR

stop

END



;################################
FUNCTION GET_MU_SEG_REG, Image, ImgSEG

Dim = SIZE(Image,/DIMENSION)
NB = Dim[0]   &   NC = Dim[1]   &   NL = Dim[2]
RegIndex = ImgSEG[UNIQ(ImgSEG, SORT(ImgSEG))]

;Vetor de estrutura usado para guardar parametros das regioes a serem classificadas
;VRegs = REPLICATE( {Mu: FLTARR(NB), Sigma: FLTARR(NB,NB), $
;                    InvSigma: FLTARR(NB,NB)} , N_ELEMENTS(RegIndex) )

VRegs = PTRARR(N_ELEMENTS(RegIndex))

FOR i = 0L, N_ELEMENTS(RegIndex)-1 DO BEGIN
   
   Index = RegIndex[i]
   Lex = WHERE(ImgSEG EQ Index)
   
   Samples = FLTARR(NB)
   FOR j = 0L, N_ELEMENTS(Lex)-1 DO BEGIN
      lin = FIX(Lex[j]/NC)
      col = FIX(Lex[j] MOD NC)
      Samples = [ [Samples] , [Image[*,col,lin]] ]
   ENDFOR
   Samples = Samples[*,1:N_ELEMENTS(Samples[0,*])-1]
      
   ;calcular os parametros...
   MeanVec = MEAN_VECTOR(Samples)
    
   VRegs[i] = PTR_NEW({Mu: MeanVec})
ENDFOR

Return, VRegs
END


;################################
FUNCTION GET_MU_NEIGH, Image, ImgSEG, winX, winY

  Dim = SIZE(Image,/DIMENSION)
  NB = Dim[0]   &   NC = Dim[1]   &   NL = Dim[2]
  RegIndex = ImgSEG[UNIQ(ImgSEG, SORT(ImgSEG))]

  ;Vetor de estrutura usado para guardar parametros das regioes a serem classificadas
  ;VRegs = REPLICATE( {Mu: FLTARR(NB), Sigma: FLTARR(NB,NB), $
  ;                    InvSigma: FLTARR(NB,NB)} , N_ELEMENTS(RegIndex) )

  VRegs = PTRARR(N_ELEMENTS(RegIndex))

  FOR i = 0L, N_ELEMENTS(RegIndex)-1 DO BEGIN

    Index = RegIndex[i]
    Lex = WHERE(ImgSEG EQ Index)
    
    lin = LONG(Lex/NC)
    col = LONG(Lex MOD NC)
    
    Samples = GET_QUICK_NEIGH_VALS(col,lin,WinX,WinY,Dim[1],Dim[2],Image)

    ;calcular os parametros...
    MeanVec = MEAN_VECTOR(Samples)
    SigMatrix = COVARIANCE_MATRIX(Samples)

    if ~finite(MeanVec[0]) then stop

    InvSigma = INVERT(SigMatrix, Status, /DOUBLE)
    ;IF Status THEN print, 'Opa! Matriz singular... (get seg reg)'

    WHILE Status DO BEGIN
      print, 'Opa! Matriz singular... (compute parameters)', i

      auxxx = RANDOMU(SYSTIME(/SECONDS),N_ELEMENTS(SigMatrix[*,0])) * 0.01
      ;SigMatrix += RANDOMU(SYSTIME(/SECONDS),N_ELEMENTS(SigMatrix[*,0]), N_ELEMENTS(SigMatrix[0,*]))
      SigMatrix += (auxxx ## auxxx)

      InvSigma = INVERT(SigMatrix, Status, /DOUBLE)
    ENDWHILE

    VRegs[i] = PTR_NEW({Mu: MeanVec, Sigma: SigMatrix, InvSigma: InvSigma})
  ENDFOR

  Return, VRegs
END



;;#################################
;FUNCTION MEAN_VECTOR, Samples
;
;MeanVec = Samples[*,0]
;
;FOR i = 0, N_ELEMENTS(Samples[*,0])-1 DO $
;   MeanVec[i] = TOTAL(Samples[i,*])/FLOAT(N_ELEMENTS(Samples[0,*]))
;
;Return, MeanVec
;END
;



;################################
FUNCTION GET_NEIGH_PARS, Image, winX, winY

  Dim = SIZE(Image,/DIMENSION)
  NB = Dim[0]   &   NC = Dim[1]   &   NL = Dim[2]
  
  ;Vetor de estrutura usado para guardar parametros das regioes a serem classificadas
  ;VRegs = REPLICATE( {Mu: FLTARR(NB), Sigma: FLTARR(NB,NB)} , NC*NL )
  ;VRegs = REPLICATE( {Mu: FLTARR(NB)} , NC*NL )
  VRegs = PTRARR(NC*NL)
  
  pos = 0L
  FOR i = 0L, NC-1 DO BEGIN
    FOR j = 0L, NL-1 DO BEGIN
      
      Samples = GET_QUICK_NEIGH_VALS(i,j,WinX,WinY,NB,NC,NL,Image)

      ;calcular os parametros...
      MeanVec = MEAN_VECTOR(Samples)
      SigMatrix = COVARIANCE_MATRIX(Samples)

      if ~finite(MeanVec[0]) then stop
      
      invSigma = INVERT(SigMatrix, Status, /DOUBLE)

      WHILE Status DO BEGIN
        ;print, 'Opa! Matriz singular... (compute parameters)', i

        auxxx = RANDOMU(SYSTIME(/SECONDS),N_ELEMENTS(SigMatrix[*,0])) * 0.01
        ;SigMatrix += RANDOMU(SYSTIME(/SECONDS),N_ELEMENTS(SigMatrix[*,0]), N_ELEMENTS(SigMatrix[0,*]))
        SigMatrix += (auxxx ## auxxx)

        InvSigma = INVERT(SigMatrix, Status, /DOUBLE)
      ENDWHILE
      
      
            
      VRegs[pos] = PTR_NEW({Mu: MeanVec, Sigma: SigMatrix, InvSigma: InvSigma})
      pos++
    ENDFOR
  ENDFOR

  Return, VRegs
END




