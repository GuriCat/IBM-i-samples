
***

## 5250画面の活用 - インストール手順

SAVFをダウンロードしてIBM i に送信、復元。

SAVFの送信は、ACSのIFSプラグインで拡張子「.SAVF」をライブラリー(/QSYS.LIB/ライブラリー名.lib)に直接(事前にSAVFを作成せずに)アップロードする事も可能。  

---

### IBM i で空のSAVFを作成

CRTSAVFコマンドで任意の名前のSAVFを作成。

~~~
> CRTSAVF FILE(QGPL/LMS5250)                             
   ライブラリー QGPL にファイル LMS5250 が作成された。  
~~~

  
### SAVFのダウンロード(GitHub→PC)

GitHubからSAVFをダウンロード。

Webブラウザでリポジトリーの「IBM-i-samples/LMS5250/lms5250.savf」を開くと、右に「download」と表示されるのでこれをクリック。  
  

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
ftp> put lms5250.savf qgpl/lms5250
200 PORT SUBCOMMAND REQUEST SUCCESSFUL.
150 SENDING FILE TO MEMBER LMS5250 IN FILE LMS5250 IN LIBRARY QGPL.
226 FILE TRANSFER COMPLETED SUCCESSFULLY.
ftp: 80784 バイトが送信されました 0.03秒 2524.50KB/秒。
ftp> quit
221 QUIT SUBCOMMAND RECEIVED.
~~~
  

### オブジェクトの復元

任意のライブラリー(この例では「GURILIB」)に転送したSAVFから復元。
復元後はSAVFは削除可能。

~~~
> RSTOBJ OBJ(*ALL) SAVLIB(DIST) DEV(*SAVF) SAVF(QGPL/LMS5250) RSTLIB(GURILI
  B)                                                                       
  1 個のオブジェクトを DIST から GURILIB へ復元した。                     
~~~
  

### ソースの編集

RPGプログラム内でホスト名またはIPアドレスを5250画面に表示するので、サンプルを実行するIBM i の設定値に編集。

下記ソースメンバーの「IBMI」を、実際のホスト名またはIPアドレスに置き換え。

|メンバー|行|ステートメント|
|-------|--|-------|
|RPGI2A|0337.00| FILE://**IBMI**/IMG/  |
|RPGI2ALE|0292.00|        URIIMG = 'FILE://**IBMI**/IMG/' + %CHAR(REGNO) + '.JPG';|
  

### オブジェクトの作成

自動でサンプルをコンパイルするREXXプロシージャー「MAKE」を提供。  
※ 個別にCLコマンドでコンパイルしても良い  
これを使用してオブジェクトを作成する前に、ソースの変数 OLIB(オブジェクト・ライブラリー)、および、SLIB(ソース・ライブラリー)の設定値を編集。

~~~
> STRSEU SRCFILE(GURILIB/LMS5250) SRCMBR(MAKE) 
~~~

編集前
~~~
0013.00 OLIB = 'DIST'   
0014.00 SLIB = 'DIST'   
0015.00 SFIL = 'LMS5250'
~~~

編集後(この例ではオブジェクト、ソースともにライブラリー「GURILIB」に配置)
~~~
0013.00 OLIB = 'GURILIB'  
0014.00 SLIB = 'GURILIB'  
0015.00 SFIL = 'LMS5250'  
~~~

STRREXPRCコマンドを実行(またはPDMでメンバーMAKEにオプション16を指定)するとコンパイルが実行される。

~~~
> STRREXPRC SRCMBR(MAKE) SRCFILE(GURILIB/LMS5250)
~~~

画面に実行内容と結果が表示されるので、指示に従って動作を確認。

~~~
                                                                      
   「 5250 画面の活用」オブジェクトの作成                           
                                                                      
    ****************************************************************  
    ** 必要な権限を持つユーザーで実行                             **  
    ** オブジェクトライブラリー、ソースは事前に準備               **  
    ** ファイル PERSON, PERSONL1 をオブジェクトライブラリーに復元 **  
    ** IFS の /IMG ディレクトリーに画像を復元済み                 **  
    ** IFS の /IMG ディレクトリーをネットサーバーで共有           **  
    ** このソース内の OLIB, SLIB を実際のライブラリーに修正       **  
    ****************************************************************  
                                                                      
    現行ライブラリーを GURILIB に変更します。                        
    現行ジョブの CCSID を 65535 に変更します。                       
                                                                      
    照会画面（非モダナイズ版）の作成                                 
      表示装置ファイル DSPF2 の作成...                               
       結果 -> 0                                                      
      RPG/400 プログラム RPGI2 の作成...    
       結果 -> 0                             
                                             
    照会画面（モダナイズ版）の作成          
      表示装置ファイル DSPF2A の作成...     
       結果 -> 0                             
      RPG/400 プログラム RPGI2A の作成...   
       結果 -> 0                             
      ILE-RPG プログラム RPGI2ALE の作成... 
       結果 -> 0                             
                                             
    メニュー・バー例の作成.                 
      表示装置ファイル MNUDDS の作成...     
       結果 -> 0                             
      RPG/400 プログラム MNURPG の作成...   
       結果 -> 0                             
                                             
    5250 表示属性一覧の作成                 
      表示装置ファイル DSPFATR の作成...                                    
       結果 -> 0                                                             
      CL プログラム DSPFATRC の作成...                                      
       結果 -> 0                                                             
                                                                             
    エラー（結果が 0 以外）の有無を確認してください。                       
    エラーがある場合はジョブログで原因を確認し、修正して再実行します。      
                                                                             
    エラーが無ければ下記コマンドで各サンプルを実行できます。                
    ※このプロシージャーの冒頭で現行ライブラリーを GURILIB に変更しています。
                                                                             
     ●照会画面（非モダナイズ版）        - CALL RPGI2                        
     ●照会画面（モダナイズ版） RPG/400  - CALL RPGI2A                       
                                ILE-RPG  - CALL RPGI2ALE                     
     ●メニュー・バーの例                - CALL MNURPG                       
     ●5250表示属性一覧                  - CALL DSPFATRC                     
                                                                             
    プロシージャーの終わり。                                                
~~~
---  
