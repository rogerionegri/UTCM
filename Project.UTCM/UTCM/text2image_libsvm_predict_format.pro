FUNCTION TEXT2Image_LIBSVM_PREDICT_FORMAT, Path_Prediction, numCol, numLines

OpenR, Arq, Path_Prediction, /GET_LUN

imgPred = FLTARR(numCol, numLines)

Head = ''
ReadF, Arq, Head
FOR i = 0, numCol-1 DO BEGIN
   FOR j = 0, numLines-1 DO BEGIN
      ReadF, Arq, lab, yp, ym
      imgPred[i,j] = yp    
   ENDFOR
ENDFOR

Close, Arq
FREE_LUN, Arq

Return, imgPred
END


;====================================================
FUNCTION TEXT2Image_LIBSVM_PREDICT_FORMAT_MULTICLASS, Path_Prediction, numCol, numLines, PtrROIs

OpenR, Arq, Path_Prediction, /GET_LUN

imgPred = FLTARR(n_elements(PtrROIs),numCol, numLines)

Head = ''
Line = ''
ReadF, Arq, Head
FOR i = 0, numCol-1 DO BEGIN
  FOR j = 0, numLines-1 DO BEGIN
    ReadF, Arq, Line
    info = strsplit(Line,' ',/extract)
    ;ReadF, Arq, lab, yp, ym
    imgPred[*,i,j] = float(info[1:-1]) 
  ENDFOR
ENDFOR

Close, Arq
FREE_LUN, Arq

Return, imgPred
END