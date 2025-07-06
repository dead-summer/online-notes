#import "@preview/shiroa:0.2.0": get-page-width, target, is-web-target, is-pdf-target, plain-text, templates
#import templates: *

#import "math-macros.typ": *

// 元数据和目标检测
#let page-width = get-page-width()
#let is-pdf-target = is-pdf-target()
#let is-web-target = is-web-target()

// ==========================================
// 内置主题颜色配置
// ==========================================

// 主题检测函数 (可以根据需要修改检测逻辑)
#let detect-theme() = {
  // 默认使用 light 主题，可以根据需要修改为 dark
  // 也可以添加其他检测逻辑，比如基于系统设置或用户选择
  "light"
}

// Light 主题颜色
#let light-theme = (
  main-color: rgb("#333333"),        // 主文本颜色
  dash-color: rgb("#2563eb"),        // 链接和强调色
  bg-color: rgb("#ffffff"),          // 背景色
  code-bg: rgb("#f8f9fa"),          // 代码块背景
  code-fg: rgb("#24292f"),          // 代码文本
  border-color: rgb("#e1e4e8"),     // 边框颜色
  muted-color: rgb("#6f7681"),      // 次要文本颜色
)

// Dark 主题颜色
#let dark-theme = (
  main-color: rgb("#e6edf3"),        // 主文本颜色
  dash-color: rgb("#58a6ff"),        // 链接和强调色
  bg-color: rgb("#0d1117"),          // 背景色
  code-bg: rgb("#161b22"),          // 代码块背景
  code-fg: rgb("#e6edf3"),          // 代码文本
  border-color: rgb("#30363d"),     // 边框颜色
  muted-color: rgb("#8b949e"),      // 次要文本颜色
)

// 获取当前主题
#let current-theme-name = detect-theme()
#let current-theme = if current-theme-name == "dark" { dark-theme } else { light-theme }

// 主题变量
#let is-dark-theme = current-theme-name == "dark"
#let is-light-theme = current-theme-name == "light"
#let main-color = current-theme.main-color
#let dash-color = current-theme.dash-color
#let bg-color = current-theme.bg-color

// 代码主题配置
#let code-extra-colors = (
  bg: current-theme.code-bg,
  fg: current-theme.code-fg,
)


// ==========================================
// 字体配置
// ==========================================

#let default-font = (
  main: "IBM Plex Serif",
  mono: "IBM Plex Mono",
  cjk: "Noto Serif CJK SC",
  emph-cjk: "KaiTi",
  math: "New Computer Modern Math",
  math-cjk: "Noto Serif CJK SC",
)

#let code-font = ((name: default-font.mono, covers: "latin-in-cjk"), default-font.cjk)

// 尺寸配置
#let main-size = if is-web-target { 16pt } else { 12.5pt }
#let heading-sizes = (34pt, 30pt, 22pt, 20pt, main-size)
#let list-indent = 0.5em


// 标题哈希函数 (如果需要)
#let heading-hash(it, hash-color: dash-color) = {
  // 简单的标题哈希实现
  [#text(fill: hash-color)[\#] #it.body]
}

// ==========================================
// 主项目函数
// ==========================================

#let project(title: "Typst Notes", authors: (), kind: "page", body) = {
  
  // ==========================================
  // 通用设置部分
  // ==========================================
  
  // 基本文档元数据
  set document(
    author: authors,
    title: title,
  ) if not is-pdf-target

  // 字体设置
  set text(
    font: ((name: default-font.main, covers: "latin-in-cjk"), default-font.cjk),
    size: main-size,
    fill: main-color,
    lang: "en",
  )
  show emph: text.with(font: ((name: default-font.main, covers: "latin-in-cjk"), default-font.emph-cjk))
  show raw: set text(font: code-font)
  show math.equation: it => {
    set text(font: default-font.math)
    show regex("\p{script=Han}"): set text(font: default-font.math-cjk)
    it
  }
  // 修复引号
  show smartquote: set text(font: default-font.main)

  // 列表和段落基础设置
  set enum(
    indent: list-indent * 0.618,
    body-indent: list-indent,
  )
  set list(
    indent: list-indent * 0.618,
    body-indent: list-indent,
  )
  set par(leading: 0.7em)
  set block(spacing: 0.7em * 1.5)

  // 链接设置
  show link: set text(fill: dash-color)

  // 数学设置
  show math.equation: set text(weight: 400)
  set math.equation(numbering: (..nums) => {
    let h = counter(heading).get().first()
    numbering("(1.1)", h, ..nums)
  })
  // 有 label 时才编号
  show math.equation.where(block: true): it => {
    if not it.has("label") {
      let fields = it.fields()
      let _ = fields.remove("body")
      fields.numbering = none
      [#counter(math.equation).update(v => v - 1)#math.equation(..fields, it.body)<math-equation-without-label>]
    } else {
      it
    }
  }
  // 设置定理层级
  set-inherited-levels(1)
  
  set-qed-symbol[#math.qed]
  show: show-theorem


  // 引用设置
  // 未找到 label 时仍能编译
  show ref: it => {
    if it.element == none {
      return text(fill: red, "<" + str(it.target) + ">")
    }
    it
  }

  // ==========================================
  // Web Target 特定设置
  // ==========================================
  
  // Web 页面布局
  set page(
    width: page-width,
    margin: (
      // reserved beautiful top margin
      top: 20pt,
      // reserved for our heading style.
      // If you apply a different heading style, you may remove it.
      left: 20pt,
      // Typst is setting the page's bottom to the baseline of the last line of text. So bad :(.
      bottom: 0.5em,
      // remove rest margins.
      rest: 0pt,
    ),
    height: auto,
    fill: bg-color,  // 添加背景色
  ) if is-web-target

  // Web 标题样式
  show heading: set text(weight: "regular") if is-web-target
  
  // ==========================================
  // PDF Target 特定设置
  // ==========================================
  
  // PDF 标题编号
  set heading(numbering: "1.1") if is-pdf-target
  show heading.where(
    level: 1,
  ): it => if is-pdf-target {
    if it.numbering != none {
      block(width: 100%)[
        #line(length: 100%, stroke: 0.6pt + dash-color)
        #v(0.1cm)
        #set align(left)
        #set text(heading-sizes.at(it.level))
        #text(dash-color)[Chapter
        #counter(heading).display(
          "1:" + it.numbering
        )]

        #it.body
        #v(-0.5cm)
        #line(length: 100%, stroke: 0.6pt + dash-color)
      ]
    }
    else {
      block(width: 100%)[
        #line(length: 100%, stroke: 0.6pt + dash-color)
        #v(0.1cm)
        #set align(left)
        #set text(heading-sizes.at(it.level))
        #it.body
        #v(-0.5cm)
        #line(length: 100%, stroke: 0.6pt + dash-color)
      ]
    }
  } else {
    it
  }

  // ==========================================
  // 标题显示规则 (通用但根据目标调整)
  // ==========================================
  
  show heading: it => {
    let it = {
      set text(size: heading-sizes.at(it.level))
      if is-web-target {
        heading-hash(it, hash-color: dash-color)
      } else {
        it
      }
    }

    block(
      spacing: 0.7em * 1.5 * 1.2,
      below: 0.7em * 1.2,
      it,
    )
  }
  show heading.where(level: 1): it => {
      pagebreak(to: "odd", weak: true)
    it
  }

  // ==========================================
  // 代码块渲染 (根据目标和主题设置)
  // ==========================================

  // 代码块显示规则
  show raw: it => {
    if "block" in it.fields() and it.block {
      rect(
        width: 100%,
        inset: (x: 4pt, y: 5pt),
        radius: 2pt,
        stroke: 0.5pt + current-theme.border-color,
        fill: code-extra-colors.at("bg"),
        [
          #set text(font: code-font)
          #set text(fill: code-extra-colors.at("fg")) if code-extra-colors.at("fg") != none
          #set par(justify: false)
          #it
        ],
      )
    } else {
      box(
        fill: code-extra-colors.at("bg"),
        inset: (x: 2pt, y: 1pt),
        radius: 2pt,
        [
          #set text(
            font: code-font,
            baseline: -0.08em,
            fill: code-extra-colors.at("fg"),
          )
          #it
        ]
      )
    }
  }

  // ==========================================
  // 最终内容渲染
  // ==========================================
  
  // 主内容段落对齐
  set par(justify: true)

  body

}
