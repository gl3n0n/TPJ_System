-- For PO                                               
SELECT AP_NO,                                           
       DRHD.DR_NO RR_NO,                                
       DRHD.PO_NO PO_NO,                                
       DRHD.RS_NO RS_NO,                                
       NVL(DRHD.DR_DATE, DRHD.INVOICE_DT) RR_DATE,      
       NVL(DRHD.INVOICE_NO, DRHD.SUPP_DR_NO) INVOICE_NO,
       DRHD.RR_AMT RR_AMT,                              
       DRHD.RR_PAID RR_PAID,                            
       DRHD.PO_CURRENCY                                 
FROM   ACC_INV_RR_DTL DRHD                              
WHERE  DRHD.PO_NO = '014401';                           
                                                        
-- For JO                                               
SELECT DRHD.AP_NO,                                      
       DRHD.JO_DR_NO DR_NO,                             
       DRHD.SUPP_CODE SUPP_CODE,                        
       DRHD.JOHD_JO_NO JO_NO,                           
       JOHD.JSHD_JS_NO JS_NO,                           
       DRHD.SUPP_DR_NO INVOICE_NO,                      
       NVL(DRHD.INVOICE_DT,DRHD.JO_DR_DATE) DR_DATE,    
       DRHD.RR_AMT RR_AMT,                              
       DRHD.RR_PAID RR_PAID,                            
       'PHP' PO_CURRENCY                                
FROM  INV_JO_DR_HDR DRHD,                               
      INV_JO_HDR JOHD                                   
WHERE DRHD.JOHD_JO_NO = JOHD.JO_NO                      
AND   DRHD.JOHD_JO_NO = '002149';                       