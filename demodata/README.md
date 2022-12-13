# サンプルデータの準備

---

## Overview

すぐにサンプルを実行できるように下記データを配布。

|オブジェクト|属性|備考|
|----------|---|---|
|PERSON|物理ファイル|登録者マスター|
|PERSONL1|論理ファイル|登録者マスター(キー：半角カタカナの「読み」)|
|PREFCODE|物理ファイル|都道府県マスター|
|/IMG|ディレクトリーと画像ファイル|登録者の画像ファイル(jpeg)|

***

## インストール手順

SAVFをダウンロードしてIBM i に送信⇒復元。

SAVFの送信は、ACSのIFSプラグインで拡張子「.SAVF」をライブラリー(/QSYS.LIB/ライブラリー名.lib)に直接(事前にSAVFを作成せずに)アップロードする事も可能。

---

### IBM i で空のSAVFを作成

CRTSAVFコマンドで任意の名前のSAVFを作成。

~~~
> CRTSAVF FILE(QGPL/DEMODB)                              
   ライブラリー QGPL にファイル DEMODB が作成された。   
> CRTSAVF FILE(QGPL/IFSIMG)                              
   ライブラリー QGPL にファイル IFSIMG が作成された。  
~~~   
   
### SAVFのダウンロード(GitHub→PC)

GitHubからSAVFをダウンロード。

「/IMG」はサイズが大きいので分割zipファイルで掲載。  
末尾が数字のファイルをダウンロードし、Windowsのコマンドプロンプトから下記コマンドで結合し、ifsimg.zip(82.6MB)を解凍してifsimg.savf(118MB)を解凍。

~~~   
C:\Users\(Windowsのユーザー名)\Desktop>copy /B ifsimg.zip.001+ifsimg.zip.002+ifsimg.zip.003+ifsimg.zip.004+ifsimg.zip.005 ifsimg.zip
ifsimg.zip.001
ifsimg.zip.002
ifsimg.zip.003
ifsimg.zip.004
ifsimg.zip.005
        1 個のファイルをコピーしました。
~~~   

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
ftp> put demodb.savf qgpl/demodb
200 PORT SUBCOMMAND REQUEST SUCCESSFUL.
150 SENDING FILE TO MEMBER DEMODB IN FILE DEMODB IN LIBRARY QGPL.
226 FILE TRANSFER COMPLETED SUCCESSFULLY.
ftp: 174768 バイトが送信されました 0.08秒 2131.32KB/秒。
ftp> put ifsimg.savf qgpl/ifsimg
200 PORT SUBCOMMAND REQUEST SUCCESSFUL.
150 SENDING FILE TO MEMBER IFSIMG IN FILE IFSIMG IN LIBRARY QGPL.
226 FILE TRANSFER COMPLETED SUCCESSFULLY.
ftp: 120764160 バイトが送信されました 64.55秒 1870.95KB/秒。
ftp> quit
221 QUIT SUBCOMMAND RECEIVED.
~~~   

### オブジェクトの復元

任意の名前(この例では「GURILIB」)のライブラリーを作成し、ここに転送したSAVFから復元。  

復元後はSAVFを削除可能。

~~~   
> CRTLIB LIB(GURILIB) TYPE(*TEST) TEXT(' GURI のサンプルライブラリー') 
   ライブラリー GURILIB が作成された。                                
> RSTOBJ OBJ(*ALL) SAVLIB(DIST) DEV(*SAVF) SAVF(QGPL/DEMODB) RSTLIB(GURILIB
  )                                                                        
  4 個 のオブジェクトを DIST から GURILIB へ復元した。                     
> RST DEV('/QSYS.LIB/QGPL.LIB/IFSIMG.FILE') OBJ(('/IMG'))    
  1493 個のオブジェクトが復元された。                       
~~~


***

## NetServerファイル共有の設定

サンプルプログラム「登録者照会（モダナイズ版）」ではACSの「URL ホット・スポット」機能で5250画面に表示されたURL(FILE://パス名)をクリックして画像を表示。  
これを可能にするため、IFSのディレクトリー「/IMG」をNetServerで共有する。

最初にURLをクリックしたとき、「ネットワーク資格情報の入力」ダイアログがWindowsに表示されたり、アクセスが拒否されたりするケースがある。
この場合、一度Explorerで「\\\\(IBM i のホスト名またはIPアドレス)\IMG」を開いて「ネットワーク資格情報の入力」にIBM i のユーザー名とパスワードを入力し、「資格情報を記憶する」のチェックボックスを入れると、次回からはダイアログをスキップできる。
