# プラレール+

## 概要
[![](http://img.youtube.com/vi/rKU_vScfGiY/0.jpg)](http://www.youtube.com/watch?v=rKU_vScfGiY "")

乾電池型IoT「Mabeee」でプラレール（こまち＋はやぶさ）を運転してみる。

Mabeeeには、[オリジナルモデル](https://amzn.to/2F7jnW3)と[スクラッチモデル](https://amzn.to/3kEE0Jq)があり、このプロジェクトでは、スクラッチモデルを買いました。

おとなしくオリジナルモデルを買っておけば「MaBeeeトレイン」や「MaBeeeレーシング」などの公式アプリがあるので、そちらがオススメです。

このプロジェクトをインストールしたい場合には、clone後、Const.swiftに書いてあるkHayabusaPeripheralNameとkKomachiPeripheralNameを自身の端末のものに変更してください.。‎`Bluetooth Explorer` などを使って検知できます。Bluetooth Explorer.appはApple開発者サイトからAdditional Toolsをダウンロードするとその中に入っています。

オリジナルモデルの場合は、キャラクタリスティックの変更も必要かもしれません（未確認）。その場合は、Const.swiftのkCharacteristicUUIDも修正してください。

iOSアプリをビルドすると使えるようになります。

## 物理ボタンで操作
Arduino互換マイコンのESP-WROOM-32を使って、MabeeeにBLEで接続してプラレールを操作します。

[![](http://img.youtube.com/vi/q4K6wlKSGDQ/0.jpg)](http://www.youtube.com/watch?v=q4K6wlKSGDQ "")

<img src="https://github.com/ayakix/plarailplus/blob/master/hardware.jpg?raw=true" width="440px">

<img src="https://github.com/ayakix/plarailplus/blob/master/circuit.png?raw=true" width="440px">

| 概要 | 品番 | 価格 | 必須 |
| ---- | ---- | ---- | :---: |
|  マイコン  | [ESP-WROOM-32(ESP32-DevKitC)](http://akizukidenshi.com/catalog/g/gM-11819/)  | 1,480円 | ○ |
|  ボタン  |  [押しボタンスイッチ(モーメンタリ)](https://www.marutsu.co.jp/pc/i/827604/)  | 580円 x2 | ○ |
|  電源スイッチ  |  [スイッチ付き電源用USBケーブル](https://www.marutsu.co.jp/pc/i/574291/)  | 400円 | X |
|  筐体  |  [Bookers(バーボンウイスキー)](https://amzn.to/34x37Z9)  | 1万円ほど | X |
|  モバイルバッテリー  |  (試供品のため不明)  | -- | X |

他にはジャンパワイヤ、抵抗、ユニバーサル基板、ピンヘッダー、半田こて等の電子工作に必要なもの。
