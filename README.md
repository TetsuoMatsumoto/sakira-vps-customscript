## Node-RED セットアップ用カスタムスクリプト  

**さくらのVPS** で環境構築する際に利用できるカスタムスクリプトです  
Node-RED＋HTTPSでアクセスできる＋nginxでアクセスのログが取得できるようになります  
  
具体的には以下のスクリプトを組み合わせています  

1. ScriptName: CentOS_LetsEncrypt  
2. ScriptName: CentOS_NodeRed  
3. ScriptName: CentOS_yum-update  
4. mariaDb->MySQLに入れ替えして、node pluginのinstallをする  
5. memcachedのnode pluginをinstallをする  
6. nginx->NodeRedでアクセスするようにする  
  
ベースは **さくらインターネットさん** が公開されている[スタートアップスクリプト](https://github.com/sakura-internet/cloud-startupscripts)を組み合わせています！ **感謝！**  

---

## 使い方
1. スクリプトの以下の箇所を自身の環境に合わせて置換する  
 `@@@@@your domain name@@@@@` -----> SSL証明書を取得するドメイン名  
 `@@@@@youre email addres@@@@@` -----> let's encryptの通知を受け取るメールアドレス  
 `@@@@@Node-Red flow editer login id@@@@@` -----> Node-RED フローエディターのログインID（５文字以上）  
 `@@@@@Node-Red flow editer login password@@@@@` -----> Node-RED フローエディターのパスワード（8文字以上）  
2. カスタムスクリプトの登録、実行方法は[さくらのVPS カスタムスクリプトの使い方](https://vps-news.sakura.ad.jp/startupscripts/)を参考にしてください

正常終了していれば、  
Node-REDのflowediterには`https://@@@@@your domain name@@@@@/`でアクセスすることができます  

### MySQLを利用する場合は、以下を実行してください
node-red-node-mysqlがMySQL 8.0の認証方式caching_sha2_passwordに未対応のため、以前採用されていた認証方式のユーザを作成します  
こちらを参考にさせていただきました！ **感謝！**  
[MySQL8.0におけるデフォルトの認証プラグインの変更](http://variable.jp/2018/02/23/mysql8-0%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E3%83%87%E3%83%95%E3%82%A9%E3%83%AB%E3%83%88%E3%81%AE%E8%AA%8D%E8%A8%BC%E3%83%97%E3%83%A9%E3%82%B0%E3%82%A4%E3%83%B3%E3%81%AE%E5%A4%89%E6%9B%B4/)  


1. sshでログインする
2. MySQLの初期パスワードを確認する  
   `sudo cat /var/log/mysqld.log | grep password`
3. MySQLの初期設定を行う  
   `mysql_secure_installation`
4. MySQLにログインしてください
5. node-red-node-mysqlでアクセスするためのユーザを作成する  
   `CREATE USER '@@@user name@@@'@'@@@host name@@@' IDENTIFIED WITH mysql_native_password BY  '@@@password@@@';`
6. ユーザ権限を追加する  
   `GRANT ALL PRIVILEGES ON '@@@db_name@@@'.* TO '@@@user name@@@'@'@@@host name@@@';`

### memcachedを利用する場合は、以下を実行してください
こちらを参考にさせていただきました！ **感謝！**  
[CentOS7でmemcachedのインストールから動作確認](https://yomon.hatenablog.com/entry/2016/02/16/195809#%E8%A8%AD%E5%AE%9A%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E7%A2%BA%E8%AA%8D)  

1. sshでログインする
2. 環境情報を変更&確認する  
   `vi /etc/sysconfig/memcached`
---

## やっていないこと

*  さくらのVPS 以外で利用する場合は、参考にはなりますが、そのままでは動作しません（ご自身でご対応ください）  
*  nginxでhttpアクセスはブロックしていません  
*  Let's Encryptの証明書は自動更新するようにはしていません  
*  環境に合わせて設定いただく入力値に対するvalidation check  
*  自動でMySQLのcaching_sha2_passwordのユーザを作成する  

---

## おねがい

* カスタムスクリプトについては、さくらインターネットさんでは調査およびQAに対応などは **対応いただけません**  
  くれぐれもお問い合わせ等を **行わないよう** にお願いします  
* 利用については、 **自己責任で利用をお願いします**  
* ISSUEやお問い合わせについては、ベストエフォートで対応するつもりですが、お答えできないこともあります  
