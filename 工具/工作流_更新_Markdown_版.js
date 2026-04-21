/*
 * 【作用】 根据 `数据.txt` 更新 `老子道德经：原文译文注释.md`。
 * 【调用】 此文件由 `./.github/workflows/更新 Markdown 版.yml` 调用。
 */

const fs = require('fs');
const path = require('path');

// --- 1. 路径配置 ---
const SOURCE_PATH     = path.join(process.cwd(), 'PDF编译用源码', '数据.txt');
const TARGET_MD       = path.join(process.cwd(), '老子道德经：原文译文注释.md');

// --- 2. 解析内容结构 ---
function parseRawData(text) {
    let result = [];
    const lines = text.split('\n').map(l => l.trim());

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

// --- 解析元信息 ---
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

* 本文的 Markdown版、PDF版的数据源：\`./PDF编译用源码/数据.txt\`
* 本文件由 Github Actions 自动生成。`;
}

// --- 3. 渲染逻辑 (MD) ---
function renderMarkdown(sections, docInfo) {
    
    let header = `\`\`\`less\n${getCommonMetaText(docInfo)}\n\`\`\`\n\n&nbsp;\n\n`;
    let body = sections.map(sec => {
        let md = `### ${sec.title}\n\n&nbsp;\n\n`;
        sec.paras.forEach(p => {
            md += `${p.ancient}\n\n\`\`\`less\n${p.translation}\n`;
            if (p.numbered.length) md += `\n${p.numbered.join('\n')}\n`;
            if (p.note.length) md += `\nnote:\n${p.note.map(n => `　　${n}`).join('\n')}\n`;
            md += `\`\`\`\n\n`;
        });
        return md;
    }).join('\n&nbsp;\n\n');

    return header + body;
}


// --- 4. 执行主流程 ---
try {
    const rawData = fs.readFileSync(SOURCE_PATH, 'utf8');
    const sections = parseRawData(rawData);
    const docInfo = extractDocInfo(rawData);

    fs.writeFileSync(TARGET_MD, renderMarkdown(sections, docInfo), 'utf8');
    console.log('✅ Markdown 更新成功，HTML 渲染已弃用');

} catch (err) {
    console.error('❌ 执行失败:', err.message);
    process.exit(1);
}