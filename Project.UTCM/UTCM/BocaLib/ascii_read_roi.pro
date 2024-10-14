;+
; Function developed to parse samples colected from images and stored in
; ENVI ASCII format, just using the lexicographic pixel adress (1d-adress).
;
; @returns a pointer to structures that contains informations like name, 
;          color representations and lexicographic pixel adress that compose 
;          the samples of each class
; 
; @param PathROI {in}{required}{type=string} sample file path.
;-
FUNCTION ASCII_READ_ROI,PathROI
COMMON PkgROIs, NumROIs, FileDIM
COMMON PkgARQs, ArqROI
COMMON PkgStruct, RoiStruct, CountStruct
COMMON PkgPointer, PointerROIs
close,/all
OpenR,ArqROI,PathROI,/GET_LUN
Line = ''
CountStruct = 0
WHILE ~EOF(ArqROI) DO BEGIN
   ReadF,ArqROI,Line
   Split = STRSPLIT(Line,' ',/EXTRACT)
   VERIFY_INFO, Split
ENDWHILE
Return, PointerROIs
END

;+
; Procedure used to read ASCII file and store the lexicographic pixel information, for each sample.
; The set variables used into this procedure are global, and defined in ASCII_READ_ROI procedure
;-
PRO FILL_ROI
COMMON PkgROIs, NumROIs, FileDIM
COMMON PkgARQs, ArqROI
COMMON PkgStruct, RoiStruct, CountStruct
COMMON PkgPointer, PointerROIs
pos = 0L
TEMP = *PointerROIs[CountStruct]

Line = '' ;to defy as string type
WHILE ~EOF(ArqROI) DO BEGIN
   ReadF,ArqROI,Line
  
   IF pos EQ N_ELEMENTS(TEMP.RoiLex) THEN BEGIN
      pos = 0L
      CountStruct++
   ENDIF
   
   IF STRLEN(Line) GT 0 THEN BEGIN
      TEMP = *PointerROIs[CountStruct]
      TEMP.RoiLex[pos] = ULONG(Line)
      *PointerROIs[CountStruct]=TEMP
      pos++
   ENDIF

;   TEMP = *PointerROIs[CountStruct]
;   TEMP.RoiLex[pos] = ULONG(Line)
;   *PointerROIs[CountStruct]=TEMP
;   pos++
   
ENDWHILE
END

;+
; Procedure responsable to parse keywords into ENVI's ASCII sample file format. 
; 
; @param Split {in}{required}{type=string} string line read from ASCII file
;-
PRO VERIFY_INFO, Split
COMMON PkgROIs, NumROIs, FileDIM
COMMON PkgARQs, ArqROI
COMMON PkgStruct, RoiStruct, CountStruct
COMMON PkgPointer, PointerROIs
IF N_ELEMENTS(Split) GT 1 THEN BEGIN
   IF Split[0]+Split[1] EQ ';Number' THEN  PointerROIs = PTRARR(FIX(Split[4]))
 
   IF Split[0]+Split[1] EQ ';File' THEN  FileDIM = [Split[3],Split[5]]
   IF Split[0]+Split[1] EQ ';ROI' THEN  BEGIN
      BUILD_ROI_STRUCT, Split
      PointerROIs[CountStruct] = PTR_NEW(RoiStruct)
      CountStruct++
   ENDIF
   IF Split[0]+Split[1] EQ ';Addr' THEN  BEGIN
      CountStruct = 0
      FILL_ROI
   ENDIF
ENDIF
END

;+
; Function used to parse and recognize the color defined to each class into ENVI's ASCII sample file. 
;
; @returns a 3d integer array with the RGB color class representation
; 
; @param Colour {in}{required}{type=string} string segment read from ASCII file
;-
FUNCTION ExtractColor,Colour
Colour = STRSPLIT(Colour,'{',/EXTRACT)
Colour = STRSPLIT(Colour,'}',/EXTRACT)
Vector = STRSPLIT(Colour,',',/EXTRACT)
Red = FIX(Vector[0])
Green = FIX(Vector[1])
Blue = FIX(Vector[2])
Return,[Red,Green,Blue]
END

;+
; Procedure used to join all parsed information and build a structure with informations about the sample. 
; 
; @param Split {in}{required}{type=string} string line read from ASCII file
;-
PRO BUILD_ROI_STRUCT, Split
COMMON PkgROIs, NumROIs, FileDIM
COMMON PkgARQs, ArqROI
COMMON PkgStruct, RoiStruct, CountStruct
COMMON PkgPointer, PointerROIs
Name = Split[3]
Line = ''
ReadF,ArqROI,Line
Split = STRSPLIT(Line,' ',/EXTRACT)
Colour = Split[4]+Split[5]+Split[6]
VecCOLOR = ExtractColor(Colour)
ReadF,ArqROI,Line
Split = STRSPLIT(Line,' ',/EXTRACT)
Points = LONG(Split[3])
RoiStruct = { RoiName: Name, RoiColor: VecCOLOR, RoiLex: LONARR(Points)}
END