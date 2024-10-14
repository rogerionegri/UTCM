function BHATTACHARYYA_UNIDIMENSIONAL, mu1, mu2, sigmaSq1, sigmaSq2
D = 0.25 * ((mu1 - mu2)^2)/((sigmaSq1 + sigmaSq2)) + 0.5*alog( (sigmaSq1 + sigmaSq2)/(2*sqrt(sigmaSq1)*sqrt(sigmaSq2)) )
Return, D
end