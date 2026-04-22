/** 
 * 文件：main.typ
 * 输出：老子道德经：原文译文注释。以 章原文-章译文-章注释和笔记 形式输出。
 * 引用关系：本文件读取了`数据.txt`，没有被别的文件调用。
 */

/**
 * =======================================================
 * 1. 解析 `数据.txt`
 * =======================================================
 */

#let _文档信息解析结果_ = {
  let txt_string = read("数据.txt")
  (
    title: txt_string.find(regex("【标题】\[[^\]]+\]")).trim("【标题】").trim("[").trim("]"),
    author: txt_string.find(regex("【地址】\[[^\]]+\]")).trim("【地址】").trim("[").trim("]"),
    description: txt_string.find(regex("【描述】\[[^\]]+\]")).trim("【描述】").trim("[").trim("]"),
    keywords: txt_string.find(regex("【关键词】\[[^\]]+\]"))
                        .trim("【关键词】").trim("[").trim("]").split("&").map(x => x.trim()),
  )
}

#let _内容解析结果_ = {
  
  let r = ()

  for ln in read("数据.txt").split("\n").map(l => l.trim())  {
    
    if ln == "" or ln.starts-with("//") { continue }

    let sec_ok = r.len() != 0
    let para_ok = sec_ok and r.last().paras.len() != 0

    // 原文
    if ln.starts-with("§") {
      r.push((title: "", sec_ancient: ln.trim("§").trim(), paras: ()))

    // 译文
    } else if ln.starts-with("¶") and sec_ok {
      r.last().paras.push(
        (ancient:"", translation:ln.trim("¶").trim(), numbered:(), note:())
      )

    // 注释
    } else if ln.starts-with("@") and para_ok {
      r.last().paras.last().numbered.push(ln.trim("@").trim())

    // 笔记
    } else if para_ok {
      r.last().paras.last().note.push(ln.trim())

    } else { panic("无法归类：", ln) }
  }

  // 返回值
  r.map(sec => { 

    // 章原文分段
    let ancient_arr = sec.sec_ancient.split("¶").map(x => x.trim())
    
    if ancient_arr.len() - 1 != sec.paras.len() {
      panic("原文与译文段数不对齐：", ancient_arr.first())
    }   

    // 向每段写入原文。
    for (i, _ancient) in ancient_arr.slice(1).enumerate() {
      sec.paras.at(i).ancient = _ancient
    }
    
    sec.title = ancient_arr.first().trim("第")
    return sec
  })
}

/**
 * =======================================================
 * 2. 排版打印
 * =======================================================
 */
 
#set document(
  title: _文档信息解析结果_.title,
  author: _文档信息解析结果_.author ,
  description: _文档信息解析结果_.description,
  keywords: _文档信息解析结果_.keywords
)

#set text(
  font:("Noto Serif CJK SC"),
  size: 12pt,
  weight: 400,
  lang: "zh",
)

#set par(
  spacing:1.1em, 
  leading:1.1em,
)

#set page(
  paper:"a4", 
  margin:(x:2.9cm, y:3.3cm), 
  numbering: "1",
  header: context {
      let curr-page = here().page()
      
      let headings = query(heading.where(level: 1))
      let on-page = headings.filter(h => h.location().page() == curr-page)
      
      if on-page.len() > 0 {
        return none
      }
      
      let before = headings.filter(h => h.location().page() < curr-page)
      if before.len() > 0 {
        align(center, text("（" + before.last().body + "）", 0.8em))
      }
    }
)

#set math.frac(style: "skewed")

#show math.equation: set text(font: "STIX Two Math")

#show raw: set text(font: "Noto Serif CJK SC", weight: 400)

#show strong: set text(font: "Noto Sans CJK SC", weight: 0) // 100 + delta = 300

#show heading: it => {
  set block(sticky: true)
  align(center, text(font: "Noto Sans CJK SC", weight: 400, it))
  v(2em)
}
#show <part> : it => {
  parbreak();pad(y:0.4em, it);parbreak()
}



/* 封面页 ::::::::::::::: */
#[
  #set page(margin: (x:3cm, y:0cm))
  #pad(top:3.3cm, bottom:4cm, grid(
    align: bottom, rows:(72pt,4cm,1fr), columns: 1fr,
    [#text("老子道德经", size:72pt, font:"Noto Serif CJK SC")],
    [#h(0.4cm);#text("原文、译文、注释", size:36pt, font:"Noto Sans CJK SC")],
    [#align(center, text(link("https://github.com/tt24h/laozi"), size:14pt))]
  ))
]
#pagebreak()


/* 说明页 ::::::::::::::: */
#[
  #set par(justify: true)
  
  = #text([说明], tracking: 0.2em)

  #h(2em);本文原文部分来自《老子道德经：四种原文表》中的各表首行文本。各表首行文本校订自王弼本、帛书本、郭简本及北大本，优先选用古早版本的文本，例外少。\
  
  #h(2em);使用王弼本分章方案，配有译文注释和笔记。注释以文义理解为主，不包含大量字典释义。在本文仓库内有：字典与字典工具的介绍文档，本文的 Markdown 版，生成本 PDF 文件的 Typst 格式源码。\
  
  #h(2em);*注意*：仅在编写期间，笔者对文义的理解就经历了多次转变，不排除以后还会推翻文中的观点。故本文仅供参考。\
  
  #table(
    columns: 2, stroke: none, inset: (x:2em, y:0.65em),
    [本文], [#h(-3em)→#h(1em);https://github.com/tt24h/laozi],
    [老子道德经：四种原文表], [#h(-3em)→#h(1em);https://github.com/tt24h/daodejing]
  )
  #h(2em);本文内容使用 CC0 1.0 协议发布。
]
#pagebreak()



/* 正文页 ::::::::::::::: */
#for (i, sec) in _内容解析结果_.enumerate(start: 1) {
    
  // 章标题
  [ = #sec.title ] 

  [【原文】<part>]

  let processed_ancient = sec.paras
      .map(para => "#h(2em)" + para.ancient).join("#parbreak()")
  // 原文
  {
    set text(weight: 500, size:1.1em)
    eval(processed_ancient, mode: "markup")
  }

  [【译文】<part>]

  let processed_translation = sec.paras
      .map(para => "#h(2em)" + para.translation).join("#parbreak()")

  // 译文
  eval(processed_translation, mode: "markup")

  let has_anno = (
    sec.paras.map(para => para.numbered.len()).sum(),
    sec.paras.map(para => para.note.len()).sum(),
  ).sum() != 0
  
  if has_anno {
    [【注释】<part>]
  } else {
    if i != 81 { pagebreak() }
    continue
  }

  for (i, para) in sec.paras.enumerate(start: 1) {

    let order = box($frac(#str(i), #str(sec.paras.len()))$, width: 1em, inset: 0pt)

    let processed_ancient = (
      "#h(1em)",
      para.ancient,
      "#parbreak()"
    ).join("")

    underline(
      stroke: 0.6pt,
      background: true,
      evade: false,
      offset: 0.3em,
      
      // 原文（【注释】中的）
      order + eval(processed_ancient, mode: "markup")
    )
    
    parbreak()

    if para.numbered.len() != 0 {
      
      let processed_numbered = para.numbered.map(
        line => "#h(2em)" + line.replace("：", "#box(width:1em, [：])", count: 1)
      ).join("#parbreak()") + "#parbreak()"

      // 注释
      eval(processed_numbered, mode: "markup")
    }

    if para.note.len() != 0 {
      set text(fill: olive)
      let processed_note = para.note.map(
        line => "#h(2em)" + line
      ).join("#parbreak()") + "#parbreak()"

      // 笔记
      eval(processed_note, mode: "markup")
    }
    
  }
  if i != 81 { pagebreak() }
}      
#align(right, [（完）])