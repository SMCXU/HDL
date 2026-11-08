# 工业科幻位图资产源文件

2026-11-03，使用内置 image_gen 按本项目已批准的原创概念图制作，无外部商业游戏素材。

- approved-reference.png：用户批准的本项目概念图，视觉参考，非游戏运行背景。
- factory-source.png：工厂完整位图源文件；运行副本 assets/art/factory.png。
- actors-source.png：5×2 透明角色图集源文件；运行副本 assets/art/actors.png。
- structures-source.png：2×2 透明场景与机械图集源文件；运行副本 assets/art/structures.png。
- generation-prompts.json：生成方式与提示词记录。
- assets/art/regions.json：图集矩形边界；原图不被裁切改写，运行时选取区域。

角色索引：0 待机、1～3 跑动姿势、4 跳跃、5 下蹲、6 斜上瞄准、7 红甲步兵、8 炮台、9 无人机。
场景索引：0 地面、1 平台、2 反应炉门、3 Boss。

这些源文件是可编辑 PNG 位图及图集描述，并非 Blender 模型或多图层 PSD。
动画为图集姿势切换，尚未覆盖完整逐帧受击、死亡等动作；不宣称达到最终美术验收。

## 本轮动作与战斗源图

- player-motion-source.png：5×4主角动作姿势源图；motion.json记录区域，player-anchors.json记录人工校对枪口；resources/player_pose.tres是运行锚点定义。
- enemy-motion-source.png：4×3敌人状态与残骸源图，运行区域在assets/art/enemy-motion.json。
- combat-fx-source.png：4×3爆炸、烟雾、枪火、命中源图。
- polish-prompts.json：本轮内置image_gen提示词与参考来源。

已额外补入player-transitions-source.png（4×4）：4帧待机、4帧落地、4帧蹲下、4帧起身；资源profile包含36个姿势。transition-prompt.json记录本轮生成提示词。不同源图按同一人物尺度校准，不按每帧边框强制缩放。保留源图继续修绘，不把PNG宣称为PSD/Blender工程。
