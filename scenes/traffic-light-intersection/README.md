# 十字路口交通灯实训

这个 OIP 教学项目包含十字路口道路、车道线、四组红黄绿灯和简化车辆。车辆运动与灯色由 OIP 内置 IEC PLC 仿真逻辑联动。

## 打开和运行

1. 下载或克隆本仓库。
2. 在 OIP 中打开 `scenes/traffic-light-intersection/` 项目文件夹。
3. 按 **F5** 开始仿真。

## 控制周期

南北绿灯 8 秒 → 南北黄灯 2 秒 → 全红 1 秒 → 东西绿灯 8 秒 → 东西黄灯 2 秒 → 全红 1 秒，然后循环。南北与东西绿灯互锁；换向前经过全红间隔。车辆仅在对应方向绿灯时沿直线滑台运动，红灯或黄灯时停止。

PLC 输出变量：`NS_Red`、`NS_Yellow`、`NS_Green`、`EW_Red`、`EW_Yellow`、`EW_Green`。`Conflict` 用于诊断南北和东西是否同时处于绿灯。

## 文件和验证边界

- `parts/training.traffic-intersection/manifest.json`：道路、路缘、人行横道、信号灯杆和车辆的程序化 3D 几何。
- `parts/training.traffic-intersection/behavior.js`：信号灯与车辆的仿真行为。
- `plc/TrafficLight.st`：IEC Structured Text 控制逻辑。
- `tests/phase-sequence.test.json`：相位顺序回归测试。
- `part-library/`：可在 OIP“获取零件 → 添加库”中使用的独立模型包。

本场景的 11 项自动检查通过，且曾在 OIP 内置仿真中运行。它没有连接 TIA Portal、S7-PLCSIM 或真实 PLC；车辆是简化运动学滑台，不含碰撞驾驶、转弯和行人相位，也不是道路安全控制器。

## OIP 部件库导入

添加以下库地址即可单独导入十字路口模型：

`https://raw.githubusercontent.com/UserLIJUN0727/oip-industrial-parts/main/scenes/traffic-light-intersection/part-library/index.json`

库中模型 ID：`userlijun0727.traffic-intersection`。

## 许可

本目录中的原始场景、PLC 逻辑、程序化几何和教学说明采用 MIT 许可证。此许可不改变仓库根目录下既有四个模型的许可状态。
