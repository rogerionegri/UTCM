;-----------------------------------
FUNCTION read_paths, path_list

  OpenR, Arq, path_list, /get_lun
  line = ''
  paths = ['null']
  while ~eof(Arq) do begin
    ReadF, Arq, line
    paths = [paths , line]
  endwhile
  Close, Arq
  Free_lun, Arq

  return, paths[1:*]
END