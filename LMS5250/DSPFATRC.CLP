             PGM                                                 
             DCLF       FILE(DSPFATR)                            
                                                                 
 LOOP:       SNDRCVF                                             
             IF         COND(&IN03 = '1') THEN(GOTO CMDLBL(EXIT))
             GOTO       CMDLBL(LOOP)                             
 EXIT:       ENDPGM                                              
