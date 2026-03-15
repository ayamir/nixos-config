#!/usr/bin/env python3
"""
ime-switch.py — KDE Wayland + Fcitx5 自动输入法切换器
监听 KWin 窗口焦点变化，按 app 规则自动切换 / 记忆输入法状态

依赖：python3-dbus, python3-gi, fcitx5-remote
"""

import subprocess
import sys
import json
import os
import signal
import logging
from pathlib import Path

try:
    import dbus
    import dbus.service
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib
    DBusGMainLoop(set_as_default=True)
except ImportError:
    print("错误：缺少依赖。请安装 python3-dbus 和 python3-gi")
    print("NixOS: 在 environment.systemPackages 中添加 python3Packages.dbus-python python3Packages.pygobject3")
    sys.exit(1)

# ─── 配置文件路径 ──────────────────────────────────────────────
CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "ime-switcher"
CONFIG_FILE = CONFIG_DIR / "rules.json"
LOG_FILE = CONFIG_DIR / "ime-switcher.log"
KWIN_SCRIPT_FILE = CONFIG_DIR / "kwin-ime-switcher.js"

# ─── DBus 服务名 ───────────────────────────────────────────────
DBUS_SERVICE = "org.imeswitcher.Daemon"
DBUS_PATH = "/org/imeswitcher/Daemon"
DBUS_IFACE = "org.imeswitcher.Daemon"
KWIN_SCRIPT_NAME = "ime-switcher"

# ─── KWin 脚本（在 KWin 进程内运行）──────────────────────────
KWIN_SCRIPT = f"""\
callDBus("{DBUS_SERVICE}", "{DBUS_PATH}", "{DBUS_IFACE}", "onWindowActivated", "__script_loaded__");
workspace.windowActivated.connect(function(window) {{
    var cls = (window && window.resourceClass) ? window.resourceClass : "";
    callDBus(
        "{DBUS_SERVICE}",
        "{DBUS_PATH}",
        "{DBUS_IFACE}",
        "onWindowActivated",
        cls
    );
}});
"""

# ─── 日志 ─────────────────────────────────────────────────────
CONFIG_DIR.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout),
    ]
)
log = logging.getLogger("ime-switch")

# ─── 默认配置 ──────────────────────────────────────────────────
DEFAULT_CONFIG = {
    "rules": {
        "org.kde.konsole":       "keyboard-us",
        "kitty":                 "keyboard-us",
        "alacritty":             "keyboard-us",
        "code":                  "keyboard-us",
        "code-url-handler":      "keyboard-us",
        "firefox":               "",
        "chromium-browser":      "",
        "google-chrome":         "",
        "org.telegram.desktop":  "",
        "obsidian":              "",
    },
    "default_im": "",
    "remember_state": True,
}


def load_config() -> dict:
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE) as f:
                cfg = json.load(f)
                log.info(f"已加载配置: {CONFIG_FILE}")
                return cfg
        except Exception as e:
            log.warning(f"配置读取失败，使用默认配置: {e}")
    else:
        save_config(DEFAULT_CONFIG)
        log.info(f"已生成默认配置: {CONFIG_FILE}")
    return DEFAULT_CONFIG


def save_config(cfg: dict):
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    with open(CONFIG_FILE, "w") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)


# ─── Fcitx5 控制 ──────────────────────────────────────────────

def get_current_im() -> str:
    """查询 fcitx5 当前激活的输入法名称"""
    try:
        result = subprocess.run(
            ["fcitx5-remote", "-n"],
            capture_output=True, text=True, timeout=2
        )
        return result.stdout.strip()
    except Exception:
        return ""


def set_im(im_name: str) -> bool:
    """切换到指定输入法，返回是否成功"""
    if not im_name:
        return False
    try:
        subprocess.run(["fcitx5-remote", "-s", im_name], timeout=2, check=True)
        return True
    except Exception as e:
        log.warning(f"切换输入法失败 ({im_name!r}): {e}")
        return False


def list_ims() -> list[str]:
    """通过 DBus 获取当前输入法组的所有输入法"""
    try:
        bus = dbus.SessionBus()
        fcitx_obj = bus.get_object("org.fcitx.Fcitx5", "/controller")
        fcitx = dbus.Interface(fcitx_obj, "org.fcitx.Fcitx.Controller1")
        group_name = str(fcitx.CurrentInputMethodGroup())
        result = fcitx.InputMethodGroupInfo(group_name)
        return [str(item[0]) for item in result[1]]
    except Exception:
        return []


# ─── DBus 服务（接收 KWin 脚本回调）──────────────────────────

class IMESwitcherService(dbus.service.Object):
    def __init__(self, bus, switcher):
        bus_name = dbus.service.BusName(DBUS_SERVICE, bus)
        super().__init__(bus_name, DBUS_PATH)
        self.switcher = switcher

    @dbus.service.method(DBUS_IFACE, in_signature='s', out_signature='')
    def onWindowActivated(self, resource_class: str):
        self.switcher.on_window_changed(str(resource_class))


# ─── 主切换器逻辑 ─────────────────────────────────────────────

class IMESwitcher:
    def __init__(self):
        self.config = load_config()

        # im_memory: app_class -> 该 app 上次确认使用的输入法
        # 只通过 _remember() 写入，保证准确性
        self.im_memory: dict[str, str] = {}

        # 当前焦点窗口的 app class（空字符串代表启动时无记录）
        self.current_app: str = ""

        # 记录最近一次由我们主动 set_im() 设置的值，
        # 用于在轮询时排除「自己触发的变化」，避免误判为用户手动切换
        self._last_set_im: str | None = None

        self.session_bus = None
        self._service = None

        log.info("═══════════════════════════════════════")
        log.info("  IME Switcher 启动")
        log.info(f"  配置文件: {CONFIG_FILE}")
        available = list_ims()
        log.info(f"  可用输入法: {', '.join(available) or '(无法获取)'}")
        log.info("═══════════════════════════════════════")

    # ── 内部：写入记忆 ───────────────────────────────────────────
    def _remember(self, app: str, im: str):
        """记录 app 当前使用的输入法"""
        if not app or not im:
            return
        old = self.im_memory.get(app)
        if old != im:
            self.im_memory[app] = im
            log.info(f"  [记忆] {app!r}: {old!r} → {im!r}")
        else:
            log.debug(f"  [记忆] {app!r}: 无变化 ({im!r})")

    # ── 内部：切换并同步记忆 ─────────────────────────────────────
    def _switch_and_remember(self, app: str, im: str, reason: str):
        """
        切换输入法，成功后立即更新记忆。
        这是保证「记忆 == 实际」的唯一出口。
        """
        log.info(f"  [切换] {reason} → {im!r}")
        self._last_set_im = im  # 告知轮询：接下来的这次变化是我们触发的
        if set_im(im):
            self._remember(app, im)
        else:
            self._last_set_im = None  # 切换失败，撤销豁免
            log.warning(f"  [切换失败] 无法切换到 {im!r}")

    # ── 查找规则 ─────────────────────────────────────────────────
    def _get_rule(self, app_class: str):
        """
        返回值：
          str (非空) → 强制切换到该输入法
          ""         → 记忆模式
          None       → 未匹配任何规则
        """
        rules = self.config.get("rules", {})
        for pattern, im in rules.items():
            if app_class == pattern.lower() or app_class.startswith(pattern.lower()):
                return im
        return None

    # ── 核心：窗口切换事件处理 ───────────────────────────────────
    def on_window_changed(self, new_app: str):
        new_app = new_app.lower().strip()

        if new_app == "__script_loaded__":
            log.info("KWin 脚本连接成功")
            return

        if new_app == self.current_app:
            return

        old_app = self.current_app
        log.info(f"─── 窗口切换: {old_app!r} → {new_app!r} ───")

        # ── Step 1: 离开旧窗口 ──────────────────────────────────────
        #
        # 不在此处读取 fcitx5 当前输入法：窗口切换时 fcitx5 已对新窗口
        # 自动切换，此时读到的是新窗口的值，而非旧窗口用户最后的选择。
        # 轮询定时器（_poll_im）负责实时追踪用户手动切换，memory 中的值
        # 始终是准确的，无需在离开时重复读取。

        # ── Step 2: 更新当前 app ────────────────────────────────
        self.current_app = new_app

        # ── Step 3: 为新窗口应用规则或恢复记忆 ─────────────────
        rule = self._get_rule(new_app)

        if rule is not None and rule != "":
            # 命中强制规则
            self._switch_and_remember(new_app, rule, f"强制规则 {new_app!r}")

        elif rule == "":
            # 命中记忆模式规则
            remembered = self.im_memory.get(new_app)
            if remembered:
                self._switch_and_remember(new_app, remembered, f"记忆恢复 {new_app!r}")
            else:
                # 首次进入该 app，以当前输入法作为初始记忆
                current = get_current_im()
                log.info(f"  [记忆模式] {new_app!r} 首次出现，初始化记忆为 {current!r}")
                if current:
                    self._remember(new_app, current)

        else:
            # rule is None：未匹配任何规则
            default_im = self.config.get("default_im", "")
            if default_im:
                self._switch_and_remember(new_app, default_im, f"默认输入法 {new_app!r}")
            elif self.config.get("remember_state", True):
                remembered = self.im_memory.get(new_app)
                if remembered:
                    self._switch_and_remember(new_app, remembered, f"未匹配规则，记忆恢复 {new_app!r}")
                else:
                    current = get_current_im()
                    log.info(f"  [未匹配规则] {new_app!r} 首次出现，初始化记忆为 {current!r}")
                    if current:
                        self._remember(new_app, current)
            else:
                log.info("  [未匹配规则] 记忆功能关闭，保持当前输入法")

    # ── KWin 脚本管理 ────────────────────────────────────────
    def load_kwin_script(self):
        KWIN_SCRIPT_FILE.write_text(KWIN_SCRIPT)
        try:
            scripting_obj = self.session_bus.get_object("org.kde.KWin", "/Scripting")
            scripting = dbus.Interface(scripting_obj, "org.kde.kwin.Scripting")
            try:
                scripting.unloadScript(KWIN_SCRIPT_NAME)
                log.debug("已卸载旧 KWin 脚本")
            except Exception:
                pass
            script_id = scripting.loadScript(str(KWIN_SCRIPT_FILE), KWIN_SCRIPT_NAME, signature='ss')
            scripting.start()
            log.info(f"KWin 脚本已加载并启动 (ID: {script_id})")
        except Exception as e:
            log.error(f"KWin 脚本加载失败: {e}")
            sys.exit(1)

    def unload_kwin_script(self):
        if not self.session_bus:
            return
        try:
            scripting_obj = self.session_bus.get_object("org.kde.KWin", "/Scripting")
            scripting = dbus.Interface(scripting_obj, "org.kde.kwin.Scripting")
            scripting.unloadScript(KWIN_SCRIPT_NAME)
            log.debug("KWin 脚本已卸载")
        except Exception:
            pass

    # ── fcitx5 手动切换：轮询检测 ────────────────────────────────
    #
    # fcitx5 的 Controller1 D-Bus 接口只暴露方法，没有 IM 切换信号。
    # 因此只能用定时轮询 `fcitx5-remote -n` 来感知用户手动切换。
    # 间隔 500ms，几乎无感知，CPU 占用可忽略不计。

    POLL_INTERVAL_MS = 500  # 轮询间隔（毫秒）

    def _poll_im(self) -> bool:
        """
        GLib 定时回调：轮询当前输入法，若用户手动切换则更新记忆。
        返回 True 表示继续定时，False 表示停止。
        """
        if not self.current_app:
            return True  # 还没有焦点窗口，跳过

        current = get_current_im()
        if not current:
            return True

        # 跳过「我们自己刚刚 set_im() 设置的值」，避免误判
        # _last_set_im 在 _switch_and_remember 里赋值
        if current == self._last_set_im:
            self._last_set_im = None  # 消费掉这次豁免
            return True

        remembered = self.im_memory.get(self.current_app)
        if current != remembered:
            log.info(f"  [轮询] 用户在 {self.current_app!r} 手动切换输入法: {remembered!r} → {current!r}")
            self._remember(self.current_app, current)

        return True  # 持续轮询

    def run(self):
        self.session_bus = dbus.SessionBus()
        self._service = IMESwitcherService(self.session_bus, self)
        self.load_kwin_script()

        # 启动轮询定时器
        GLib.timeout_add(self.POLL_INTERVAL_MS, self._poll_im)
        log.info(f"输入法轮询已启动（间隔 {self.POLL_INTERVAL_MS}ms）")

        log.info("正在监听窗口焦点变化及输入法切换... (Ctrl+C 退出)")

        loop = GLib.MainLoop()

        def handle_sigterm(*_):
            log.info("收到退出信号，正在关闭...")
            self.unload_kwin_script()
            loop.quit()

        signal.signal(signal.SIGTERM, handle_sigterm)
        signal.signal(signal.SIGINT, handle_sigterm)

        try:
            loop.run()
        except KeyboardInterrupt:
            log.info("已退出。")


# ─── 命令行子命令 ──────────────────────────────────────────────

def cmd_list():
    ims = list_ims()
    if ims:
        print("可用输入法：")
        for im in ims:
            print(f"  {im}")
    else:
        print("无法获取输入法列表，请确认 fcitx5 正在运行")


def cmd_status():
    current = get_current_im()
    print(f"当前输入法: {current or '(无法获取)'}")


def cmd_edit_config():
    if not CONFIG_FILE.exists():
        save_config(DEFAULT_CONFIG)
    editor = os.environ.get("EDITOR", "nano")
    os.execlp(editor, editor, str(CONFIG_FILE))


def main():
    import argparse
    parser = argparse.ArgumentParser(
        description="KDE Wayland + Fcitx5 自动输入法切换器",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
子命令：
  run         启动监听（默认）
  list        列出所有可用输入法
  status      显示当前输入法
  config      用 $EDITOR 编辑规则配置文件
        """
    )
    parser.add_argument("command", nargs="?", default="run",
                        choices=["run", "list", "status", "config"])
    args = parser.parse_args()

    if args.command == "list":
        cmd_list()
    elif args.command == "status":
        cmd_status()
    elif args.command == "config":
        cmd_edit_config()
    else:
        IMESwitcher().run()


if __name__ == "__main__":
    main()
