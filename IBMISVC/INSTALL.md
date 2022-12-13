
***

## 複数区画/サーバー集中管理 - インストール手順

SAVFをダウンロードしてIBM i に送信、復元。

SAVFの送信は、ACSのIFSプラグインで拡張子「.SAVF」をライブラリー(/QSYS.LIB/ライブラリー名.lib)に直接(事前にSAVFを作成せずに)アップロードする事も可能。  


---

### IBM i で空のSAVFを作成

CRTSAVFコマンドで任意の名前のSAVFを作成。

~~~
> CRTSAVF FILE(QGPL/IBMISVC)                          
   ライブラリー QGPL にファイル IBMISVC が作成された。
~~~

  
### SAVFのダウンロード(GitHub→PC)

GitHubからSAVFをダウンロード。

Webブラウザでリポジトリーの「[IBM-i-samples/OADEMO/ibmisvc.savf](ibmisvc.savf)」を開くと、右に「download」と表示されるのでこれをクリック。  

<BR>

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
ftp> put ibmisvc.savf qgpl/ibmisvc
200 PORT SUBCOMMAND REQUEST SUCCESSFUL.
150 SENDING FILE TO MEMBER IBMISVC IN FILE IBMISVC IN LIBRARY QGPL.
226 FILE TRANSFER COMPLETED SUCCESSFULLY.
ftp: 48048 バイトが送信されました 0.02秒 2002.00KB/秒。
ftp> quit
221 QUIT SUBCOMMAND RECEIVED.
~~~
  

### オブジェクトの復元

任意のライブラリー(この例では「GURILIB」)に転送したSAVFから復元。
復元後はSAVFは削除可能。

~~~
> RSTOBJ OBJ(*ALL) SAVLIB(DIST) DEV(*SAVF) SAVF(QGPL/IBMISVC) RSTLIB(GURILI
  B)                                                                       
  1 個のオブジェクトを DIST から GURILIB へ復元した。                      
~~~
  
---

### ソースの編集

実行環境(対象IBM i サーバー)に合わせて下記の要領でソースを編集。

#### 一括稼働状況表示

ソースメンバーDSPSVRSTSRを変更

- [42行目](DSPSVRSTSR.SQLRPGLE#L42)の「CONST(3)」の数値を対象サーバー/区画数に合わせて変更
- [100～102行目](DSPSVRSTSR.SQLRPGLE#L100)の「(サーバー/区画#x)」を実際のリレーショナル・データベース項目に置き換え。対象サーバー/区画数に合わせて行を追加・削除

それぞれ、CRTDSPF、CRTSQLRPGIでコンパイル。  
※ コンパイルには「5770ST1 DB2 QUERY MGR AND SQL DEVKIT」が必要

#### 一括動作時刻表示

ソースメンバーDSPSVRTIMRを変更

- [47行目](DSPSVRTIMR.SQLRPGLE#L47)の「CONST(3)」の数値を対象サーバー/区画数に合わせて変更
- [97～99行目](DSPSVRTIMR.SQLRPGLE#L97)の「(サーバー/区画#x)」を実際のリレーショナル・データベース項目に置き換え。対象サーバー/区画数に合わせて行を追加・削除

それぞれ、CRTDSPF、CRTSQLRPGIでコンパイル。  
※ コンパイルには「5770ST1 DB2 QUERY MGR AND SQL DEVKIT」が必要

#### 区画間システム値比較

ソースメンバーCMPPARTVALを変更。  
SQLの区画処理部分を対象サーバーの数に合わせて追加(「SVRx」の数値を変える)、または、削除。
~~~
〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜
0005.00              DCL        VAR(&SVR3) TYPE(*CHAR) LEN(10) VALUE(IBMI#3)
〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜
0021.00              CHGVAR     VAR(&STMT) VALUE( +                   
0022.00   'DECLARE GLOBAL TEMPORARY TABLE SESSION/SYSVAL3 AS +        
0023.00     (SELECT * FROM ' || &SVR3 |< '/QSYS2/SYSTEM_VALUE_INFO +  
0024.00        ORDER BY SYSTEM_VALUE_NAME) +                          
0025.00      WITH DATA INCLUDING DEFAULTS WITH REPLACE')              
0026.00              RUNSQL     SQL(&STMT) COMMIT(*NC)                              
〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜
0034.00                                ' || &SVR3 |< '_VAL CHAR(32) CCSID 5035, +
0035.00                                ' || &SVR3 |< '_DIF INT) +                
〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜
0054.00        SUBSTRING(IFNULL(S3.CURRENT_CHARACTER_VALUE, +                          
0055.00                         CHAR(S3.CURRENT_NUMERIC_VALUE)), 1, 32) ' +            
0056.00                                                 || &SVR3 |< '_VAL, +           
0057.00        CASE +                                                                  
0058.00          WHEN S1.CURRENT_NUMERIC_VALUE <> S3.CURRENT_NUMERIC_VALUE THEN 1 +    
0059.00          WHEN S1.CURRENT_CHARACTER_VALUE <> S3.CURRENT_CHARACTER_VALUE THEN 2 +
0060.00          ELSE 0 +                                                              
0061.00        END AS ' || &SVR3 |< '_DIF +                          
〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜
0065.00          FULL OUTER JOIN SESSION/SYSVAL3 AS S3 +                    
0066.00            ON S1.SYSTEM_VALUE_NAME = S3.SYSTEM_VALUE_NAME' +    
〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜
~~~

- SQLの文法に合わせて区切り文字(「)」や「,」など)を適宜修正
- サンプルでは4区画の比較を198桁で印刷出力。区画数が5以上の場合は、比較結果ファイル(QTEMP/CMPSYSVAL)をExcelなどに変換すれば結果の確認が容易

CRTCLPGMでコンパイル。「5770ST1 DB2 QUERY MGR AND SQL DEVKIT」は不要。

---

## 複数区画/サーバー集中管理 - オブジェクトの作成

自動でサンプルをコンパイルするREXXプロシージャー「MAKE」を提供。  
※ 個別にCLコマンドでコンパイルしても良い    

「MAKE」を使用してオブジェクトを作成する前に、ソースの変数 OLIB(オブジェクト・ライブラリー)、および、SLIB(ソース・ライブラリー)の設定値を編集。

~~~
> STRSEU SRCFILE(GURILIB/IBMISVC) SRCMBR(MAKE) 
~~~

編集前
~~~
0013.00 OLIB = 'DIST'   
0014.00 SLIB = 'DIST'   
0015.00 SFIL = 'IBMISVC'
~~~

編集後(この例ではオブジェクト、ソースともにライブラリー「GURILIB」に配置)
~~~
0013.00 OLIB = 'GURILIB'  
0014.00 SLIB = 'GURILIB'  
0015.00 SFIL = 'IBMISVC'  
~~~

STRREXPRCコマンドを実行(またはPDMでメンバーMAKEにオプション16を指定)するとコンパイルが実行される。

~~~
> STRREXPRC SRCMBR(MAKE) SRCFILE(GURILIB/IBMISVC)
~~~

画面に実行内容と結果が表示されるので、指示に従って動作を確認。

~~~
    「複数区画／サーバー集中管理」オブジェクトの作成                
                                                                    
    ****************************************************************
    ** 必要な権限を持つユーザーで実行                             **
    ** オブジェクトライブラリー、ソースは事前に準備               **
    ** このソース内の OLIB, SLIB を実際のライブラリーに修正       **
    ****************************************************************
                                                                    
    現行ライブラリーを GURILIB に変更します。                       
    現行ジョブの CCSID を 65535 に変更します。                      
                                                                    
    一括稼働状況表示の作成                                          
      表示装置ファイル DSPSVRSTSD の作成 ...                        
       結果 -> 0                                                    
      SQL ILE-RPG オブジェクト DSPSVRSTSR の作成 ...                
       結果 -> 0                                                       
                                                                       
    一括動作時刻表示の作成                                             
      表示装置ファイル DSPSVRTIMD の作成 ...                           
       結果 -> 0                                                       
      SQL ILE-RPG オブジェクト DSPSVRTIMR の作成 ...                   
       結果 -> 0                                                       
                                                                       
    区画間システム値比較                                               
      CL プログラム CMPPARTVAL の作成 ...                              
       結果 -> 0                                                       
                                                                       
    エラー（結果が 0 以外）の有無を確認してください。                  
    エラーがある場合はジョブログで原因を確認し、修正して再実行します。 
                                                                       
    プロシージャーの終わり。                                           
                                                                       
    実行キーを押して端末セッションを終了してください。                       
~~~

---  

## 複数区画/サーバー集中管理 - 環境設定

このプログラムを実行するサーバー/区画から他のサーバー/区画にDRDAが構成されており、3部構成のSQL表名」で遠隔RDBにアクセスができるように環境を設定する。

[「3部構成のSQL表名」](https://www.ibm.com/docs/ja/i/7.5?topic=request-three-part-names)はIBM i 7.2で拡張された機能で、テーブルを「遠隔システムのRDB名/ライブラリー/テーブル」で指定する。

　    
***(補足) DRDAによるSQLアクセスの設定***

他のサーバー/区画へSQLで透過的にアクセスするには、DRDA (分散リレーショナル データベース体系)で接続できる事が前提。  
IBM iでは次のような項目がDRDA構成に関係する。

- CHGDDMTCPAコマンドでDRDAサーバーの基本設定を実施。設定には、サーバーの自動開始、パスワード機密保護の最低レベル、接続要求で許可される最低強度の暗号化アルゴリズムが含まれる
- ADDRDBDIREコマンド(またはWRKRDBDIREコマンドのオプション「1=追加」)で、リモート・ロケーションを「*LOCAL」に設定し、このサーバー自身のデータベースを指定
- DRDA接続を行うリモート・サーバー(データベース)をADDRDBDIREコマンド(またはWRKRDBDIREコマンドのオプション「1=追加」)で追加。RDB名、リモート・サーバーのIPアドレス、リモート認証方式、暗号化アルゴリズムリモートを指定

経験上、接続する全てのサーバーに同一ユーザーID/同一パスワードを設定し、このユーザーで接続すると問題が少ない。  
実装にあたっては暗号化機能も含めて、組織のセキュリティ要件を満たすよう設計すべきであろう。

<BR>

遠隔RDB接続のセキュリティに関しては下記IBM文書なども参照して適切な手法を選択。
- [「IBM i 7.5 データベース 分散データベース・プログラミング」](https://www.ibm.com/docs/ja/ssw_ibm_i_75/pdf/rbal1pdf.pdf)
- [「TCP/IP ネットワークでのクライアントのセキュリティー」](https://www.ibm.com/support/knowledgecenter/ja/ssw_ibm_i_73/ddp/rbal1sourcesecurity.htm)
- [「Using a Group Profile in a DDM/DRDA Server Authentication Entry」](https://www.ibm.com/support/pages/using-group-profile-ddmdrda-server-authentication-entry)
- [「QDDMDRDASERVER special value in server authentication entries」](https://www.ibm.com/support/pages/qddmdrdaserver-special-value-server-authentication-entries)

<BR> 

例えば、サーバー名に特殊名「QDDMDRDASERVER」を使用すると、デフォルトのDDM/DRDAサーバー接続のユーザーが設定でき、管理が省力化できる。  
具体的には、全サーバー/区画に配置する「接続用のユーザーID/パスワード」を作成し、サーバー認証項目の追加(ADDSVRAUTE)コマンドで実行ユーザーと関連付ける。
~~~
> ADDSVRAUTE USRPRF(実行ユーザー) SERVER(QDDMDRDASERVER) USRID(接続用のユーザーID) PASSWORD(接続用パスワード)
~~~

登録済みの「サーバー認証項目」を確認するにはIBM i サービスを利用。ユーザーID/パスワードは大文字／小文字を区別する事に留意。
~~~
SELECT * FROM QSYS2.DRDA_AUTHENTICATION_ENTRY_INFO;
~~~
   
