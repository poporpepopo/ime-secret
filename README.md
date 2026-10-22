# ime-secret

Google日本語入力のシークレットモード（学習しないモード）をメニューバーに表示し、クリックで切り替える macOS アプリ。

- オフのときは目のアイコン、オンのときは赤い「シークレット」バッジを表示
- 左クリックで切り替え。右クリック（または control + クリック）で状態表示と終了のメニュー
- 変換候補「しーくれっと」や環境設定から切り替えた場合も、設定ファイルを 2 秒ごとに見て表示を追従させる

## 仕組み

切り替えは `bin/gime-incognito`（Python）が行う。Google日本語入力の設定ファイル
`~/Library/Application Support/Google/JapaneseInput/config1.db`（protobuf）のフィールド 20
（`incognito_mode`）を書き換え、変換エンジンを `launchctl kickstart -k` で再起動して読み込ませる。

```sh
gime-incognito [on|off|toggle|status]   # 省略時は toggle
```

アプリはこのスクリプトを `~/.local/bin/gime-incognito` から呼ぶので、リンクを置いておく。

```sh
ln -s "$PWD/bin/gime-incognito" ~/.local/bin/gime-incognito
```

## ビルド

Xcode のコマンドラインツール（`swiftc`）があればビルドできる。

```sh
./build.sh
open ~/Applications/IMEシークレット.app
```

`~/Applications/IMEシークレット.app` にビルドして入れ直す。

## ログイン時に起動する

`~/Library/LaunchAgents/` に、`ProgramArguments` が `~/Applications/IMEシークレット.app/Contents/MacOS/ime-secret` の絶対パスで、`RunAtLoad` が true の plist を置く。
