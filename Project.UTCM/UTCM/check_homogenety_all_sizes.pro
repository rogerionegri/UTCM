FUNCTION CHECK_HOMOGENETY_ALL_SIZES, Image, alpha

   decFocus = 0

   dims = GET_DIMENSIONS(Image)
   availBlocks = BYTARR(dims[1],dims[2])

   maxRadius = ((MIN(dims[1:2]) - 1)/2)
   listHomo = [PTR_NEW()]

   ;--------------------------
   rhoMin = 3
   rhoMax = maxRadius
   kk = floor( (alog(rhoMax) - alog(rhoMin))/alog(2) )
   FOR kkk = kk, 0, -1 DO BEGIN
      radius = (2L^kkk) * rhoMin
   
      diameter = 2*radius + 1
  
      ptrTemp = FIND_HOMOGENEOUS_BLOCKS_IF_POSSIBLE(availBlocks, dims[1:2], diameter, decFocus)
      structChecked = CHECK_HOMOGENETY(Image, ptrTemp, alpha)
     
      posHomo = WHERE(structChecked.blockConditions EQ 1)
      IF posHomo[0] NE -1 THEN BEGIN
         listHomo = [listHomo , ptrTemp[posHomo]]
         availBlocks[*,*] += structChecked.imageConditions
         print, radius, N_ELEMENTS(posHomo)
      ENDIF ELSE print, radius, 0
     
   ENDFOR
   
   listHomo = listHomo[1:*]


   ;Homogeneity testing---------------------------------------------
   compZ = FLTARR(N_ELEMENTS(listHomo))
   FOR i = 0L, N_ELEMENTS(listHomo)-1 DO BEGIN
      temp = *listHomo[i]
      ParFocusZ = GET_PARAMETERS_FROM_BLOCK_UNIDIMENSIONAL(Image, temp.focus) ;ParFocusZ = GET_PARAMETERS_FROM_BLOCK(Image, temp.focus)
      compZ[i] = abs(ParFocusZ.Mu)
   ENDFOR  


    if n_elements(compZ) eq 1 then $
    return, {homoBlocks: 0, homoImage: 0, homoImageRefined: 0, $
      homoBlocksRefined: 0, meanHB: 0, stdevHB: 0, $
      tauDev: 0, fail: 1}
    
    
    bbb = best_bouding_box(compz)
    statThres_sup = bbb.lims[1]
    statThres_inf = bbb.lims[0]
    tau = statThres_sup
    
    posT1 = WHERE(compZ LE statThres_sup)
    posT2 = WHERE(compZ[posT1] GE statThres_inf)

    availBlocksRefined = availBlocks[*,*]*(-1)    ;alterado em 31out23
    FOR i = 0L, N_ELEMENTS(posT1[posT2])-1 DO BEGIN
       temp = *listHomo[posT1[posT2[i]]]
       FOR j = 0L, N_ELEMENTS(temp.focus[0,*])-1 DO availBlocksRefined[temp.focus[0,j],temp.focus[1,j]] = 1
    ENDFOR
    ;----------------------------------------------------------------

    Return, {homoBlocks: listHomo, homoImage: listHomo, homoImageRefined: availBlocksRefined, $
             homoBlocksRefined: listHomo[posT1[posT2]], meanHB: mean(compZ), stdevHB: stddev(compZ), $
             tauDev: tau, fail: 0}
END