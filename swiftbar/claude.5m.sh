#!/usr/bin/env bash
# <xbar.title>Claude Usage</xbar.title>
# <xbar.desc>Uso Claude: % ufficiali se il token CLI è disponibile, altrimenti costo/token via ccusage.</xbar.desc>
# <xbar.version>4.0</xbar.version>
#
# Prova prima le PERCENTUALI UFFICIALI (claude-usage -> endpoint /api/oauth/usage).
# Se il token OAuth della CLI non è disponibile (su questo Mac è gestito dall'app
# desktop ed è cifrato), ripiega su ccusage (costo e token dai log locali).

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
PURPLE="#8a5cf6"; CACHE_DIR="$HOME/.cache/claude-usage"; CACHE="$CACHE_DIR/usage.json"; TTL=240
mkdir -p "$CACHE_DIR" 2>/dev/null

# --- Prova le % ufficiali (con cache) ---
STATUS="noauth"; BODY=""
now=$(date +%s); cache_age=999999
[ -f "$CACHE" ] && cache_age=$(( now - $(stat -f %m "$CACHE" 2>/dev/null || echo 0) ))
if [ "$cache_age" -lt "$TTL" ] && [ -f "$CACHE" ]; then
  BODY="$(cat "$CACHE")"; STATUS="ok"
elif command -v claude-usage >/dev/null 2>&1; then
  ENVJSON="$(claude-usage --json 2>/dev/null)"
  STATUS="$(printf '%s' "$ENVJSON" | /usr/bin/python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("status","err"))
except Exception: print("err")' 2>/dev/null)"
  BD="$(printf '%s' "$ENVJSON" | /usr/bin/python3 -c 'import sys,json
try:
    d=json.load(sys.stdin); print(json.dumps(d["body"]) if d.get("body") else "")
except Exception: print("")' 2>/dev/null)"
  if [ "$STATUS" = "ok" ] && [ -n "$BD" ]; then printf '%s' "$BD" > "$CACHE"; BODY="$BD"
  else [ -f "$CACHE" ] && BODY="$(cat "$CACHE")"; fi
fi

# --- ccusage (fallback e riga costo) ---
COST_JSON=""; WEEK_JSON=""
if command -v ccusage >/dev/null 2>&1; then
  COST_JSON="$(ccusage claude blocks --active --json 2>/dev/null)"
  WEEK_JSON="$(ccusage claude weekly --json 2>/dev/null)"
fi

BODY="$BODY" STATUS="$STATUS" COST_JSON="$COST_JSON" WEEK_JSON="$WEEK_JSON" PURPLE="$PURPLE" \
CLAUDE_SESSION="$HOME/.local/bin/claude-session" CACHE="$CACHE" /usr/bin/python3 <<'PY'
import os, json, datetime
purple=os.environ.get("PURPLE","#8a5cf6"); status=os.environ.get("STATUS","noauth")
session=os.environ.get("CLAUDE_SESSION",""); cache=os.environ.get("CACHE","")
def loadj(s):
    s=(s or "").strip()
    if not s: return None
    try: return json.loads(s)
    except Exception: return None
data=loadj(os.environ.get("BODY","")); cost=loadj(os.environ.get("COST_JSON","")); week=loadj(os.environ.get("WEEK_JSON",""))
def color(p): return "red" if p>=90 else ("orange" if p>=70 else purple)
def ftok(n):
    n=n or 0
    return f"{n/1_000_000:.1f}M" if n>=1_000_000 else (f"{n/1000:.0f}k" if n>=1000 else str(int(n)))
def pct(w):
    try: return int(round(float((data.get(w) or {}).get("utilization") or 0)))
    except Exception: return 0
def reset_in(w):
    try:
        r=(data.get(w) or {}).get("resets_at")
        if not r: return None
        dt=datetime.datetime.fromisoformat(str(r).replace("Z","+00:00")) if not isinstance(r,(int,float)) else datetime.datetime.fromtimestamp(r,datetime.timezone.utc)
        s=int((dt-datetime.datetime.now(datetime.timezone.utc)).total_seconds())
        if s<=0: return "ora"
        d,rem=divmod(s,86400); h,rem=divmod(rem,3600); m,_=divmod(rem,60)
        return f"{d}g {h}h" if d else (f"{h}h {m:02d}m" if h else f"{m}m")
    except Exception: return None
out=[]
official = bool(data and data.get("five_hour") is not None)
if official:
    s=pct("five_hour"); w=pct("seven_day")
    out.append(f"✦ {s}% / {w}% | color={color(max(s,w))}")
    out.append("---"); out.append(f"Utilizzo ufficiale · Claude | color={purple}")
    sr=reset_in("five_hour"); wr=reset_in("seven_day")
    out.append(f"Sessione (5h): {s}% "+(f"· reset tra {sr}" if sr else "")+f" | color={color(s)}")
    out.append(f"Settimana (7d): {w}% "+(f"· reset tra {wr}" if wr else "")+f" | color={color(w)}")
    try:
        seen=False
        for lim in (data.get("limits") or []):
            if isinstance(lim,dict) and lim.get("kind")=="weekly_scoped":
                name=(lim.get("scope") or {}).get("model") or lim.get("name") or "modello"
                lp=int(round(float(lim.get("utilization") or 0)))
                if not seen: out.append("---"); seen=True
                out.append(f"{name} (settimana): {lp}% | color={color(lp)}")
    except Exception: pass
else:
    # Fallback ccusage (costo/token)
    c=None; tok=0; remain=None; pcost=None
    try:
        if cost and cost.get("blocks"):
            b=cost["blocks"][0]; c=b.get("costUSD") or 0.0; tok=b.get("totalTokens") or 0
            pr=b.get("projection") or {}; remain=pr.get("remainingMinutes"); pcost=pr.get("totalCost")
    except Exception: pass
    if c is not None:
        out.append(f"✦ ${c:.2f} | color={purple}")
        out.append("---"); out.append(f"Finestra 5h · Claude (costo) | color={purple}")
        out.append(f"Costo: ${c:.2f} · {ftok(tok)} token | font=Menlo")
        if remain is not None:
            h,m=divmod(int(remain),60); out.append(f"Tempo residuo: {h}h{m:02d}m | font=Menlo")
        if pcost is not None:
            out.append(f"Proiezione a fine finestra: ${pcost:.2f} | font=Menlo")
        try:
            if week and week.get("weekly"):
                cur=week["weekly"][-1]
                wc=cur.get("totalCost")
                if wc is None: wc=sum((mb.get("cost") or 0) for mb in (cur.get("modelBreakdowns") or []))
                out.append(f"Questa settimana: ${wc:.2f} | font=Menlo")
        except Exception: pass
    else:
        out.append(f"✦ … | color=#888888"); out.append("---"); out.append("Nessun dato di utilizzo | color=#888888")
    out.append("---")
    out.append("% ufficiale non disponibile | color=orange")
    out.append("Token CLI assente (auth dall'app desktop) | color=#888888")
    out.append("Per le %: fai login con la CLI standalone | color=#888888")

# riga costo anche in modalità ufficiale
if official:
    try:
        if cost and cost.get("blocks"):
            b=cost["blocks"][0]; c=b.get("costUSD") or 0.0; tok=b.get("totalTokens") or 0
            out.append("---"); out.append(f"Costo finestra 5h: ${c:.2f} · {ftok(tok)} token | font=Menlo")
    except Exception: pass

out.append("---")
out.append(f"Apri / riprendi Claude Code  (⌃⌥A) | bash={session} terminal=false")
out.append("Apri Claude.app | bash=/usr/bin/open param1=-a param2=Claude terminal=false")
out.append(f"Aggiorna ora | bash=/bin/rm param1={cache} terminal=false refresh=true")
print("\n".join(out))
PY
