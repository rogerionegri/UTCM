PRO ExchangeFunctions
  ;...
END


FUNCTION MAP_TO_ID, Map

Map = DOUBLE(Map)

Dims = GET_DIMENSIONS(Map)

Dims = [Dims[1],Dims[2]]

ID = LONARR(Dims[0],Dims[1])
Seed = LONG([0,-1]) ;inicialização do vetor de sementes
index = 1L     ;inicialização do indice

WHILE Seed[0] NE -1 DO BEGIN
   
   col = LONG(Seed[0] MOD Dims[0])
   lin = LONG(Seed[0]  /  Dims[0])
   Seed = Seed[1:N_ELEMENTS(Seed)-1] ;retira da fila o elemento usado
   ID[col,lin] = long(index)
   ;print, index

   Neighs = GET_NEIGHBORS(col,lin,3,3,Dims[0],Dims[1])
   FreePos = SEEDS_CANDIDATE(Map[*,col,lin],Map,ID,Neighs,Dims,Seed)
   
   ;verificar a disponibilidade dos vizinhos e colocar no vetor de sementes
   IF FreePos[0] NE -1 THEN Seed = [FreePos,Seed]

   ;retirar o elemento usado da fila de sementes
   IF Seed[0] EQ -1 THEN BEGIN
      NewSeed = LONG(WHERE(ID EQ 0))
      IF NewSeed[0] NE -1 THEN BEGIN
         index++ ;hove mudança de região
         Seed = [NewSeed[0],-1]
      ENDIF ELSE Seed = -1 ;fim do processo
   ENDIF
   
ENDWHILE

Return, ID
END 



;################################
FUNCTION SEEDS_CANDIDATE, Point, Map, ID, Neigh, Dims, VecSeed

Seeds = [-1]
FOR i = 0, N_ELEMENTS(Neigh[0,*])-1 DO BEGIN
   
   IF (NORM(Point - Map[*,Neigh[0,i],Neigh[1,i]]) EQ 0) AND $
      (ID[Neigh[0,i],Neigh[1,i]] EQ 0) THEN BEGIN
      
      ;colocar a posição na fila de sementes
      pos = (Neigh[1,i]*Dims[0]) + Neigh[0,i]
      IF (WHERE(VecSeed EQ pos) EQ -1) THEN Seeds = [Seeds,pos]
   ENDIF
ENDFOR

IF N_ELEMENTS(Seeds) EQ 1 THEN Return, -1 $
ELSE Return, Seeds[1:N_ELEMENTS(Seeds)-1]

END





;#####################
FUNCTION COLOR_TO_ID, Map

Dims = GET_DIMENSIONS(Map)

MapID = INTARR(Dims[1],Dims[2])

DictRGB = [[-1,-1,-1]]
FOR i = 0, Dims[1]-1 DO BEGIN
   FOR j = 0, Dims[2]-1 DO BEGIN
      
      ;Check to add into de dictionary
      exist = 0
      FOR k = 0, N_ELEMENTS(DictRGB[0,*])-1 DO BEGIN
         IF NORM(DictRGB[*,k] - Map[*,i,j]) EQ 0 THEN BEGIN
            exist = 1
            id = k-1
            BREAK
         ENDIF
      ENDFOR
      
      IF exist EQ 1 THEN MapID[i,j] = id ELSE BEGIN
         MapID[i,j] = N_ELEMENTS(DictRGB[0,*])-1
         DictRGB = [[DictRGB] , [Map[*,i,j]]]
      ENDELSE
      
   ENDFOR
ENDFOR

Return, MapID
END