#import "@preview/shiroa:0.2.0": *

#import "/templates/ebook.typ"


#show: ebook.project.with(
  title: "Linear Algebra",
  authors: ("Summer",),
  display-title: "线性代数",
  spec: "./book.typ",
  // set a resolver for inclusion
  styles: (
    inc: it => {
      include it
      },
  ),
)