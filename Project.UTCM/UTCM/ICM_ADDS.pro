PRO ICM_ADDS

END


FUNCTION REORDER4ICM, img

  Dims = GET_DIMENSIONS(img)
  NB = Dims[0] & NC = Dims[1] & NL = Dims[2]

  __img = FLTARR(NC,NL,n_elements(img[*,0,0]))
  for b = 0, n_elements(img[*,0,0])-1 do __img[*,*,b] = img[b,*,*]

  Return, __img
END


FUNCTION Icm_Win_Config,w,class=class
  central=w[4]
  neigh=w[[0,1,2,3,5,6,7,8]]
  hist=byte(histogram(neigh,min=0,max=max(w)))
  result=hist[central]
  hist[central]=0
  class=[central,reverse(sort(hist))]
  hist=hist[class[1:*]]
  temp=where(hist ne 0)
  if temp[0] ne -1 then result=[result,hist[temp]]
  class=class[0:n_elements(result)-1]
  return,StrCompress(string(result,/print),/Rem)
END



FUNCTION Icm_dbet, beta
; Parametric function of Beta
; Solve for Beta By iteractive method
  COMMON icm_vars,knames,k,nclass

  enb=exp(beta[0]*findgen(9)) ;1, exp(B), exp(2B), ...
  den=fltarr(n_elements(knames))
  num=fltarr(n_elements(knames))
  num[0]=8*(nclass-1)
  den[0]=enb[8]+nclass-1
  for i=1,n_elements(knames)-1 do begin
    temp=byte(knames[i])-48.
    temp1=temp[1:*]
    num[i]=total(enb[temp1]*(temp[0]-temp1))+nclass*(8-total(temp1))-temp[0]*$
      n_elements(temp)
    den[i]=total(enb[temp])+nclass-n_elements(temp)
  endfor
  return,[total(k*num/den)]
END