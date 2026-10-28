# Kaffelogic Studio Native (macOS)

专为 macOS 设计的全新现代原生 **Kaffelogic Nano 7 / Nucleus Link** 咖啡烘焙曲线管理与监控软件。

采用 **Swift 6 + SwiftUI + AppKit** 纯原生重构，告别老旧的 Python 2.7 / wxPython 框架，具备极致流畅的视觉与操作体验。

---

## 🌟 核心特性

- **现代 macOS 原生设计**：完美适配深色/浅色模式、系统毛玻璃半透明材质、纯正简体中文化。
- **高刷曲线画布**：120Hz ProMotion 级 Canvas 渲染，三次贝塞尔曲线拟合、升温速率 (RoR) 滑动求导。
- **专业热能分析**：
  - 烘焙四阶段（脱水、梅纳德、一爆、发展期）自动识别与发展时间占比 (DTR %)；
  - 曲线下面积 (AUC) 累积热能积分计算器 (`⌘U`)；
  - 烘焙阶段时间解算器 (`⌥⌘U`)；
  - 曲线线性变换与拉伸 (`⌘T`)。
- **杀手级配方反推**：从实测烘焙记录中一键提取实际豆温为新配方方案 (`⌘E` Make Profile)。
- **机器即插即连**：自动识别树莓派 RP2040 (USB-CDC) 串口直连与局域网 WiFi 通信，插上自动连、拔掉自动断。
- **双向格式兼容**：原生读写官方标准 `.kpro` / `.klog` 及 Nucleus `.npro` / `.nlog` 文件。
- **极致轻量**：整包体积仅约 1 MB（原版 88 MB），0.1 秒秒开。

---

## 🛠️ 构建与编译

环境要求：macOS 14.0+，Xcode 15+ / Swift 5.9+。

```bash
# 1. 克隆仓库
git clone https://github.com/<your-username>/KaffelogicStudioNative.git
cd KaffelogicStudioNative

# 2. 一键编译并生成 DMG 安装包
./make_single_dmg.sh
```
