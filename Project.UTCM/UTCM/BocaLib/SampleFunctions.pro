PRO SampleFunctions
   ;funções de manipulacao de amostras
END


;##################################################
FUNCTION RandSubSample, PtrROIs, SubSize, Seed 

FOR i = 0, N_ELEMENTS(PtrROIs)-1 DO BEGIN
  Aux = *PtrROIs[i]
  LexSize = N_ELEMENTS(Aux.RoiLex)
  IF LexSize GT SubSize THEN BEGIN
      Lex = [0]
      Rand = SORT(randomu(Seed,LexSize))
      FOR j = 0, SubSize-1 DO Lex = [Lex,Aux.RoiLex[Rand[j]]]
      Lex = Lex[1:N_ELEMENTS(Lex)-1]   
      Temp = {RoiName: Aux.RoiName, RoiColor: Aux.RoiColor, RoiLex: Lex}
      PTR_FREE, PtrROIs[i]
      PtrROIs[i] = PTR_NEW(Temp)
   ENDIF   
ENDFOR

Return, PtrROIs
END


;######################################
FUNCTION CHECK_SAMPLES_SUFFICIENCY, NB, PtrROIs

FOR i = 0, N_ELEMENTS(PtrROIs)-1 DO BEGIN
   Temp = *PtrROIs[i]
   IF N_ELEMENTS(UNIQ(Temp.RoiLex)) LE NB THEN Return, 0
ENDFOR

Return, 1
END