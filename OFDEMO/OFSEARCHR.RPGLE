     H DFTACTGRP(*NO) ACTGRP(*NEW)
     H OPTION(*SRCSTMT : *NOUNREF : *NODEBUGIO)
     H DATEDIT(*YMD)
      *ファイル定義
     FOFSEARCHD CF   E             WORKSTN INDDS(ws)
     F                                     SFILE(MEISFL:@SRRN)
     FIFSRESULT IF   E             DISK    USROPN
     F                                     RENAME(IFSRESULT:IFSR)
     FSPLRESULT IF   E             DISK    USROPN
     F                                     RENAME(SPLRESULT:SPLR)
      * API QCMDEXCのプロトタイプ
     DQCMDEXC          PR                  EXTPGM('QCMDEXC')
     D  cmdStr                     2048    CONST OPTIONS(*VARSIZE)
     D  cmdLen                       15P 5 CONST
     D  cmdIGC                        3    CONST OPTIONS(*NOPASS)
      *
      * DBCS考慮版SCANR
     Dxscanr           PR             5I 0
     D  searchArg                     1    CONST
     D  searchStr                  2048    CONST OPTIONS(*VARSIZE)
      * DBCS文字列の短縮
     DtrimDBCS         PR          1024
     D  trimStr                    1024    CONST
     D  trimPos                       5P 0 CONST
      *
     Dcmd              S           2048    VARYING
      *プログラム名の取得
     D                SDS
     D PGMNAM            *PROC
      *名前付き標識
     Dws               DS                  QUALIFIED
     D  exit_03                        N   OVERLAY(ws : 3)
     D  list_04                        N   OVERLAY(ws : 4)
     D  prev_07                        N   OVERLAY(ws : 7)
     D  next_08                        N   OVERLAY(ws : 8)
     D  cncl_12                        N   OVERLAY(ws : 12)
     D  updateIFS_14                   N   OVERLAY(ws : 14)
     D  updateSPL_16                   N   OVERLAY(ws : 16)
     D  sflDspCtlClr_31_32...
     D                                2    OVERLAY(ws : 31)
     D  errorMsg_50                    N   OVERLAY(ws : 50)
     D  dspDetail_60                   N   OVERLAY(ws : 60)
     D  dspIFS_70                      N   OVERLAY(ws : 70)
      *表示色属性
     D cGreen          C                   X'20'
     D cGreenU         C                   X'24'
     D cBlue           C                   X'3A'
     D cBlueU          C                   X'3E'
     D cRed            C                   X'28'
     D cRedU           C                   X'2C'
     D cWhite          C                   X'22'
     D cWhiteU         C                   X'26'
     D cPink           C                   X'38'
     D cPinkU          C                   X'3C'
     D cTrq            C                   X'30'
     D cTrqU           C                   X'34'
      *その他変数
     DoptCount         S              5S 0
     DworkRRN          S                   LIKE(@SRRN)
     DI                S                   LIKE(@SRRN)
     DJ                S                   LIKE(@SRRN)
     DhostIP           C                   'x.x.x.x'
     DPCCmd            S           1023    VARYING
     DdirName          S           1023    VARYING
     DfileName         S           1023    VARYING
     DfileExt          S              5
     DtsChr            S             26
      *
      *********************
      *メインルーチン
      *********************

        //初期設定
        SEARCHTGT = 1; //検索対象1=IFS 2=SPL
        SEARCHLMT = 1; //検索上限1=20 2=無制限
        cmd = 'STRPCO PCTA(*NO)';
        MONITOR;
          CALLP QCMDEXC(cmd : %LEN(cmd));
        ON-ERROR *ALL;
        ENDMON;

        DOW (1 = 1);

          WRITE FOOTER; //フッター（機能キーガイド）
          EXFMT HEADER; //見出し（検索条件）

          IF ws.exit_03; // F3=終了
            LEAVE;
          ENDIF;

          ws.errorMsg_50 = *OFF;

          IF ws.updateIFS_14; // F14=IFS索引更新
            cmd = 'RUNSQL SQL(''CALL TSIFS.UPDATE'') COMMIT(*NC)';
            ws.errorMsg_50 = *ON;
            MSGDTA = 'IFS索引の更新終了。';
            MONITOR;
              CALLP QCMDEXC(cmd : %LEN(cmd));
            ON-ERROR *ALL;
              MSGDTA = 'IFS索引の更新でエラー。';
            ENDMON;
            ITER;
          ENDIF;

          IF ws.updateSPL_16; // F16=SPL索引更新
            cmd = 'RUNSQL SQL(''CALL TSOUTQ.UPDATE'') COMMIT(*NC)';
            ws.errorMsg_50 = *ON;
            MSGDTA = 'SPL索引の更新終了。';
            MONITOR;
              CALLP QCMDEXC(cmd : %LEN(cmd));
            ON-ERROR *ALL;
              MSGDTA = 'SPL索引の更新でエラー。';
            ENDMON;
            ITER;
          ENDIF;

          IF SEARCHWRD = *BLANKS; //検索語未入力
            ws.errorMsg_50 = *ON;
            MSGDTA = '検索語が未入力。';
            ITER;
          ENDIF;

          IF SEARCHTGT = 0; //検索対象未選択
            ws.errorMsg_50 = *ON;
            MSGDTA = '検索対象が未選択。';
            ITER;
          ENDIF;

          IF SEARCHLMT = 0; //検索上限件数未選択
            ws.errorMsg_50 = *ON;
            MSGDTA = '検索上限件数が未選択。';
            ITER;
          ENDIF;

          //サブファイル・レコードのセット
          EXSR #SETSF;

          //検索条件に合致したデータが見つからない
          IF RCDNUM = 0;
            ws.errorMsg_50 = *ON;
            MSGDTA = '検索条件に合致したデータが見つからない';
            ITER;
          ENDIF;

          //サブファイル表示
          ws.sflDspCtlClr_31_32 = '10'; // 31:SFLDSP/SFLDSPCTL, 32:SFLCLR
          @SPLOC = 1;                   // SFLRCDNBR
          ws.dspDetail_60 = *ON;        //見出し表示切替
          ws.exit_03 = *OFF;
          ws.cncl_12 = *OFF;

          DOW (1 = 1);

            WRITE FOOTER; //フッター（機能キーガイド）
            SEARCHARG = cGreen + '対象' +
                        cPink + %SUBST('IFSSPL':(SEARCHTGT - 1) * 3 + 1 : 3) +
                        cGreen + '上限' +
                        cPink + %SUBST('20 MAX':(SEARCHLMT - 1) * 3 + 1 : 3);
            WRITE HEADER; //見出し（検索条件）
            //サブファイル
            EXFMT MEICTL;

            IF ws.exit_03 OR ws.cncl_12; // F3/12=戻る
              LEAVE;
            ENDIF;
            ws.errorMsg_50 = *OFF;

            //サブファイル対話処理
            EXSR #SFLP;

            IF ws.exit_03 OR ws.cncl_12; // F3/12=戻る
              LEAVE;
            ENDIF;

          ENDDO;
          ws.dspDetail_60 = *OFF;

        ENDDO;

        *INLR = *ON;
        RETURN;

      *********************
      *サブルーチン
      *********************

        //サブファイルのセット////////////////////////////
        BEGSR #SETSF;

          //サブファイルのクリア
          ws.sflDspCtlClr_31_32 = '01'; // 31:SFLDSP/SFLDSPCTL, 32:SFLCLR
          WRITE MEICTL;
          ws.sflDspCtlClr_31_32 = '10';

          //変数の初期化
          @SRRN = 0; // SFLCSRRRN(SFL内のカーソルが位置するレコードのRRN)
          RCDNUM = 0;
          OPTION = ' ';

          // OmniFind検索とサブファイルへの書出し
          IF SEARCHTGT = 1; // IFS検索SQL
            cmd = 'RUNSQL SQL(''' +
                  'DECLARE GLOBAL TEMPORARY TABLE IFSRESULT AS ' +
                  '(SELECT "SCORE", MODIFY_TIME AS MODTS, ' +
                  'OBJECT_NAME AS PATHNAME FROM TABLE ' +
                  '(TSIFS.TS_IFS(''''TSIFS'''',''''' +
                  %TRIM(SEARCHWRD) + ''''')) X';
          ELSE;             // SPL検索SQL
            cmd = 'RUNSQL SQL(''' +
                  'DECLARE GLOBAL TEMPORARY TABLE SPLRESULT AS ' +
                  '(SELECT "SCORE",OBJECT_LIB,OBJECT_NAM,JOB_NAME,' +
                  'USER_NAME,JOB_NBR,SPOOL_NAME,SPOOL_NBR,SYS_NAME,' +
                  'MODIFY_TIME AS MODTS FROM TABLE ' +
                  '(TSOUTQ.TS_OUTQ(''''TSOUTQ'''',''''' +
                  %TRIM(SEARCHWRD) + ''''')) X';
          ENDIF;
          IF SEARCHLMT = 1;
            cmd +=
                ' ORDER BY "SCORE" DESC FETCH FIRST 20 ROWS ONLY) ' +
                'WITH DATA WITH REPLACE'') COMMIT(*NC)';
          ELSE;
            cmd +=
                ' ORDER BY "SCORE" DESC) ' +
                'WITH DATA WITH REPLACE'') COMMIT(*NC)';
          ENDIF;
          MONITOR;
            CALLP QCMDEXC(cmd : %LEN(cmd));
          ON-ERROR *ALL;
            ws.errorMsg_50 = *ON;
            MSGDTA = '検索SQLの実行でエラー。';
            LEAVESR;
          ENDMON;

          IF SEARCHTGT = 1;
            OPEN IFSRESULT;
          ELSE;
            OPEN SPLRESULT;
          ENDIF;

          DOW (1 = 1);
            IF SEARCHTGT = 1;
              READ(E) IFSR;
            ELSE;
              READ(E) SPLR;
            ENDIF;
            //ファイルの終わり
            IF %EOF();
              LEAVE;
            ENDIF;

            RCDNUM += 1;
            @SRRN += 1;
            tsChr = %CHAR(MODTS);

            IF SEARCHTGT = 1;
              ws.dspIFS_70 = *ON;
              //サブファイルの隠しフィールドにPATHNAMEを記録
              IFSPATH = PATHNAME;
              MONITOR;
                dirName = %SUBST(PATHNAME : 1 : xscanr('/' : PATHNAME));
                fileName = %SUBST(PATHNAME : xscanr('/' : PATHNAME) + 1);
                fileExt = %SUBST(fileName : xscanr('.' : fileName) + 1);
              ON-ERROR *ALL;
                dirName = '';
                fileName = cRed + '(パス解析中にエラー)';
                fileExt = '';
              ENDMON;
              SFLLIN1 = trimDBCS(fileName : 66);
              SFLLIN2 = cGreen + ' UPD' + cBlue +
                        %SUBST(tsChr : 1 : 4) + '/' + %SUBST(tsChr : 6 : 2) +
                        '/' + %SUBST(tsChr : 9 : 2) + ' ' +
                        cGreen + ' EXT' + cBlue + fileExt +
                        cGreen + ' DIR' + cBlue + dirName;
            ELSE;
              ws.dspIFS_70 = *OFF;
              SFLLIN1 = 'FILE' + cWhite + SPOOL_NAME +
                        cGreen + 'NO' + cWhite + SPOOL_NBR +
                        cGreen + 'OUTQ' + cWhite +
                        %TRIMR(OBJECT_LIB) + '/' + %TRIMR(OBJECT_NAM);
              %SUBST(SFLLIN1 : 54) = cGreen + ' SYS' + cBlue + SYS_NAME;
              SFLLIN2 = cGreen + ' JOB' + cBlue +
                        JOB_NBR + '/' + %TRIMR(USER_NAME) + '/' + JOB_NAME;
              %SUBST(SFLLIN2 : 38) = cGreen + 'UPD' + cBlue +
                        %SUBST(tsChr : 1 : 4) + '/' + %SUBST(tsChr : 6 : 2) +
                        '/' + %SUBST(tsChr : 9 : 2) + ' ' +
                        %SUBST(tsChr : 12 : 2) + ':' + %SUBST(tsChr : 15 : 2) +
                        ':' + %SUBST(tsChr : 18 : 2);
            ENDIF;
            WRITE MEISFL;

          ENDDO;

          IF SEARCHTGT = 1;
            CLOSE IFSRESULT;
          ELSE;
            CLOSE SPLRESULT;
          ENDIF;

        ENDSR;

        //サブファイル対話処理////////////////////////////
        BEGSR #SFLP;

          //変数の初期化
          ws.errorMsg_50 = *OFF;
          optCount = 0;
          workRRN = @SRRN;

          //サブファイルでの操作チェック
          FOR I = 1 TO RCDNUM;

            CHAIN(E) I MEISFL;
            IF %ERROR();
              LEAVE;
            ENDIF;

            SELECT;
              //オプションに5が指定→検索対象表示
              WHEN OPTION = '5';
                optCount += 1;
                OPTION = ' '; //オプションのクリア
                UPDATE MEISFL;
                workRRN = @SRRN;
                EXSR #DSPTGT; //検索対象表示
              //オプションがブランク→そのまま更新
              WHEN OPTION = ' ';
                UPDATE MEISFL;
              //オプションに5とブランク以外→エラー
              OTHER;
                optCount += 1;
                ws.errorMsg_50 = *ON;
                MSGDTA = '表示は''5''を指定。';
                OPTION = ' '; //オプションのクリア
                UPDATE MEISFL;
                workRRN = @SRRN;
                LEAVE;
            ENDSL;

          ENDFOR;

          //オプション未指定＆サブファイル上でENTER→検索対象表示
          //　　　　　　　　　　　　　　　外でENTER→前画面
          IF optCount = 0; //オプションがブランクのみ
            //カーソル行のデータを表示
            IF (0 < workRRN) AND (workRRN <= RCDNUM);
              CHAIN(E) workRRN MEISFL;
              IF %FOUND();
                EXSR #DSPTGT; //検索対象表示
                // @SPLOC SFLRCDNBR(CURSOR)
                //表示したいサブファイルのページが、このフィールドにある相対レ
                //コード番号を持つレコードの入っているページであることを指定
                @SPLOC = @SRRN;
              ENDIF;
            ELSE; //カーソルがサブファイル外
              ws.cncl_12 = *ON; //キャンセル（前画面）扱い
            ENDIF;

          ELSE; //オプションがブランク以外
            @SPLOC = workRRN;

          ENDIF;

        ENDSR;

        //検索対象表示////////////////////////////////////
        BEGSR #DSPTGT;

          // IFSファイルの表示
          IF SEARCHTGT = 1;
            PCCmd = 'START "起動中..." "//' +
                    %TRIM(hostIP) + %TRIM(IFSPATH) + '"';
            IF %LEN(PCCmd) > 1023;
              ws.errorMsg_50 = *ON;
              MSGDTA = 'パス長(' + %CHAR(%LEN(PCCmd)) + ')が' +
                       '1023を越えている。';
              LEAVESR;
            ENDIF;
            cmd = 'STRPCCMD PCCMD(''' + PCCmd + ''') PAUSE(*NO)';
            MONITOR;
              CALLP QCMDEXC(cmd : %LEN(cmd));
            ON-ERROR *ALL;
              ws.errorMsg_50 = *ON;
              MSGDTA = 'IFSファイルの表示でエラー。';
              LEAVESR;
            ENDMON;

          //スプールファイルの表示
          ELSE;
            cmd = 'DSPSPLF FILE(' + %TRIMR(%SUBST(SFLLIN1 : 6 : 10)) +
                  ') JOB(' + %TRIMR(%SUBST(SFLLIN2 : 7 : 28)) +
                  ') SPLNBR(' + %TRIMR(%SUBST(SFLLIN1 : 20 : 4)) +
                  ')';
            MONITOR;
              CALLP QCMDEXC(cmd : %LEN(cmd));
            ON-ERROR *ALL;
              ws.errorMsg_50 = *ON;
              MSGDTA = 'スプールファイルの表示でエラー。';
              LEAVESR;
            ENDMON;
          ENDIF;

        ENDSR;

      *****************************************************************
      * DBCS考慮版%SCANR
     Pxscanr           B
     Dxscanr           PI             5I 0
     D  searchArg                     1    CONST
     D  searchStr                  2048    CONST OPTIONS(*VARSIZE)
      *
     D pos             S              5P 0 INZ(0)
     D strLen          S              5P 0
     D aChr            S              1
     D inDBCS          S               N   INZ(*OFF)
      *
        strLen = %LEN(%TRIMR(searchStr));
        FOR pos = strLen DOWNTO 1 BY 1;
          aChr = %SUBST(searchStr : pos : 1);
          SELECT;
            WHEN aChr = X'0F';
              inDBCS = *ON;
            WHEN aChr = searchArg;
              IF NOT inDBCS;
                RETURN pos;
              ENDIF;
            WHEN aChr = X'0E';
              inDBCS = *OFF;
          ENDSL;
        ENDFOR;

        RETURN pos;

     Pxscanr           E
      *****************************************************************
      * DBCS文字列の短縮
     PtrimDBCS         B
     DtrimDBCS         PI          1024
     D  trimStr                    1024    CONST
     D  trimPos                       5P 0 CONST
      *
     D newStr          S           1024
     D pos             S              5P 0 INZ(0)
     D aChr            S              1
      *
        //文字列長が指定長と同じか短い→そのまま返す
        IF %LEN(%TRIMR(trimStr)) <= trimPos;
          RETURN trimStr;
        ENDIF;

        //指定位置+ ellipsis（省略記号）まで切り取り
        newStr = %SUBST(trimStr : 1 : trimPos - 3);
        //不完全なDBCS文字列の検出と補償
        FOR pos = trimPos DOWNTO 1 BY 1;
          aChr = %SUBST(newStr : pos : 1);
          SELECT;
            WHEN aChr = X'0F';  // 0x0eの前に0x0fが見つかった→整合性OK
              LEAVE;
            WHEN aChr = X'0E';  //不完全なDBCS→0x0fとellipsisを補償
              IF %REM(trimPos - pos : 2) = 0;
                %SUBST(newStr : trimPos - 3 : 4) = X'0F' + '...';
                RETURN newStr;
              ELSE;
                %SUBST(newStr : trimPos - 4 : 5) = X'0F' + ' ...';
                RETURN newStr;
              ENDIF;
          ENDSL;
        ENDFOR;

        //シフト文字(0x0e/0x0f)が無い→ellipsisを補填
        %SUBST(newStr : trimPos - 3 : 4) = ' ...';
        RETURN newStr;

     PtrimDBCS         E
