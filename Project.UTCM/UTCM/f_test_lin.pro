function F_TEST_LIN, x, y, n  ;, nx, tx, txs ;vars usadas para otimizar o cálculo
common pkgStaticVars, nx, tx, txs
  
  x11 = nx
  x12 = tx
  x22 = txs
  
  b0 = total(y)
  b1 = total(x*y)
  
  beta1 = (b1 - (x12-b0)/x11)/(x22 - (x12^2)/x11)
  beta0 = (b0 - x12*beta1)/x11
  
  sse = 0.0
  ssr = 0.0
  mu = mean(y)
  for i = 0, n-1 do sse += (y[i] - (x[i]*beta1 + beta0))^2
  for i = 0, n-1 do ssr += (y[i] - mu)^2

  F = (ssr-sse)/((n-1) - (n-2)) / (sse/(n-2))
  pVal = 1.0 -  F_PDF(F, 1, n-2)
  
  Return, {F: F, pVal: pVal, rmse: sqrt(sse/float(n))}
end