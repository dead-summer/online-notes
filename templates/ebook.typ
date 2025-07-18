#import "@preview/shiroa:0.2.0": *
#import "page.typ": project, dash-color

#let _page-project = project

/// Show a title page with a full page background
#let cover(title, display-title, authors: ()) = {
  
  let authors-text = if authors.len() > 0 {
    authors.join(" ")
  } else {
    "Unknown"
  }

  stack(
    1fr,
    align(
      center + horizon,
      block(
        width: 100%,
        fill: dash-color.lighten(70%),
        height: 6.2cm,
        pad(x: 2cm, y: 1cm)[
          #text(size: 3em, weight: 900, title)
          // #text(size: 3em, weight: 900, [The Raindrop-Blue Book])
          #v(1cm, weak: true)
          // #text(size: 3em, project-meta.at("subtitle", default: none))
          #text(size: 2em, display-title)
          #v(1cm, weak: true)
          #text(size: 1em, weight: "bold", authors-text)
        ],
      ),
    ),
    2fr,
  )
}

#let p = counter("book-part")
#let p-num = numbering.with("1")
#let default-styles = (
  cover: cover,
  part: it => {
    page(
      margin: 0cm,
      header: none,
      {
        p.step()
        stack(
          1fr,
          align(
            right + bottom,
            block(
              width: 100%,
              fill: dash-color.lighten(70%),
              height: 6.2cm,
              pad(x: 1cm, y: 1cm)[
                #set text(size: 32pt)
                #v(1em)
                #context {
                  let loc = here()
                  heading([Part.#p-num(..p.at(loc))#sym.space] + it)
                }
              ],
            ),
          ),
          2fr,
        )
      },
    )
  },
  chapter: it => {
    it
  }, 
)


#let project(title: "", display-title: none, authors: (), spec: "", content, styles: default-styles) = {
  let display-title = display-title
  if display-title == none {
    display-title = title
  }

  // inherit styles
  let styles = default-styles + styles

  // set document metadata early
  set document(
    author: authors,
    title: title,
  )

  // set web/pdf page properties
  set page(numbering: "1")

  {
    // inherit from page setting
    show: _page-project.with(title: none, kind: none)

    //set image(width: 100%, height: 100%)
    set page(
      margin: 0cm,
      header: none,
    )

    // place book meta
    external-book(spec: (styles.inc)(spec))
    (styles.cover)(title, display-title, authors: authors)
    pagebreak(to: "odd")
  }

  context {
    let project-meta = (title: title, display-title: display-title, book: book-meta-state.final(), styles: styles)

    {
      // inherit from page setting
      show: _page-project.with(title: none, kind: none)

      // set web/pdf page properties
      set page(numbering: "I")
      counter(page).update(1)


      let outline-numbering-base = numbering.with("1.")
      let outline-numbering(a0, ..args) = if a0 > 0 {
        h(1em * args.pos().len())
        outline-numbering-base(a0, ..args) + [ ]
      }

      let outline-counter = counter("outline-counter")
      show outline.entry: it => {
        let has-part = if it.body().func() != none and "children" in it.body().fields() {
          for ch in it.body().children {
            if "text" in ch.fields() and ch.text.contains("Part") {
              ch.text
            }
          }
        }

        let numbering = if has-part == none {
          outline-counter.step(level: it.level + 1)
          context outline-counter.display(outline-numbering)
        } else {
          outline-counter.step(level: 1)
        }
        link(it.element.location(), text(black, it.indented(numbering + it.prefix(), it.inner())))
      }


      set outline.entry(fill: repeat[.])
      outline(depth: 3)
      pagebreak(to: "odd")
    }

    set page(numbering: "1")
      counter(page).update(1)


    if project-meta.book != none {
      project-meta.book.summary.map(it => visit-summary(it, styles)).sum()
    }
  }

  

  content
}



// #show: project.with(
//   title: "typst-online-notes",
//   authors: ("Summer",),
//   display-title: "Typst在线笔记",
//   spec: "/book.typ",
//   // set a resolver for inclusion
//   styles: (
//     inc: it => {
//       include it
//       },
//   ),
// )


