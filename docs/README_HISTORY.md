# README 历史归档

归档日期：2026-11-06。以下保留旧首页的开发过程记录，包含已被后续版本覆盖的状态，不代表当前功能与验收结论。当前项目介绍以[根目录 README](../README.md)为准，近期修复见[选关记录](evidence/mission-selection/REPORT.md)。

---

# 钢铁突围 / Iron Breakout

原创 Android 横版射击游戏，Godot 4.7.2 + GDScript + Compatibility 渲染。

当前版本 **0.5.2 自由选关阶段原型**：已打通主菜单、移动跳跃、五种武器与单层R强化、三类敌人、检查点、Boss、失败重试和通关结算。画面由本项目原创概念生成的位图图集与 GDScript 绘制组成，音乐与音效由原创合成脚本生成，不使用现成游戏素材。

第二关现为一屏宽的纵向水坝：54次登高、左右折返、六个高度区域、可选供能节点与顶部Boss。[本批验证与待验收项](evidence/vertical/REPORT.md)。

三关普通架空平台已支持“正下＋跳跃”下穿，实体地面与Boss底板受保护。[功能与验证](evidence/drop-through/REPORT.md)。

## 运行

在 Godot 4.7.2 导入 `project.godot`，按 F6/F5 运行。首次启动先等待资源导入。

本机已准备引擎：

```sh
python3 tools/manage.py run
python3 tools/manage.py test
python3 tools/manage.py build
python3 tools/manage.py install --serial YOUR_DEVICE_SERIAL
```

干净 macOS 环境先运行 `python3 tools/manage.py bootstrap`，该步骤需要网络和约 3 GB 临时空间。也可设置 `GODOT_BIN` 使用已有的 4.7.2 引擎。Android SDK 和 JDK 17 需预先安装。

操作、构建和验收详情见 `docs/`。当前不包含联网、广告或付费功能。

## 当前开发边界

这是第一轮可玩版本，并非计划中的最终发布成品。关卡节奏、动作表现和视觉素材仍需进一步打磨；3～5 分钟目标时长、三指真机操作、蓝牙手柄、跨设备适配和持续真机性能尚未完成验收。详见 `docs/KNOWN_ISSUES.md` 与 `docs/DEVELOPMENT_PLAN.md`。

## 视觉样板更新

2026-11-03：接入暗夜工业科幻方向的首轮视觉样板，含分层厂区、装甲轮廓、射击特效与战术 HUD。桌面渲染已检查，测试 20/20 通过；未完成新视觉 Android 验收，仍为原型。详见 `docs/VISUAL_DIRECTION.md`。

2026-11-03 第二轮：已将工厂背景、角色动画图集、三类敌人、平台和 Boss 替换为细节位图，安装至 JER-AN20 并查看真机菜单与战斗截图。资产源文件及生成提示词位于 `source_assets/art/`。仍为视觉原型，详见 `docs/BITMAP_ART_PASS.md`。

## 后续打磨规划

见 [《完整打磨与验收规划》](POLISH_MASTER_PLAN.md)：涵盖 M0～M5 阶段、角色动作、战斗特效、场景与音频、性能预算、Android 测试矩阵和最终交付门槛。

Agent 接手与持续开发见 [开发执行计划](AGENT_DEVELOPMENT_PLAN.md) 和 [执行台账](AGENT_PROGRESS.md)。

## 本轮优化阶段

已接入主角36姿势/过渡、敌人状态图集、共享枪口、Boss演出、特效池、分层视差、音频优先级与摇杆防误触；本轮回归60/60。误触修复版已装JER-AN20，用户反馈明显改善。20分钟真实长测、完整动作/音频听检、多设备与手柄验收未完成，仍是原型。详见 [执行证据](evidence/polish/REPORT.md)、[性能口径](PERFORMANCE_BUDGET.md) 和 [诊断操作](AGENT_RUNBOOK.md)。

当前验收缺口见 [QA状态](QA_STATUS.md)。最新阶段包已安装并实际查看亮屏显示；历史锁屏断点不再代表当前安装状态。


## 2026-11-04 关卡节奏阶段更新

0.2.0-prototype将同一关分为三段27组遭遇，加入清敌开门、段落检查点/得分恢复、屏外敌人指引和分段音乐。66/66回归通过，已安装JER-AN20并查看画面。无敌自动逻辑回放可通关，不代表人工时长或20分钟验收。详见[本批证据](evidence/continuation/REPORT.md)。


## 0.2.1 导航与重试专项

修复Android返回键默认退出、菜单背景误启动、设置区外误改及过早触摸重试。76/76回归；单设备导航和设置重启保存已复验，死亡重试按独立自动场景采集。最新证据及剩余限制见[本批报告](evidence/verification/REPORT.md)。仍是阶段原型，人工长测、多设备、手柄与听检未完成。


## 第二关「暴雨水坝」阶段实现

用户新增第二关需求：原创「暴雨水坝 / 雷闸行动」，河道突入→泄洪井攀登→坝顶断电→双臂闸机Boss。详细玩法、双关架构、任务依赖和验收见[第二关Agent开发计划](LEVEL_02_AGENT_DEVELOPMENT_PLAN.md)，状态见[第二关台账](LEVEL_02_PROGRESS.md)。用户确认设计后已接入0.3.0双关阶段版，105/105回归；第一关正常通关后解锁第二关，debug快速预览不写入成绩/解锁。实际范围与限制见[第二关首轮报告](evidence/level02/implementation/REPORT.md)，一期欠验收继续保留。


## 第二关纵向重设计草案（待确认）

用户反馈0.3.0横向跑动过多，新增[纵向攀登关卡设计](LEVEL_02_VERTICAL_REDESIGN.md)：整关一屏宽、左右交替登高、纵向镜头、顶部直接接Boss。当前仅设计文档，等待用户满意后再修改，游戏和APK未变。


第三关「赤岩瀑布·断崖要塞」已接入：44次登高、两座横移台、两条局部分路、落石/热流和独立顶部要塞Boss。用户已批准主题及开发，[执行计划](LEVEL_03_AGENT_DEVELOPMENT_PLAN.md)、[台账](LEVEL_03_PROGRESS.md)与[阶段证据](evidence/level03/implementation/REPORT.md)记录真实完成范围。


五武器＋R已按用户授权接入：[设计方案](WEAPON_EXPANSION_DESIGN.md)、[执行计划](WEAPON_AGENT_DEVELOPMENT_PLAN.md)、[台账](WEAPON_PROGRESS.md)和[阶段验证](evidence/weapons/REPORT.md)。普通/M/S/L/F、固定类型拾取、统一伤害与三Boss部位保护已实现；真人平衡/听检/长测等仍待验收。


内部Release构建：`python3 tools/build_release.py`，产物[iron-breakout-release.apk](../builds/iron-breakout-release.apk)。使用非调试Release模板及现有内部测试证书；正式上架需正式签名，验证边界见[Release构建记录](RELEASE_BUILD.md)。

## 0.5.2 自由选择行动

“选择行动”中的三关均可点击进入，不再要求先通关上一关。旧进度与分关最佳成绩保留。191/191逻辑回归通过，已查看桌面选择页，未做本轮手机实测。[修复记录](evidence/mission-selection/REPORT.md)。
