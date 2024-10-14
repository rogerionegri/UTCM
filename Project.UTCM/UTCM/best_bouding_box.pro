function best_bouding_box, data ;Implementation -- 27jun23

  k = 1
  seed = 1234567L
  rep = 10000L

  BS = 0.5*__IQR(data)*(N_ELEMENTS(data)^(-1.0/3.0)) ;freedman-diaconis rule
  y = HISTOGRAM(data, BINSIZE=BS, LOCATIONS = x)

  ;Remove extreme values---------------
  z = total(y,/cumulative)/total(y)
  posInf = where(z lt 0.01) & if posInf[0] eq -1 then posInf[0] = 0
  posSup = where(z gt 0.99) & if posSup[0] eq -1 then posSup[0] = n_elements(z)-1
  y = y[posInf[-1]:posSup[0]]
  x = x[posInf[-1]:posSup[0]]
  ;------------------------------------

  nx = n_elements(x)
  dx = x[1]-x[0]

  sentinelPos = 0
  sentinelCost = (max(y) * (x[-1] - x[0])) - total(y*dx)

  cost = dblarr(rep)
  conf = lonarr(k+2,rep)

  for r = 0, rep-1 do begin

    rnd = sort(randomu(seed,nx))
    conf[*,r] = [0, rnd(sort(rnd[0:k-1])), nx-1]  ;represents the partition configuration

    penaltyDiag = 0
    for i = 0, k do begin
      BOX = max(y[conf[i,r]:conf[i+1,r]]) * (x[conf[i+1,r]] - x[conf[i,r]])
      AUF = total( y[conf[i,r]:conf[i+1,r]]*dx )
      cost[r] += (BOX - AUF)
    endfor

  endfor

  minPos = where(cost eq min(cost))
  bestConf = conf[*,minPos[0]]
  lims = x[bestConf] ;disregards the inf/sup limits

  midPoints = fltarr(n_elements(bestConf)-1)
  for i = 0, n_elements(bestConf)-2 do midPoints[i] = (bestConf[i] + bestConf[i+1])*0.5

  return, {bestConf: bestConf, lims: lims, midPoints: midPoints}
end


;------------------------
FUNCTION __IQR, Img

  sortData = Img[SORT(Img)]
  ind = N_ELEMENTS(Img)/2

  IF N_ELEMENTS(sortData) MOD 2 EQ 0 THEN BEGIN
    lower = sortData[0:ind-1]
    higher = sortData[ind:N_ELEMENTS(Img)-1]
  ENDIF ELSE BEGIN
    lower = sortData[0:ind]
    higher = sortData[ind:N_ELEMENTS(Img)-1]
  ENDELSE

  q25 = MEDIAN(lower, /EVEN)
  q75 = MEDIAN(higher, /EVEN)

  Return, q75-q25
END