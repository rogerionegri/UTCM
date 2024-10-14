@ICM_ADDS.pro

FUNCTION ICM,imgc,max_changes,max_iterat,nrclass,fdp,PtrROIs

COMMON icm_vars,knames,k,nclass
nclass=nrclass

knames=['8','71','62','611','53','521','5111','44','431','422',$
    '4211','41111','35','341','332','3311','3221','32111','311111',$
    '26','251','242','2411','233','2321','23111','2222','22211',$
    '221111','2111111','17','161','152','1511','143','1421','14111',$
    '1331','1322','13211','131111','12221','122111','1211111',$
    '11111111','08','071','062','0611','053','0521','05111','044',$
    '0431','0422','04211','041111','0332','03311','03221','032111',$
    '0311111','02222','022211','0221111','02111111','011111111']

nlin=size(imgc)
ncol=nlin[1]-2 ;discarting borders
nlin=nlin[2]-2

iteration=1
changes=100. ;inicial value for % of changes
beta_estim=1.d300
beta_est=.1
  While (changes gt max_changes) and (iteration le max_iterat) do begin
    k=intarr(n_elements(knames)) ;nulling the k coefficients
    d_beta=1.
    min_d_beta=.02
    step=Fix((ncol < nlin)*.10)
    line_smp=-1
    
    While (step gt 1.) and (abs(d_beta) gt min_d_beta) do begin
      for j=1l,nlin,round(step) do begin ; go in row
        temp=where(line_smp eq j)
        if temp[0] eq -1 then begin  ;this line was not sampled
          for i=1,ncol,round(step) do begin  ; go in column
            kconf=Icm_Win_Config(imgc[i-1:i+1,j-1:j+1])
            temp=where(knames eq kconf)
            k[temp]=k[temp]+1
          endfor
          line_smp=[line_smp,j]
        endif
      endfor
      step=step/2.
      
      beta_estn=Broyden([.1],'Icm_dbet'); estimate Beta
      beta_est = (beta_estn[0] > beta_est)
      
;      d_beta=beta_estim-beta_est[0]
      d_beta=beta_estim-beta_est
;      beta_estim=beta_est[0]
      beta_estim=beta_est
    EndWhile
    

; applying ICM
    enb=exp(beta_estim*findgen(9)) ;1, exp(b), exp(2b), ...
    changest=0l
    for iini=1,2 do for jini=1,2 do begin
      for j=jini,nlin,2 do begin  ; go in row
        for i=iini,ncol,2 do begin ; go in column
          w=imgc[i-1:i+1,j-1:j+1]
          wc=w[4]
          w=w[[0,1,2,3,5,6,7,8]]
          hist=histogram(w,min=1,max=nclass)
          temp=where(hist ne 0)
          if n_elements(temp) eq 1 then begin ;neighbors are the same class
            if temp[0] ne -1 then imgc[i,j]=temp+1 ;Don't change if neigh are
                                                   ; unclassified
          endif else begin
            like=enb[hist]*fdp[i,j,*] ;*(hist ne 0) ;Use only classes of neig
            
            imgc[i,j]=(reverse(sort(like)))(0)+1 ;<<<<<< este +1 deve estar ajustando o indice da classe
            
          endelse
          changest=changest+(imgc[i,j] ne wc)
        endfor
        
      endfor

    endfor
    changes=changest*100./n_elements(imgc)
    iteration=iteration+1
        
  EndWhile


Return, imgc
END