SAY " "
SAY "「ワンアクション連携」オブジェクトの作成"
SAY " "
SAY " ****************************************************************"
SAY " **必要な権限を持つユーザーで実行                            **"
SAY " **オブジェクトライブラリー、ソースは事前に準備              **"
SAY " **ファイルPERSONをオブジェクトライブラリーに復元          **"
SAY " **このソース内のOLIB, SLIBを実際のライブラリーに修正      **"
SAY " ****************************************************************"

OLIB = 'DIST'
SLIB = 'DIST'
SFIL = 'OADEMO'

OPTION = 0
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
SAY "現行ジョブのCCSIDを65535に変更します。"
  'CHGJOB CCSID(65535)'

SAY " "
SAY ' DB2 FOR I (物理ファイル) ⇒ EXCEL変換＆表示の作成'
  SAY '  表示装置ファイルDB2CSVDの作成...'
  'CRTDSPF FILE(&OLIB/DB2CSVD) SRCFILE(&SLIB/&SFIL) SRCMBR(DB2CSVD)'
  SAY "   結果->" RC
  SAY '   ILE-CLプログラムDB2CSVの作成...'
  'CRTBNDCL PGM(&OLIB/DB2CSV) SRCFILE(&SLIB/&SFIL) SRCMBR(DB2CSV) ',
  'DBGVIEW(&DEBUG) OPTIMIZE(&OPT) TGTRLS(&TGTRLS)'
  SAY "   結果->" RC
  SAY '  コマンドDB2CSVPDMの作成...'
  'CRTCMD CMD(&OLIB/DB2CSVPDM) PGM(&OLIB/DB2CSV) SRCFILE(&SLIB/&SFIL)'
  SAY "   結果->" RC

SAY " "
SAY 'スプールファイル⇒ TEXT/PDF変換＆表示の作成'
  SAY '   ILE-CLプログラムSPL2PCDの作成...'
  'CRTBNDCL PGM(&OLIB/SPL2PCD) SRCFILE(&SLIB/&SFIL) SRCMBR(SPL2PCD) ',
  'DBGVIEW(&DEBUG) OPTIMIZE(&OPT) TGTRLS(&TGTRLS)'
  SAY "   結果->" RC
  SAY '   ILE-RPGプログラムSHIFTの作成...'
  'CRTBNDRPG PGM(&OLIB/SHIFT) SRCFILE(&SLIB/&SFIL) SRCMBR(SHIFT) ',
  'DBGVIEW(&DEBUG) OPTIMIZE(&OPT) TGTRLS(&TGTRLS)'
  SAY "   結果->" RC

SAY " "
SAY '高品質な帳票生成とPDF化の作成'
  SAY '  表示装置ファイルJMAPの作成...'
  'CRTDSPF FILE(&OLIB/JMAP) SRCFILE(&SLIB/&SFIL) SRCMBR(JMAP)'
  SAY "   結果->" RC
  SAY '   ILE-CLプログラムJMAPCの作成...'
  'CRTBNDCL PGM(&OLIB/JMAPC) SRCFILE(&SLIB/&SFIL) SRCMBR(JMAPC) ',
  'DBGVIEW(&DEBUG) OPTIMIZE(&OPT) TGTRLS(&TGTRLS)'
  SAY "   結果->" RC
  SAY '  印刷装置ファイルAFPPRTFの作成...'
  'CRTPRTF FILE(&OLIB/AFPPRTF) SRCFILE(&SLIB/&SFIL) SRCMBR(AFPPRTF) ',
  'DEVTYPE(*AFPDS) PAGESIZE(11 8 *UOM) UOM(*INCH)'
  SAY "   結果->" RC
  SAY '   ILE-RPGプログラムAFPPRTの作成...'
  'CRTBNDRPG PGM(&OLIB/AFPPRT) SRCFILE(&SLIB/&SFIL) SRCMBR(AFPPRT) ',
  'DBGVIEW(&DEBUG) OPTIMIZE(&OPT) TGTRLS(&TGTRLS)'
  SAY "   結果->" RC

SAY " "
SAY "エラー（結果が0以外）の有無を確認してください。"
SAY "エラーがある場合はジョブログで原因を確認し、修正して再実行します。"
SAY " "
SAY "エラーが無ければ下記環境設定を実施します。"
SAY " ●DB2 FOR I (物理ファイル) ⇒ EXCEL変換＆表示"
SAY "   ★STRPDM →「F16=ユーザー・オプション」でEXCEL変換用の"
SAY "      オプションXLとXFを追加"
SAY "   ★ワークディレクトリーの作成とNETSERVER共有、FTP用のユーザー設定"
SAY "   ★PCのデスクトップにDB2EXCEL.XLSMとDB2EXCEL.CMDを配置"
SAY " ●スプールファイル⇒ PDF変換＆表示"
SAY "   ★ワークディレクトリーの作成とNETSERVER共有"
SAY "   ★出口プログラムの登録"
SAY " ●高品質な帳票生成とPDF化"
SAY "  （前提ライセンス・プログラムが導入済みであれば設定はなし）"
SAY " "
SAY "下記手順で各サンプルを実行できます。"
SAY "※このプロシージャーの冒頭で現行ライブラリーを"OLIB"に変更しています。"
SAY " "
SAY " ●DB2 FOR I (物理ファイル) ⇒ EXCEL変換＆表示"
SAY "   ★WRKOBJPDM画面から物理ファイルのオプションにXLまたはXFを指定"
SAY " ●スプールファイル⇒ TEXT/PDF変換＆表示"
SAY "   ★WRKSPLF/WRKOUTQなどのスプール一覧でオプションにPまたはTを指定"
SAY " ●高品質な帳票生成とPDF化"
SAY "   ★CALL JMAPCを実行"
SAY " "
SAY "プロシージャーの終わり。"
SAY " "
