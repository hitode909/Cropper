Cropper
=========

概要
------

近代デジタルライブラリーから画像をダウンロードした画像の余白を除いて左右に分割します．

使い方
------

起動時の引数に，分割したい本の画像が入ったディレクトリのパスを指定します．スペース区切りで複数指定できます．

    perl cropper.pl ~/Documents/正義の叫/

この例の場合，以下に，分割された画像が保存されます．

    ~/Documents/正義の叫/crop/

処理には大変時間がかかります．

動作環境
--------

* Perl が必要です．
* Imager が必要なので，CPAN でインストールしてください．

その他
------
アルゴルズムが良くないので，大変遅く，精度もあまりよくないです．