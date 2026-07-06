# TopUp — 账户解析

macOS 原生应用，粘贴大段文本后自动解析账户名称、ID、余额、消耗与充值金额。

## 功能

- 支持余额报告行：`账户名(ID)余额:xxx[USD]消耗xxx`
- 支持名称 + ID 列表 + 充值指令
- 充值金额：显式提取 > 公式（消耗 × 5 − 余额）> 留空
- 表格展示，点击单元格复制

## 运行

```bash
open TopUp.xcodeproj
```

在 Xcode 中选择 TopUp scheme，按 `Cmd+R` 运行。

## 测试

```bash
xcodebuild test -project TopUp.xcodeproj -scheme TopUp -destination 'platform=macOS'
```
