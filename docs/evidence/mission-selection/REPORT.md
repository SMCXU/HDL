# 0.5.2 选择行动无响应修复 / 2026-11-05

原因：旧选关界面 items() 将第二/第三关设置为 enabled=false，activate() 又重复判断 unlocked_levels。新存档及未通关存档会静默忽略点击。Release 不提供 debug 快速预览，因此出现用户反馈现象。

已按用户直接选关的预期调整：三张卡片始终可选，鼠标/触摸命中与键盘/手柄确认共用入口；移除直接进入的进度门槛与“完成第X关解锁”文案。每次进入仍为正式新开局，清理旧关状态；分关最佳成绩、真实通关记录和胜利页下一关流程保留，不伪造已通关状态。不需要清存档或卸载。

验证：python3 tools/manage.py test 完整通过191/191。包含新存档第二、第三关指针点击、新存档三关键盘确认、进入不篡改通关进度、旧存档迁移、真实完成记分与下一关。此为逻辑模拟，不代表手指/手柄硬件实测。首次沙箱运行受本机权限阻塞，重跑本机完整回归通过，日志 work/mission-selection-tests-full.log。

已运行 tools/visual_check.gd --scenario=selection，实际打开并查看 selection.png：三卡片正常高亮、标题/主题正常、无旧锁定文案。这是桌面窗口渲染，不是Android截图。

交付：builds/iron-breakout-release.apk，0.5.2-prototype/code10，46.76MiB；SHA256 726cc6f8f1edf878790f3a49d18391a06a0f849a8c097e434fd44145a5193895。
Godot4.7.2 Release原生模板、非debuggable Manifest、apksigner签名/来源检查通过，继续沿用现有内部测试证书。本轮没有安装/重启用户手机，未做新版Android实测；未关闭既有长测/真人体验/多设备终验缺口。
