/** 
 * 文件：main_仅原文.typ
 * 输出：老子道德经：原文译文注释（仅输出原文部分）
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
  title: _文档信息解析结果_.title + "（仅原文）",
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
  spacing:1.2em, 
  leading:1.2em,
  justify: true,
  first-line-indent: (amount:2em, all:true)
)

#set page(
  paper:"a4", 
  margin:(x:2.9cm, y:3.4cm), 
  numbering: "1",
  header: [
    #set text(0.8em )
    #grid(
      columns: (1fr, 1fr),
      [#_文档信息解析结果_.title （原文部分）],
      align(right)[#_文档信息解析结果_.author]
    )
    #line(length: 100%, stroke: 0.5pt + gray) // 页眉横线
  ],
)

/* 正文页 ::::::::::::::: */
#for (i, sec) in _内容解析结果_.enumerate(start: 1) {

  let sec_title = [（#str(i);章）]
  v(1em, weak: true)
  sec.paras.map(para => para.ancient).join("") + sec_title + parbreak()
  v(1em)
}       // end ← 章处理
#align(right, [（完）])