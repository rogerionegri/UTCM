PRO IMAGE2TEXT_LIBSVM_PREDICT_FORMAT, Image
COMMON PkgOpSolvers, PATH_OP_SOLVERS

OpenW, Arq, PATH_OP_SOLVERS+'predictFile', /GET_LUN

dims = GET_DIMENSIONS(Image)

FOR i = 0, dims[1]-1 DO BEGIN
   FOR j = 0, dims[2]-1 DO BEGIN
      
      line = '+1 '
      FOR k = 0, dims[0]-1 DO BEGIN
         ind = STRTRIM(STRING(k+1),2)
         val = STRTRIM(STRING(Image[k,i,j]),2)
         line += ind+':'+val+' '
      ENDFOR
      PrintF,Arq,line
      
   ENDFOR
ENDFOR
Close, Arq
FREE_LUN, Arq

END