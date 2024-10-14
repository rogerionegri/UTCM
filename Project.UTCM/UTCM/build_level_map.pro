;----------------------
FUNCTION build_level_map, walk, tauDev, alpha

  dims = size(walk.walk,/dimensions)
  mapLevel = INTARR(dims[1],dims[2])

  posNonChange = where(walk.stat[1,*,*] lt tauDev)
  posChange = where(walk.stat[1,*,*] ge tauDev)

  imTestLB = reform(walk.LB[1,*,*],dims[1],dims[2])
  imTestF = reform(walk.FT[1,*,*],dims[1],dims[2])

  posF = where(imTestF lt alpha)
  posLB = where(imTestLB lt alpha)

  posLB[0] = 0 & posF[0] = 0 ;garantir que nao exista caso "-1" (ausencia de)
  imAlphaF = imTestF*0 & imAlphaF[posF] = 1
  imAlphaLB = imTestLB*0 & imAlphaLB[posLB] = 1

  imFLB = imAlphaF[*,*]

  posSeasonal = where(imFLB[posChange] eq 0)
  posPermanent = where(imFLB[posChange] eq 1)
  posSeasonal[0] = 0
  posPermanent[0] = 0

  rois = [PTR_NEW({RoiName: 'NC', RoiColor: [255,0,0], RoiLex: posNonChange}), $
    PTR_NEW({RoiName: 'Seasonal', RoiColor: [0,255,0], RoiLex: posChange[posSeasonal]}), $
    PTR_NEW({RoiName: 'Permanent', RoiColor: [0,0,255], RoiLex: posChange[posPermanent]})]


  mapLevel[posNonChange] = 0
  mapLevel[posChange[posSeasonal]] = 1
  mapLevel[posChange[posPermanent]] = 2

  Return, {rois: rois, mapLevel: mapLevel}
END
