/*
 * 【作用】 根据 `数据.txt` 更新 `index.md`。
 * 【调用】 此文件由 `./.github/workflows/同步Markdown.yml` 调用。
 */

const fs = require('fs');
const path = require('path');

// --- 路径配置 ---
const SOURCE_PATH     = path.join(process.cwd(), 'PDF编译用源码', '数据.txt');
const TARGET_MD       = path.join(process.cwd(), 'index.md');

        // --- 1. 解析内容结构 ---
        function parseRawData(text) {
            let result = [];
            const lines = text.split('\n').map(l => l.trim()).map(l => l.replaceAll('|', '\\|'));

            for (let ln of lines) {
                if (ln === "" || ln.startsWith("//")) continue;

                let sec_ok = result.length !== 0;
                let para_ok = sec_ok && result[result.length - 1].paras.length !== 0;

                if (ln.startsWith("§")) {
                    result.push({ title: "", sec_ancient: ln.replace(/^§/, '').trim(), paras: [] });
                } else if (ln.startsWith("¶") && sec_ok) {
                    result[result.length - 1].paras.push({ ancient: "", translation: ln.replace(/^¶/, '').trim(), numbered: [], note: [] });
                } else if (ln.startsWith("@") && para_ok) {
                    result[result.length - 1].paras[result[result.length - 1].paras.length - 1].numbered.push(ln.trim());
                } else if (para_ok) {
                    result[result.length - 1].paras[result[result.length - 1].paras.length - 1].note.push(ln);
                } else {
                    throw new Error(`解析错误：该行无法归入任何章节或段落 -> ${ln}`);
                }
            }

            return result.map(sec => {
                let ancient_arr = sec.sec_ancient.split("¶").map(x => x.trim());
                if (ancient_arr.length - 1 !== sec.paras.length) throw new Error(`段数不对齐 -> ${ancient_arr[0]}`);
                ancient_arr.slice(1).forEach((_ancient, i) => { sec.paras[i].ancient = _ancient; });
                sec.title = ancient_arr[0].trim().replace(/^第/, '');
                return sec;
            });
        }

        // --- 2. 解析元信息 ---
        function extractDocInfo(text) {
            const getMeta = (key) => {
                const match = text.match(new RegExp(`【${key}】\\[([^\\]]+)\\]`));
                return match ? match[1].trim() : "";
            };
            return {
                title: getMeta("标题"),
                author: getMeta("地址"),
                description: getMeta("描述")
            };
        }


        // --- 拼装文档信息 ---
        function getCommonMetaText(docInfo) {

            return `标题：${docInfo.title}
描述：${docInfo.description}
仓库地址：${docInfo.author}
使用协议：CC0 1.0

* 本文的 Markdown 版、PDF 版的数据源：\`./PDF编译用源码/数据.txt\`
* 仓库内有字典工具的介绍、《老子道德经：四种原文表》等。`;
        }

        // --- 3. 生成 Markdown 代码 ---
        function renderMarkdown(sections, docInfo) {

            const github_pages_css = `---
layout: default
---`;

            const title = `\n老子道德经：原文译文注释\n======\n`
            
            let header = github_pages_css + 
                         title + `\`\`\`less
${getCommonMetaText(docInfo)}\n\`\`\`

&nbsp;

本文包含两遍81章：

* 第1遍：整章原文置于章首，其后罗列该章各段译文及其注释。
* 第2遍：章内各段原文后紧跟其译文及注释。
* 点击章标题，可在两种排版之间跳转。

&nbsp;

`;
            
            // 第1遍， 章内原文在章首
            let body = '## [第1遍](#第2遍)\n\n&nbsp;\n\n';

            body += sections.map((sec, s) => {

                let md = `### [${sec.title}](#chapter-${s + 1})\n\n&nbsp;\n\n`;

                md += sec.paras.map(p => p.ancient).join('\n\n') + "\n\n&nbsp;\n\n";

                sec.paras.forEach((p, i) => {

                    const index = i + 1;
                    const isLastPara = (i === sec.paras.length - 1)

                    md += `${index}. ${p.translation}\n`;

                    if (p.numbered.length) {

                        const isEndOfSection = isLastPara && p.note.length === 0;

                        md += '\n' + p.numbered.map(anno => {

                            const  cleanAnno = anno.replace('*', '').replace('*', '').replace('@', '');
                            return `    - ${cleanAnno}`

                        }).join('\n') + (isEndOfSection ? '\n' : '\n\n');

                    };

                    if (p.note.length) {

                        md += (p.numbered.length ? '' : '\n') +
                               p.note.map(line => `    > ${line}`).join("\n    >\n") +
                              (isLastPara ? '\n' : '\n\n');
                    };
                });

                return md;
            }).map(x => x.trim('\n')).join('\n\n&nbsp;\n\n');


            // 第2遍， 各段原文后紧跟译文等
            body += '\n\n&nbsp;\n\n## [第2遍](#第1遍)\n\n&nbsp;\n\n';

            body += sections.map((sec, s) => {

                let md = `### [chapter-${s + 1}](#${sec.title})\n\n&nbsp;\n\n`;

                sec.paras.forEach((p, i) => {

                    const isLastPara = (i === sec.paras.length - 1);
                    
                    md += `${p.ancient}\n\n\`\`\`less\n${p.translation}\n`;

                    const numbered_str = p.numbered.map(item => item.replace('@', '•').replace('*', '').replace('*', '')).join('\n');

                    if (p.numbered.length) md += `\n${numbered_str}\n`;
                    
                    if (p.note.length) md += `\nnote:\n${p.note.map(n => `　　${n}`).join('\n')}\n`;
                    
                    md += `\`\`\``;
                    md += isLastPara ? `` : `\n\n`;
                });

                return md;
            }).map(x => x.trim('\n')).join('\n\n&nbsp;\n\n');

            return header + body;
        }


// --- 4. 执行主流程 ---
try {
    const rawData = fs.readFileSync(SOURCE_PATH, 'utf8');
    const sections = parseRawData(rawData);
    const docInfo = extractDocInfo(rawData);

    fs.writeFileSync(TARGET_MD, renderMarkdown(sections, docInfo), 'utf8');
    console.log('✅ Markdown 更新成功');

} catch (err) {
    console.error('❌ 执行失败:', err.message);
    process.exit(1);
}