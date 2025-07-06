#import "@preview/shiroa:0.2.0": *
#show: book


#book-meta(
  title: "Math Analysis",
  summary: [
    - #chapter("./chapter1/1 test.typ", section: "1")[First Chapter]
    - #chapter("./chapter2/2 测试.typ", section: "2")[Second Chapter]
  ]
)

// re-export page template
#import "/templates/page.typ": *
#let book-page = project