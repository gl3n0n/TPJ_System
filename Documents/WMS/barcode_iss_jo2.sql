set head off                                                                                                                                                                                                                                                                                                            
set lines 256                                                                                                                                                                                                                                                                                                           
set feedback off                                                                                                                                                                                                                                                                                                        
set pages 0                                                                                                                                                                                                                                                                                                             
spoo D:\import\ISSUANCE_JO\004934H.txt                                                                                                                                                                                                                                                                                  
select joiss_no || chr(9) || to_char(joiss_date, 'DD-MON-RRRR') || chr(9)  || '"' || SF_GET_EMPL_NAME(issued_to)  || '"' || chr(9)  || '"' || SF_GET_EMPL_NAME(received_by)  || '"' line_desc                                                                                                                           
from INV_JOISS_HDR                                                                                                                                                                                                                                                                                                      
where joiss_no='004934'                                                                                                                                                                                                                                                                                                 
order by joiss_no;                                                                                                                                                                                                                                                                                                      
spoo off                                                                                                                                                                                                                                                                                                                
spoo D:\import\ISSUANCE_JO\004934D.txt                                                                                                                                                                                                                                                                                  
select JOISHD_JOISS_NO || chr(9) || ITTY_CODE || chr(9) || ITGR_CODE || chr(9) || CATE_CODE  || chr(9) || ITEM_CODE || chr(9) || ISS_QTY  || chr(9) || UOME_CODE line_desc                                                                                                                                              
from INV_JOISS_DTL                                                                                                                                                                                                                                                                                                      
where   joishd_joiss_no='004934';                                                                                                                                                                                                                                                                                       
spoo off                                                                                                                                                                                                                                                                                                                
update inv_wsm_jo_iss set downloaded='Y' where jo_iss_no = '004934';                                                                                                                                                                                                                                                    
commit;                                                                                                                                                                                                                                                                                                                 
@barcode_iss_jo.sql                                                                                                                                                                                                                                                                                                     
                                                                                                                                                                                                                                                                                                                        
