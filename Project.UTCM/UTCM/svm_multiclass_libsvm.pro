;TODO: Incluir a documentação desta função
FUNCTION SVM_MULTICLASS_LIBSVM, Img, PntROIs, ParamStruct
  COMMON PkgOpSolvers, PATH_OP_SOLVERS

  ;Data normalization for SVM (good for LibSVM)
  Image = IMAGE_NORMALIZATION(Img)

  IMAGE2TEXT_LIBSVM_PREDICT_FORMAT, Image
  ROIs = PntROIs

  Dims = GET_DIMENSIONS(Image)
  NC = Dims[1]
  NL = Dims[2]

  ;Training data set building
  PtrTRAINING = BUILD_TRAINING_DATA_MULTICLASS(Image,ROIs)
  DiImage = INTERFACE_LIBSVM_TRAIN_PREDICT__COMPLETE_MULTICLASS(PtrTRAINING,ParamSTRUCT,ROIs)
  ClaImage = CLASSIF(DiImage,ROIs)
  IndexImage = CLASSIF_INDEX(ClaImage,ROIs)

  Return, {Index: IndexImage, Classification: ClaImage, RuleImage: DiImage}
END