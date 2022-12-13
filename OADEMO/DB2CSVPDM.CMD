 /*コンパイル                                                               + 
  > CRTCMD CMD(GURILIB/DB2CSVPDM) PGM(GURILIB/DB2CSV) SRCFILE(GURILIB/OADEMO) + 
     ALWLMTUSR(*YES)                                                         + 
    コマンドDB2CSVPDMがライブラリーGURILIBに作成された。                + 
                                                                            */  
                                                                                
             CMD        PROMPT('DBのCSVへの変換')                           
                                                                                
             PARM       KWD(LIB) TYPE(*NAME) MIN(1) MAX(1) +                    
                          EXPR(*YES) PROMPT('ライブラリー')                   
                                                                                
             PARM       KWD(FILE) TYPE(*NAME) MIN(1) MAX(1) +                   
                          EXPR(*YES) PROMPT('データベース・ファイル')         
                                                                                
             PARM       KWD(TFR) TYPE(*CHAR) LEN(1) RSTD(*YES) +                
                          VALUES('N' 'F') MIN(1) MAX(1) EXPR(*YES) +            
                          PROMPT('転送方法')                                  
