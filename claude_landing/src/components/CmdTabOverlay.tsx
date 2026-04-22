"use client";

import { useEffect, useState } from "react";
import { BrandIcon } from "./BrandIcon";

const APPS = [
  "Finder", "Safari", "Chrome", "Mail", "Messages", "Slack", "Teams", "Discord",
  "Zoom", "Spotify", "WhatsApp", "Telegram", "Notion", "Obsidian", "ChatGPT", "Claude",
  "Cursor", "VSCode", "IntelliJ", "Terminal", "Figma", "Linear", "Dropbox", "Drive",
  "Calendar", "Photos", "Notes", "Reminders", "Maps", "Music", "Xcode", "Preview",
];

export function CmdTabOverlay() {
  const [selected, setSelected] = useState(0);

  useEffect(() => {
    const id = setInterval(() => setSelected((s) => (s + 1) % APPS.length), 650);
    return () => clearInterval(id);
  }, []);

  return (
    <div
      style={{
        position: "absolute",
        top: "32%",
        left: 0,
        right: 0,
        zIndex: 5,
        display: "flex",
        justifyContent: "center",
        pointerEvents: "none",
      }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          gap: 14,
          width: "max-content",
          maxWidth: "calc(100% - 24px)",
        }}
      >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          flexWrap: "nowrap",
          gap: 3,
          padding: "10px 12px",
          background: "rgba(20,20,25,0.68)",
          backdropFilter: "blur(28px) saturate(180%)",
          WebkitBackdropFilter: "blur(28px) saturate(180%)",
          border: "1px solid rgba(255,255,255,0.1)",
          borderRadius: 16,
          boxShadow:
            "0 30px 80px rgba(0,0,0,0.55), 0 8px 20px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.08)",
          width: "max-content",
          maxWidth: "100%",
        }}
      >
        {APPS.map((name, i) => {
          const isSelected = i === selected;
          return (
            <div
              key={name}
              style={{
                flexShrink: 0,
                padding: 3,
                borderRadius: 8,
                background: isSelected ? "rgba(255,255,255,0.14)" : "transparent",
                boxShadow: isSelected
                  ? "inset 0 0 0 1.5px rgba(255,255,255,0.45)"
                  : "none",
                transition: "background 140ms ease, box-shadow 140ms ease",
              }}
            >
              <BrandIcon name={name} size={26} />
            </div>
          );
        })}
      </div>
      <div
        style={{
          fontSize: 15,
          color: "rgba(255,255,255,0.95)",
          fontWeight: 500,
          letterSpacing: -0.2,
          textShadow: "0 2px 10px rgba(0,0,0,0.9)",
          padding: "4px 14px",
          background: "rgba(0,0,0,0.35)",
          borderRadius: 8,
          backdropFilter: "blur(10px)",
          WebkitBackdropFilter: "blur(10px)",
        }}
      >
        {APPS[selected]}
      </div>
      </div>
    </div>
  );
}
