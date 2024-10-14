;------------------------------
PRO BUILD_MAPS, walk, levelMap, optMeth, path_out, path_serie, prefix

  if optMeth eq 'mlc' then begin
    ;MLC
    classMLC = MLC(walk.walk,levelMap.rois)
    mlc_icm = ICM(classMLC.Index+1,1.0,10,n_elements(levelMap.rois),reorder4icm(classMLC.RuleImage),'NULL')
    mlc_icm_cla = COLORIZE_INDEX(mlc_icm[*,*]-1, levelMap.rois)
    SAVE_OUTPUT_MAPS, path_out, path_serie, mlc_icm, mlc_icm_cla, prefix, 'mlc+icm'
  endif else begin
    ;SVM (fixed hyperparameters: C=1000, RBF's gamma=2.5, Epsilon=10e-5, Multiclass strategy=OAA )
    ;The grid-search process was removed...
    Params = {Penalty: 1000, KernelType: 2, KernelParameters: [3, 2.5, 0], Strategy: 0, Epsilon: 0.00001, Shrinking: 0}
    classSVM = SVM_MULTICLASS_LIBSVM(walk.walk,levelMap.rois,Params)
    svm_icm = ICM(classSVM.Index+1,1.0,10,n_elements(levelMap.rois),reorder4icm(classSVM.RuleImage),'NULL')
    svm_icm_cla = COLORIZE_INDEX(svm_icm[*,*]-1, levelMap.rois)
    SAVE_OUTPUT_MAPS, path_out, path_serie, svm_icm, svm_icm_cla, prefix, 'svm+icm'
  endelse

END


;------------------------------
PRO SAVE_OUTPUT_MAPS, path_out, path_serie, mapIndex, mapClass, prefix, method

  filename = prefix+method
  vecNames = read_paths(path_serie)
  
  ;Anciliary variables:
  path_refImage = vecNames[0]
  Result = QUERY_TIFF(path_refImage, Info, GEOTIFF=geoVar)
  nc = Info.DIMENSIONS[0]
  nl = Info.DIMENSIONS[1]
  nb = Info.CHANNELS
  nt = n_elements(vecNames)
  __nb = n_elements(Atts)

  ;Saving results...
  if size(geovar,/type) le 3 then begin
    write_tiff, path_out+filename+'_index.tif', mapIndex
    write_tiff, path_out+filename+'_class.tif', mapClass
  endif else begin
    write_tiff, path_out+filename+'_index.tif', geotiff=geoVar, mapIndex
    write_tiff, path_out+filename+'_class.tif', geotiff=geoVar, mapClass
  endelse
  
END


