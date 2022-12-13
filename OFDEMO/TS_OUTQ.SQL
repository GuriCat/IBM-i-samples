-- Ref: https://www.ibm.com/support/pages/omnifind-systssearchreturntocaller
CREATE OR REPLACE FUNCTION TSOUTQ.TS_OUTQ (
      p_ts_collection VARCHAR(1000),
      p_search_string VARCHAR(1000),
      p_search_options VARCHAR(32700) CCSID 1399 DEFAULT NULL,
      p_result_options VARCHAR(32700) CCSID 1399 DEFAULT NULL
    )
  RETURNS TABLE (
    OBJECT_LIB CHAR(10) CCSID 1399,
    OBJECT_NAM CHAR(10) CCSID 1399,
    JOB_NAME CHAR(10) CCSID 1399,
    USER_NAME CHAR(10) CCSID 1399,
    JOB_NBR CHAR(6) CCSID 1399,
    SPOOL_NAME CHAR(10) CCSID 1399,
    SPOOL_NBR CHAR(6) CCSID 1399,
    SYS_NAME CHAR(10) CCSID 1399,
    CRT_DATE CHAR(7) CCSID 1399,
    CRT_TIME CHAR(6) CCSID 1399,
    SCORE DECIMAL(4, 1),
    OBJTYPE CHAR(10) CCSID 1399,
    OBJATTR CHAR(10) CCSID 1399,
    MODIFY_TIME TIMESTAMP
  )
  LANGUAGE SQL
  NOT DETERMINISTIC
  NO EXTERNAL ACTION
  MODIFIES SQL DATA
  CALLED ON NULL INPUT
  SET OPTION COMMIT = *NONE,
             DBGVIEW = *SOURCE
  BEGIN
    DECLARE V_OBJTYPE CHAR(10) CCSID 1399;
    DECLARE V_OBJATTR CHAR(10) CCSID 1399;
    DECLARE V_CONTAINING_OBJECT_LIB CHAR(10) CCSID 1399;
    DECLARE V_CONTAINING_OBJECT_NAME CHAR(10) CCSID 1399;
    DECLARE V_OBJECTINFOR XML;
    DECLARE V_JOB_NAME CHAR(10) CCSID 1399;
    DECLARE V_USER_NAME CHAR(10) CCSID 1399;
    DECLARE V_JOB_NBR CHAR(6) CCSID 1399;
    DECLARE V_SPOOL_NAME CHAR(10) CCSID 1399;
    DECLARE V_SPOOL_NBR CHAR(6) CCSID 1399;
    DECLARE V_SYS_NAME CHAR(10) CCSID 1399;
    DECLARE V_CRT_DATE CHAR(7) CCSID 1399;
    DECLARE V_CRT_TIME CHAR(6) CCSID 1399;
    DECLARE V_SCORE DOUBLE;
    DECLARE V_SCORE_PERCENT DECIMAL(4, 1);
    DECLARE V_MODIFY_TIME TIMESTAMP;
    DECLARE SQLCODE INT DEFAULT 0;
    DECLARE V_Result_Set_Locator RESULT_SET_LOCATOR VARYING;
    DECLARE GETout INTEGER DEFAULT 0;
    -- Declare condition handler
    /* end loop when row not found is hit */
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET GETout = 1;
    /* SQL0204 means the procedure has not been called */
    -- 未定義のオブジェクトまたは制約名が見つかりました。
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' SET GETout = 1;
    -- データ・タイプ、長さ、位取り、値、または CCSID が無効です。
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42815' SET GETout = 1;
    -- 名前のストリング表記が無効です。
    DECLARE CONTINUE HANDLER FOR SQLSTATE '22503' SET GETout = 1;
    -- DESCRIBE PROCEDURE ステートメントまたは ASSOCIATE LOCATOR 
    -- ステートメントで参照されるプロシージャーは、
    -- まだアプリケーション・プロセス内で呼び出されていません。
    DECLARE CONTINUE HANDLER FOR SQLSTATE '51030' SET GETout = 1;
    CALL QDBTSLIB.SYSTS_SEARCH_RETURN_TO_CALLER(
      p_ts_collection,
      p_search_string,
      p_search_options,
      p_result_options
    );
    ASSOCIATE LOCATOR (V_Result_Set_Locator) 
        WITH PROCEDURE QDBTSLIB.SYSTS_SEARCH_RETURN_TO_CALLER;
    ALLOCATE C1 CURSOR FOR RESULT SET V_Result_Set_Locator;
    LOOP_ON_RESULTS: WHILE (GETout = 0) DO
      FETCH FROM C1
        INTO V_OBJTYPE,
             V_OBJATTR,
             V_CONTAINING_OBJECT_LIB,
             V_CONTAINING_OBJECT_NAME,
             V_OBJECTINFOR,
             V_MODIFY_TIME,
             V_SCORE;
      IF (GETout = 1) THEN
        LEAVE LOOP_ON_RESULTS;
      END IF;
      SELECT *
        INTO V_JOB_NAME,
             V_USER_NAME,
             V_JOB_NBR,
             V_SPOOL_NAME,
             V_SPOOL_NBR,
             V_SYS_NAME,
             V_CRT_DATE,
             V_CRT_TIME
        FROM
          XMLTABLE(
            XMLNAMESPACES ('http://www.ibm.com/xmlns/prod/db2textsearch/obj1' AS "x"), 'x:Spool_File' 
                PASSING V_OBJECTINFOR COLUMNS 
                    "job_name" CHAR(10) CCSID 1399 PATH 'x:job_name', 
                    "job_user_name" CHAR(10) CCSID 1399 PATH 'x:job_user_name',
                    "job_number" CHAR(6) CCSID 1399 PATH 'x:job_number', 
                    "spool_file_name" CHAR(10) CCSID 1399 PATH 'x:spool_file_name',
                    "spool_file_number" CHAR(6) CCSID 1399 PATH 'x:spool_file_number', 
                    "job_system_name" CHAR(10) CCSID 1399 PATH 'x:job_system_name', 
                    "create_date" CHAR(7) CCSID 1399 PATH 'x:create_date', 
                    "create_time" CHAR(6) CCSID 1399 PATH 'x:create_time');
      SET V_SCORE_PERCENT = V_SCORE * 100;
      PIPE (
        V_CONTAINING_OBJECT_LIB,
        V_CONTAINING_OBJECT_NAME,
        V_JOB_NAME,
        V_USER_NAME,
        V_JOB_NBR,
        V_SPOOL_NAME,
        V_SPOOL_NBR,
        V_SYS_NAME,
        V_CRT_DATE,
        V_CRT_TIME,
        V_SCORE_PERCENT,
        V_OBJTYPE,
        V_OBJATTR,
        V_MODIFY_TIME
      );
    END WHILE;
    CLOSE C1;
    RETURN;
  END;

-- (実行例)
-- SELECT * FROM TABLE (TSOUTQ.TS_OUTQ('TSOUTQ', 'コンパイル')) x ORDER BY SCORE DESC;
