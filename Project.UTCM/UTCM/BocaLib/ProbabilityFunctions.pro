;+
; Compilation procedure.
;
PRO ProbabilityFunctions
END

;+
; Compute a probability of a given vector from a Gaussian Multivariated function 
; with parameters Mu (mean vector) and Sigm (covariance matrix).  
;
; @returns a probability value.
; 
; @param X {in}{required}{type=numeric} n-dimensional real vector
; 
; @param Mu {in}{required}{type=numeric} n-dimensional real vector
; 
; @param Sigm {in}{required}{type=numeric} n-square real matrix
;-
FUNCTION MULTIV_GAUSS, X, Mu, Sigm

Dim = SIZE(X,/DIMENSION)

Value = (1/((2*!PI)^(Dim/2.0) * (DETERM(Sigm, /DOUBLE, /CHECK))^(0.5))) * $
        EXP( -0.5 * (X - Mu) ## INVERT(Sigm, /DOUBLE) ## TRANSPOSE(X - Mu) )

Return, Value
END




FUNCTION MULTIV_GAUSS_ALT, X, Mu, Sigm

     invSigma = INVERT(Sigm, /DOUBLE)
     detSigma = (DETERM(Sigm, /DOUBLE))
     cte = -0.5*ALOG(detSigma)
     
     K = FLOAT(N_ELEMENTS(X))
     Z = -0.5*((transpose(X)-Mu)#invSigma#TRANSPOSE(transpose(X)-Mu))
     
     F = -0.5D*(K*ALOG(2*!PI) + ALOG(detSigma)) + Z
     
     ;Value = EXP(F)
     
     ;if finite(value) EQ 0 then stop

;Return, Value
return, exp(f)
END


;#############################################
FUNCTION MULTIV_GAUSS_COMMON, X
COMMON PkgParsGauss, globalMu, globalSigma

Dim = SIZE(X,/DIMENSION)

Value = (1/((2*!PI)^(Dim/2.0) * (DETERM(globalSigma, /DOUBLE))^(0.5))) * $
        EXP( -0.5 * (X - globalMu) ## INVERT(globalSigma, /DOUBLE) ## TRANSPOSE(X - globalMu) )

Return, Value
END


;;;;;;;;;;;;;;;;;;;;;;;;
;FUNCTION JM_DISTANCE, X
;
;Dist = 2*(1 - EXP(-X))
;Return, Dist
;END