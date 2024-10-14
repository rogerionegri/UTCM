function ACF_Feats, Img, ratio
common pkgStaticVars, nx, tx, txs

  dims = size(Img,/dimensions)
  p = dims[0]-1

  acf_img = fltarr(p/ratio,dims[1],dims[2])
  acf_LBtest = fltarr(2,dims[1],dims[2])
  acf_rmseLinear = fltarr(dims[1],dims[2])
  acf_Ftest = fltarr(2,dims[1],dims[2])

  N = n_elements(acf_img[*,0,0])
  
  ;common def...
  __x = indgen(N)
  nx = N
  tx = total(__x)
  txs = total(__x^2)

  for i = 0, dims[1]-1 do begin
    for j = 0, dims[2]-1 do begin

      for k = 0, (p/ratio)-1 do acf_img[k,i,j] = a_correlate(Img[*,i,j],k+1)

      ;Ljiung-Box test for lag=1 only
      acf_LBtest[0,i,j] = (acf_img[0,i,j]^2)/float(p -1)  ;for k = 0, 0 do acf_LBtest[0,i,j] += (acf_img[k,i,j]^2)/float( (p/ratio) - (k+1) )
      acf_LBtest[0,i,j] = (p)*(p+2) * acf_LBtest[0,i,j]
      acf_LBtest[1,i,j] = 1 - CHISQR_PDF(acf_LBtest[0,i,j], 1)
      
      ;OLS Adjust
      adj = f_test_lin(__x, acf_img[*,i,j], N)
      
      acf_Ftest[0,i,j] = adj.F
      acf_Ftest[1,i,j] = adj.pVal
      acf_rmseLinear[i,j] = adj.rmse
    endfor
  endfor

  Return, {lags: acf_img, $
           LB: acf_LBtest, $
           FT: acf_Ftest, $
           rmseLinear: acf_rmseLinear}
END