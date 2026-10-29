# 前端组件架构

> **历史文档（2026-10-30）**：ES/Scout、HarmonyOS、Angular/React 前端，以及报修、投诉、访客、合同、财务、社区活动、能耗、消息通知、审批、投票、催缴、集团、问答、巡检、商城、人脸、大屏等模块已移除。当前功能与架构以 README.md / docs/ 目录为准。


## Flutter Web 组件树

```mermaid
flowchart TD
    app["AdminApp(GetMaterialApp)"]

    app --> login["/login<br/>LoginPage"]
    app --> dashboard["/dashboard<br/>AdminLayout"]

    login --> form["登录表单<br/>用户名+密码"]
    login --> captcha["点击验证码组件<br/>GestureDetector+Stack<br/>Image.memory(base64)<br/>点击标记Circle"]

    dashboard --> sidebar["侧边栏NavigationDrawer<br/>可折叠64px/240px<br/>仪表盘/用户/角色/配置/日志"]
    dashboard --> header["顶栏56px<br/>折叠按钮+用户菜单<br/>退出确认AlertDialog"]
    dashboard --> content["内容区"]

    content --> stats["统计卡片GridView×4"]
    content --> chart["趋势折线图LineChart"]
    content --> pie["分布饼图PieChart"]
    content --> logs["最近操作ListTile×8"]

    style app fill:#1677FF,color:#fff
    style captcha fill:#FA8C16,color:#fff
    style sidebar fill:#722ED1,color:#fff
```
