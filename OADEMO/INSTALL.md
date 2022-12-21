
***

## ワンアクション連携 - インストール手順

SAVFをダウンロードしてIBM i に送信、復元。

SAVFの送信は、ACSのIFSプラグインで拡張子「.SAVF」をライブラリー(/QSYS.LIB/ライブラリー名.lib)に直接(事前にSAVFを作成せずに)アップロードする事も可能。  

事前に[サンプルデータの準備](/demodata/README.md)が完了している事。  

---

### IBM i で空のSAVFを作成

CRTSAVFコマンドで任意の名前のSAVFを作成。

~~~
> CRTSAVF FILE(QGPL/OADEMO)                           
   ライブラリー QGPL にファイル OADEMO が作成された。 
~~~

  
### SAVFのダウンロード(GitHub→PC)

GitHubからSAVFをダウンロード。

Webブラウザでリポジトリーの「IBM-i-samples/OADEMO/oademo.savf」を開くと、右に「download」と表示されるのでこれをクリック。  
  

### IBM i のSAVFへ転送

FTPでSAVFをIBM i にput。

~~~
C:\Users\(Windowsのユーザー名)\Desktop>ftp (IBM i のホスト名またはIPアドレス)
(IBM i のホスト名またはIPアドレス) に接続しました。
220-QTCP AT xxx.yyy.CO.JP.
220 CONNECTION WILL CLOSE IF IDLE MORE THAN 5 MINUTES.
501 OPTS UNSUCCESSFUL; SPECIFIED SUBCOMMAND NOT RECOGNIZED.
ユーザー (ibmi:(none)): (IBM i ユーザー名)
331 ENTER PASSWORD.
パスワード: (IBM i パスワード)
230 ZZZZ LOGGED ON.
ftp> bi
200 REPRESENTATION TYPE IS BINARY IMAGE.
ftp> put oademo.savf qgpl/oademo
200 PORT SUBCOMMAND REQUEST SUCCESSFUL.
150 SENDING FILE TO MEMBER OADEMO IN FILE OADEMO IN LIBRARY QGPL.
226 FILE TRANSFER COMPLETED SUCCESSFULLY.
ftp: 75504 バイトが送信されました 0.03秒 2904.00KB/秒。
ftp> quit
221 QUIT SUBCOMMAND RECEIVED.
~~~
  

### オブジェクトの復元

任意のライブラリー(この例では「GURILIB」)に転送したSAVFから復元。
復元後はSAVFは削除可能。

~~~
> RSTOBJ OBJ(*ALL) SAVLIB(DIST) DEV(*SAVF) SAVF(QGPL/OADEMO) RSTLIB(GURILIB
  )                                                                        
  1 個のオブジェクトを DIST から GURILIB へ復元した。                      
~~~
  

### ワークディレクトリーの作成

#### Db2 for i (物理ファイル) ⇒ Excel変換＆表示

Excel変換用のワークファイル(CSV/パラメーターファイル)を配置するディレクトリー(例では「/TMP/EMUTOOL/」)を作成。

~~~
> MKDIR DIR('/TMP/EMUTOOL')    
   ディレクトリーが作成された。
~~~

#### スプールファイル ⇒ TEXT/PDF変換＆表示 および 高品質な帳票生成とPDF化

スプールを変換したTEXT/PDFの保存用のワークディレクトリーを作成。
「Db2 for i (物理ファイル) ⇒ Excel変換＆表示」も含め、全て同じディレクトリーを使用しても、機能ごとに分けても良い。

***

### ソースの編集

実行環境(対象IBM i サーバー)に合わせてプログラムを修正。    

**※ CCSIDが5026(日本語カタカナ)のソースファイルで不変文字セットの英小文字を入力する場合は下記の環境で実施。**
- 5250エミュレーターのホスト・コード・ページが**939**または**1399**
- SEUでの編集**前**に「CHGJOB CCSID(65535)」を実行  


#### Db2 for i (物理ファイル) ⇒ Excel変換＆表示

下記4点を編集。

- ワークディレクトリー(例では「/TMP/EMUTOOL/」)を使用するディレクトリーに変更
- オブジェクト・ライブラリー名を実際に使用するライブラリー名に変更
- ホスト名「IBMI」を、実際のホスト名またはIPアドレスに置き換え
- IBM i のFTPサーバーにログインするユーザーとパスワードを設定

|メンバー|行|ステートメント|
|-------|--|-------|
|DB2CSV|0035.00| VALUE('**/TMP/EMUTOOL/**')  |
||0038.00|DCL        VAR(&PGMLIB) TYPE(\*CHAR) LEN(10) VALUE(**GURILIB**)|
||0042.00| VALUE('**IBMI**')  |
||0045.00|DCL        VAR(&USER) TYPE(\*CHAR) LEN(10) VALUE(**XXXX**)|
||0046.00|DCL        VAR(&PASS) TYPE(\*CHAR) LEN(10) VALUE(**YYYY**)|


#### スプールファイル ⇒ TEXT/PDF変換＆表示

下記3点を編集。

- ワークディレクトリー(例では「/TMP/EMUTOOL/」)を使用するディレクトリーに変更
- オブジェクト・ライブラリー名を実際に使用するライブラリー名に変更
- ホスト名「IBMI」を、実際のホスト名またはIPアドレスに置き換え

|メンバー|行|ステートメント|
|-------|--|-------|
|SPL2PCD|0045.00| VALUE('**/TMP/EMUTOOL/**')  |
||0049.00| VALUE('**IBMI**')  |
||0052.00|VALUE(**GURILIB**)|

#### 高品質な帳票生成とPDF化

下記2点を編集。

- ワークディレクトリー(例では「/TMP/EMUTOOL/」)を使用するディレクトリーに変更
- ホスト名「IBMI」を、実際のホスト名またはIPアドレスに置き換え

|メンバー|行|ステートメント|
|-------|--|-------|
|JMAPC|0030.00| VALUE('**/TMP/EMUTOOL/**')|
||0040.00|  VALUE('**IBMI**')|

  
### オブジェクトの作成

自動でサンプルをコンパイルするREXXプロシージャー「MAKE」を提供。  
※ 個別にCLコマンドでコンパイルしても良い    
これを使用してオブジェクトを作成する前に、ソースの変数 OLIB(オブジェクト・ライブラリー)、および、SLIB(ソース・ライブラリー)の設定値を編集。

~~~
> STRSEU SRCFILE(GURILIB/OADEMO) SRCMBR(MAKE) 
~~~

編集前
~~~
0013.00 OLIB = 'DIST'   
0014.00 SLIB = 'DIST'   
0015.00 SFIL = 'OADEMO'
~~~

編集後(この例ではオブジェクト、ソースともにライブラリー「GURILIB」に配置)
~~~
0013.00 OLIB = 'GURILIB'  
0014.00 SLIB = 'GURILIB'  
0015.00 SFIL = 'OADEMO'  
~~~

STRREXPRCコマンドを実行(またはPDMでメンバーMAKEにオプション16を指定)するとコンパイルが実行される。

~~~
> STRREXPRC SRCMBR(MAKE) SRCFILE(GURILIB/OADEMO)
~~~

画面に実行内容と結果が表示されるので、指示に従って動作を確認。

~~~
                                                                    
    「ワンアクション連携」オブジェクトの作成                        
                                                                    
    ****************************************************************
    ** 必要な権限を持つユーザーで実行                             **
    ** オブジェクトライブラリー、ソースは事前に準備               **
    ** ファイル PERSON をオブジェクトライブラリーに復元           **
    ** このソース内の OLIB, SLIB を実際のライブラリーに修正       **
    ****************************************************************
                                                                    
    現行ライブラリーを GURILIB に変更します。                       
    現行ジョブの CCSID を 65535 に変更します。                      
                                                                    
    DB2 FOR I ( 物理ファイル )  ⇒  EXCEL 変換＆表示の作成          
      表示装置ファイル DB2CSVD の作成 ...                           
       結果 -> 0                                                    
      ILE-CL プログラム DB2CSV の作成 ...                           
       結果 -> 0                                                    
      コマンド DB2CSVPDM の作成 ...                     
       結果 -> 0                                        
                                                        
    スプールファイル  ⇒  TEXT/PDF 変換＆表示の作成     
      ILE-CL プログラム SPL2PCD の作成 ...              
       結果 -> 0                                        
      ILE-RPG プログラム SHIFT の作成 ...               
       結果 -> 0                                        
                                                        
    高品質な帳票生成と PDF 化の作成                     
      表示装置ファイル JMAP の作成 ...                  
       結果 -> 0                                        
      ILE-CL プログラム JMAPC の作成 ...                
       結果 -> 0                                        
      印刷装置ファイル AFPPRTF の作成 ...               
       結果 -> 0                                        
      ILE-RPG プログラム AFPPRT の作成 ...              
       結果 -> 0                              
                                                                             
    エラー（結果が 0 以外）の有無を確認してください。                        
    エラーがある場合はジョブログで原因を確認し、修正して再実行します。       
                                                                             
    エラーが無ければ下記環境設定を実施します。                               
     ● DB2 FOR I ( 物理ファイル )  ⇒  EXCEL 変換＆表示                     
       ★ STRPDM  →「 F16= ユーザー・オプション」で EXCEL 変換用の          
          オプション XL と XF を追加                                         
       ★ワークディレクトリーの作成と NETSERVER 共有、 FTP 用のユーザー設定  
       ★ PC のデスクトップに DB2EXCEL.XLSM と DB2EXCEL.CMD を配置           
     ●スプールファイル  ⇒  PDF 変換＆表示                                  
       ★ワークディレクトリーの作成と NETSERVER 共有                         
       ★出口プログラムの登録                                                
     ●高品質な帳票生成と PDF 化                                             
      （前提ライセンス・プログラムが導入済みであれば設定はなし）             
                                                                             
    下記手順で各サンプルを実行できます。                                     
    ※このプロシージャーの冒頭で現行ライブラリーを GURILIB に変更しています。
     ● DB2 FOR I ( 物理ファイル )  ⇒  EXCEL 変換＆表示                    
       ★ WRKOBJPDM 画面から物理ファイルのオプションに XL または XF を指定  
     ●スプールファイル  ⇒  TEXT/PDF 変換＆表示                            
       ★ WRKSPLF/WRKOUTQ などのスプール一覧でオプションに P または T を指定
     ●高品質な帳票生成と PDF 化                                            
       ★ CALL JMAPC を実行                                                 
                                                                            
    プロシージャーの終わり。                                                
~~~
---  

### 環境設定

#### Db2 for i (物理ファイル) ⇒ Excel変換＆表示

STRPDM → 「F16=ユーザー・オプション」でExcel変換用のオプション「XL」と「XF」を追加  
<pre>
OPT  ｵﾌﾟｼｮﾝ  ｺﾏﾝﾄﾞ 
       XF    GURILIB/DB2CSVPDM LIB(&L) FILE(&N) TFR(F)
       XL    GURILIB/DB2CSVPDM LIB(&L) FILE(&N) TFR(N)
</pre>

#### スプールファイル ⇒ TEXT/PDF変換＆表示

ADDEXITPGMコマンドを実行して出口プログラムを登録。詳細は下記URLなどを参照。
- https://www-01.ibm.com/support/docview.wss?uid=nas8N1012369             
- https://www.ibm.com/support/knowledgecenter/en/ssw_ibm_i_72/apis/xsp_splf_list_act.htm     

"?"はスプールファイル一覧から指定する文字で、例では「T」および「P」。

<pre>
> ADDEXITPGM EXITPNT(QIBM_QSP_SPLF_LSTACT) FORMAT(LASP0100) PGMNBR(*LOW) PG
  M(ライブラリー/SPL2PCD) PGMDTA(*JOB 1 ?)                             
</pre>    

下記のWRKREGINFコマンドを実行し、オプション「8= 出口プログラムの処理」を選択して出口プログラムが登録されているか確認。
「出口プログラムの表示」画面で最下行の「出口プログラム・データ」が「T」(テキスト変換)と「P」(PDF変換)の2パターンを登録。

<pre>
> WRKREGINF EXITPNT(QIBM_QSP_SPLF_LSTACT)  
</pre>
<pre>
                                登録情報の処理                               
                                                                             
 オプションを入力して，実行キーを押してください。                            
   5= 出口点の表示   8= 出口プログラムの処理                                 
                                                                             
                             出口点                                          
 OPT   出口点                の形式    登録済み    テキスト                  
  8   QIBM_QSP_SPLF_LSTACT  LASP0100     *YES     ﾕｰｻﾞｰ 定義の ｽﾌﾟｰﾙ･ﾌｧｲﾙ･ﾘｽﾄ
</pre>
<pre>
                             出口プログラムの処理        
                                                         
 出口点 :   QIBM_QSP_SPLF_LSTACT     形式 :   LASP0100   
                                                         
 オプションを入力して，実行キーを押してください。        
   1= 追加   4= 除去   5= 表示   10= 置換え              
                                                         
          出口 ﾌﾟﾛｸﾞﾗﾑ      出口                         
 OPT          番号         ﾌﾟﾛｸﾞﾗﾑ        ﾗｲﾌﾞﾗﾘｰ        
                                                         
 5                  1      SPL2PCD        GURILIB        
                    2      SPL2PCD        GURILIB            
</pre>
<pre>
                             出口プログラムの表示                             
                                                          システム :   GURICAT
 出口点  . . . . . . . . . . . . . . . . . :   QIBM_QSP_SPLF_LSTACT           
 出口点形式  . . . . . . . . . . . . . . . :   LASP0100                       
                                                                              
 出口プログラム番号  . . . . . . . . . . . :   1                              
 出口プログラム  . . . . . . . . . . . . . :   SPL2PCD                        
   ライブラリー  . . . . . . . . . . . . . :     GURILIB                      
 テキスト記述  . . . . . . . . . . . . . . :   *BLANK                         
                                                                              
 出口プログラム・データ CCSID  . . . . . . :   1399                           
 出口プログラム・データ長  . . . . . . . . :   1                              
 スレッド・セーフ  . . . . . . . . . . . . :   *UNKNOWN                       
 マルチスレッド・ジョブの処置  . . . . . . :   *MSG                           
 出口プログラム・データ  . . . . . . . . . :                                  
 T                                                    
</pre>

#### 高品質な帳票生成とPDF化

特別な環境設定は不要。  

下記のライセンス・プログラムが利用可能(インストール済み)であることを確認。

~~~
ﾗｲｾﾝｽ･   ﾌﾟﾛﾀﾞｸﾄ         
ﾌﾟﾛｸﾞﾗﾑ  ･ｵﾌﾟｼｮﾝ   記述  
5770SS1   8       AFP 互換フォント
5770SS1   43       追加フォント
5770TS1   *BASE   IBM TRANSFORM SERVICES FOR I  
5770TS1   1        変換－ AFP から PDF への変換 
~~~

オブジェクトとデータベースファイルが存在するライブラリー(例では「GURILIB」)をライブラリーリストに存在する事。
