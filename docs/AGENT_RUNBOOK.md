# 诊断与阶段交付操作

## 复现与检查

在项目根目录执行：

```sh
python3 tools/manage.py test
python3 tools/quality.py capture --scenario normal --out work/polish/review
python3 tools/quality.py capture --scenario dense --out work/polish/review
python3 tools/quality.py capture --scenario boss --out work/polish/review
python3 tools/quality.py capture --scenario poses --out work/polish/review
python3 tools/quality.py capture --scenario animation --out work/polish/review
```

其他可选场景：sector2、sector3、settings、dead。桌面固定状态与连续采样图不是 Android 实际游玩验收；输出截图必须打开检查。

## 手机诊断

先确认 `adb devices -l` 中本次授权目标。以下序列号使用占位符，不能原样执行；SDK 路径按本机环境发现。

```sh
python3 tools/manage.py build
python3 tools/manage.py install --serial SERIAL
```

显式启用采样：调试包在 `run-as com.hdl.ironbreakout` 下创建 `files/telemetry.flag`，下一次启动生效。未经真实试玩完成确认，不因等待了20分钟就通过长测。用户正在试玩时禁止为取数重启游戏。

```sh
python3 tools/quality.py device-capture --serial SERIAL --out work/polish/device-session
python3 tools/quality.py summarize work/polish/device-session/frame-samples.csv --label '单设备实测；交互来源另行记录'
```

采样文件：frame-samples.csv；成功/死亡计时文件：run-results.csv。只有 `won` 且 checkpoint=false 的完整成功流程才可作为正常通关时长样本，不能把失败时间计入3～5分钟通过结论。

`device_check.py` 执行3次冷启动与10次后台循环，等待实际新渲染采样后截图，最后停在菜单：

```sh
python3 tools/device_check.py --serial SERIAL --out work/polish/device-smoke
```

该工具会中断游玩，必须安排在人工试玩前后。自动单点点击不是真实三指验证。首次未等待渲染的旧脚本曾截到过渡黑屏，那组结果不用于通过结论。

诊断结束后，在同一调试数据目录移除 telemetry.flag 并于方便时重新启动以关闭采样；仅删除该标记，不清空游戏数据。当前用户尚在验证时先保留标记，避免丢失采样。

## 快照与阶段包

```sh
python3 tools/quality.py snapshot --out work/polish/source-checkpoint
python3 tools/package_stage.py --out builds/polish-stage
```

阶段包包含当前 APK、源码归档、源码逐文件哈希和包哈希。明确标记原型，不代表A23最终验收完成。快照排除 work/、密钥、引擎、缓存；保留 source_assets/ 与制作记录。


## 单设备自动输入回放（不是人工验收）

`python3 tools/device_replay.py --serial <serial> --seconds 180 --out work/continuation/device-replay`

仅debug包读取临时qa-replay.json；回放开无敌保护、不会保存最高分。手机必须由用户解锁，工具不绕过锁屏。真实触控可终止、暂停会停止推进；超时不判通过，退出恢复原配置。采样interaction_source=automated_debug_replay，不得计入真人三指/听检/成功通关/20分钟验收。新版run-results-v2.csv保留来源，analyze_runs.py只纳入明确human_verified且非无敌的样本；原始记录不能未经录像/现场证据直接改为human_verified。


## 死亡重试和Android导航专项

`python3 tools/device_replay.py --serial <serial> --seconds 180 --mode retries --retry-count 23 --out work/verification/device-retries-final`

先做3次预热，再分析20个稳定采样：`python3 tools/analyze_retries.py work/verification/device-retries-final/replay-status.json`。自动输入交替全新开局/段落检查点，每次战斗3秒后主动受致命伤，等待死亡演出再重试。此场景只覆盖短生命周期，不证明整关资源/20分钟热稳定。记录总PSS、供电和电池温度，不能把电池传感器当机身触感。

`python3 tools/device_navigation.py --serial <serial> --out work/verification/navigation-final`执行菜单背景、设置、返回键、暂停恢复、设置进程重启保存；验证模式和前台窗口，仍须查看截图。测试结束恢复原settings.cfg。不会更改飞行模式、锁屏或其他手机设置。

新版frame-samples.csv的interval_valid=false表示无上一回调时间，摘要单列排除数量，不能当作0ms快速帧或启动卡顿。旧版无此字段的样本仍保留旧口径，不能悄悄修订历史数字。
