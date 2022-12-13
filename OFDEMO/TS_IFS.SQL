CREATE OR REPLACE FUNCTION TSIFS.TS_IFS (
      p_ts_collection VARCHAR(1000),
      p_search_string VARCHAR(1000),
      p_search_options VARCHAR(32700) CCSID 1399 DEFAULT NULL,
      p_result_options VARCHAR(32700) CCSID 1399 DEFAULT NULL
    )
  RETURNS TABLE (
    OBJECT_NAME VARCHAR(5000) CCSID 1399,
    SCORE DECIMAL(4,1),
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
    /* https://www.ibm.com/support/knowledgecenter/ja/ssw_ibm_i_74/rzash/extensions_search.htm */
    DECLARE V_OBJTYPE CHAR(10) CCSID 1399;
    DECLARE V_OBJATTR CHAR(10) CCSID 1399;
    DECLARE V_CONTAINING_OBJECT_LIB CHAR(10) CCSID 1399;
    DECLARE V_CONTAINING_OBJECT_NAME CHAR(10) CCSID 1399;
    DECLARE V_OBJECTINFOR XML;
--    DECLARE V_XML XML;
    DECLARE V_OBJECT_NAME VARCHAR(5000) CCSID 1399;
    DECLARE V_MODIFY_TIME TIMESTAMP;
    DECLARE V_SCORE DOUBLE;
    DECLARE V_SCORE_PERCENT DECIMAL(4,1);

    DECLARE SQLCODE INT DEFAULT 0;
    DECLARE V_Result_Set_Locator RESULT_SET_LOCATOR VARYING;
    DECLARE GETout INTEGER DEFAULT 0;

    -- Declare condition handler
    /* end loop when row not found is hit */
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET GETout = 1;
    /* SQL0204 means the procedure has not been called */
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' SET GETout = 1;
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42815' SET GETout = 1;
    DECLARE CONTINUE HANDLER FOR SQLSTATE '22503' SET GETout = 1;
    /* SQL0480 means the procedure has not been called */
    DECLARE CONTINUE HANDLER FOR SQLSTATE '51030' SET GETout = 1;

    CALL QDBTSLIB.SYSTS_SEARCH_RETURN_TO_CALLER(
      p_ts_collection,
      p_search_string,
      p_search_options,
      p_result_options
    );

    ASSOCIATE LOCATOR (V_Result_Set_Locator) WITH PROCEDURE QDBTSLIB.SYSTS_SEARCH_RETURN_TO_CALLER;
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
      SET V_OBJECT_NAME = (
            SELECT "file_path"
              FROM XMLTABLE(XMLNAMESPACES ('http://www.ibm.com/xmlns/prod/db2textsearch/obj1' AS "x"), 
                'x:Stream_File' PASSING V_OBJECTINFOR 
                    COLUMNS "file_path" VARCHAR(5000) CCSID 1399 PATH 'x:file_path') Stream_File);
      SET V_SCORE_PERCENT = V_SCORE * 100;
      PIPE (
        V_OBJECT_NAME,
        V_SCORE_PERCENT,
        V_OBJTYPE,
        V_OBJATTR,
        V_MODIFY_TIME
      );
    END WHILE;

    CLOSE C1;
    RETURN;

  END;


/*(実行例)
SELECT SCORE,
      TRIM(OBJECT_NAME) AS FILE_PATH,
      OBJTYPE,
      OBJATTR,
      TO_CHAR(MODIFY_TIME, 'YYYY/MM/DD HH24:MI:SS') AS LAST_MODIFIED
 FROM TABLE (
     TSIFS.TS_IFS('TSIFS', 'アダプタ')
   ) x
 ORDER BY SCORE DESC;
*/
