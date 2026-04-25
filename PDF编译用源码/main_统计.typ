/** 
 * 文件：main_统计.typ
 * 输出：老子道德经：原文译文注释（仅输出统计结果）
 * 引用关系：本文件读取了`数据.txt`，没有被别的文件调用。
 */

#let 查询原文文本 = "

输入待查询的原文文本。

"

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
 * 2. 统计
 * =======================================================
 */

#let _查询原文文本_(text) = {
  let r = ()
  
  text = text.trim()
  for sec in _内容解析结果_ {
    for para in sec.paras {
      if text in para.ancient {
        r.push((sec.title, para.ancient.replace(text, "《《"+text+ "》》")))
      }
    }
  }
  return r
}

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

#set page(
  "a4", 
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
      align(center, text(before.last().body, 0.8em))
    }
  }
)

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

= 查询原文文本

#if _查询原文文本_(查询原文文本).len() == 0 {
  [没有找到【#查询原文文本.trim()】]
} else {
  
  show regex("《《[^》]+》》"): it => {
    set text(fill:red)
    it.text.trim("《《").trim("》》")
  }
  
  table(
    columns: 2,
    stroke: 0.4pt,
    .._查询原文文本_(查询原文文本).flatten()
  )
}

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

#let _排序后结果_ = _统计结果_.未排序字频结果.sorted(key: x => x.出现次数).rev()

#let _用于表格_ =  for (i, char_info) in _排序后结果_.enumerate(start: 1) {
  (
    str(i), 
    str(char_info.unicode, base:16),
    str(char_info.字),
    str(char_info.出现次数)
  )
}
#table(
  align: horizon + center,
  columns: (3em, 4em, 5em, 3em),
  stroke: none,
  .._用于表格_.flatten()
)
#pagebreak()

= 原文字频统计（Unicode 排序）

#let _排序后结果_ = _统计结果_.未排序字频结果.sorted(key: x => x.unicode)

#let _用于表格_ =  for (i, char_info) in _排序后结果_.enumerate(start: 1) {
  (
    str(i), 
    str(char_info.unicode, base:16),
    str(char_info.字),
    str(char_info.出现次数)
  )
}
#table(
  columns: (3em, 4em,5em, 3em),
  stroke: none,
  .._用于表格_.flatten()
)