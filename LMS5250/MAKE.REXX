SAY " "
SAY "「5250画面の活用」オブジェクトの作成"
SAY " "
SAY " ****************************************************************"
SAY " **必要な権限を持つユーザーで実行                            **"
SAY " **オブジェクトライブラリー、ソースは事前に準備              **"
SAY " **ファイルPERSON, PERSONL1をオブジェクトライブラリーに復元**"
SAY " ** IFSの/IMGディレクトリーに画像を復元済み                **"
SAY " ** IFSの/IMGディレクトリーをネットサーバーで共有          **"
SAY " **このソース内のOLIB, SLIBを実際のライブラリーに修正      **"
SAY " ****************************************************************"

OLIB = 'DIST'
SLIB = 'DIST'
SFIL = 'LMS5250'

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
SAY '照会画面（非モダナイズ版）の作成'
  SAY '  表示装置ファイルDSPF2の作成...'
  'CRTDSPF FILE(&OLIB/DSPF2) SRCFILE(&SLIB/&SFIL) SRCMBR(DSPF2)'
  SAY "   結果->" RC
  SAY '   RPG/400プログラムRPGI2の作成...'
  'CRTRPGPGM PGM(&OLIB/RPGI2) SRCFILE(&SLIB/&SFIL) SRCMBR(RPGI2) ',
  'TGTRLS(&TGTRLS)'
  SAY "   結果->" RC

SAY " "
SAY '照会画面（モダナイズ版）の作成'
  SAY '  表示装置ファイルDSPF2Aの作成...'
  'CRTDSPF FILE(&OLIB/DSPF2A) SRCFILE(&SLIB/&SFIL) SRCMBR(DSPF2A)'
  SAY "   結果->" RC
  SAY '   RPG/400プログラムRPGI2Aの作成...'
  'CRTRPGPGM PGM(&OLIB/RPGI2A) SRCFILE(&SLIB/&SFIL) SRCMBR(RPGI2A) ',
  'TGTRLS(&TGTRLS)'
  SAY "   結果->" RC
  SAY '   ILE-RPGプログラムRPGI2ALEの作成...'
  'CRTBNDRPG PGM(&OLIB/RPGI2ALE) SRCFILE(&SLIB/&SFIL) SRCMBR(RPGI2ALE) ',
  'DBGVIEW(&DEBUG) OPTIMIZE(&OPT) TGTRLS(&TGTRLS)'
  SAY "   結果->" RC

SAY " "
SAY 'メニュー・バー例の作成.'
  SAY '  表示装置ファイルMNUDDSの作成...'
  'CRTDSPF FILE(&OLIB/MNUDDS) SRCFILE(&SLIB/&SFIL) SRCMBR(MNUDDS)'
  SAY "   結果->" RC
  SAY '   RPG/400プログラムMNURPGの作成...'
  'CRTRPGPGM PGM(&OLIB/MNURPG) SRCFILE(&SLIB/&SFIL) SRCMBR(MNURPG) ',
  'TGTRLS(&TGTRLS)'
  SAY "   結果->" RC

SAY " "
SAY ' 5250表示属性一覧の作成'
  SAY '  表示装置ファイルDSPFATRの作成...'
  'CRTDSPF FILE(&OLIB/DSPFATR) SRCFILE(&SLIB/&SFIL) SRCMBR(DSPFATR)'
  SAY "   結果->" RC
  SAY '   CLプログラムDSPFATRCの作成...'
  'CRTCLPGM PGM(&OLIB/DSPFATRC) SRCFILE(&SLIB/&SFIL) SRCMBR(DSPFATRC)'
  SAY "   結果->" RC

SAY " "
SAY "エラー（結果が0以外）の有無を確認してください。"
SAY "エラーがある場合はジョブログで原因を確認し、修正して再実行します。"
SAY " "
SAY "エラーが無ければ下記コマンドで各サンプルを実行できます。"
SAY "※このプロシージャーの冒頭で現行ライブラリーを"OLIB"に変更しています。"
SAY " "
SAY " ●照会画面（非モダナイズ版）       - CALL RPGI2"
SAY " ●照会画面（モダナイズ版）RPG/400  - CALL RPGI2A"
SAY "                             ILE-RPG  - CALL RPGI2ALE"
SAY " ●メニュー・バーの例               - CALL MNURPG"
SAY " ●5250表示属性一覧               - CALL DSPFATRC"
SAY " "
SAY "プロシージャーの終わり。"
SAY " "
