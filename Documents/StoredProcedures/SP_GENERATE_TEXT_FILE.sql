create or replace procedure sp_generate_text_file as
  vFileName  varchar2(64);
  vDelimiter varchar2(64);
  o_file     text_io.file_type;
begin
  vFileName  := 'c:\test.txt'; 
  vDelimiter := ','; 
  vHeader    := 'TABLE NAME' || vDelimiter || 'TYPE'; 
  o_file  := text_io.fopen(vFileName, 'w');
  text_io.put(o_file, vHeader);
  text_io.new_line(o_file, 1);
  for i in (select lower(table_name), lower(table_type) from cat)
  loop
     text_io.put(o_file, i.table_name || vDelimiter || i.table_type);
     text_io.new_line(o_file, 1);
  end loop;
  text_io.fclose(o_file);
end sp_generate_text_file;
/
show err 
