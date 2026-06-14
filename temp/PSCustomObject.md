# PSCustomObject vs Class

## 言語を PowerShell から C# に変えるべきか

### C#にするべき要件

- 静的型
- 厳密なモデル
- 不変条件
- 大きめのロジック
- 複雑な検証
- 長期保守
- テスト容易性

### PowerShellのままでいいケース

これらは型安全性よりも操作性や配布の容易さが重要になるため、PowerShell が向いている。

- Windows 管理・自動化
- レジストリ操作
- サービス操作
- イベントログ操作
- Active Directory 操作
- WMI / CIM
- ファイル操作
- JSON / CSV / Excel の入出力
- 外部コマンドとの連携
- 薄いグルーコード
- 利用者が PowerShell から呼び出すツール

PowerShell に静的型のような仕組みを無理に作るより、C# に型やロジックの責任を持たせる方が健全。

## PowerShell では型が暗黙で変換される

```powershell
class NewRecord {
  [int]$Id

  NewRecord([int]$id) {
    this.Id = $id
  }
}
```

というクラスがあったとして、

```powershell
[NewRecord]::New("1")
```

で、文字列型の"1"が数値に変換できてしまうため、通ってしまう。

関数同士で渡すオブジェクトをクラスで定義しても、渡される時に暗黙の返還が入るため、厳密にクラス通りの内容だという保証がされない。

```powershell
function Get-RecordId ([NewRecord]$Record) {
  return $Record.Id
}
```

という関数に対して、以下が通ってしまう。

```powershell
$Record = @{ [string]Id = "1" }
```

コンストラクタに型チェックさせるとする。

```powershell
class NewRecord {
  [int]$Id

  NewRecord($id) {
    if ($id -isnot [int]) {
      throw 'Id must be Int32.'
    }

    $this.Id = $id
  }
}
```

この場合、`[NewRecord]::New("1")` は跳ねられる。しかし、`$Record = [NewRecord]::New(1); $Record.Id = "2"` という改ざんはできてしまう。

ただ、結局 `int` になり得る値しか受け入れないので、問題ないと言えばない。
