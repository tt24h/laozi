## 文件夹内文件说明：

1. `从「数据.txt」还原原文.html`：
	* 提取「数据.txt」中的原文，用于和《老子道德经：四种原文表》中“校订文”核对。

2. `工作流_更新 HTML 版和 Markdown 版.js`：
	* 解析「数据.txt」数据，生成 Html 版 和 Markdown 文本。
	* `.github/workflows/自动同步 HTML 和 Markdown 版.yml`调用此文件。
3. `工作流_index 模板.html`
	* `工作流_更新 HTML 版和 Markdown 版.js`调用此文件，将此文件的内容当作大字符串，替换其中的内容，用于产生 `./index.html`。
4. `carrot-192.png` 和 `carrot-512.png`：
	* Github Pages 实现PWA，需要给定的两个图片。
	* 写在：`./manifest.json`（实现）和`./index.html`（作为网页图标） 。

## 与 PWA 有关的文件：
1. `./index.html`。 -- 网站主页，在这个文件的<head></head>内，写着`manifest.json`引用和`Service Worker 注册脚本`。
2. `./manifest.json`。 -- 配置 PWA。
3. `./sw.js`。-- PWA要执行的操作。
4. `carrot-192.png` 和 `carrot-512.png` 。-- PWA在桌面的图标、欢迎界面的图标。