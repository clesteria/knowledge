# hooks/post_merge.nim
import std/[osproc, os, strutils]

# 1. scraps build の実行
echo "ビルドを開始する..."
let buildStatus = execCmd("scraps build")
if buildStatus != 0:
  echo "エラー: scraps build に失敗した。"
  quit(1)

# 2. カスタム CSS のコピーとインクルード処理
let srcCss = "assets/highlight.css"
let destCss = "public/highlight.css"

if fileExists(srcCss):
  try:
    # public ディレクトリが存在することを確認してコピー
    createDir("public")
    copyFile(srcCss, destCss)
    echo "highlight.css を public/ にコピーした。"

    # 3. public/ 配下の CSS ファイルを探し、@import を追記する
    # walkDirRec で再帰的に検索する
    for file in walkDirRec("public"):
      # コピーした highlight.css 自体は処理対象から除外する
      if file.endsWith(".css") and not file.endsWith("highlight.css"):
        let originalContent = readFile(file)
        let importStatement = "@import \"highlight.css\";\n"

        # 二重追記を防ぐため、未記載の場合のみ先頭に挿入する
        if not originalContent.startsWith(importStatement):
          writeFile(file, importStatement & originalContent)
          echo "インポート文を " & file & " に追加した。"

  except CatchableError as e:
    echo "エラー: CSS のインクルード処理に失敗した。"
    echo e.msg
    quit(1)
else:
  echo "警告: " & srcCss & " が見つからないため、スタイルの追加処理をスキップした。"

# 4. デプロイの実行
echo "デプロイを開始する..."
let deployStatus = execCmd("npx wrangler pages deploy --branch=main")
if deployStatus != 0:
  echo "エラー: デプロイに失敗した。"
  quit(1)

echo "すべての処理が完了した。"
