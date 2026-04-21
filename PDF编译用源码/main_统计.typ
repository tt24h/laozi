/** 
 * 文件：main_统计.typ
 * 输出：老子道德经：原文译文注释（仅输出统计结果）
 * 引用关系：本文件调用了`数据.txt`，没有被别的文件调用。
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
 * 2. 统计
 * =======================================================
 */

#let _统计结果_ = {
  
  let _章节数_ = _内容解析结果_.len()
  
  let _段落数_ = _内容解析结果_.map(sec => sec.paras).flatten().len()
  
  let _原文总字数_ = _内容解析结果_
    .map(sec => sec.paras.map(para => para.ancient).join("")).join("")
    .codepoints().len()
    
  let _译文总字数_ = _内容解析结果_
    .map(sec => sec.paras.map(para => para.translation).join("")).join("")
    .codepoints().len()

  let _注释总字数_ = _内容解析结果_
    .map(sec => 
      sec.paras
      .map(para => para.numbered.map(line => line.replace("*","",count:2)).join(""))
      .join("")
    ).join("").codepoints().len()

  let _笔记总字数_ = _内容解析结果_
    .map(sec => sec.paras.map(para => para.note.join("")).join("")).join("")
    .codepoints().len()

  let _注释总条数_ = _内容解析结果_
    .map(sec => sec.paras.map(para => para.numbered.len()).sum(default: 0)).sum()

  let _笔记总条数_ = _内容解析结果_
    .map(sec => sec.paras.map(para => if para.note.len() == 0 {0} else {1}).sum()).sum()

  let _总字数_ = _原文总字数_ + _译文总字数_ + _注释总字数_ + _笔记总字数_

  // 原文字频统计

  let _所有字_ = _内容解析结果_
    .map(sec => sec.paras.map(para => para.ancient).join("")).join("")

  let _无重字符数组_ = _所有字_.codepoints().dedup()

  let _未排序字频结果_ = _无重字符数组_.map(char =>
    (
      unicode: char.to-unicode(),
      字: char,
      出现次数: int((_所有字_.len() - _所有字_.replace(char, "").len()) / char.len())
    )
  )

  // 返回值

  (
    章节数: _章节数_,
    段落数: _段落数_,
    原文总字数: _原文总字数_,
    译文总字数: _译文总字数_,
    注释总字数: _注释总字数_,
    笔记总字数: _笔记总字数_,
    注释总条数: _注释总条数_,
    笔记总条数: _笔记总条数_,
    总字数: _总字数_,
    未排序字频结果: _未排序字频结果_
  )
}

 /**
 * =======================================================
 * 3. 打印统计结果
 * =======================================================
 */

#set text(font:"Noto Serif CJK SC")

#set page("a4", numbering: "1")

#set par(spacing: 1em, leading: 1em)

#show heading: it => {
  it
  v(1.2em)
}

#let _章平均字数_ = int(_统计结果_.总字数 / _统计结果_.章节数)
#let _原文段平均字数_ = int(_统计结果_.原文总字数 / _统计结果_.段落数)
#let _译文段平均字数_ = int(_统计结果_.译文总字数 / _统计结果_.段落数)
#let _注释平均字数_ = int(_统计结果_.注释总字数 / _统计结果_.注释总条数)
#let _笔记平均字数_ = int(_统计结果_.笔记总字数 / _统计结果_.笔记总条数)

= 字数段落
#table(
  align: center,
  columns: 6,
  [单位], [章节], [原文],  [译文], [注释], [笔记], 
  [组数], [#_统计结果_.章节数], table.cell(colspan: 2)[#_统计结果_.段落数], 
  [#_统计结果_.注释总条数], [#_统计结果_.笔记总条数],
  
  [字数], [#_统计结果_.总字数], [#_统计结果_.原文总字数], [#_统计结果_.译文总字数],
  [#_统计结果_.注释总字数], [#_统计结果_.笔记总字数],

  [平均字数], [#_章平均字数_], [#_原文段平均字数_], [#_译文段平均字数_],
  [#_注释平均字数_], [#_笔记平均字数_]
)
#v(2em)

= 原文字频统计（出现次数≤5，从少开始）
#v(1em)

#let _5次以内排序后结果_ = {
  _统计结果_.未排序字频结果.sorted(key: x => x.出现次数)
    .filter(x => x.出现次数 <= 5)
}

#table(
  align: horizon + center,
  stroke: none,
  columns:23,
  .._5次以内排序后结果_.map(x => x.字),
  [🥕]
)

= 原文字频统计（出现次数排序）

原文共含 #_统计结果_.未排序字频结果.len() 个不重复字符。
#v(1em)
#columns(2, gutter: 2em, )[

  #let _排序后结果_ = _统计结果_.未排序字频结果.sorted(key: x => x.出现次数).rev()
  
  #for char_info in _排序后结果_ {
    h(4em);box(inset:0pt, width: 3em)[
      U+#str(char_info.unicode, base:16)
    ]
    
    h(3em);box(inset:0pt, width: 1.4em, 
      outset: 0pt,
      stroke: none)[
      #align(center)[#char_info.字]
    ]
    h(3em)
    box(width: 3em)[#align(right, str(char_info.出现次数))]
    
    linebreak()
  }
  #colbreak()
]

#pagebreak()

= 原文字频统计（Unicode 排序）
#columns(2, gutter: 2em, )[

  #let _排序后结果_ = _统计结果_.未排序字频结果.sorted(key: x => x.unicode)
  
  #for char_info in _排序后结果_ {
    h(4em);box(inset:0pt, width: 3em)[
      U+#str(char_info.unicode, base:16)
    ]
    
    h(3em);box(inset:0pt, width: 1.4em, 
      outset: 0pt,
      stroke: none)[
      #align(center)[#char_info.字]
    ]
    h(3em)
    box(width: 3em)[#align(right, str(char_info.出现次数))]
    
    linebreak()
  }
  #colbreak()
]



