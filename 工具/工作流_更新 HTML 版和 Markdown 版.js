/*
 * 【作用】 根据 `数据.txt` 更新 `index.html` 和 `老子道德经：原文译文注释.md`。
 * 【调用】 此文件由 `./.github/workflows/更新 Markdown 版.yml` 调用。
 */
const fs = require('fs');
const path = require('path');

// --- 1. 路径配置 ---
const SOURCE_PATH     = path.join(process.cwd(), 'PDF编译用源码', '数据.txt');
const TEMPLATE_PATH   = path.join(process.cwd(), '工具', '工作流_index 模板.html');
const TARGET_MD       = path.join(process.cwd(), '老子道德经：原文译文注释.md');
const TARGET_HTML     = path.join(process.cwd(), 'index.html');

// --- 2. 核心解析逻辑 ---
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

function getCommonMetaText(docInfo) {
    return `标题：${docInfo.title}
描述：${docInfo.description}
仓库地址：${docInfo.author}
使用协议：CC0 1.0

* 本文的HTML版、Markdown版、PDF版的数据源：\`./PDF编译用源码/数据.txt\`
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

// --- 4. 渲染逻辑 (HTML) ---
function renderHTML(sections, docInfo, template) {

    const metaText = getCommonMetaText(docInfo);

    const optionsHtml = Array.from({ length: 81 }, (_, i) => 
        `<option value="chap${i + 1}">chap${i + 1}</option>`
    ).join('\n');

    const contentHtml = sections.map((sec, index) => {

        const chapterId = `chap${index + 1}`;

        const parasHtml = sec.paras.map(p => {
            let detail = p.translation;
            if (p.numbered.length) detail += `\n\n${p.numbered.join('\n')}`;
            if (p.note.length) detail += `\n\nnote:\n${p.note.map(n => `　　${n}`).join('\n')}`;
            return `\n<section>\n\t<p class="ancient">${p.ancient}</p>\n\t<pre>\n${detail}</pre>\n</section>\n`;
        }).join('');
        return `<article>\n<h3 id="${chapterId}">${sec.title}</h3>\n${parasHtml}\n</article>\n<!--==================================================-->`;
    }).join('\n');

    return template
        .replace('{{DOC_TITLE}}', docInfo.title)
        .replace('{{DOC_META}}', metaText)
        .replace('{{DOC_CONTENT}}', contentHtml)
        .replace('{{REPO_URL}}', docInfo.author)
        .replace('{{CHAPTER_OPTIONS}}', optionsHtml);
}

// --- 5. 执行主流程 ---
try {
    const rawData = fs.readFileSync(SOURCE_PATH, 'utf8');
    const sections = parseRawData(rawData);
    const docInfo = extractDocInfo(rawData);

    // 写入 MD
    fs.writeFileSync(TARGET_MD, renderMarkdown(sections, docInfo), 'utf8');
    console.log('✅ Markdown 更新成功');

    // 写入 HTML
    if (fs.existsSync(TEMPLATE_PATH)) {
        const template = fs.readFileSync(TEMPLATE_PATH, 'utf8');
        fs.writeFileSync(TARGET_HTML, renderHTML(sections, docInfo, template), 'utf8');
        console.log('✅ HTML 网页更新成功');
    }

} catch (err) {
    console.error('❌ 执行失败:', err.message);
    process.exit(1);
}