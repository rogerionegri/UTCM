pro print_report, index, ptrROIs, conf, path_report, 
  CM = CONFUSION_MATRIX(index,ptrROIs)
  measures = CONCORDANCE_MEASURES(CM)

  OpenW, Arq, path_report, /get_lun, /append
  PrintF, systime()
  line = conf+';'+STRTRIM(STRING(measures[0]),1)+';'+STRTRIM(STRING(measures[3]),1)+';'+STRTRIM(STRING(measures[4]),1)
  PrintF, line
  Close, Arq
  Free_lun, Arq
  
end