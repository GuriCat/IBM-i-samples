SAY " "
SAY " 「IBM iで全文検索」オブジェクトの作成 "
SAY " "
SAY " ****************************************************************"
SAY " **  OMNIFIND検索定義を作成したユーザーで実行（借用権限）    **"
SAY " ** ユーザーがオブジェクト作成に必要な権限を所有             **"
SAY " ** オブジェクトライブラリー、ソースは事前に準備             **"
SAY " **  OMNIFINDがインストール／構成済みで検索が実行できる事    **"
SAY " ** このソース内のOLIB, SLIBを実際のライブラリーに修正     **"
SAY " **  RUNSQL内の検索語２箇所をヒットがある語句に修正          **"
SAY " ** ソースメンバーOFSEARCHRのIPアドレスを                **"
SAY " **   実際のIBM iのIPアドレスに修正。                    **"
SAY " ** ソースメンバーUDTFSPLFの「DIST」を                   **"
SAY " **   実際のライブラリー名に修正。                           **"
SAY " ****************************************************************"

OLIB = 'DIST'
SLIB = 'DIST'
SFIL = 'OFDEMO'

OPTION = 1
/* TGTRLS = 'V7R4M0'                   */
TGTRLS = '*CURRENT'

IF OPTION = 0 THEN DO
  DEBUG = "*NONE"
  OPT = "*FULL"
END
IF OPTION = 1 THEN DO
  DEBUG = "*ALL"
  OPT = "*NONE"
END

SAY " "
SAY "現行ライブラリーを"OLIB"に変更します。"
  'CHGCURLIB CURLIB(&OLIB)'
SAY "現行ジョブのCCSIDを1399に変更します。"
  'CHGJOB CCSID(1399)'

  'COMMIT'

SAY " "
SAY "スプール検索出力ファイル作成"
  SAY '  スプール検索出力ファイルの作成...'
  "RUNSQL SQL('DECLARE GLOBAL TEMPORARY TABLE SPLRESULT AS ",
  '           (SELECT "SCORE",OBJECT_LIB,OBJECT_NAM,JOB_NAME,USER_NAME, ',
  "            JOB_NBR,SPOOL_NAME,SPOOL_NBR,SYS_NAME,MODIFY_TIME AS MODTS ",
  "            FROM TABLE (TSOUTQ.TS_OUTQ(''TSOUTQ'', ''ファイル'')) X ",
  '            ORDER BY "SCORE" DESC FETCH FIRST 10 ROWS ONLY) ',
  "            WITH DATA WITH REPLACE') COMMIT(*NC)"
  SAY "   結果->" RC
  SAY "   IFS検索出力ファイル作成..."
  "RUNSQL SQL('DECLARE GLOBAL TEMPORARY TABLE IFSRESULT AS ",
  '           (SELECT "SCORE",MODIFY_TIME AS MODTS,OBJECT_NAME AS PATHNAME ',
  "            FROM TABLE (TSIFS.TS_IFS(''TSIFS'', ''V7R1'')) X ",
  '            ORDER BY "SCORE" DESC FETCH FIRST 10 ROWS ONLY) ',
  "            WITH DATA WITH REPLACE') COMMIT(*NC)"
  SAY "   結果->" RC

SAY " "
SAY "スプールファイルデータの取得用UDTFの作成"
  SAY '   ILE-RPGプログラムSHIFTUDTFの作成 ...'
  'CRTBNDRPG PGM(&OLIB/SHIFTUDTF) SRCFILE(&SLIB/&SFIL) SRCMBR(SHIFTUDTF) ',
  'DBGVIEW(&DEBUG) OPTIMIZE(&OPT) TGTRLS(&TGTRLS) DFTACTGRP(*NO)'
  SAY "   結果->" RC
  SAY '   SQL-UDTF UDTFSPLFの作成 ...'
  'RUNSQLSTM SRCFILE(&SLIB/&SFIL) SRCMBR(UDTFSPLF) COMMIT(*NC)'
  SAY "   結果->" RC

SAY " "
SAY " ILE-RPG検索アプリケーションの作成"
  SAY '  表示装置ファイルOFSEARCHDの作成 ...'
  'CRTDSPF FILE(&OLIB/OFSEARCHD) SRCFILE(&SLIB/&SFIL) SRCMBR(OFSEARCHD)'
  SAY "   結果->" RC
  'DLTPGM PGM(&OLIB/OFSEARCHR)'
  SAY '   ILE-RPGプログラムOFSEARCHRの作成 ...'
  'CRTBNDRPG PGM(&OLIB/OFSEARCHR) SRCFILE(&SLIB/&SFIL) SRCMBR(OFSEARCHR) ',
  'DBGVIEW(&DEBUG) OPTIMIZE(&OPT) TGTRLS(&TGTRLS) ',
  'DFTACTGRP(*NO) USRPRF(*OWNER)'
  SAY "   結果->" RC

SAY " "
SAY "エラー（結果が0以外）の有無を確認してください。"
SAY "エラーがある場合はジョブログで原因を確認し、修正して再実行します。"
SAY " "
SAY "下記コマンドで検索アプリケーションを実行できます。"
SAY "※このプロシージャーの冒頭で現行ライブラリーを"OLIB"に変更しています。"
SAY "   CALL OFSEARCHR"
SAY " "
SAY "プロシージャーの終わり。"
SAY " "
