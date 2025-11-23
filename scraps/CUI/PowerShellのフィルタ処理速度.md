#[[PowerShell]]

## 結論

`Where-Object` より `Where`メソッドの方が早い。のを確認しようとしたけど、オブジェクトに対して `-match` するのが一番早い。

## 準備

System.IO.DirectoryInfo のメンバーを取得して、そこから _BaseName_ をフィルタする。

```ps1
$Object = Get-Item . | Get-Member
$Measure = @()
```

以下の5ケース。

```ps1
$Measure += Measure-Time -Expression { $Object | Where-Object { $_ -match "BaseName" } } -Name 'Where-Object'
$Measure += Measure-Time -Expression { $Object | Where-Object { $_.Name -match "BaseName" } } -Name 'Where-Object(Name)'
$Measure += Measure-Time -Expression { $Object.Where({ $_ -match "BaseName" }) } -Name '.where'
$Measure += Measure-Time -Expression { $Object.Where({ $_.Name -match "BaseName" }) } -Name '.where(Name)'
$Measure += Measure-Time -Expression { $Object -match 'BaseName' } -Name '-match'
```

それぞれのケースが同じ結果を得られることの確認。

```ps1
> $Object | Where-Object { $_ -match "BaseName" }

   TypeName: System.IO.DirectoryInfo

Name     MemberType     Definition
----     ----------     ----------
BaseName ScriptProperty System.Object BaseName {get=$this.Name;}

> $Object | Where-Object { $_.Name -match "BaseName" }

   TypeName: System.IO.DirectoryInfo

Name     MemberType     Definition
----     ----------     ----------
BaseName ScriptProperty System.Object BaseName {get=$this.Name;}

> $Object.Where({ $_ -match "BaseName" })

   TypeName: System.IO.DirectoryInfo

Name     MemberType     Definition
----     ----------     ----------
BaseName ScriptProperty System.Object BaseName {get=$this.Name;}

> $Object.Where({ $_.Name -match "BaseName" })

   TypeName: System.IO.DirectoryInfo

Name     MemberType     Definition
----     ----------     ----------
BaseName ScriptProperty System.Object BaseName {get=$this.Name;}

> $Object -match 'BaseName'

   TypeName: System.IO.DirectoryInfo

Name     MemberType     Definition
----     ----------     ----------
BaseName ScriptProperty System.Object BaseName {get=$this.Name;}
```

これは得られる結果が異なるのでケースには含めない。

```ps1
> $Object.Name -match "BaseName"
BaseName
```

## 結果

```ps1
> $Measure | ft

Name               Count Average Maximum Minimum StandardDeviation
----               ----- ------- ------- ------- -----------------
Where-Object       10000    0.17    3.62    0.13              0.12
Where-Object(Name) 10000    0.16    6.25    0.12              0.12
.where             10000    0.05    3.77    0.04              0.06
.where(Name)       10000    0.04    3.44    0.03              0.05
-match             10000    0.01    1.91    0.01              0.02
```

Nameの指定はしなくても同じ結果が得られるのは、そういう仕様かもしれない。他のプロパティに対してだとできなかった。
速度も指定ありなしで有意な差はなし。

## Measure-Time関数

Measure-Commandのラッパー。

```ps1
function Measure-Time {
    param(
        [scriptblock]$Expression,
        [int]$Count = 10000,
        [string]$Name
    )

    $array = @()
    foreach ($i in (1..$Count)) {
        $array += (Measure-Command -Expression $Expression).TotalMilliseconds
    }

    return $array | Measure-Object -AllStats | Select-Object @{N = "Name"; e = { $Name } }, Count, Average, Maximum, Minimum, StandardDeviation
}
```
