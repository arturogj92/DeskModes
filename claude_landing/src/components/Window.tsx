import React from "react";
import { BrandIcon } from "./BrandIcon";
import type { WindowConfig, WindowPanel } from "@/lib/modes";

export interface WindowProps {
  win: WindowConfig;
  idx: number;
}

export function Window({ win, idx }: WindowProps) {
  if (win.kind === "shot") {
    return (
      <div
        style={{
          position: "absolute",
          left: win.x,
          top: win.y,
          width: win.w,
          height: win.h,
          zIndex: win.z,
          borderRadius: 8,
          overflow: "hidden",
          boxShadow: "0 20px 50px rgba(0,0,0,0.6)",
          animation: "v2WinIn 600ms cubic-bezier(.2,.7,.2,1) backwards",
          animationDelay: `${idx * 90}ms`,
        }}
      >
        <img
          src={win.src}
          alt=""
          style={{ width: "100%", height: "100%", objectFit: "cover", objectPosition: "top left", display: "block" }}
        />
      </div>
    );
  }

  if (win.kind === "meeting") {
    return (
      <div
        style={{
          position: "absolute",
          left: win.x,
          top: win.y,
          width: win.w,
          height: win.h,
          zIndex: win.z,
          background: "#1b1b24",
          borderRadius: 8,
          overflow: "hidden",
          boxShadow: "0 20px 50px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.08)",
          display: "flex",
          flexDirection: "column",
          animation: "v2WinIn 600ms cubic-bezier(.2,.7,.2,1) backwards",
          animationDelay: `${idx * 90}ms`,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 5, padding: "6px 10px", background: "#2a2a3a" }}>
          <div style={{ width: 9, height: 9, borderRadius: 5, background: "#ff5f57" }} />
          <div style={{ width: 9, height: 9, borderRadius: 5, background: "#febc2e" }} />
          <div style={{ width: 9, height: 9, borderRadius: 5, background: "#28c840" }} />
          <div
            style={{
              flex: 1,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              gap: 6,
              fontSize: 11,
              fontWeight: 600,
              color: "rgba(255,255,255,0.9)",
              whiteSpace: "nowrap",
              overflow: "hidden",
              textOverflow: "ellipsis",
            }}
          >
            {win.headerApp && <BrandIcon name={win.headerApp} size={14} />}
            <span>{win.header}</span>
          </div>
          <div style={{ fontSize: 10, color: "#ef4444", fontWeight: 600 }}>● REC</div>
        </div>
        <div style={{ flex: 1, padding: 10, display: "grid", gridTemplateColumns: "1fr 1fr", gap: 6, minHeight: 0 }}>
          {win.participants.map((p) => (
            <div
              key={p.name}
              style={{
                background: `linear-gradient(135deg, ${p.color}44 0%, ${p.color}11 100%)`,
                borderRadius: 6,
                position: "relative",
                overflow: "hidden",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                border: "1px solid rgba(255,255,255,0.06)",
              }}
            >
              <div
                style={{
                  width: "34%",
                  aspectRatio: "1",
                  borderRadius: "50%",
                  background: p.color,
                  color: "#fff",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontWeight: 700,
                  fontSize: 13,
                  letterSpacing: -0.5,
                  boxShadow: `0 6px 16px ${p.color}66`,
                }}
              >
                {p.initials}
              </div>
              <div
                style={{
                  position: "absolute",
                  bottom: 4,
                  left: 6,
                  fontSize: 9,
                  color: "rgba(255,255,255,0.85)",
                  fontWeight: 500,
                }}
              >
                {p.name}
              </div>
              {p.muted && (
                <div
                  style={{
                    position: "absolute",
                    top: 4,
                    right: 4,
                    width: 14,
                    height: 14,
                    borderRadius: 7,
                    background: "rgba(0,0,0,0.6)",
                    fontSize: 8,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    color: "#ef4444",
                  }}
                >
                  ×
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    );
  }

  return <PanelWindow win={win} idx={idx} />;
}

function PanelWindow({ win, idx }: { win: WindowPanel; idx: number }) {
  return (
    <div
      style={{
        position: "absolute",
        left: win.x,
        top: win.y,
        width: win.w,
        height: win.h,
        zIndex: win.z,
        background: win.notepaper ? "#fdf6c4" : win.terminal ? "#15151a" : "#1f1f22",
        color: win.notepaper ? "#3a2e10" : "#fff",
        borderRadius: 8,
        overflow: "hidden",
        boxShadow: "0 20px 50px rgba(0,0,0,0.6), 0 0 0 1px rgba(255,255,255,0.08)",
        display: "flex",
        flexDirection: "column",
        animation: "v2WinIn 600ms cubic-bezier(.2,.7,.2,1) backwards",
        animationDelay: `${idx * 90}ms`,
        fontFamily: win.terminal ? "'SF Mono', Menlo, monospace" : "inherit",
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 5,
          padding: "6px 10px",
          background: win.notepaper ? "#f5ec9a" : win.terminal ? "#1a1a1f" : "#2a2a2e",
          borderBottom: `1px solid ${win.notepaper ? "rgba(0,0,0,0.08)" : "rgba(0,0,0,0.35)"}`,
        }}
      >
        <div style={{ width: 9, height: 9, borderRadius: 5, background: "#ff5f57" }} />
        <div style={{ width: 9, height: 9, borderRadius: 5, background: "#febc2e" }} />
        <div style={{ width: 9, height: 9, borderRadius: 5, background: "#28c840" }} />
        <div
          style={{
            flex: 1,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 6,
            fontSize: 10,
            fontWeight: 600,
            color: win.notepaper ? "rgba(0,0,0,0.6)" : "rgba(255,255,255,0.85)",
            whiteSpace: "nowrap",
            overflow: "hidden",
            padding: "0 6px",
          }}
        >
          {win.headerApp && <BrandIcon name={win.headerApp} size={13} />}
          <span style={{ overflow: "hidden", textOverflow: "ellipsis" }}>{win.header}</span>
        </div>
        <div style={{ width: 14 }} />
      </div>
      <div style={{ flex: 1, padding: "9px 11px", minHeight: 0, overflow: "hidden" }}>
        {win.sub && <div style={{ fontSize: 9, color: "rgba(255,255,255,0.5)", marginBottom: 6 }}>{win.sub}</div>}
        {win.custom === "yours" && (
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              gap: 14,
              height: "100%",
              padding: "20px 12px",
            }}
          >
            <img
              src="/images/new_mode.png"
              alt=""
              style={{ width: 64, height: 64, objectFit: "contain", filter: "drop-shadow(0 10px 20px rgba(91,209,154,0.5))" }}
            />
            <div style={{ fontSize: 15, fontWeight: 600, letterSpacing: -0.3, color: "#fff" }}>Create your mode</div>
            <div
              style={{
                fontSize: 10,
                color: "rgba(255,255,255,0.55)",
                textAlign: "center",
                lineHeight: 1.5,
                maxWidth: 220,
              }}
            >
              Pick the apps. Name it. Save it. Switch to it in one click.
            </div>
            <div
              style={{
                marginTop: 6,
                display: "flex",
                gap: 4,
                flexWrap: "wrap",
                justifyContent: "center",
                maxWidth: 240,
              }}
            >
              {["Figma", "Linear", "Notion", "Spotify", "Chrome"].map((a) => (
                <span
                  key={a}
                  style={{
                    fontSize: 9,
                    padding: "3px 7px",
                    borderRadius: 99,
                    background: "rgba(91,209,154,0.15)",
                    color: "#9ee4bf",
                    border: "1px solid rgba(91,209,154,0.25)",
                  }}
                >
                  + {a}
                </span>
              ))}
            </div>
          </div>
        )}
        {win.custom === "preview" && (
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            <div style={{ fontSize: 9, color: "rgba(255,255,255,0.45)", fontFamily: "'SF Mono', monospace" }}>
              ◉ localhost:3000
            </div>
            <div style={{ fontSize: 13, fontWeight: 600, lineHeight: 1.3 }}>One Mac. Every mode.</div>
            <div style={{ display: "flex", gap: 5 }}>
              {["#ffb74d", "#4dd0e1", "#ba68c8"].map((c) => (
                <div key={c} style={{ width: 16, height: 16, borderRadius: 4, background: c, opacity: 0.85 }} />
              ))}
            </div>
          </div>
        )}
        {!win.custom &&
          win.rows?.map((r, i) => {
            if (win.terminal) {
              return (
                <div
                  key={i}
                  style={{
                    fontSize: 10,
                    color: r[0] === "$" ? "#50fa7b" : "rgba(255,255,255,0.85)",
                    lineHeight: 1.65,
                    whiteSpace: "nowrap",
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                  }}
                >
                  {r[0] && (
                    <span style={{ color: r[0] === "$" ? "#50fa7b" : "rgba(255,255,255,0.35)", marginRight: 6 }}>
                      {r[0]}
                    </span>
                  )}
                  <span>{r[1]}</span>
                </div>
              );
            }
            if (win.notepaper) {
              return (
                <div
                  key={i}
                  style={{
                    fontSize: 11,
                    lineHeight: 1.7,
                    fontFamily: "var(--font-playfair), Georgia, serif",
                  }}
                >
                  {r[0]}
                </div>
              );
            }
            return (
              <div
                key={i}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 8,
                  padding: "6px 0",
                  borderBottom:
                    i < (win.rows?.length ?? 0) - 1 ? "1px solid rgba(255,255,255,0.05)" : "none",
                }}
              >
                <div
                  style={{
                    width: 20,
                    height: 20,
                    borderRadius: 10,
                    flexShrink: 0,
                    background: win.color,
                    color: "#fff",
                    fontSize: 9,
                    fontWeight: 700,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                >
                  {r[0].charAt(0).toUpperCase()}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div
                    style={{
                      fontSize: 10,
                      fontWeight: 600,
                      color: "#fff",
                      marginBottom: 1,
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                      whiteSpace: "nowrap",
                    }}
                  >
                    {r[0]}
                  </div>
                  <div
                    style={{
                      fontSize: 9,
                      color: "rgba(255,255,255,0.55)",
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                      whiteSpace: "nowrap",
                    }}
                  >
                    {r[1]}
                  </div>
                </div>
                {r[2] && (
                  <div style={{ fontSize: 8, color: "rgba(255,255,255,0.35)", flexShrink: 0 }}>{r[2]}</div>
                )}
              </div>
            );
          })}
      </div>
    </div>
  );
}
