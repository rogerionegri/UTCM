;----------------------------------------
FUNCTION BUILD_WALK, path_serie, path_out, prefix, rho, Atts, optSave, optNorm, ratioLengthACF

  filename = prefix+'_rho'+strtrim(string(rho),1)+'.tif'
  ;------------------------------------

  ;Open data series filenames
  vecNames = read_paths(path_serie)

  ;Anciliary variables:
  path_refImage = vecNames[0]
  Result = QUERY_TIFF(path_refImage, Info, GEOTIFF=geoVar)
  nc = Info.DIMENSIONS[0]
  nl = Info.DIMENSIONS[1]
  nb = Info.CHANNELS
  nt = n_elements(vecNames)
  __nb = n_elements(Atts)

  imgBase = FLTARR(nt,__nb,nc,nl)
  listBase = FLTARR(__nb,nt*nc*nl)

  ;Smoothing/filtering the data series
  for t = 0, nt-1 do begin
    path = vecNames[t]
    img = read_tiff(path)
    if rho eq 0 then imgBase(t,*,*,*) = img[Atts,*,*] else $
      imgBase(t,*,*,*) = (optNorm) ? smooth_filter_normalize(img[Atts,*,*],rho) : smooth_filter(img[Atts,*,*],rho)

    ;Defining a single list before computingthe PCA:
    for b = 0, __nb-1 do listBase[b,t*(nc*nl):(t+1)*(nc*nl)-1] = reform(imgBase(t,b,*,*), 1, nl*nc)
  endfor

  ;Find the largest variability axes---
  struPCs = pca_axis(listBase)


  ;Computing the trajectories:---------
  imgWalk = FLTARR(nt-1,nc,nl)
  imgWalkStat = FLTARR(2,nc,nl)
  vecWalk = fltarr(nt-1)
  for c = 0, nc-1 do begin
    for l = 0, nl-1 do begin
      vecWalk *= 0.0D
      acc_cost = 0.0D
      for t = 0, (nt-1)-1 do begin
        cost = ((imgBase[t+1,*,c,l] - imgBase[t,*,c,l])  # struPCs.eivec) # struPCs.eival
        acc_cost += cost
        vecWalk[t] = acc_cost
      endfor
      imgWalk[*,c,l] = vecWalk
      imgWalkStat[*,c,l] = [mean(vecWalk),stddev(vecWalk)]
    endfor
  endfor

  ;Extract_the autocorrelation values and other features from the "walk" series
  acf =  ACF_Feats(imgWalk,ratioLengthACF)

  ;Saving results...
  if optSave then begin
    if size(geovar,/type) le 3 then begin
      write_tiff, path_out+filename, imgWalk, /float
      write_tiff, path_out+'stats__'+filename, imgWalkStat, /float
      write_tiff, path_out+'acf__'+filename, acf.lags, /float
      write_tiff, path_out+'dev_acf__'+filename, stddev(acf.lags,dimension=1), /float
      write_tiff, path_out+'testLB_acf__'+filename, acf.LB, /float
      write_tiff, path_out+'testF_acf__'+filename, acf.FT, /float
      write_tiff, path_out+'rmseLinear_acf__'+filename, acf.rmseLinear, /float
    endif else begin
      write_tiff, path_out+filename, geotiff=geoVar, imgWalk, /float
      write_tiff, path_out+'stats__'+filename, geotiff=geoVar, imgWalkStat, /float
      write_tiff, path_out+'acf__'+filename, geotiff=geoVar, acf.lags, /float
      write_tiff, path_out+'dev_acf__'+filename, geotiff=geoVar, stddev(acf.lags,dimension=1), /float
      write_tiff, path_out+'testLB_acf__'+filename, geotiff=geoVar, acf.LB, /float
      write_tiff, path_out+'testF_acf__'+filename, geotiff=geoVar, acf.FT, /float
      write_tiff, path_out+'rmseLinear_acf__'+filename, geotiff=geoVar, acf.rmseLinear, /float
    endelse
  endif


  Return, {geoVar: geoVar, $
    walk: imgWalk, $
    stat: imgWalkStat, $
    acf: acf.lags, $
    acfDev: stddev(acf.lags,dimension=1), $
    LB: acf.LB, $
    FT: acf.FT, $
    rmseLinear: acf.rmseLinear, $
    dims: size(imgWalk, /dimensions)}
END