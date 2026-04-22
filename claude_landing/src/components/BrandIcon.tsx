import React from "react";

const ICON_PNG: Record<string, string> = {
  // Chat / productivity
  Teams: "/images/icons/teams.png",
  Slack: "/images/icons/slack.png",
  Outlook: "/images/icons/outlook.png",
  Notion: "/images/icons/notion.png",
  Obsidian: "/images/icons/obsidian.png",
  Discord: "/images/icons/discord.png",
  Zoom: "/images/icons/zoom.png",
  Spotify: "/images/icons/spotify.png",
  WhatsApp: "/images/icons/whatsapp.png",
  Telegram: "/images/icons/telegram.png",

  // AI
  Claude: "/images/icons/claude.png",
  ChatGPT: "/images/icons/chatgpt.png",

  // Dev
  Cursor: "/images/icons/cursor.png",
  VSCode: "/images/icons/vscode.png",
  CodeAgentSwarm: "/images/icons/codeagentswarm.png",
  IntelliJ: "/images/icons/intellij.png",
  Terminal: "/images/icons/terminal.png",
  Xcode: "/images/icons/xcode.png",

  // Browsers
  Chrome: "/images/icons/chrome.png",
  Safari: "/images/icons/safari.png",

  // macOS natives
  Finder: "/images/icons/finder.png",
  Mail: "/images/icons/mail.png",
  Messages: "/images/icons/messages.png",
  Calendar: "/images/icons/calendar.png",
  Photos: "/images/icons/photos.png",
  Notes: "/images/icons/notes.png",
  Reminders: "/images/icons/reminders.png",
  Maps: "/images/icons/maps.png",
  Music: "/images/icons/music.png",
  Preview: "/images/icons/preview.png",
};

const ICON_SVG_TILE: Record<string, { src: string; bg: string; padRatio?: number }> = {
  Figma: { src: "/images/icons/figma.svg", bg: "#1a1a1c", padRatio: 0.22 },
  Linear: { src: "/images/icons/linear.svg", bg: "#f4f5f8", padRatio: 0.2 },
  Dropbox: { src: "/images/icons/dropbox.svg", bg: "#fff", padRatio: 0.2 },
  Drive: { src: "/images/icons/drive.svg", bg: "#fff", padRatio: 0.18 },
};

const GENERIC_COLORS: Record<string, string> = {
  Mail: "#1f9bff",
  Music: "#fa2d48",
  Photos: "#e879f9",
  Maps: "#34d399",
  Messages: "#22c55e",
  Safari: "#0c83e0",
  Zoom: "#2d8cff",
};

export interface BrandIconProps {
  name: string;
  size?: number;
}

export function BrandIcon({ name, size = 28 }: BrandIconProps) {
  const wrap: React.CSSProperties = {
    width: size,
    height: size,
    borderRadius: size * 0.22,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
    overflow: "hidden",
    boxShadow: "inset 0 1px 0 rgba(255,255,255,0.15), 0 2px 6px rgba(0,0,0,0.35)",
  };

  if (ICON_PNG[name]) {
    return (
      <img
        src={ICON_PNG[name]}
        alt={name}
        style={{
          width: size,
          height: size,
          borderRadius: size * 0.22,
          flexShrink: 0,
          display: "block",
          filter: "drop-shadow(0 2px 6px rgba(0,0,0,0.35))",
        }}
      />
    );
  }

  if (ICON_SVG_TILE[name]) {
    const { src, bg, padRatio = 0.2 } = ICON_SVG_TILE[name];
    const pad = size * padRatio;
    return (
      <div style={{ ...wrap, background: bg }}>
        <img
          src={src}
          alt={name}
          style={{
            width: size - pad * 2,
            height: size - pad * 2,
            display: "block",
          }}
        />
      </div>
    );
  }

  const color = GENERIC_COLORS[name] || "#666";
  return (
    <div
      style={{
        ...wrap,
        background: color,
        color: "#fff",
        fontWeight: 800,
        fontSize: size * 0.44,
        fontFamily: "system-ui, sans-serif",
      }}
    >
      {name.charAt(0)}
    </div>
  );
}
