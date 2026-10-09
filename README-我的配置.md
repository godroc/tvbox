# OK影视独立配置与维护说明

## 已检查的仓库
- Fork：https://github.com/godroc/tvbox
- 默认分支：master；上游：qist/tvbox。
- 检查版本：14c12ddb39dc81d5b48f62ecfffa3641ca69e3fa（2026-10-09）。
- 根目录已有 jsm.json、js.json 等；脚本/依赖位于 jar、lib、js、py；另有 live、json、cat、FTY、XBPQ、XYQBiu、XYQHiker、biliext、tools、xiaosa。
- jsm.json 包含 153 个站点、3 个直播项；顶层 spider/lives/parses/hosts/flags/doh/rules/ads 等保持原值。
- 上游两个“苹果”站点重名。新配置仅将第二个 key 改为 苹果-upstream-2，保留其内容。
- 本包是覆盖到原仓库的增量文件，不是完整仓库，也不能单独托管使用。

## 文件用途
- my-tv.json：OK影视实际加载的完整配置，放在仓库根目录。
- custom/sites.json：自有站点对象数组，已加入 my_yangshipin（央视频 • 测试）。同 key 覆盖上游；新 key 追加到末尾。
- custom/exclude-sites.json：不想显示的上游站点 key 数组，初始为 []。
- custom/py、custom/js：自有脚本目录，以 .gitkeep 保留空目录。
- custom/build-config.ps1：从当前 jsm.json + 自有清单重新生成 my-tv.json，不改 jsm.json。校验相对引用和 JAR MD5；失败时不写新配置。

## 上传和使用
1. 将本包中的 my-tv.json 与整个 custom 目录加入 fork 的 master 根目录。
2. 首次上传不要替换原有文件；核对新增文件后提交。
3. 上传成功后，在 OK影视 TV 的点播配置中填写：
   https://raw.githubusercontent.com/godroc/tvbox/master/my-tv.json
   该地址用于读取 master 分支中的独立配置。
4. 先加载配置，再分别测试 JS、JAR、Python 站点的首页/搜索/详情/播放，以及直播线路。网络、地区和电视版本均可能影响结果。
5. jsm.json 不需要添加引用；OK影视直接加载 my-tv.json。此文件是完整单接口配置，不是多仓入口。

## 路径和兼容性
所有配置中的 ./ 都以根目录 my-tv.json 所在位置为基准，不以 custom/sites.json 为基准：
- JAR：spider 保留 ./jar/spider.jar 及其 MD5；csp_* 站点依赖该 JAR 提供对应类。
- drpy JS 规则：type=3、api=./lib/drpy2.min.js、ext=./custom/js/你的规则.js。
  当前 js/drpy.js 是 var rule 规则文件。不能把任何 JS 文件直接当作 api；
  drpy-node、ES module、CatVodOpen 等脚本不能凭扩展名视作兼容。
- Python：type=3、api=./custom/py/你的脚本.py。
  当前上游示例 py/ITalkBBTV.py 使用 from base.spider import Spider，并定义 Spider 类，依赖 requests。
  新脚本也应检查客户端提供的 Python 环境、依赖及首页/分类/详情/搜索/播放方法。
  普通命令行 Python 脚本不能直接作为站点。
- 搬移脚本前检查 import、require、读文件操作等内部路径；配置路径正确不等于脚本内部路径正确。
- 中文文件名可以保留，但字母大小写须与 GitHub 完全一致。Windows 检出已有两组大小写冲突：
  cat/js/AppYsV2.js 与 cat/js/appysv2.js；js/LIBVIO.js 与 js/libvio.js。此次新增文件不涉及它们。
- 不将 Cookie、网盘 token 等写入这个公开仓库；保留上游的电视本机凭据路径。

## 自有清单示例（仅说明格式，不默认启用）
确认脚本已上传且兼容后，才将对应对象加入 custom/sites.json：

Python：
{"key":"my_python","name":"我的Python站点","type":3,"api":"./custom/py/你的脚本.py","searchable":1,"quickSearch":1,"filterable":1}

drpy JS：
{"key":"my_drpy","name":"我的JS站点","type":3,"api":"./lib/drpy2.min.js","ext":"./custom/js/你的规则.js","searchable":1,"quickSearch":1,"filterable":1}

这些是占位示例，不是已验证可用的站点。请根据脚本实际能力调整 searchable/quickSearch/filterable。
custom/sites.json 是维护用输入，不会被 OK影视自动合并；每次修改后必须重新生成 my-tv.json。

## 后续更新
1. 在 GitHub fork 的 Sync fork 同步上游。不要强制丢弃自己的提交。
2. 将同步后的完整仓库拉到电脑，在仓库根目录执行：
   powershell -ExecutionPolicy Bypass -File custom/build-config.ps1
   使用 Windows PowerShell 5.1 或 PowerShell 7。生成器不联网、不执行站点脚本。
3. 核对 my-tv.json 的差异，再提交生成文件。电视刷新配置。
4. 同步 jsm.json 不会自动更新 my-tv.json。自有覆盖会持续生效，因此同 key 的自有对象要自行检查上游兼容变化。
5. 本次不增加定时任务。仓库已有 .github/workflows/run.yml 会生成/覆盖 jsm.json；它没有负责重建 my-tv.json。启用继承的 Actions 前应先检查用途。

## 本次验证与限制
- my-tv.json 能解析，站点 key 唯一，154 个站点；自有清单包含央视频测试站点。
- 对完整配置递归检查 ./ 引用，全部文件存在；spider.jar MD5 与原配置一致。
- 在本地克隆中执行生成器成功，jsm.json 与检出版本一致。
- 央视频脚本已通过 Python 语法与 Spider 方法静态检查；未实测电视播放。

## 本地维护位置与央视频测试
- 完整本地仓库：D:\git\Tvbox。
- 自有脚本：custom/py/yangshipin.py；配置 api 为 ./custom/py/yangshipin.py。
- 在点播站点选择“央视频 • 测试”，先测试“央视频道”的 CCTV-1，再测试“央视高码”。
- 脚本使用标准库，播放依赖 OK影视提供 Python 本地代理与 getProxyUrl 功能。
