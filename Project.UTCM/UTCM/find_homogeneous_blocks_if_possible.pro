FUNCTION find_homogeneous_blocks_if_possible, availBlocks, dims, diameter, decFocus

   ;--------------------------------------------
   sysOrig = [(diameter/2),(diameter/2)]

   support  = LONARR(dims[0],dims[1])
   countSegm = 1L
   centerSegms = [-1L,-1L,-1L]
   ;--------------------------------------------


   startPoint = sysOrig
   horizPos = startPoint[0]
   countHoriz = 0L
   WHILE (startPoint[0] + countHoriz*diameter) LT dims[0] DO BEGIN

      horizPos = startPoint[0] + countHoriz*diameter
      vertPos = startPoint[1]
      countVert = 0L
      WHILE (startPoint[1] + countVert*diameter) LT dims[1] DO BEGIN
         vertPos = startPoint[1] + countVert*diameter

         IF (horizPos GE 0) AND (vertPos GE 0) THEN BEGIN
        
        
            ;Check if block region is available----------------------
            available = 1
            FOR colBlock = -(diameter/2), (diameter/2) DO BEGIN
               FOR linBlock = -(diameter/2), (diameter/2) DO BEGIN
                  IF ((horizPos+colBlock) GE 0) AND ((horizPos+colBlock) LT dims[0]) AND $
                     ((vertPos+linBlock) GE 0) AND ((vertPos+linBlock) LT dims[1]) THEN BEGIN
              
                     IF availBlocks[horizPos+colBlock,vertPos+linBlock] NE 0 THEN available=0
                
                  ENDIF
               ENDFOR
            ENDFOR
        
           ;If available... reserve ir-------------------------------
           IF available THEN BEGIN
              centerSegms = [[centerSegms] , [horizPos,vertPos,countSegm]]
              FOR colBlock = -(diameter/2), (diameter/2) DO BEGIN
                 FOR linBlock = -(diameter/2), (diameter/2) DO BEGIN

                     IF ((horizPos+colBlock) GE 0) AND ((horizPos+colBlock) LT dims[0]) AND $
                       ((vertPos+linBlock) GE 0) AND ((vertPos+linBlock) LT dims[1]) THEN BEGIN
                      
                        support[horizPos+colBlock,vertPos+linBlock] = countSegm 
                     ENDIF
                     
                  ENDFOR
               ENDFOR
               countSegm++ 
            ENDIF
             
         ENDIF
         countVert++
      ENDWHILE
      countHoriz++
   ENDWHILE

   centerSegms = centerSegms[*,1:*]
   
   ;Define the segments/parts inside each block
   ptrStructBlocks = PTR_NEW()
   FOR ind = 1L, countSegm-1 DO BEGIN
      pos = WHERE(support EQ ind)
      IF N_ELEMENTS(pos) EQ diameter*diameter THEN BEGIN

         center = centerSegms[0:1,(ind-1)]


         ;Defining the region itself
         countBlock = 0L
         focus = INTARR( 2 , (diameter - decFocus)*(diameter - decFocus) )
         FOR i = (-(diameter/2 - decFocus)) , ((diameter/2 - decFocus)) DO BEGIN
            FOR j = (-(diameter/2 - decFocus)) , ((diameter/2 - decFocus)) DO BEGIN
               focus[*,countBlock] = [center[0] + i, center[1] + j]
               countBlock++
            ENDFOR
         ENDFOR

         ;Defining the upper triangle region
         countBlock = 0L
         triangSup = INTARR( 2 , diameter*(diameter-1)/2 + diameter)
         FOR j = (-(diameter/2)) , ((diameter/2)) DO BEGIN
            FOR i = j, ((diameter/2)) DO BEGIN
               triangSup[*,countBlock] = [center[0] + i, center[1] + j]
               countBlock++
            ENDFOR
         ENDFOR


         ;Defining the lower triangle region
         countBlock = 0L
         triangInf = INTARR( 2 , diameter*(diameter-1)/2 + diameter)
         FOR j = (-(diameter/2)) , ((diameter/2)) DO BEGIN
            FOR i = (-(diameter/2)), j DO BEGIN
               triangInf[*,countBlock] = [center[0] + i, center[1] + j]
               countBlock++
            ENDFOR
         ENDFOR


         ;Defining the upper rectangle region
         countBlock = 0L
         rectSup = INTARR( 2 , diameter*(diameter/2 + 1) )
         FOR i = (-diameter/2) , (diameter/2) DO BEGIN
            FOR j = (-diameter/2) , 0 DO BEGIN
               rectSup[*,countBlock] = [center[0] + i, center[1] + j]
               countBlock++
            ENDFOR
         ENDFOR


         ;Defining the lower rectangle region
         countBlock = 0L
         rectInf = INTARR( 2 , diameter*(diameter/2 + 1) )
         FOR i = (-diameter/2) , (diameter/2) DO BEGIN
            FOR j = 0 , (diameter/2) DO BEGIN
               rectInf[*,countBlock] = [center[0] + i, center[1] + j]
               countBlock++
            ENDFOR
         ENDFOR


         ;Defining the left rectangle region
         countBlock = 0L
         rectLeft = INTARR( 2 , diameter*(diameter/2 + 1) )
         FOR i = (-diameter/2) , 0 DO BEGIN
            FOR j = (-diameter/2) , (diameter/2) DO BEGIN
               rectLeft[*,countBlock] = [center[0] + i, center[1] + j]
               countBlock++
            ENDFOR
         ENDFOR


         ;Defining the right rectangle region
         countBlock = 0L
         rectRight = INTARR( 2 , diameter*(diameter/2 + 1) )
         FOR i = 0 , (diameter/2) DO BEGIN
            FOR j = (-diameter/2) , (diameter/2) DO BEGIN
               rectRight[*,countBlock] = [center[0] + i, center[1] + j]
               countBlock++
            ENDFOR
         ENDFOR

         temp = {diameter: diameter, decFocus: decFocus, $
                 center: center, focus: focus, $
                 regs: [PTR_NEW(triangSup), PTR_NEW(triangInf), PTR_NEW(rectSup), PTR_NEW(rectInf), PTR_NEW(rectLeft), PTR_NEW(rectRight)]}

         ptrStructBlocks = [ptrStructBlocks , PTR_NEW(temp)]
      ENDIF
   ENDFOR

  Return, ptrStructBlocks[1:*]
END
