;----------------------------
;Bocalib
  @ascii_read_roi.pro
  @ClassificationFunctions.pro
  @MatVecFunctions.pro
  @MeasureFunctions.pro
  @ProbabilityFunctions.pro
  @ImageFunctions.pro

@build_walk.pro
  @read_paths.pro
  @smooth_filter.pro
  @pca_axis.pro

@map_homoblocks.pro
  @check_homogenety_all_sizes.pro
    @find_homogeneous_blocks_if_possible.pro
    @check_homogenety.pro
      @bhattacharyya_unidimensional.pro
      @best_bouding_box.pro

@build_level_map.pro

@MLC.pro

@ICM.pro
  @ICM_ADDS.pro

@svm_multiclass_libsvm.pro
  @image2text_libsvm_predict_format.pro
  @interface_libsvm_train_predict__complete.pro
  @text2image_libsvm_predict_format.pro

@build_maps.pro

;========================================
PRO UTCM

  ;Input description:
  ;'path_series' is a path to a text file containing a sequence of paths to images that define the data series
  ;'path_out' is a directory where the outputs are stored
  ;'prefix' is a simple/optional identifier used to better organize the outputs 
  ;'Atts' is a vector representing the selected features/bands of the images/data series
  ;'rho' is the size of the neighborhood considered by the low-pass filtering applied to smooth the input image series
  ;'optSave' is a logical flag used to define wheter intermediate output should be saved
  ;'alphaHB' and 'alphaF' are significance parameters' required by the methods
  ;'optMeth' defines de classification model used to generate the final change/non-change mapping (MLC or SVM).


  ;In/Out paths
  path_series = '.../series.txt' ;set the full path
  path_out = '.../'              ;set the full path
  prefix = 'Sim_'
  Atts = [0,1]

  ;Internal parameters----------------------
  ratioLengthACF = 1   ;number of lags in the ACF (1 = all possible)
  optNorm = 1          ;flag for data normalization (1 = True)
  COMMON PkgOpSolvers, PATH_OP_SOLVERS ;Set this path to '.../LibSVM_solver/'
  PATH_OP_SOLVERS = ".../LibSVM_solver/" ;set the full path to libsvm

  ;Parameters-------------------------------
  rho = 2              ;datset detail (smoothing process/optional)
  optSave = 1          ;flag to define wheter save or don't the intermediate outputs (optional)
  alphaHB = 0.35       ;significance for homogeneous block identification
  alphaF = 0.09        ;significance for F-test (trend identification)
  optMeth = 'mlc'      ;classification method ['mlc'|'svm']

  paramsName = ['rho','alphaHB','alphaF','ratioLengthACF','optNorm']
  paramsValue = [rho,alphaHB,alphaF,ratioLengthACF,optNorm]
  ;-----------------------------------------

  ;Build TS-Walk representation---------------------
  walk = build_walk(path_series, path_out, prefix, rho, Atts, optSave, optNorm, ratioLengthACF)

  ;Seeding process----------------------------------
  ;First division: Non-changed areas/position identifyed from low variability homogeneous regions.
  imDevWalk = reform(walk.stat[1,*,*],walk.dims[1],walk.dims[2]) ;Standard deviation of "walk" values for each pixel
  MHB = Map_homoBlocks(imDevWalk, alphaHB) ;HBS.tauDev is defined inside...

  ;Second division:
  levelMap = build_level_map(walk, MHB.tauDev, alphaF)

  ;Process the changes/non-change resulting maps
  BUILD_MAPS, walk, levelMap, optMeth, path_out, path_series, prefix
  
  print, 'End of process...'
END

