#import "@preview/shiroa:0.2.0": *

#import "/templates/ebook.typ"


#show: ebook.project.with(
  title: "Math Analysis",
  authors: ("Summer",),
  display-title: "数学分析",
  spec: "./book.typ",
  // set a resolver for inclusion
  styles: (
    inc: it => {
      include it
      },
  ),
)