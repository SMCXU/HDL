# 0.5.1 图标更新 / 2026-11-05

用户授权重新制作符合项目风格的 App 图标并打 Release。

- DONE：原创重装头盔、青色目镜、枪灰装甲、橙色火花。内置 image_gen 制作，未引用商业游戏素材。原始图与完整提示词见 source_assets/branding/；可编辑单色 SVG 在 assets/branding/launcher-monochrome.svg。
- DONE：project.godot 图标、Android 普通桌面、自适应前景/背景与单色主题图标全部显式配置。版本 0.5.1-prototype/code9。
- DONE：Godot 派生脚本 tools/build_app_icon.gd 保留，生成1024项目图标、192普通图标与432自适应层；前景缩放至中心288，保留裁切余量。圆形/圆角方形/方形以及48px预览已实际打开查看：launcher-mask-preview.png。不是手机桌面截图或多设备验收。
- DONE：从最终 APK 解出 xxxhdpi 普通、自适应前景及单色 WebP，实际打开查看；aapt2 检查 Manifest 图标引用及 adaptive-icon 的背景/前景/monochrome 三层引用。实际图标已替换。原图、派生图与源码资产清单共98项哈希核对无误。
- DONE：Release 构建、apksigner 签名验证、非 debuggable Manifest、原生库与锁定 Release 模板一致、源哈希稳定；旧 debug APK 保留。
- 未测试：新版真机桌面/安装/游戏性能。本轮没有修改玩法，不将历史186项回归冒写成新回归。真人长测、听检、多设备等旧门槛继续未通过。

最终 APK：builds/iron-breakout-release.apk，49033958 bytes（46.76MiB）。
SHA256：600c1c401fff4ba15a77bce70037c88118b1a9af8c70e694690e32bac6cdf441。
签名沿用现有内部测试证书，可覆盖此前同证书版本；不是正式应用商店发布证书。

原始构建/签名/Manifest 工作证据：work/release-0.5.1-prototype/、work/release-0.5.1-build.log、work/icon-apk-check/。可分享构建身份：builds/iron-breakout-release.build.json。

引擎工具提示模板资源表残留 unused mipmap/themed_icon 指向不存在文件；Manifest 实际引用 mipmap/icon，已确认该 adaptive-icon 包含自定义 monochrome，未将此模板警告描述为真机主题图标通过。配置依据：[Godot4.7 Android 导出选项](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformandroid.html)。

重建派生图：`work/engine/Godot.app/Contents/MacOS/Godot --headless --path . --script tools/build_app_icon.gd`；重建 Release：`python3 tools/build_release.py`。
