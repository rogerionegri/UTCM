;TODO: Fazer documentação
FUNCTION INTERFACE_LIBSVM_TRAIN_PREDICT__COMPLETE, PtrTRAINING, ParamSTRUCT;, ROIs
COMMON PkgOpSolvers, PATH_OP_SOLVERS

;transforma no formato de entrada adequado
OpenW, File, PATH_OP_SOLVERS+'TrainingLibSVM', /GET_LUN
X = *PtrTRAINING[0]
Y = *PtrTRAINING[1]
n = N_ELEMENTS(Y)-1
d = N_ELEMENTS(X[*,0])-1

FOR i = 0L, n DO BEGIN
   Line = STRTRIM(STRING(FIX(Y[i])),1)
   FOR j = 0L, d DO BEGIN
      Att = ' '+STRTRIM(STRING(j+1),1) + ':'+STRTRIM(STRING(X[j,i], FORMAT='(F30.20)'),1)
      Line += Att   
   ENDFOR
   PrintF, File, Line
ENDFOR
Close, File   &   FREE_LUN, File

CD, PATH_OP_SOLVERS

command_train = BUILD_COMMAND_TRAIN(ParamSTRUCT)
 
SPAWN, command_train;, /HIDE

command_pred = './svm-predict_LINUX ' + ' -b 1' + ' predictFile ' + ' FileSV ' + ' outPrediction' 
SPAWN, command_pred;, /HIDE

dims = GET_DIMENSIONS(*PtrTRAINING[2])
DiImage = TEXT2Image_LIBSVM_PREDICT_FORMAT(PATH_OP_SOLVERS+'outPrediction', dims[1], dims[2])

Return, DiImage
END



;TODO: Fazer documentação
FUNCTION INTERFACE_LIBSVM_TRAIN_PREDICT__COMPLETE_MULTICLASS, PtrTRAINING, ParamSTRUCT, ROIs
  COMMON PkgOpSolvers, PATH_OP_SOLVERS

  ;transforma no formato de entrada adequado
  OpenW, File, PATH_OP_SOLVERS+'TrainingLibSVM', /GET_LUN
  X = *PtrTRAINING[0]
  Y = *PtrTRAINING[1]
  n = N_ELEMENTS(Y)-1
  d = N_ELEMENTS(X[*,0])-1

  FOR i = 0L, n DO BEGIN
    Line = STRTRIM(STRING(FIX(Y[i])),1)
    FOR j = 0L, d DO BEGIN
      Att = ' '+STRTRIM(STRING(j+1),1) + ':'+STRTRIM(STRING(X[j,i], FORMAT='(F30.20)'),1)
      Line += Att
    ENDFOR
    PrintF, File, Line
  ENDFOR
  Close, File   &   FREE_LUN, File


  CD, PATH_OP_SOLVERS

  command_train = BUILD_COMMAND_TRAIN(ParamSTRUCT)

  SPAWN, command_train;, /HIDE

  command_pred = './svm-predict_LINUX ' + ' -b 1' + ' predictFile ' + ' FileSV ' + ' outPrediction'
  SPAWN, command_pred;, /HIDE

  dims = GET_DIMENSIONS(*PtrTRAINING[2])
  DiImage = TEXT2Image_LIBSVM_PREDICT_FORMAT_MULTICLASS(PATH_OP_SOLVERS+'outPrediction', dims[1], dims[2], ROIs)

  Return, DiImage
END




;#################################################
 FUNCTION BUILD_COMMAND_TRAIN, Params
 
 
command_train = './svm-train_LINUX'

CASE Params.KernelType OF
   ;Linear Kernel
   0: command_train += ' -t 0 '  
   
   ;Polynomial Kernel
   1: command_train += ' -t 1 ' + '-d ' + STRTRIM(STRING(Params.KernelParameters[0]),1) $
                                + ' -r ' + STRTRIM(STRING(Params.KernelParameters[2]),1)

   ;RBF Kernel
   2: command_train += ' -t 2 ' + '-g ' + STRTRIM(STRING(Params.KernelParameters[1]),1)

   ;Sigmoid Kernel
   3: command_train += ' -t 3 ' + '-g ' + STRTRIM(STRING(Params.KernelParameters[1]),1) $
                                        + ' -r ' + STRTRIM(STRING(Params.KernelParameters[2]),1)                                      
ENDCASE

command_train += ' -e ' + STRTRIM(STRING(Params.Epsilon),1) $
               + ' -c ' + STRTRIM(STRING(Params.Penalty),1) $
               + ' -h ' + STRTRIM(STRING(FIX(Params.Shrinking)),1) $
               + ' -b 1 ' $ ;para estimação na forma de probabilidades...
               + ' TrainingLibSVM' + ' FileSV' 
 
 
Return, command_train 
END



;----------------------------------------------
;#######################
FUNCTION BUILD_TRAINING_DATA_MULTICLASS, Image, PtrRois

  ;#OUTPUT
  ;Vector containing with pointers to X and Y vectors
  ;[X,Y]: X = Pointer to Data Training matrix / Y = Pointer to Class Label vector

  Dims = size(Image,/dimension)
  NL = Dims[2]
  NC = Dims[1]

  ;Build a image just with interest attributes
  ImageAux = Image

  trainElements = 0L
  for i = 0L, n_elements(PtrRois)-1 do begin
    roi = *PtrRois[i]
    trainElements += n_elements(roi.RoiLex)
  endfor

  X = FLTARR(Dims[0],trainElements)
  Y = FLTARR(trainElements)
  pos = 0L
  for i = 0L, n_elements(PtrRois)-1 do begin
    roi = *PtrRois[i]
    for j = 0L, n_elements(roi.RoiLex)-1 do begin

      lin = FIX(roi.RoiLex[j]/NC)
      col = (roi.RoiLex[j] MOD NC)

      X[*,pos] = ImageAux[*,col,lin]
      Y[pos] = (i+1)
      pos++

    endfor
  endfor

  Return, [PTR_NEW(X),PTR_NEW(Y),PTR_NEW(ImageAux)]
END