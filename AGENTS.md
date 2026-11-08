# 项目开发约定

阅读 README.md 和 docs/DEVELOPMENT_PLAN.md 了解当前阶段。用户已授权按计划自主开发，避免逐项确认常规实现。

- 锁定 Godot 4.7.2 与 GDScript；Android Compatibility 渲染；离线单机。
- 核心范围不扩展到联网、广告或内购。
- 所有游戏图形、音乐和音效自行制作，保留代码/工程源文件和资产清单。
- 字体等开源依赖记录来源与许可，禁止使用无来源商业游戏素材。
- 临时脚本、引擎下载、签名密钥和诊断日志放 work/，禁止提交密钥。
- 修改玩法后运行 python3 tools/manage.py test；修改 UI/渲染后实际查看截图。
- Android 验收必须区分模拟、单设备实测、多设备实测、未测试，不能把逻辑模拟当成真机性能。
- 未满足 docs/DEVELOPMENT_PLAN.md 最终验收时，标记为原型或阶段版本，不声称成品完成。

## Agent 执行入口

继续开发前阅读 [Agent 开发执行计划](docs/AGENT_DEVELOPMENT_PLAN.md) 和 [执行台账](docs/AGENT_PROGRESS.md)，按任务依赖与当前断点推进。需求与最终验收见 [完整打磨规划](docs/POLISH_MASTER_PLAN.md)。每轮更新任务状态与真实验证证据，不能将历史样板或未测试项标记为完成。
