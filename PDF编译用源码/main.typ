/** 
 * 文件：main.typ
 * 输出：老子道德经：原文译文注释。
 * 引用关系：本文件读取了`数据.txt`，没有被别的文件调用。
 */

/**
 * =======================================================
 * 1. 解析 `数据.txt`
 * =======================================================
 */

#let _解析字段_(content, tag) = {
  
  let pattern = regex("【" + tag + "】\[[^\]]+\]")
  let match = content.find(pattern)
  
  if match == none { panic("未在`数据.txt`找到：【" + tag + "】") }
  
  match.trim("【" + tag + "】").trim("[").trim("]")
}

#let _文档信息解析结果_ = {
  
  let txt_string = read("数据.txt")
  
  (
    title: _解析字段_(txt_string, "标题"),
    author: _解析字段_(txt_string, "地址"),
    description: _解析字段_(txt_string, "描述"),
    keywords: _解析字段_(txt_string, "关键词").split("&").map(x => x.trim()),
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
  spacing:1.3em, 
  leading:1.3em,
)

#let logic-page = counter("logic-page")
#let cycle-string = state("cycle-string", "第1遍")

#let extract-text(it) = {
  if type(it) == str { it }
  else if it.has("text") { it.text }
  else if it.has("body") { extract-text(it.body) }
  else if it.has("children") { it.children.map(extract-text).join() }
  else { "" }
}

#set page(
  paper:"a4", 
  margin:(x:2.9cm, y:3.3cm), 
  numbering: "1",
  header: context {

      let last_section = none
      let curr-page = here().page()  
      let headings = query(heading.where(level: 2))
      let on-page = headings.filter(h => h.location().page() == curr-page)
      
      if on-page.len() > 0 {
        last_section = none
      } else {
        
        let before = headings.filter(h => h.location().page() < curr-page)

        if before.len() > 0 {
          let target = before.last()
          last_section = extract-text(target.body)
        }
      }
      
      let cur-logic = logic-page.get().at(0)
      let cur-abs = counter(page).get().at(0)

      grid(
        inset:0pt,
        align:(left,center, right),
        columns:(0.5fr,1fr, 0.5fr),
        [#cycle-string.get()],
        [#if last_section != none{[（ #last_section ）]}else{"老子道德经：原文译文注释"}],
        [#cur-logic;],
      )
      move(dy:-0.5em,line(length:100%, stroke:0.5pt))
    },

    background: context {
      logic-page.step()
      none
    },
)

#set strong(delta: 200)
#set math.frac(style: "skewed")

#show raw: set text(font:"Noto Sans CJK SC")
#show math.equation: set text(font: "STIX Two Math")

#show heading: it => {
  set block(sticky: true)
  align(center, text(font: "Noto Sans CJK SC", weight: 400, it))
  v(2em)
}

#show heading.where(level:1): set text(size:40pt)


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
  
  == #text([说明])

  #h(2em);本文原文部分来自《老子道德经：四种原文表》中的各表首行文本。各表首行文本校订自王弼本、帛书本、郭简本及北大本，优先选用古早版本的文本，例外少。\
  
  #h(2em);使用王弼本分章方案，配有译文注释和笔记。注释以文义理解为主，不包含大量字典释义。在本文仓库内有：字典与字典工具的介绍文档，本文的 Markdown 版，生成本 PDF 文件的 Typst 格式源码。\

  #h(2em);本文包含两遍81章：第1遍，整章原文置于章首，其后罗列该章各段译文及其注释。第2遍，章内各段原文后紧跟其译文及注释。点击章标题，可在两种排版之间跳转。
  
  #h(2em);*注意*：仅在编写期间，笔者对文义的理解就经历了多次转变，不排除以后还会推翻文中的观点。本文仅供参考。\
  
  #table(
    columns: 2, stroke: none, inset: (x:2em, y:0.65em),
    [本文 仓库], [#h(-3em)→#h(1em);https://github.com/tt24h/laozi],
    [本文 在线版], [#h(-3em)→#h(1em);https://tt24h.github.io/laozi/],
    [老子道德经：四种原文表], [#h(-3em)→#h(1em);https://github.com/tt24h/daodejing]
  )
  #h(2em);本文内容使用 CC0 1.0 协议发布。
]
#pagebreak()



#let main = [ // 这样，两种标题互相建立连接不会有 找不到标签的冲突。

  /* 正文页 第1遍，章内原文在章首 ::::::::::::::: */
  
  #[
  #set page(margin:(y:-100pt))
  #v(1fr)
  #[= #link(label("v2"), "第1遍") #label("v1")]
  #v(1fr)
  ]
  #pagebreak()
  
  #for (i, sec) in _内容解析结果_.enumerate(start: 1) {
      
    // 章标题
    let this_v1 = label("v1|"+str(i))
    let dest_v2 = label("v2|"+str(i))
    
    [#link(dest_v2,[== #sec.title #this_v1])]
     
    let x_ancient = sec.paras
        .map(para => "#h(2em)" + para.ancient).join("#parbreak()")
        
    {
      set text(weight: 500, size:1.1em)
  
      // 原文
      eval(x_ancient, mode: "markup")
      parbreak()
    }
    
    v(2em)
  
    for (i, para) in sec.paras.enumerate(start: 1) {
  
      pad(
        left: 0.2em,
        {
          let order = box($frac(#str(i), #str(sec.paras.len()))$, width: 1em, inset: 0pt)
  
          // 译文
          order + eval("#h(1em)"+para.translation+"#parbreak()", mode: "markup")
          parbreak()
          
          if para.numbered.len() != 0 {
        
            let x_numbered = para.numbered.map(l => "#h(2em)" + l).join("#parbreak()")
            
            // 注释
            v(0.6em)
            eval(x_numbered, mode: "markup")
            parbreak()
            v(0.6em)
            
          }
  
          if para.note.len() != 0 {
            
            set text(fill: olive)
            let x_note = para.note.map(l => "#h(2em)"+l).join("#parbreak()")
      
            // 笔记
            if para.numbered.len() == 0 {v(0.6em)}
            eval(x_note, mode: "markup")
            parbreak()
            v(0.6em) 
            
          }
        }
      )    
    }
    pagebreak()
  }
  
  /* 正文页 第2遍，各段原文后紧跟译文等 ::::::::::::::: */
  
  #[
    #set page(margin:(y:-100pt))
    #v(1fr)
    #[= #link(label("v1"), "第2遍") #label("v2")]
    #v(1fr)
    #cycle-string.update("第2遍")
    #logic-page.update(1)
  ]
  #pagebreak()
  
  
  #for (i, sec) in _内容解析结果_.enumerate(start: 1) {
      
    // 章标题
    let dest_v1 = label("v1|" + str(i))
    let this_v2 = label("v2|" + str(i))
    
    [== #link(dest_v1)[#text(font:"Crimson Pro","chapter-" + str(i))] #this_v2]
  
    for (i, para) in sec.paras.enumerate(start: 1) {
  
      {
        set text(font:"Noto Sans CJK SC", size: 1.1em, weight: 400);
    
        // 原文
        [ #eval(para.ancient, mode: "markup") ]  
      }
      
      pad(left:1.2em, y:1em,{
        
        set par(justify: true)
        
        // 译文
        [ #eval(para.translation, mode: "markup"); #parbreak()]
             
        // 注释
        if para.numbered.len() != 0 {
          v(1em)
          for item in para.numbered {
            let processed = item.replace("：", "#box(width:1em, [：])", count: 1)
            [ + #eval(processed, mode: "markup") ]
          }
        }
  
        // 笔记
        if para.note.len() != 0 {
          v(1em)
          set text(fill: olive)
          for item in para.note {
            let processed = "#h(2em)" + item + "#linebreak()"
            [ #eval(processed, mode: "markup") ] 
          }
        }
        
      })  // end ← 译文等段 
    }     // end ← 段处理
    if i != 81 { pagebreak() }
  }       // end ← 章处理
  #align(right, [（完）])
]

#main





