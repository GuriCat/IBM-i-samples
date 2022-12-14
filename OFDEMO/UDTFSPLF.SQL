--
-- DB2 FOR IBM i - modified SYSTOOLS.SPOOLED_FILE_DATA UDTF for DBCS
--
-- Run command below to make this UDTF
--   RUNSQLSTM SRCFILE(GURILIB/DB2ISVC) SRCMBR(UDTFSPLF) COMMIT(*NC)
--

CREATE OR REPLACE FUNCTION GURILIB.SPOOLED_FILE_DBCS (
    JOB_NAME VARCHAR(28) ,
    SPOOLED_FILE_NAME VARCHAR(10) ,
    SPOOLED_FILE_NUMBER VARCHAR(6) DEFAULT  '*LAST'  )
  RETURNS TABLE (
    ORDINAL_POSITION INTEGER ,
    SPOOLED_DATA VARCHAR(200) FOR MIXED DATA )
  LANGUAGE SQL
  SPECIFIC GURILIB.SPOOL_FILE_DBCS
  NOT DETERMINISTIC
  MODIFIES SQL DATA
  CALLED ON NULL INPUT
  SYSTEM_TIME SENSITIVE NO
  SET OPTION  ALWBLK = *ALLREAD ,
  ALWCPYDTA = *OPTIMIZE ,
  COMMIT = *NONE ,
  DECRESULT = (31, 31, 00) ,
  DFTRDBCOL = QSYS2 ,
  DLYPRP = *NO ,
  DYNDFTCOL = *NO ,
  DYNUSRPRF = *USER ,
  MONITOR = *SYSTEM ,
  SRTSEQ = *HEX ,
  USRPRF = *USER

BEGIN
  DECLARE ERROR_V BIGINT DEFAULT 0 ;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET ERROR_V = 1 ;
    CALL QSYS2 . QCMDEXC (
      'QSYS/CRTPF FILE(QTEMP/QIBM_SFD) RCDLEN(200) IGCDTA(*YES)' CONCAT
      ' MBR(*NONE) MAXMBRS(*NOMAX) SIZE(*NOMAX)' ) ;
  END ;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET ERROR_V = 2 ;
    CALL QSYS2 . QCMDEXC (
      'QSYS/CPYSPLF FILE(' CONCAT SPOOLED_FILE_NAME CONCAT
      ') TOFILE(QTEMP/QIBM_SFD) JOB(' CONCAT JOB_NAME CONCAT
      ') MBROPT(*REPLACE) SPLNBR(' CONCAT SPOOLED_FILE_NUMBER CONCAT
      ') OPNSPLF(*YES)' ) ;
  END ;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET ERROR_V = 3 ;
    CALL QSYS2 . QCMDEXC (
      'QSYS/CALL PGM(GURILIB/SHIFTUDTF)' ) ;
  END ;

  -- Ignore error in CRTPF

  IF ERROR_V = 2 THEN
    SIGNAL SQLSTATE '42704'
    SET MESSAGE_TEXT = 'CPYSPLFでエラー。' ;
  END IF ;

  IF ERROR_V = 3 THEN
    SIGNAL SQLSTATE '42704'
    SET MESSAGE_TEXT = 'CALLでエラー。' ;
  END IF ;

  RETURN SELECT RRN ( JL ) , JL . * FROM QTEMP . QIBM_SFD JL ORDER BY RRN ( JL )
  ASC ;
END  ;

COMMENT ON SPECIFIC FUNCTION GURILIB.SPOOL_FILE_DBCS
 IS 'DB2 FOR IBM i - modified SYSTOOLS.SPOOLED_FILE_DATA UDTF for DBCS' ;

GRANT EXECUTE
ON SPECIFIC FUNCTION GURILIB.SPOOL_FILE_DBCS
TO PUBLIC ;

GRANT ALTER , EXECUTE
ON SPECIFIC FUNCTION GURILIB.SPOOL_FILE_DBCS
TO QSYS WITH GRANT OPTION ;
