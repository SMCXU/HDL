# 0.5.2 Release 内部测试包 / 2026-11-05

修复“选择行动”第二、第三关因旧进度门槛而静默无响应；现在三关均可直接进入，保留原存档、成绩与0.5.1原创图标。

- 产物：builds/iron-breakout-release.apk，0.5.2-prototype/code10，arm64-v8a，46.76MiB。
- SHA256：726cc6f8f1edf878790f3a49d18391a06a0f849a8c097e434fd44145a5193895。
- Godot4.7.2真正Release模板、非debuggable Manifest、apksigner签名及源身份检查通过。
- 现有内部Android测试证书签名，支持同证书覆盖；正式商店发布仍需正式证书。密钥只在work/。
- 本轮191/191逻辑回归、实际桌面选关页截图；未安装/真机验收，仍为阶段原型。既有人工/长测/多设备缺口继续保留。

重建：python3 tools/build_release.py。构建身份：builds/iron-breakout-release.build.json；[修复证据](evidence/mission-selection/REPORT.md)。旧debug APK保留，当前Release已替换0.5.1包。
