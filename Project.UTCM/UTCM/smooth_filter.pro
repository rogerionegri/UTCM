function smooth_filter, img, rho

  nb = n_elements(img[*,0,0])
  nc = n_elements(img[0,*,0])
  nl = n_elements(img[0,0,*])
  
  smo = img*0
  for b = 0, nb-1 do begin
    for c = 0, nc-1 do begin
      ci = (c-rho) > 0
      cf = (c+rho) < (nc-1)
      for l = 0, nl-1 do begin
        li = (l-rho) > 0
        lf = (l+rho) < (nl-1)
        smo[b,c,l] = mean(img[b,ci:cf,li:lf])
      endfor
    endfor  
  endfor  

  Return, smo
end


;---------------------------------
function smooth_filter_normalize, img, rho

  nb = n_elements(img[*,0,0])
  nc = n_elements(img[0,*,0])
  nl = n_elements(img[0,0,*])
  
  __img = img
  mu = fltarr(nb)
  dp = fltarr(nb)
  for i = 0, nb-1 do begin
    mu[i] = mean(img[i,*,*])
    dp[i] = stddev(img[i,*,*])
  endfor
  
  for c = 0, nc-1 do begin
    for l = 0, nl-1 do begin
      __img[*,c,l] = (img[*,c,l] - mu[*])/dp[*]
    endfor
  endfor

  smo = img*0
  for b = 0, nb-1 do begin
    for c = 0, nc-1 do begin
      ci = (c-rho) > 0
      cf = (c+rho) < (nc-1)
      for l = 0, nl-1 do begin
        li = (l-rho) > 0
        lf = (l+rho) < (nl-1)
        smo[b,c,l] = mean(__img[b,ci:cf,li:lf])
      endfor
    endfor
  endfor

  Return, smo
end