      *
      * May not work for IBM i 7.1.
      * Specify SQLPKG(any_obj_name) to avoid connection error.
      *
      * > CRTSQLRPGI OBJ(DSPSVRTIMR) SRCFILE(IBMISVCSS) SQLPKG(QTEMP/XX)
      *   DBGVIEW(*SOURCE)
      *
      * See SNTP client log file to check activity.
      * > EDTF STMF('/QIBM/USERDATA/OS400/TCPIP/NTP')
      *
     H DFTACTGRP(*NO) ACTGRP(*NEW) OPTION(*SRCSTMT : *NOUNREF : *NODEBUGIO)
     H ALWNULL(*INPUTONLY)
      *
     FDSPSVRTIMDCF   E             WORKSTN
     F                                     SFILE(SFL : SFLRRN)
     F                                     INFDS(SFLDS)
      *
     D SFLRRN          S              4P 0
     D SFLDS           DS
     D   sflRcdNo            378    379I 0
      *
     D sysValInfo    E DS                  EXTNAME('QSYS2/SYSVALINFO')
     D nulIndArr3      S              5I 0 DIM(3)
     D charVal         S             64A
     D partTS          S               Z
      * For JOB_INFO table function
     D jobInfo         DS
     D   jobName                     28A
     D   jobActTime                    Z
     D nulIndArr2      S              5I 0 DIM(2)
     D wTime           S               Z
     D elapsedDays     S              3P 0
     D elapsedHours    S                   LIKE(elapsedDays)
     D elapsedMins     S                   LIKE(elapsedDays)
      *
     D stmt            S            500
     D SQLerror        S               N
      * Procedures
     D cmdLine         PR                  EXTPGM('QUSCMDLN')
     D sndStsMsg       PR            10I 0
     D   msgTxt                     200A   CONST VARYING
     D usleep          PR                  EXTPROC('usleep')
     D   milSec                      10U 0 VALUE
      * Depends on lpar configuration
     D lpar            S             10    DIM(4) VARYING
     D remoteDB        S             10    VARYING
     D lparNumber      C                   CONST(3)
      * Misc
     D i               S              3P 0
     D rc              S             10I 0
      *
        EXSR #init;

        // Main loop
        DOW (1 = 1);

          IF *IN03; // Exit
            LEAVE;
          ENDIF;

          IF *IN21; // Show command window
            CALLP cmdLine();
            *IN21 = *OFF;
            ITER;
          ENDIF;

          IF *IN05; // Refresh

            // Run sql and get info
            *IN32 = *OFF; // SFLDSP SFLDSPCTL
            *IN30 = *ON;  // SFLCLR
            WRITE SFLCTL;

            FOR i = 1 TO lparNumber;
              EXSR #getLparTimes;
            ENDFOR;

          ENDIF;

          // Display status
          WRITE HEADER;
          WRITE FOOTER;
          *IN32 = *ON;  // SFLDSP SFLDSPCTL
          *IN30 = *OFF; // SFLCLR
          EXFMT SFLCTL;

        ENDDO;

        *INLR = *ON;
        RETURN;

        // Subroutines //////////////////////////////////

        // Set DRDA host name defined at RDBDIR
        BEGSR #init;

          lpar(1) = '(サーバー/区画#1)';
          lpar(2) = '(サーバー/区画#2)';
          lpar(3) = '(サーバー/区画#3)';
          *IN05 = *ON; // For first time
          // Avoid CPI8350
          EXEC SQL SET OPTION COMMIT = *NONE;

        ENDSR;

        // Check SQL error
        BEGSR #checkSQLError;

          IF %SUBST(SQLSTATE : 1 : 2) <> '00';
            sndStsMsg('SQLエラー: SQLCODE ' + %CHAR(SQLCODE) +
                      ', SQLSTATE ' + SQLSTATE);
            SQLerror = *ON;
            usleep(500000); // Wait 0.5 sec
          ENDIF;

        ENDSR;

        // Get time information of respective lpar
        BEGSR  #getLparTimes;

          // partition info
          PARTID    = i;
          PARTNAME  = lpar(i);
          // Disconnect from database (LPAR)
          EXEC SQL DISCONNECT ALL;
          EXSR #checkSQLError;
          // Connect to specified database (LPAR)
          remoteDB = lpar(i);
          EXEC SQL CONNECT TO :remoteDB;
          EXSR #checkSQLError;

          // Get QDATETIME system value
          SQLerror = *OFF;
          stmt = 'SELECT * FROM QSYS2.SYSTEM_VALUE_INFO ' +
                 'WHERE SYSTEM_VALUE_NAME = ''QDATETIME'' FOR FETCH ONLY';
          sndStsMsg(stmt);
          EXEC SQL PREPARE s1 FROM :stmt;
          EXSR #checkSQLError;
          EXEC SQL DECLARE c1 CURSOR for s1;
          EXEC SQL OPEN c1;
          EXSR #checkSQLError;
          EXEC SQL FETCH c1 INTO :sysValInfo :nulIndArr3;
          EXSR #checkSQLError;
          EXEC SQL CLOSE c1;
          EXSR #checkSQLError;
          // Convert result
          IF NOT SQLerror;
            sndStsMsg(remoteDB + 'から正常にQDATETIMEが取得された。');
            charVal = CURCHARVAL;   // vargraphic(1280) ccsid(1200)
            partTS = %TIMESTAMP(%SUBST(charVal : 1 : 4) + '-' +    // Year
                                %SUBST(charVal : 5 : 2) + '-' +    // Month
                                %SUBST(charVal : 7 : 2) + '-' +    // Day
                                %SUBST(charVal : 9 : 2) + '.' +    // Hour
                                %SUBST(charVal : 11 : 2) + '.' +   // Minute
                                %SUBST(charVal : 13 : 2) + '.' +   // Second
                                %SUBST(charVal : 15 : 6));         // ms
            PARTDATE = %DATE(partTS);
            PARTTIME = %TIME(partTS);
            PARTTDIF = %DIFF(PARTTIME : %TIME() : *S);
          ELSE;
            sndStsMsg(remoteDB + 'のデータ取得でエラー。SQLSTATE = ' +
                      SQLSTATE);
            PARTDATE = *LOVAL;
            PARTTIME = *LOVAL;
            PARTTDIF = *LOVAL;
          ENDIF;
          usleep(500000); // Wait 0.5 sec

          // Get QIPLDATTIM system value
          SQLerror = *OFF;
          stmt = 'SELECT * FROM QSYS2.SYSTEM_VALUE_INFO ' +
                 'WHERE SYSTEM_VALUE_NAME = ''QIPLDATTIM'' FOR FETCH ONLY';
          sndStsMsg(stmt);
          EXEC SQL PREPARE s2 FROM :stmt;
          EXSR #checkSQLError;
          EXEC SQL DECLARE c2 CURSOR for s2;
          EXEC SQL OPEN c2;
          EXSR #checkSQLError;
          EXEC SQL FETCH c2 INTO :sysValInfo :nulIndArr3;
          EXSR #checkSQLError;
          EXEC SQL CLOSE c2;
          EXSR #checkSQLError;
          // Convert result
          IF NOT SQLerror;
            sndStsMsg(remoteDB + 'から正常にQIPLDATTIMが取得された。');
            charVal = CURCHARVAL;   // vargraphic(1280) ccsid(1200)
            IF charVal <> '*NONE';
              PARTNIPL = %SUBST(charVal : 2 : 2) + '/' +  // Year
                         %SUBST(charVal : 4 : 2) + '/' +  // Month
                         %SUBST(charVal : 6 : 2) + '  ' +  // Day
                         %SUBST(charVal : 8 : 2) + '.' +  // Hour
                         %SUBST(charVal : 10 : 2) + '.' + // Min
                         %SUBST(charVal : 12 : 2);        // Sec
            ELSE;
              PARTNIPL = *BLANKS;
            ENDIF;
          ELSE;
            sndStsMsg(remoteDB + 'のデータ取得でエラー。SQLSTATE = ' +
                      SQLSTATE);
            PARTNIPL = *BLANKS;
          ENDIF;
          usleep(500000); // Wait 0.5 sec

          // Get SCPF start date and time
          SQLerror = *OFF;
          stmt = 'SELECT JOB_NAME, JOB_ACTIVE_TIME FROM TABLE(' +
                 'QSYS2.JOB_INFO(JOB_STATUS_FILTER => ''*ACTIVE'', ' +
                                'JOB_USER_FILTER => ''QSYS'')) X ' +
                 'WHERE JOB_NAME LIKE ''%SCPF'' FOR FETCH ONLY';
          sndStsMsg(stmt);
          EXEC SQL PREPARE s3 FROM :stmt;
          EXSR #checkSQLError;
          EXEC SQL DECLARE c3 CURSOR for s3;
          EXEC SQL OPEN c3;
          EXSR #checkSQLError;
          EXEC SQL FETCH c3 INTO :jobInfo :nulIndArr2;
          EXSR #checkSQLError;
          EXEC SQL CLOSE c3;
          EXSR #checkSQLError;
          // Convert result
          IF NOT SQLerror;
            sndStsMsg(remoteDB + 'から正常にJOBINFOが取得された。');
            PARTUPDT = %DATE(jobActTime);
            PARTUPTI = %TIME(jobActTime);
            wTime = %TIMESTAMP();
            elapsedDays = %DIFF(wTime : jobActTime : *D);
            IF elapsedDays > 0;
              wTime -= %DAYS(elapsedDays);
            ENDIF;
            elapsedHours = %DIFF(wTime : jobActTime : *H);
            IF elapsedHours > 0;
              wTime -= %HOURS(elapsedHours);
            ENDIF;
            elapsedMins = %DIFF(wTime : jobActTime : *MN);
            PARTUPDU = %CHAR(elapsedDays) + '日' +
                       %CHAR(elapsedHours) + '時' +
                       %CHAR(elapsedMins) + '分';
          ELSE;
            sndStsMsg(remoteDB + 'のデータ取得でエラー。SQLSTATE = ' +
                      SQLSTATE);
            PARTUPDT = *LOVAL;
            PARTUPTI = *LOVAL;
            PARTUPDU = *BLANKS;
          ENDIF;
          usleep(500000); // Wait 0.5 sec

          SFLRRN = i;
          WRITE SFL;
          sndStsMsg(' ');

       ENDSR;

      *
     P sndStsMsg       B
     D sndStsMsg       PI            10I 0
     D   msgTxt                     200A   CONST VARYING
      *
      /INCLUDE QSYSINC/QRPGLESRC,QUSEC
      *
     D QMHSNDPM        PR                  EXTPGM('QMHSNDPM')
     D   msgID                        7A   CONST
     D   msgFile                     20A   CONST
     D   msgData                    200A   CONST OPTIONS(*VARSIZE)
     D   msgLen                      10I 0 CONST
     D   msgType                     10A   CONST
     D   msgStkEnt                   10A   CONST
     D   msgRStkEnt                  10I 0 CONST
     D   msgRtnKey                    4A
     D   msgErrDS                          LIKEDS(QUSEC) OPTIONS(*VARSIZE)
      *
     D messageKey      S              4A
      *
       QUSBPRV = 16;

       QMHSNDPM('CPF9897' : 'QCPFMSG   *LIBL     ' :
                msgTxt : %LEN(msgTxt) : '*STATUS   ' :
                '*EXT      ' : 0 : messageKey : QUSEC);

       RETURN QUSBAVL;
      *
     P                 E
