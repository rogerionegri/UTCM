;+
; Compilation procedure.
;-
PRO MeasureFunctions
END


;+
; Compute the confusion matrix from a classification results and a given set of test samples.
;
; @returns a numeric (KxK) matrix, where K is the number of classes
; 
; @param IndexImage {in}{required}{type=numeric} image classification index
;
; @param TestROIs {in}{required}{type=pointer} pointer to a struct with informations about samples
;-
FUNCTION CONFUSION_MATRIX, IndexImage, TestROIs

NClass = N_ELEMENTS(TestROIs)
ConfMatrix = LONARR(NClass,NClass)

FOR i = 0, N_ELEMENTS(TestROIs)-1 DO BEGIN
   Aux = *TestROIs[i]
   FOR j = 0L, N_ELEMENTS(Aux.RoiLex)-1 DO BEGIN
      Index = IndexImage[Aux.RoiLex[j]]
      ConfMatrix[Index,i]++
   ENDFOR
ENDFOR

Return, ConfMatrix
END


;+
; Compute concordance measures from a given confusion matrix.
;
; @returns a numeric array with: Overall Accuracy, Tau index of concordance, Tau variance, 
;          Kappa index of concordance and Kappa variance.
; 
; @param ConfMatrix {in}{required}{type=numeric} confusion matrix computed from a classification result
;-

FUNCTION CONCORDANCE_MEASURES, ConfMatrix

Total = DOUBLE(TOTAL(ConfMatrix))
m = FLOAT(N_ELEMENTS(ConfMatrix[*,0]))
Diag = DOUBLE(0.0) & Marg = DOUBLE(0.0)
FOR i = 0, m-1 DO Diag += ConfMatrix[i,i] 
FOR i = 0, m-1 DO Marg += TOTAL(ConfMatrix[i,*])*TOTAL(ConfMatrix[*,i])
OverAccuracy = Diag/Total
;Marg = Marg/(Total^(2))
Tau = (OverAccuracy - (1/m))/(1 - (1/m))
VarTau = (1/Total)*((OverAccuracy*(1-OverAccuracy))/((1-(1/m))^2))
;Kappa = (OverAccuracy - Marg)/(1 - Marg)
Kappa = (Total*Diag - Marg)/(Total*Total - Marg)

;Kappa variance...
T3 = 0.0 & T4 = 0.0
FOR i = 0, m-1 DO T3 += ConfMatrix[i,i]*(TOTAL(ConfMatrix[i,*]) + TOTAL(ConfMatrix[*,i]))
FOR i = 0, m-1 DO BEGIN
   ;FOR j = 0, m-1 DO T4 += ConfMatrix[i,j]*(TOTAL(ConfMatrix[j,*]) + TOTAL(ConfMatrix[*,i]))
   FOR j = 0, m-1 DO T4 += ConfMatrix[i,j]*((TOTAL(ConfMatrix[j,*]) + TOTAL(ConfMatrix[*,i]))^2)
ENDFOR
T1 = OverAccuracy
T2 = Marg/(Total^(2))
T3 = T3/(Total^(2))
T4 = T4/(Total^(3))

;VarKappa = (1/Total)*((T1*(1-T1)/(1-T1)^(2)) + $
VarKappa = (1/Total)*( ((T1*(1-T1))/((1-T2)^2)) + $
                       ((2*(1-T1)*(2*T1*T2-T3))/((1-T2)^3)) + $
                       ((((1-T1)^2)*(T4-4*(T2^2)))/((1-T2)^4)) )

Return, [OverAccuracy,Tau,VarTau,Kappa,VarKappa]
END




;####################################
FUNCTION CONFUSION_MATRIX_FORMATER, ConfusionMatrix, PntROI, TestROI

TrainNames = STRARR(N_ELEMENTS(PntROI)) & TestNames = TrainNames
maxlen = 7 ;because 'Cla/Ref' string size...
FOR i = 0, N_ELEMENTS(PntROI)-1 DO BEGIN
   Aux1 = *PntROI[i]
   Aux2 = *TestROI[i]
   TrainNames[i] = Aux1.RoiName
   TestNames[i] = Aux2.RoiName
   
   IF STRLEN(TrainNames[i]) GT maxlen THEN maxlen = STRLEN(TrainNames[i])
   IF STRLEN(TestNames[i]) GT maxlen THEN maxlen = STRLEN(TestNames[i])
ENDFOR

FOR i = 0, N_ELEMENTS(ConfusionMatrix)-1 DO BEGIN
   IF STRLEN(ConfusionMatrix[i]) GT maxlen THEN maxlen = STRLEN(ConfusionMatrix[i])
ENDFOR

maxlen++

;The Confusion Matrix header
StringCM = PUT_TAIL('Cla\Ref', maxlen) + ' '
FOR i = 0, N_ELEMENTS(PntROI)-1 DO StringCM += PUT_TAIL(TestNames[i], maxlen) + ' ' 

;...and its body
 FOR i = 0, N_ELEMENTS(PntROI)-1 DO BEGIN
   Line = ''
   Line = PUT_TAIL(TrainNames[i], maxlen) + ' '
   FOR j = 0, N_ELEMENTS(PntROI)-1 DO $
      Line += PUT_TAIL(STRTRIM(STRING(ConfusionMatrix[j,i]),1), maxlen) + ' '
   StringCM = [StringCM , Line]
ENDFOR

Return, StringCM
END


FUNCTION PUT_TAIL, Str, Len
TailLength = Len - STRLEN(Str)
Tail = ''
FOR i = 1, TailLength DO Tail += ' '
Return, Tail + Str
END



;primeira versão...
;;FUNCTION CONFUSION_MATRIX_FORMATER, ConfusionMatrix, PntROI, TestROI
;
;TrainNames = STRARR(N_ELEMENTS(PntROI)) & TestNames = TrainNames
;maxlen = 7 ;because 'Cla/Ref' string size...
;FOR i = 0, N_ELEMENTS(PntROI)-1 DO BEGIN
;   Aux1 = *PntROI[i]
;   Aux2 = *TestROI[i]
;   TrainNames[i] = Aux1.RoiName
;   TestNames[i] = Aux2.RoiName
;   
;   IF STRLEN(TrainNames[i]) GT maxlen THEN maxlen = STRLEN(TrainNames[i])
;   IF STRLEN(TestNames[i]) GT maxlen THEN maxlen = STRLEN(TestNames[i])
;ENDFOR
;
;StringFormatCode = '(a'+STRTRIM(STRING(maxlen+4),1)+')'
;;The Confusion Matrix header
;StringCM = STRING('Cla\Ref', FORMAT = StringFormatCode)+' ' 
;FOR i = 0, N_ELEMENTS(PntROI)-1 DO StringCM += STRING(TestNames[i], FORMAT = StringFormatCode) + ' ' 
;
;FOR i = 0, N_ELEMENTS(PntROI)-1 DO BEGIN
;   Line = ''
;   Line = STRING(TrainNames[i], FORMAT = StringFormatCode) + ' '
;   FOR j = 0, N_ELEMENTS(PntROI)-1 DO $
;      Line += STRING(ConfusionMatrix[j,i], FORMAT = StringFormatCode) + ' '
;   
;   StringCM = [StringCM , Line]
;ENDFOR
;
;Return, StringCM
;END