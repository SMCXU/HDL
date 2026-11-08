# 原创资产源文件索引

本原型使用可编辑的代码资产制作管线：

- 人物、敌人、Boss、场景、动作、HUD：scripts/game_view.gd。
- 枪口、子弹与粒子行为：scripts/main.gd。
- 原创图标：assets/icon.svg。
- 原创音频：tools/generate_audio.py，可用 Python 标准库完全再生成 assets/audio/。
- 音乐音序、鼓组合成、旋律和包络均在生成脚本中，无外部采样。
- 字体是第三方 OFL 依赖，获取参数见 font-source.txt，不将字体宣称为原创。

尚未制作 Blender 模型、逐帧绘图工程或 DAW 工程，所选技术路线为程序化原创像素绘制和确定性音频合成。后续正式美术阶段可以替换这些资产，而不改变玩法协议。

## 第二轮位图资产

2026-11-03 起背景、角色、敌人、平台与 Boss 使用 `source_assets/art/` 下的原创概念衍生 PNG 源图及透明图集，生成提示词与说明均保留。旧的纯代码像素描述只适用于早期版本。
