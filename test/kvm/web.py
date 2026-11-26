"""web.py <step> : 用 playwright + 本机 Chrome 操作飞牛 Web 界面, 每步截图到 $CK_KVM_DIR/w-<step>.png
状态(cookies/localStorage)存在 state.json, 便于分步操作。"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

D = os.environ["CK_KVM_DIR"]  # 截图/state.json 放测试机目录, 不进仓库
BASE = "http://127.0.0.1:25666"
STATE = os.path.join(D, "state.json")
step = sys.argv[1]
actions = json.loads(sys.argv[2]) if len(sys.argv) > 2 else []

with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome", headless=True)
    ctx = b.new_context(viewport={"width": 1440, "height": 900}, locale="zh-CN",
                        storage_state=STATE if os.path.exists(STATE) else None)
    pg = ctx.new_page()
    logs = []
    pg.on("console", lambda m: logs.append(f"console {m.type}: {m.text[:200]}"))
    pg.on("requestfailed", lambda r: logs.append(f"reqfail {r.url[:150]} {r.failure}"))
    pg.on("request", lambda r: logs.append(f"req {r.url[:150]}") if not r.url.startswith(BASE) else None)
    url = None
    for a in actions:
        kind = a[0]
        if kind == "goto":
            pg.goto(BASE + a[1], wait_until="domcontentloaded", timeout=120000); url = a[1]
        elif kind == "wait":
            time.sleep(a[1])
        elif kind == "click":
            pg.get_by_text(a[1], exact=a[2] if len(a) > 2 else False).first.click(timeout=30000)
        elif kind == "dblclick":
            pg.get_by_text(a[1], exact=a[2] if len(a) > 2 else False).first.dblclick(timeout=30000)
        elif kind == "dblclickxy":
            pg.mouse.dblclick(a[1], a[2])
        elif kind == "rclick":
            pg.get_by_text(a[1], exact=True).first.click(button="right", timeout=30000)
        elif kind == "rclickxy":
            pg.mouse.click(a[1], a[2], button="right")
        elif kind == "clickxy":
            pg.mouse.click(a[1], a[2])
        elif kind == "fill":
            pg.locator(a[1]).nth(a[3] if len(a) > 3 else 0).fill(a[2], timeout=30000)
        elif kind == "press":
            pg.keyboard.press(a[1])
        elif kind == "type":
            pg.keyboard.type(a[1], delay=30)
        elif kind == "eval":
            print("eval:", pg.evaluate(a[1]))
        elif kind == "html":
            print(pg.content()[:a[1]])
        elif kind == "inputs":
            for i, el in enumerate(pg.locator("input").all()):
                try:
                    print(i, el.get_attribute("type"), el.get_attribute("placeholder"), el.is_visible())
                except Exception as e:
                    print(i, e)
        elif kind == "shot":
            pg.screenshot(path=os.path.join(D, f"w-{step}-{a[1]}.png"))
        elif kind == "switchlast":
            for p2 in ctx.pages:
                if p2 is not pg:
                    pg = p2
            try:
                pg.wait_for_load_state(timeout=5000)
            except Exception:
                pass
        elif kind == "newpages":
            for i, p2 in enumerate(ctx.pages):
                if p2 is not pg:
                    try:
                        p2.wait_for_load_state(timeout=5000)
                    except Exception:
                        pass
                    p2.screenshot(path=os.path.join(D, f"w-{step}-np{i}.png"))
                    print("newpage url:", p2.url)
        elif kind == "text":
            print(pg.inner_text("body")[:a[1]])
    pg.screenshot(path=os.path.join(D, f"w-{step}.png"))
    ctx.storage_state(path=STATE)
    print("url:", pg.url)
    print("\n".join(l for l in logs if not l.startswith("console debug"))[-3000:])
    b.close()
