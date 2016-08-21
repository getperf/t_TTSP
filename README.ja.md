Toshiba Total Storage Platform (TTSP) モニタリングテンプレート
===============================================

TTSP モニタリング
-------------

東芝ストレージサポートユーティリティ付属の、tsuacsコマンド(ArrayFort の場合は aeuacs)を
実行してストレージのパフォーマンス情報を採取します。採取したデータをモニタリングサーバ側で集計してグラフ登録をします。本テンプレートは以下のストレージを対象としています。

* ArrayFort シリーズ
* SC3000 シリーズ

ストレージとサーバがFC接続しているローカル構成の場合は、そのサーバ上でエージェントをします。
ネットワーク経由でアクセス可能なストレージの場合は、ストレージコントローラのIPアドレスを指定してリモートで情報採取をします。その場合、エージェントの実行サーバに東芝サポートユーティリティのインストールが必要になります。

**注意**

1. FL6000(Violin),NH3000(NAS-GW)は別テンプレートとなります。

ファイル構成
-------

テンプレートに必要な設定ファイルは以下の通りです。

|          ディレクトリ          |        ファイル名        |                  用途                 |
|--------------------------------|--------------------------|---------------------------------------|
| lib/agent/TTSP/conf/           | iniファイル              | エージェント採取設定ファイル          |
| lib/Getperf/Command/Site/TTSP/ | pmファイル               | データ集計スクリプト                  |
| lib/graph/[ArrayFort,SC3000]/  | jsonファイル             | グラフテンプレート登録ルール          |
| lib/cacti/template/0.8.8g/     | xmlファイル              | Cactiテンプレートエクスポートファイル |
| script/                        | create_graph_template.sh | グラフテンプレート登録スクリプト      |

メトリック
-----------

TTSPパフォーマンス統計グラフなどの監視項目定義は以下の通りです。

|                Key                 |                                                  Description                                                   |
|------------------------------------|----------------------------------------------------------------------------------------------------------------|
| **パフォーマンス統計**             | **ストレージI/O統計パフォーマンス統計グラフ**                                                                  |
| wbc                                | **キャッシュヒット率**<br>write-back-cache schedule                                                            |
| summary                            | **コントローラI/O統計**<br>IOPS / MB/sec / Response / HDD IOPS                                                 |
| read_elapse / write_elapse         | **コントローラレスポンス統計**<br>read response histogram / write response histogram                           |
| read_size / write_size             | **コントローラブロックサイズ統計**<br>read block size / write block size                                       |
| lun_summary                        | **LUN I/O統計**<br>LUN Read IOPS / LUN Write IOPS / LUN Read MBs / LUN Write MBs / LUN Response / LUN HDD IOPS |
| lun_read_elapse / lun_write_elapse | **LUNスポンス統計**<br>LUN read response histogram / LUN write response histogram                              |
| lun_read_size / lun_write_size     | **LUNブロックサイズ統計**<br>LUN read block size / LUN write block size                                        |
| raid_summary                       | **RAIDグループI/O統計**<br>RaidGr IOPS / RaidGr MBs / RaidGr Response                                          |
| raid_read_size / raid_write_size   | **RAIDグループブロックサイズ統計**<br>RaidGr read block size / RaidGr write block size                         |

Install
=====

テンプレートのビルド
-------------------

Git Hub からプロジェクトをクローンします

```
git clone https://github.com/getperf/t_TTSP
```

プロジェクトディレクトリに移動して、--template オプション付きでサイトの初期化をします

```
cd t_TTSP
initsite --template .
```

Cacti グラフテンプレート作成スクリプトを順に実行します(1行目がArrayFort、2行目がSC3000)

```
./script/create_graph_template__af.sh
./script/create_graph_template__sc.sh
```

Cacti グラフテンプレートをファイルにエクスポートします

```
cacti-cli --export ArrayFort
cacti-cli --export SC3000
```

集計スクリプト、グラフ登録ルール、Cactiグラフテンプレートエクスポートファイル一式をアーカイブします

```
sumup --export=TTSP --archive=$GETPERF_HOME/var/template/archive/config-TTSP.tar.gz
```

テンプレートのインポート
---------------------

前述で作成した $GETPERF_HOME/var/template/archive/config-TTSP.tar.gz がTTSPテンプレートのアーカイブとなり、
監視サイト上で以下のコマンドを用いてインポートします

```
cd {モニタリングサイトホーム}
tar xvf $GETPERF_HOME/var/template/archive/config-TTSP.tar.gz
```

Cacti グラフテンプレートをインポートします。監視対象のストレージに合わせてテンプレートをインポートしてください

```
cacti-cli --import ArrayFort
cacti-cli --import SC3000
```

インポートした集計スクリプトを反映するため、集計デーモンを再起動します

```
sumup restart
```

使用方法
=====

エージェントセットアップ
--------------------

ArrayFort の場合、以下のエージェント採取設定ファイルをエージェントホームの conf ディレクトリの下(/home/{OSユーザ}/ptune/conf/)にコピーして、エージェントを再起動してください。

```
{サイトホーム}/lib/agent/TTSP/conf/ArrayFort.ini
```

SC3000 の場合、以下のファイルを conf 下にコピーしてください。

```
{サイトホーム}/lib/agent/TTSP/conf/SC3000.ini
```

監視対象サーバから直接採取する場合と、リモートで採取する場合で実行オプションの変更が必要になります。
以下例はリモート採取の設定となります。

```
;---------- Monitor command config (Storage HW resource) -----------------------------------
STAT_ENABLE.TTSP = true
STAT_INTERVAL.TTSP = 300
STAT_TIMEOUT.TTSP = 400
STAT_MODE.TTSP = concurrent

; SC3000
STAT_CMD.TTSP = 'sudo /usr/local/TSBtsu/bin/tsuacs -h {ストレージIPアドレス} -T 60 -n 5 -all',   {ストレージIPアドレス}/tsuacs.txt
```

ローカル採取の場合は、上記コマンド定義 STAT_CMD.TTSP の実行オプションの "-h {ストレージのIPアドレス}" の指定を削除します。

データ集計のカスタマイズ
--------------------

上記エージェントセットアップ後、データが集計されると、サイトホームディレクトリの lib/Getperf/Command/Master/ の下に TTSP.pm ファイルが生成されます。
本ファイルは監視対象ストレージのマスター定義ファイルで、ストレージのコントローラ、LUN、Raidグループの用途を記述します。
同ディレクトリ下の TTSP.pm_sample を例にカスタマイズしてください。

グラフ登録
-----------------

上記エージェントセットアップ後、データ集計が実行されると、サイトホームディレクトリの node の下にノード定義ファイルが出力されます。
出力されたファイル若しくはディレクトリを指定してcacti-cli を実行します。

```
cacti-cli node/ArrayFort/{ストレージノード}/
```

AUTHOR
-----------

Minoru Furusawa <minoru.furusawa@toshiba.co.jp>

COPYRIGHT
-----------

Copyright 2014-2016, Minoru Furusawa, Toshiba corporation.

LICENSE
-----------

This program is released under [GNU General Public License, version 2](http://www.gnu.org/licenses/gpl-2.0.html).
