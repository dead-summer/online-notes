# Typst Notes 项目 - 使用指南

基于 [shiroa](https://github.com/Myriad-Dreamin/shiroa) 构建的多笔记本在线文档系统。

## 📋 功能特性

- 🔗 **统一书架页面**: 美观的首页展示所有笔记本
- 📚 **多笔记本支持**: 每个课程独立的 Typst 笔记本
- 🔄 **自动构建**: 一键构建所有笔记本
- 🌐 **本地预览**: 内置开发服务器

## 🚀 快速开始

### 1. 环境准备

```bash
# 安装 shiroa
cargo install shiroa --locked

# 克隆项目
# git clone 
```


### 2. 创建笔记本

为每个课程创建 `book.typ` 文件：

```typst
// notes/math-analysis/book.typ
#import "@preview/shiroa:0.3.0": *

#show: book.with(
  title: "数学分析笔记",
  authors: ("Your Name",),
  language: "zh",
  summary: [
    = 前言
    = 第一章
    - #chapter("chapter1.typ")[函数与极限]
    = 第二章  
    - #chapter("chapter2.typ")[连续性]
  ]
)

```

### 3. 构建项目

```bash
# 使用 Python 脚本构建 (推荐)
python build.py build
```

### 4. 预览结果

```bash
# 启动本地服务器
python build.py serve
```

在浏览器中访问 http://localhost:8000

## 📁 项目结构详解

```
your-typst-notes/
├── index.html               # 书架首页
├── build.py                 # 构建脚本
├── static/                  # 静态资源
├── notes/                   # 所有笔记
│   ├── math-analysis/       # 数学分析笔记
│   │   ├── book.typ        # 笔记本配置
│   │   ├── chapter1.typ    # 章节内容
│   │   └── chapter2.typ
│   ├── linear-algebra/      # 线性代数笔记
│   └── physics/             # 物理学笔记
└── build/                   # 构建输出
    ├── index.html          # 书架首页
    ├── math-analysis/      # 各个笔记本的 HTML
    ├── linear-algebra/
    └── physics/
```

## ⚙️ 配置说明


### 自定义书架页面

编辑 `index.html` 中的 `notebooks` 数组来添加新的笔记本：

```javascript
const notebooks = [
    {
        title: "新课程",
        description: "课程描述",
        icon: "📖",
        path: "new-course",
        status: "进行中",
        lastModified: "2025-01-15"
    }
];
```


## 🔧 构建脚本说明

```bash
# 构建所有笔记本
python build.py build

# 构建并启动本地服务器
python build.py serve

# 清理构建目录
python build.py clean

# 指定自定义 BASE_URL（用于测试子路径部署）
python build.py build --base-url /my-repo/
```


## 📄 许可证

本项目采用 MIT 许可证，详见 LICENSE 文件。
