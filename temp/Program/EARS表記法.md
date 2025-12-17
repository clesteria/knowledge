#[[Develop]] #[[FromGeneratedAI]]

## EARS (Easy Approach to Requirements Syntax) 表記法

Amazon 製 AI 搭載 IDE の Kiro で採用している要件定義のフレームワーク。

| 要求              | 説明                                           | 形式                                                           |
| ----------------- | ---------------------------------------------- | -------------------------------------------------------------- |
| Ubiquitous        | 常に適用される要求                             | _THE_ <システム>, _SHALL_ <動作>                               |
| Event-driven      | あるイベントが発生した場合に適用される要求     | _WHEN_ <イベント>, _THE_ <システム> _SHALL_ <動作>             |
| State-driven      | システムが特定の状態にある場合に適用される要求 | _WHILE_ <状態>, _THE_ <システム> _SHALL_ <動作>                |
| Optional          | 追加機能やオプションの機能に関する要求         | _WHERE_ <条件>, _THE_ <システム> _SHALL_ <動作>                |
| Unwanted Behavior | 望ましくない状況を回避するための要求           | _IF_ <条件>, _THEN THE_ <システム> _SHALL NOT_ <動作>          |
| Complex           | 複数の条件やイベントを組み合わせて記述する要求 | _WHEN_ <イベント>, _IF_ <条件> _THE_ <システム> _SHALL_ <動作> |
