これを実行する場合、単にファイルを消してコミットするだけでは不十分だ。Gitの歴史（.git）を完全に削ぎ落として「最初の1コミット」にする必要がある。

## 推奨される手順

1. 作業用の別ディレクトリを作る（ローカルのRadicle原本を汚さないため）
1. `git init` で完全に新規のリポジトリを作る。
1. そこにGitHub用の README.md と init.sh だけを作成する。
1. `git commit -m "Identity migration: Repository moved to Radicle"` でコミット。
1. これをGitHubのリモートに対して `git push origin main --force`（強制上書き） する。

これで、GitHub側にあった過去の数万行のコード、すべてのブランチ、すべての過去のコミット履歴（メールアドレスの痕跡含む）が、Microsoftのサーバー上から物理的に上書き消去される。
