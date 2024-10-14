function Map_homoBlocks, img, alpha
  structHomogeneous = CHECK_HOMOGENETY_ALL_SIZES(img, alpha)
  Return, structHomogeneous
END