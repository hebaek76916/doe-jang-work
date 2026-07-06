#!/usr/bin/env python3
"""출근도장 CLI — 연봉 넣으면 터미널에서 실시간으로 돈이 오른다 💸

    pip install workstamp   (또는 이 폴더에서: pip install .)
    workstamp init          # 연봉·출퇴근 시각 설정
    workstamp               # 실시간 티커
    workstamp stamp         # 오늘 출근 도장 쾅
    workstamp cal           # 이번 달 도장 달력
    workstamp --once        # 한 줄만 출력 (tmux/starship 상태바용)
"""
import argparse
import json
import os
import sys
import time
from datetime import date, datetime
from pathlib import Path

# ── 저장소 ──────────────────────────────────────────────────────────
HOME = Path(os.environ.get("WORKSTAMP_HOME") or Path.home() / ".config" / "workstamp")
CONFIG_PATH = HOME / "config.json"
STAMPS_PATH = HOME / "stamps.json"

# ── 한국 공휴일 (대체공휴일 포함, 2025–2027 근사치) ─────────────────
HOLIDAYS = {
    # 2025
    "2025-01-01", "2025-01-27", "2025-01-28", "2025-01-29", "2025-01-30",
    "2025-03-03", "2025-05-05", "2025-05-06", "2025-06-03", "2025-06-06",
    "2025-08-15", "2025-10-03", "2025-10-06", "2025-10-07", "2025-10-08",
    "2025-10-09", "2025-12-25",
    # 2026
    "2026-01-01", "2026-02-16", "2026-02-17", "2026-02-18", "2026-03-02",
    "2026-05-05", "2026-05-25", "2026-08-17", "2026-09-24", "2026-09-25",
    "2026-09-28", "2026-10-05", "2026-10-09", "2026-12-25",
    # 2027
    "2027-01-01", "2027-02-08", "2027-02-09", "2027-03-01", "2027-05-05",
    "2027-05-13", "2027-08-16", "2027-09-14", "2027-09-15", "2027-09-16",
    "2027-10-04", "2027-10-11", "2027-12-27",
}

# ── ANSI (매트릭스 감성) ────────────────────────────────────────────
GREEN, DIM, BOLD, RESET = "\033[92m", "\033[2m", "\033[1m", "\033[0m"


def is_workday(d: date) -> bool:
    return d.weekday() < 5 and d.isoformat() not in HOLIDAYS


def workday_count(year: int) -> int:
    d = date(year, 1, 1)
    count = 0
    while d.year == year:
        if is_workday(d):
            count += 1
        d = date.fromordinal(d.toordinal() + 1)
    return count


# ── 설정/도장 파일 ──────────────────────────────────────────────────
def load_json(path: Path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return default


def save_json(path: Path, data):
    HOME.mkdir(parents=True, exist_ok=True)
    os.chmod(HOME, 0o700)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2))
    os.chmod(path, 0o600)


def load_config():
    cfg = load_json(CONFIG_PATH, None)
    if not cfg or not cfg.get("annual_salary"):
        print("먼저 설정부터: workstamp init --salary 5000  (만원 단위)")
        sys.exit(1)
    return cfg


def parse_hhmm(s: str) -> int:
    h, m = s.split(":")
    return int(h) * 60 + int(m)


# ── 계산 ────────────────────────────────────────────────────────────
def daily_wage(cfg, year: int) -> int:
    return cfg["annual_salary"] // max(workday_count(year), 1)


def now_minutes(now: datetime) -> float:
    return now.hour * 60 + now.minute + now.second / 60


def phase_and_earned(cfg, now: datetime):
    """근무 단계와 지금까지 번 돈. 앱의 WorkPhase와 동일한 5단계."""
    wage = daily_wage(cfg, now.year)
    if not is_workday(now.date()):
        return "restday", 0, 0.0
    start, end = parse_hhmm(cfg["work_start"]), parse_hhmm(cfg["work_end"])
    cur = now_minutes(now)
    if cur < start - 60:
        return "before", 0, 0.0
    if cur < start:
        return "commuting", 0, 0.0
    if cur < end:
        frac = (cur - start) / max(end - start, 1)
        return "working", int(wage * frac), frac
    if cur < end + 120:
        return "done", wage, 1.0
    return "overtime", wage, 1.0


def fmt_won(n: int, secret: bool) -> str:
    if secret:
        return f"•••,{n % 1000:03d}원" if n >= 1000 else "•••원"
    return f"{n:,}원"


def bar(frac: float, width: int = 10) -> str:
    filled = round(frac * width)
    return "█" * filled + "░" * (width - filled)


def remaining_str(cfg, now: datetime) -> str:
    end = parse_hhmm(cfg["work_end"]) * 60
    cur = now.hour * 3600 + now.minute * 60 + now.second
    left = max(end - cur, 0)
    return f"{left // 3600}:{left % 3600 // 60:02d}:{left % 60:02d}"


def ticker_line(cfg, now: datetime, secret: bool, plain: bool) -> str:
    phase, earned, frac = phase_and_earned(cfg, now)
    money = fmt_won(earned, secret)
    if phase == "restday":
        text = "🧘 무급 힐링 중 (0원도 힐링이면 OK)"
    elif phase == "before":
        text = f"🛌 출근 전 ({cfg['work_start']}부터 돈이 오릅니다)"
    elif phase == "commuting":
        text = "🏃 돈 벌러 가는 중"
    elif phase == "working":
        if plain:
            text = f"💸 +{money} [{bar(frac)}] 퇴근까지 {remaining_str(cfg, now)}"
        else:
            text = (f"💸 {GREEN}{BOLD}+{money}{RESET} "
                    f"{GREEN}[{bar(frac)}]{RESET} "
                    f"{DIM}퇴근까지 {remaining_str(cfg, now)}{RESET}")
    elif phase == "done":
        text = f"🍻 다 벌었다, 수고했다! +{money}"
    else:  # overtime
        text = f"🫠 무료봉사 중 (오늘 +{money} 확정)"
    return text


# ── 커맨드 ──────────────────────────────────────────────────────────
def cmd_init(args):
    if args.salary is None:
        args.salary = int(input("연봉 (만원): ").strip() or "0")
    cfg = {
        "annual_salary": args.salary * 10_000,
        "work_start": args.start,
        "work_end": args.end,
        "secret": False,
    }
    save_json(CONFIG_PATH, cfg)
    wage = daily_wage(cfg, date.today().year)
    print(f"저장 완료 💾  하루 출근 = {GREEN}{BOLD}+{wage:,}원{RESET} "
          f"(연 근무일 {workday_count(date.today().year)}일 기준)")


def cmd_stamp(cfg):
    stamps = set(load_json(STAMPS_PATH, []))
    today = date.today()
    key = today.isoformat()
    if not is_workday(today):
        print("오늘은 쉬는 날 🧘 도장 없이 힐링하세요")
        return
    if key in stamps:
        print(f"이미 찍음 ✅ ({key})")
        return
    stamps.add(key)
    save_json(STAMPS_PATH, sorted(stamps))
    wage = daily_wage(cfg, today.year)
    month_count = sum(1 for s in stamps if s.startswith(key[:8]))
    print(f"🔴 쾅! {key} 출근 도장 (+{wage:,}원)")
    print(f"   이번 달 도장 {month_count}개 = {GREEN}{month_count * wage:,}원{RESET}")


def cmd_cal(cfg, secret: bool):
    stamps = set(load_json(STAMPS_PATH, []))
    today = date.today()
    wage = daily_wage(cfg, today.year)
    print(f"\n  {BOLD}{today.year}년 {today.month}월{RESET}   "
          f"{DIM}● = 출근 도장{RESET}")
    print(f"  {DIM}일  월  화  수  목  금  토{RESET}")
    d = date(today.year, today.month, 1)
    row = ["    "] * ((d.weekday() + 1) % 7)
    while d.month == today.month:
        mark = f"{GREEN}●{RESET}" if d.isoformat() in stamps else " "
        cell = f"{d.day:2d}{mark} "
        if d == today:
            cell = f"{BOLD}{d.day:2d}{RESET}{mark} "
        row.append(cell)
        if (d.weekday() + 1) % 7 == 6:
            print("  " + "".join(row))
            row = []
        d = date.fromordinal(d.toordinal() + 1)
    if row:
        print("  " + "".join(row))
    month_count = sum(1 for s in stamps if s.startswith(f"{today.year}-{today.month:02d}"))
    print(f"\n  이번 달 {month_count}개 = {GREEN}{BOLD}{fmt_won(month_count * wage, secret)}{RESET}\n")


def cmd_ticker(cfg, once: bool, secret: bool, plain: bool):
    if once:
        print(ticker_line(cfg, datetime.now(), secret, plain))
        return
    try:
        while True:
            line = ticker_line(cfg, datetime.now(), secret, plain)
            print(f"\r\033[K{line}", end="", flush=True)
            time.sleep(1)
    except KeyboardInterrupt:
        print(f"\n{DIM}퇴근 아님. 티커만 종료 🫡{RESET}")


def main():
    p = argparse.ArgumentParser(prog="workstamp", description="터미널 출근도장 — 실시간으로 돈이 오른다 💸")
    p.add_argument("command", nargs="?", choices=["init", "stamp", "cal"], help="생략하면 실시간 티커")
    p.add_argument("--salary", type=int, help="연봉 (만원 단위, init용)")
    p.add_argument("--start", default="09:00", help="출근 시각 (기본 09:00)")
    p.add_argument("--end", default="18:00", help="퇴근 시각 (기본 18:00)")
    p.add_argument("--once", action="store_true", help="한 줄 출력 후 종료 (tmux/starship용)")
    p.add_argument("--secret", action="store_true", help="금액 끝 3자리만 표시 🕶️")
    p.add_argument("--plain", action="store_true", help="색상 없이 출력")
    args = p.parse_args()

    if args.command == "init":
        cmd_init(args)
        return
    cfg = load_config()
    secret = args.secret or cfg.get("secret", False)
    if args.command == "stamp":
        cmd_stamp(cfg)
    elif args.command == "cal":
        cmd_cal(cfg, secret)
    else:
        cmd_ticker(cfg, args.once, secret, args.plain)


if __name__ == "__main__":
    main()
