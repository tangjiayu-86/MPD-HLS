<div align="center">

# MPD2HLS

**MPD/DASH → HLS 转换服务 · 一键安装 · 自动管理**

![Platform](https://img.shields.io/badge/平台-Linux%20x86__64%20%7C%20aarch64%20%7C%20armv7-blue)
![License](https://img.shields.io/badge/许可-MIT-green)
[![Telegram](https://img.shields.io/badge/TG交流群-@GPT__858-26A5E4?logo=telegram)](https://t.me/GPT_858)

</div>


![image.png](https://img.111451444.xyz/files/QWdBREZ3Y0FBbThMR0VROgAzodnW-XKJmhFdhfhC7traxIErDTau3D7kH6g6Ogxw.png)
![image.png](https://img.111451444.xyz/files/QWdBRDV3WUFBaVVfR0VROnhDrm2M3NAY7nK1sIj80G1hyKkveFhna7ng-b7Ur0or.png)
![image.png](https://img.111451444.xyz/files/QWdBRGNBY0FBckNuR1VROpnF2jNRQgiZD67VUUybwI9Sg49TKaxHmPWT4rgdDzd6.png)
![image.png](https://img.111451444.xyz/files/QWdBRGJnY0FBckNuR1VROk9gapnpudyymkSl6vaPOH3HNPemWxKsOYoSOjcgX47T.png)
![image.png](https://img.111451444.xyz/files/QWdBREdBY0FBbThMR0VROnHXIHS2Ma1ArSt67xv8539Fij600jfOLWe8G7od14_z.png)
![image.png](https://img.111451444.xyz/files/QWdBREdnY0FBbThMR0VROrCuANfwaPuxxj5ZCeAuZg2a8kJw2Pa2jIFzPJE-OUIC.png)
![image.png](https://img.111451444.xyz/files/QWdBRDZBWUFBaVVfR0VROpwMIqCgzqAPDoPiVXlQ1wTEE8LWUH31cEU9CdeZSPuF.png)
![image.png](https://img.111451444.xyz/files/QWdBRGJ3Y0FBckNuR1VROo_dV1vLs97uYEM4Omftwo2T8CYNSIbHFiT_opgzB0bF.png)
![image.png](https://img.111451444.xyz/files/QWdBREdRY0FBbThMR0VROqN18wGaNaHGm8HwK_5dSIQuiRsI0Gw-kwZQljJpDFES.png)
![image.png](https://img.111451444.xyz/files/QWdBRDZRWUFBaVVfR0VROmIPgo4J5b_T2q2RQqBXw6F0GuAZU9XxIqh9GJtZ-FQ_.png)


---

## 快速安装

```bash
bash <(curl -sL https://github.com/judy-gotv/MPD-HLS/raw/main/install.sh)
```

安装完成后，输入以下命令打开管理面板：

```bash
mpd2hls
```

---

## 默认信息

| 项目 | 值 |
|---|---|
| 面板端口 | `9527` |
| 管理路径 | `/admin` |
| 默认账号 | `admin` |
| 默认密码 | `admin123` |
| 安装目录 | `/opt/mpd2hls` |
| 服务文件 | `/etc/systemd/system/mpd2hls.service` |
| 管理命令 | `/usr/local/bin/mpd2hls` |

> 安装完成后请立即修改默认密码。

---

## 安装过程示例

```
╔╦╗╔═╗╔╦╗  ┌─┐  ╦ ╦╦  ╔═╗
║║║╠═╝ ║║  ╚═╗  ╠═╣║  ╚═╗
╩ ╩╩  ═╩╝  └─┘  ╩ ╩╩═╝╚═╝

MPD/DASH → HLS 转换服务

──────────────────────────────────────────────────────

面板端口  （默认 9527，回车使用默认值）
端口 › 8080

────────────────────────────
  架构    x86_64
  端口    8080
  目录    /opt/mpd2hls
────────────────────────────

确认以上配置，按回车开始安装...

  →  创建安装目录...
  ✔  目录就绪：/opt/mpd2hls
  →  正在下载程序...
████████████████████ 100%
  ✔  程序下载完成
  →  配置 systemd 服务...
  ✔  服务文件写入完成
  →  启动服务...

┌─────────────────────────────────────┐
│         ✓   安 装 成 功 ！          │
└─────────────────────────────────────┘

  访问地址
  ▶  http://1.2.3.4:8080/admin

  默认账号  admin
  默认密码  admin123  ← 登录后请立即修改！
```

---

## 管理面板

执行 `mpd2hls` 进入管理面板：

```
╔╦╗╔═╗╔╦╗  ┌─┐  ╦ ╦╦  ╔═╗
║║║╠═╝ ║║  ╚═╗  ╠═╣║  ╚═╗
╩ ╩╩  ═╩╝  └─┘  ╩ ╩╩═╝╚═╝

──────────────────────────────────────────────────────
  状态   ● 运行中  |  版本 0.2.x  |  架构 x86_64
  地址   http://1.2.3.4:9527/admin
──────────────────────────────────────────────────────

    1  安装程序
    2  重启服务
    3  停止服务
    4  启动服务
    5  查看日志
    6  更新程序
    7  卸载程序
    0  退出

──────────────────────────────────────────────────────
  输入选项 ›
```

---

## 功能说明

### 1 · 安装程序

全新安装流程：

1. 检测系统架构（x86_64 / aarch64 / armv7l）
2. 输入面板端口（默认 `9527`）
3. 自动下载对应架构的二进制文件
4. 配置并启动 `systemd` 服务
5. 安装 `mpd2hls` 管理命令

### 2 · 重启服务

```bash
systemctl restart mpd2hls.service
```

### 3 · 停止服务

```bash
systemctl stop mpd2hls.service
```

### 4 · 启动服务

```bash
systemctl start mpd2hls.service
```

### 5 · 查看日志

实时滚动日志，按 `Ctrl+C` 退出：

```bash
journalctl -u mpd2hls.service -f
```

### 6 · 更新程序

1. 停止当前服务
2. 下载最新二进制文件
3. 同步更新管理脚本
4. 重新启动服务

### 7 · 卸载程序

输入 `yes` 二次确认后，删除以下全部内容：

| 路径 | 说明 |
|---|---|
| `/etc/systemd/system/mpd2hls.service` | systemd 服务文件 |
| `/opt/mpd2hls` | 程序目录（含所有配置与数据） |
| `/usr/local/bin/mpd2hls` | 管理命令 |

> **注意**：卸载会删除 `/opt/mpd2hls` 目录下的所有数据，执行前请备份重要配置。

---

## 常用命令

```bash
# 打开管理面板
mpd2hls

# 查看服务状态
systemctl status mpd2hls.service --no-pager -l

# 启动 / 停止 / 重启
systemctl start   mpd2hls.service
systemctl stop    mpd2hls.service
systemctl restart mpd2hls.service

# 开机自启 / 取消自启
systemctl enable  mpd2hls.service
systemctl disable mpd2hls.service

# 实时日志
journalctl -u mpd2hls.service -f

# 查看最近 100 行日志
journalctl -u mpd2hls.service -n 100 --no-pager
```

---

## 访问地址

安装完成后通过浏览器访问：

```
http://服务器IP:端口/admin
```

例如使用默认端口 `9527`：

```
http://1.2.3.4:9527/admin
```

---

## 支持的系统架构

| 架构 | 二进制文件 | 适用设备 |
|---|---|---|
| `x86_64` | `mpd2hls` | 标准服务器 / VPS |
| `aarch64` | `mpd2hls-aarch64` | ARM64 服务器 / 树莓派 4 |
| `armv7l` | `mpd2hls-armv7` | 32位 ARM 设备 / 树莓派 3 |

---

## 目录结构

```
/opt/mpd2hls/
└── mpd2hls              # 主程序

/etc/systemd/system/
└── mpd2hls.service      # 系统服务文件

/usr/local/bin/
└── mpd2hls              # 管理命令（指向安装脚本）
```

---

## 排查问题

**面板无法访问？**

```bash
# 1. 检查服务状态
systemctl status mpd2hls.service --no-pager -l

# 2. 查看错误日志
journalctl -u mpd2hls.service -n 100 --no-pager

# 3. 确认端口监听
ss -lntp | grep 9527

# 4. 检查防火墙
# 云服务器还需在安全组中放行对应 TCP 端口
```

**服务无法启动？**

```bash
# 重启后查看详细日志
systemctl restart mpd2hls.service
journalctl -u mpd2hls.service -n 50 --no-pager
```

**端口被占用？**

```bash
# 查看端口占用情况
ss -lntp | grep 9527
```

重新安装时选择一个未占用的端口即可。

---

## 注意事项

1. 需要在支持 `systemd` 的 Linux 系统上运行（Debian 8+ / Ubuntu 16.04+ / CentOS 7+）
2. 需要 root 权限执行
3. 安装前确保服务器网络正常，可访问 GitHub
4. 安装前确认所选端口未被占用
5. 卸载将永久删除 `/opt/mpd2hls` 目录，请提前备份数据
6. 如使用云服务器，需在安全组中放行面板端口（TCP）

---

<div align="center">

作者：**Go-iptv**　·　TG 交流群：[t.me/GPT_858](https://t.me/GPT_858)

</div>
