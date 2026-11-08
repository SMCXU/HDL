# 构建

## 锁定环境

- Godot：4.7.2.stable.official.ed1daf0bf，标准 GDScript 版本。
- 渲染：Compatibility / OpenGL ES 3。
- 本轮构建：macOS、JDK 17.0.16、Android SDK build-tools 36.0.0。
- 构建形式：传统 APK 导出，不依赖 Gradle，不需要联网游戏服务。
- 包名：com.hdl.ironbreakout；版本：0.1.0 / 1；ABI：arm64-v8a。
- 逻辑画布：960 × 540，保持比例；宽屏两侧留边以保持一致的战斗视野。

## 干净环境复现（流程已编写，本轮未在第二台干净机器验证）

1. 安装 Python 3、JDK 17、Android SDK。
2. 运行 `python3 tools/manage.py bootstrap` 下载锁定版本引擎与模板。
3. 设置 `ANDROID_SDK_ROOT` 和 `HDL_JAVA_PATH`，后者指向 JDK 17 根目录。本机默认值由脚本检测。
4. 运行 `python3 tools/manage.py test`。
5. 运行 `python3 tools/manage.py build`。
6. 输出为 `builds/iron-breakout-debug.apk`。
7. `python3 tools/manage.py install --serial DEVICE_SERIAL` 安装并启动。

导出模板由官方 `downloads.godotengine.org` 提供。模板归档仅提取 Android debug/release APK，完整归档保留在 work/ 便于检查。第三方引擎和临时下载不随源码包交付。

本项目不会注册商店账号或自动发布。调试签名为本地生成，work/debug.keystore 不提交。换机器生成的调试密钥不同，覆盖安装既有包时可能需要原密钥；卸载会删除本地数据，应由操作者自行决定。发布签名和商店 AAB 不在本轮交付内。

## 素材再生成

- `python3 tools/generate_audio.py`：确定性生成 19 个原创 WAV 文件，无第三方 Python 依赖。
- `python3 tools/fetch_font.py`：从 Google Fonts 获取界面字符子集，需要联网。新增中文界面文字后重新执行。
- `scripts/game_view.gd`：原创场景、人物、动作和 UI 绘制源代码。
- `assets/icon.svg`：原创可编辑启动图标。

字体为第三方开源工具资源，许可随附；人物、关卡、图形、音乐和音效为本项目制作。
