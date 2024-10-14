;PATH_ROI - roi path file
;Dims - image dimension expressed by [column , line] vector 

FUNCTION CHECK_ROI_CONSISTENCY, PATH_ROI, Dims
COMMON PkgUnit, Unit

GET_LUN,Unit
OpenR, Unit, PATH_ROI

;Check reader consistency
Line = ''

ReadF, Unit, Line ;First line (file description and data/time)
Str = STRSPLIT(Line,' ',/EXTRACT)
IF Str[0] NE ';' THEN  Return, ROI_ERROR_CODE(0)

IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
ReadF, Unit, Line ;Second line (number of regions)
Str = STRSPLIT(Line,' ',/EXTRACT)
IF Str[0] EQ ';' AND STRUPCASE(Str[1]+Str[2]+Str[3]) EQ 'NUMBEROFROIS:' AND FIX(Str[4]) GT 0 $
   THEN nROIs = FIX(Str[4]) ELSE Return, ROI_ERROR_CODE(1)

;????????????????????????????????????????????????????????? usar as diemsoes da imagem original pra que???
IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
ReadF, Unit, Line ;Third line (image dimensions)
Str = STRSPLIT(Line,' ',/EXTRACT)   
IF Str[0] EQ ';' AND STRUPCASE(Str[1]+Str[2]+Str[4]) EQ 'FILEDIMENSION:X' AND $
   FIX(Str[3]) GT 0 AND FIX(Str[5]) GT 0 THEN Dim = [FIX(Str[3]),FIX(Str[5])] ELSE Return, ROI_ERROR_CODE(2)
      

;check samples information consistency
RoiInfo = REPLICATE({RoiStruct, RoiName: '', RoiColor: [0,0,0], RoiNPTS: LONG(0)}, nROIs)
 
FOR i = 0, nROIs-1 DO BEGIN
   
   IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
   ReadF, Unit, Line  ;blank line
   IF STRSPLIT(Line,';',/EXTRACT) NE '' THEN Return, ROI_ERROR_CODE(3)
   
   IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
   ReadF, Unit, Line ;roi name
   Str = STRSPLIT(Line,' ',/EXTRACT)
   IF STRUPCASE(Str[1]+Str[2]) EQ 'ROINAME:' THEN RoiInfo[i].RoiName = Str[3] ELSE Return, ROI_ERROR_CODE(4)
   
   IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
   ReadF, Unit, Line ;roi rgb value
   Str = STRSPLIT(Line,' ',/EXTRACT)
   IF STRUPCASE(Str[1]+Str[2]+Str[3]) EQ 'ROIRGBVALUE:' THEN BEGIN
      Str = STRSPLIT(Str[4]+Str[5]+Str[6],'{,}',COUNT = match, /EXTRACT)
      IF match EQ 3 THEN RoiInfo[i].RoiColor = FIX(Str) ELSE Return, ROI_ERROR_CODE(5)
   ENDIF
   
   IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
   ReadF, Unit, Line ;# of points
   Str = STRSPLIT(Line,' ',/EXTRACT)
   IF STRUPCASE(Str[1]+Str[2]) EQ 'ROINPTS:' AND FIX(Str[3]) GT 0 $
      THEN RoiInfo[i].RoiNPTS = FIX(Str[3]) ELSE Return, ROI_ERROR_CODE(6)
   
ENDFOR

ReadF, Unit, Line ;start of sample list
Str = STRSPLIT(Line,' ',/EXTRACT)
IF N_ELEMENTS(Str) EQ 2 and STRUPCASE(Str[0]+Str[1]) EQ ';ADDR' THEN BEGIN
   
   FOR i = 0, nROIs-1 DO BEGIN
      
      FOR j = 1, RoiInfo[i].RoiNPTS DO BEGIN
      
         ;cheking pixels location
         IF EOF(Unit) THEN Return, ROI_ERROR_CODE(11)
         ReadF, Unit, Line
         IF Line EQ '' THEN Return, ROI_ERROR_CODE(10) ELSE BEGIN
            pos = LONG(Line)
         
            ;retirado de algum lugar...
            ;lin = FIX(i/NC)
            ;col = (i MOD NC)   
            ;RuleImage[*,col,lin] = U[i,*]
         
            lin = FIX(pos/Dim[0])
            col = pos MOD Dim[0]
            ;Quoc = FIX(pos/Dim[0])
            ;Rest = pos MOD Dim[0]
            ;IF Rest EQ 0 THEN lin = Quoc - 1 ELSE lin = Quoc
            ;IF Rest EQ 0 THEN col = Dim[0] ELSE col = Rest - 1
         
            IF (col LT 0) OR (col GT Dim[0]) THEN Return, ROI_ERROR_CODE(8)
            IF (lin LT 0) OR (lin GT Dim[1]) THEN Return, ROI_ERROR_CODE(8)
         ENDELSE
      ENDFOR
      
      
      IF ~EOF(Unit) THEN BEGIN
         ReadF, Unit, Line
         IF (Line NE '') THEN Return, ROI_ERROR_CODE(9)
      ENDIF
   
   ENDFOR

ENDIF ELSE Return, ROI_ERROR_CODE(7)

Close, Unit
Return, -1 ;when everthing is alright!
END


;######################################
FUNCTION ROI_ERROR_CODE, Arg
COMMON PkgUnit, Unit

;0 - Invalid file header. ';' not found.
;1 - Invalid number of rois.
;2 - Invalid image dimensions.
;3 - Blank line not found.
;4 - Invalid roi name definition.
;5 - Invalid color definition.
;6 - Invalid definition of number of points.
;7 - Invalid sample list beginig.
;8 - Invalid sample location - lexicographic location is out the image bounds.
;9 - Invalid information. Unexpected read information.
;10 - Invalid information. Unexpected null information.
;11 - Unexpected end of file.

CASE Arg OF 
   0 : Message = 'Invalid file header. ";" not found.'
   1 : Message = 'Invalid number of rois.'
   2 : Message = 'Invalid image dimensions.'
   3 : Message = 'Blank line not found.'
   4 : Message = 'Invalid roi name definition.'
   5 : Message = 'Invalid color definition.'
   6 : Message = 'Invalid definition of number of points.'
   7 : Message = 'Invalid sample list beginig.'
   8 : Message = 'Invalid sample location - lexicographic location is out the image bounds.'
   9 : Message = 'Invalid information. Unexpected read information.'
   10 : Message = 'Invalid information. Unexpected null information.'
   11 : Message = 'Unexpected end of file.'
ENDCASE

Result = DIALOG_MESSAGE( Message, /CENTER, /ERROR, TITLE = 'B.O.C.A' )

Close, Unit
Return, Arg
END



;######################################
PRO ASCII_SAVE_ROI, PtrROI, PATH, Dims

GET_LUN, Unit
OpenW, Unit, PATH

PrintF, Unit, '; BOCA ROI file [' + SYSTIME() + ']'
PrintF, Unit, '; Number of ROIs: ' + STRTRIM(STRING(N_ELEMENTS(PtrROI)),1)
PrintF, Unit, '; File Dimension: ' + STRTRIM(STRING(Dims[0]),1) + ' x ' + STRTRIM(STRING(Dims[1]),1)

FOR i = 0, N_ELEMENTS(PtrROI)-1 DO BEGIN
   ROI = *PtrROI[i]
   PrintF, Unit, ';'
   PrintF, Unit, '; ROI name: ' + ROI.RoiName
   PrintF, Unit, '; ROI rgb value: {' + $
      STRTRIM(STRING(ROI.RoiColor[0]),1) + ', ' + $
      STRTRIM(STRING(ROI.RoiColor[1]),1) + ', ' + $
      STRTRIM(STRING(ROI.RoiColor[2]),1) + '}'      
   PrintF, Unit, '; ROI npts: ' + STRTRIM(STRING(N_ELEMENTS(ROI.RoiLex)),1)
ENDFOR

PrintF, Unit, '; Addr'
FOR i = 0, N_ELEMENTS(PtrROI)-1 DO BEGIN
   ROI = *PtrROI[i]   
   FOR j = 0, N_ELEMENTS(ROI.RoiLex)-1 DO PrintF, Unit, STRTRIM(STRING(ROI.RoiLex[j]),1) 
   PrintF, Unit, ''
ENDFOR

Close, Unit
END