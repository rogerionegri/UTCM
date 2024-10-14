;+
; Compilation procedure.
;
PRO ImageFunctions
END

;;+
;; Resolve future problems when line/column images are used, adding one more 
;; dimension to represent a single band image. If the input image is represented 
;; by a line/column matrix, the output is a image with single-band/line/column dimensions 
;;
;; @returns (kxMxN) matrix, k>=1
;;
;; @param Image {in}{required}{type=numeric matrix} image matrix representation. 
;;-
;FUNCTION IMAGE_INSPECT, Image
;
;Dims = GET_DIMENSIONS(Image)
;IF (Dims[0] EQ 0) THEN BEGIN
;   Temp = MAKE_ARRAY(1, Dims[1], Dims[2], TYPE = SIZE(Image,/TYPE))
;   Temp[0,*,*] = Image
;   Image = Temp
;ENDIF
;Return, Image
;END
;
;
;;+
;; Get the correspondent [Column,Line] position of a given
;; lexicographic position from a MxN image 
;;
;; @returns [Column,Line] vector
;;
;; @param Lex {in}{required}{type=numeric long} lexicographic position.
;;  
;; @param M {in}{required}{type=numeric long} number of columns of the image where Lex is.
;; 
;; @param N {in}{required}{type=numeric long} number of lines of the image where Lex is (not yet necessary). 
;;-
;FUNCTION GET_POSITIONS, Lex, M, N
;
;;Reading values on Lex and building a vector of positions
;Pos = LONARR(2,N_ELEMENTS(Lex))
;FOR i=0, N_ELEMENTS(Lex)-1 DO BEGIN
;   Pos[0,i] = LONG(Lex[i] MOD M)
;   Pos[1,i] = LONG(Lex[i]/M)
;ENDFOR
;
;Return, Pos
;END


;+
; Return the dimensions of a image. Avoid problems with MxN and kxMxN images, 
; when the ???
;
; @returns [Bands,Column,Line] vector. If Image has MxN then Bands is zero. 
;
; @param Image {in}{required}{type=numeric matrix} a MxN or kxMxN image. 
;-
FUNCTION GET_DIMENSIONS, Image

;Dimensao dos dados
Dim = SIZE(Image, /DIMENSION)
IF N_ELEMENTS(Dim) EQ 2 THEN BEGIN
   NB = 0
   NC = Dim[0]
   NL = Dim[1]
ENDIF ELSE BEGIN
   NB = Dim[0]
   NC = Dim[1]
   NL = Dim[2]
ENDELSE

Return, [NB,NC,NL]
END




;#######################
FUNCTION OPEN_IMAGE, PATH_IMG, Attributes

;Image reading...
Image = READ_TIFF(PATH_IMG)

;Check image dimensions
Image = IMAGE_INSPECT(Image)

;Getting image dimensions
Dim = GET_DIMENSIONS(Image)

;Case of just one band...
;IF N_ELEMENTS(Attributes) EQ 1 THEN Attributes = [Attributes,Attributes] ;use two equal bands :) 

Img = MAKE_ARRAY(N_ELEMENTS(Attributes), Dim[1], Dim[2], TYPE = SIZE(Image,/TYPE))

FOR i = 0, N_ELEMENTS(Attributes)-1 DO Img[i,*,*] = Image[Attributes[i],*,*]

Return, Img
END

;#########################################################
;#######################
FUNCTION IMAGE_NORMALIZATION, Img

Image = DOUBLE(Img)
FOR i = 0, N_ELEMENTS(Img[*,0,0])-1 DO BEGIN
   coefA = 1.0/(MAX(Img[i,*,*]) - MIN(Img[i,*,*]))
   coefB = 1.0 - (MAX(Img[i,*,*]))/(MAX(Img[i,*,*]) - MIN(Img[i,*,*]))
   Image[i,*,*] = coefA*Img[i,*,*] + coefB
ENDFOR

Return, Image
END



;#######################
FUNCTION OPEN_SEGMENTATION, PATH

Image = IMAGE_INSPECT(READ_TIFF(PATH))
Dim = GET_DIMENSIONS(Image) ;Getting image dimensions
Segm = MAKE_ARRAY(Dim[1], Dim[2], TYPE = SIZE(Image,/TYPE))

Segm = REFORM(Image[0,*,*],Dim[1],Dim[2])

Return, Segm
END



;+
; Function developed get the image dimensions without open (just temporarily)
; the image and keep useless allocated memory.
;
; @returns a 3-component vector with the number of bands, coluns and lines of a
;          input image file path.
;
; @param PathImage {in}{required}{type=string} image file path.
;-
FUNCTION GET_IMAGE_DIMS_WITHOUT_OPEN, PATH_IMG
  img = READ_TIFF(PATH_IMG)
  Image = IMAGE_INSPECT(img)
  Return, GET_DIMENSIONS(Image)
END