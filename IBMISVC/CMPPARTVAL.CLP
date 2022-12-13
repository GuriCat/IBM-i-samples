             PGM

             DCL        VAR(&SVR1) TYPE(*CHAR) LEN(10) VALUE(サーバー/区画#1)
             DCL        VAR(&SVR2) TYPE(*CHAR) LEN(10) VALUE(サーバー/区画#2)
             DCL        VAR(&SVR3) TYPE(*CHAR) LEN(10) VALUE(サーバー/区画#3)
             DCL        VAR(&STMT) TYPE(*CHAR) LEN(1000)

             /* CREATE INDIVIDUAL SYSVAL TABLE */
             CHGVAR     VAR(&STMT) VALUE( +
  'DECLARE GLOBAL TEMPORARY TABLE SESSION/SYSVAL1 AS +
    (SELECT * FROM ' || &SVR1 |< '/QSYS2/SYSTEM_VALUE_INFO +
       ORDER BY SYSTEM_VALUE_NAME) +
     WITH DATA INCLUDING DEFAULTS WITH REPLACE')
             RUNSQL     SQL(&STMT) COMMIT(*NC)
             CHGVAR     VAR(&STMT) VALUE( +
  'DECLARE GLOBAL TEMPORARY TABLE SESSION/SYSVAL2 AS +
    (SELECT * FROM ' || &SVR2 |< '/QSYS2/SYSTEM_VALUE_INFO +
       ORDER BY SYSTEM_VALUE_NAME) +
     WITH DATA INCLUDING DEFAULTS WITH REPLACE')
             RUNSQL     SQL(&STMT) COMMIT(*NC)
             CHGVAR     VAR(&STMT) VALUE( +
  'DECLARE GLOBAL TEMPORARY TABLE SESSION/SYSVAL3 AS +
    (SELECT * FROM ' || &SVR3 |< '/QSYS2/SYSTEM_VALUE_INFO +
       ORDER BY SYSTEM_VALUE_NAME) +
     WITH DATA INCLUDING DEFAULTS WITH REPLACE')
             RUNSQL     SQL(&STMT) COMMIT(*NC)

             /* CREATE ALL SYSVAL INFORMATION WORK TABLE */
             CHGVAR     VAR(&STMT) VALUE( +
  'CREATE OR REPLACE TABLE QTEMP/CMPSYSVAL +
    (SYSVAL CHAR(10) NOT NULL, ' || &SVR1 |< '_VAL CHAR(32) CCSID 5035, +
                               ' || &SVR2 |< '_VAL CHAR(32) CCSID 5035, +
                               ' || &SVR2 |< '_DIF INT, +
                               ' || &SVR3 |< '_VAL CHAR(32) CCSID 5035, +
                               ' || &SVR3 |< '_DIF INT) +
     ON REPLACE DELETE ROWS')
             RUNSQL     SQL(&STMT) COMMIT(*NC)

             /* JOIN ALL SYSVAL TABLES AND INSERT TO WROK TABLE */
             RUNSQL     SQL( +
  'INSERT INTO QTEMP/CMPSYSVAL +
     SELECT S1.SYSTEM_VALUE_NAME AS SYSVALNAME, +
       SUBSTRING(IFNULL(S1.CURRENT_CHARACTER_VALUE, +
                        CHAR(S1.CURRENT_NUMERIC_VALUE)), 1, 32) ' +
                                                || &SVR1 |< '_VAL, +
       SUBSTRING(IFNULL(S2.CURRENT_CHARACTER_VALUE, +
                        CHAR(S2.CURRENT_NUMERIC_VALUE)), 1, 32) ' +
                                                || &SVR2 |< '_VAL, +
       CASE +
         WHEN S1.CURRENT_NUMERIC_VALUE <> S2.CURRENT_NUMERIC_VALUE THEN 1 +
         WHEN S1.CURRENT_CHARACTER_VALUE <> S2.CURRENT_CHARACTER_VALUE THEN 2 +
         ELSE 0 +
       END AS ' || &SVR2 |< '_DIF, +
       SUBSTRING(IFNULL(S3.CURRENT_CHARACTER_VALUE, +
                        CHAR(S3.CURRENT_NUMERIC_VALUE)), 1, 32) ' +
                                                || &SVR3 |< '_VAL, +
       CASE +
         WHEN S1.CURRENT_NUMERIC_VALUE <> S3.CURRENT_NUMERIC_VALUE THEN 1 +
         WHEN S1.CURRENT_CHARACTER_VALUE <> S3.CURRENT_CHARACTER_VALUE THEN 2 +
         ELSE 0 +
       END AS ' || &SVR3 |< '_DIF +
       FROM SESSION.SYSVAL1 AS S1 +
         FULL OUTER JOIN SESSION/SYSVAL2 AS S2 +
           ON S1.SYSTEM_VALUE_NAME = S2.SYSTEM_VALUE_NAME +
         FULL OUTER JOIN SESSION/SYSVAL3 AS S3 +
           ON S1.SYSTEM_VALUE_NAME = S3.SYSTEM_VALUE_NAME' +
                                             ) COMMIT(*NC)

             OVRPRTF    FILE(QPQUPRFIL) PAGESIZE(*N 198) CPI(15) +
                          SPLFNAME(CMPPARTVAL) OVRSCOPE(*JOB)
             RUNQRY     QRYFILE((QTEMP/CMPSYSVAL)) OUTTYPE(*PRINTER) +
                          FORMSIZE(*RUNOPT 198)
             DLTOVR     FILE(QPQUPRFIL) LVL(*JOB)
             DSPSPLF    FILE(CMPPARTVAL) SPLNBR(*LAST)

             ENDPGM
