export type ModeId = "work" | "dev" | "ai" | "yours" | "global";

export interface Mode {
  id: ModeId;
  label: string;
  img: string;
  tint: string;
  hue: number;
  apps: string[];
  brief: string;
}

export const MODES: Mode[] = [
  {
    id: "work",
    label: "Work",
    img: "/images/work_mode.png",
    tint: "#4dd0e1",
    hue: 190,
    apps: ["Microsoft Teams", "Slack", "1Password", "IntelliJ IDEA", "WhatsApp", "Finder", "Outlook", "Excel"],
    brief: "Meetings, planning, mail — calm tools only.",
  },
  {
    id: "dev",
    label: "Dev",
    img: "/images/dev_mode.png",
    tint: "#ffb74d",
    hue: 32,
    apps: ["VS Code", "Terminal", "Docker", "Postman", "Chrome", "Simulator"],
    brief: "Deep focus for shipping code.",
  },
  {
    id: "ai",
    label: "AI",
    img: "/images/ai_mode.png",
    tint: "#ba68c8",
    hue: 300,
    apps: ["Claude", "ChatGPT", "Cursor", "Raycast", "Safari", "Obsidian"],
    brief: "Paired with models, minimal distractions.",
  },
  {
    id: "yours",
    label: "Your Mode",
    img: "/images/custom_mode_3.png",
    tint: "#5eb4ff",
    hue: 220,
    apps: [],
    brief: "Build your own. Pick the apps, name it, save it.",
  },
  {
    id: "global",
    label: "Always Open",
    img: "/images/global_mode.png",
    tint: "#4dd0e1",
    hue: 180,
    apps: ["Telegram", "Chrome", "Spotify", "ChatGPT", "WhatsApp", "Notes", "Terminal"],
    brief: "Apps that remain open across all modes.",
  },
];

export type WindowKind = "shot" | "meeting" | "panel";

export interface WindowShot {
  kind: "shot";
  src: string;
  x: string;
  y: string;
  w: string;
  h: string;
  z: number;
}

export interface WindowPanelRow {
  0: string;
  1?: string;
  2?: string;
}

export interface WindowPanel {
  kind: "panel";
  app: string;
  color: string;
  x: string;
  y: string;
  w: string;
  h: string;
  z: number;
  header?: string;
  sub?: string;
  headerApp?: string;
  notepaper?: boolean;
  terminal?: boolean;
  custom?: "yours" | "preview";
  rows?: WindowPanelRow[];
}

export interface MeetingParticipant {
  name: string;
  initials: string;
  color: string;
  muted?: boolean;
}

export interface WindowMeeting {
  kind: "meeting";
  x: string;
  y: string;
  w: string;
  h: string;
  z: number;
  header: string;
  headerApp?: string;
  participants: MeetingParticipant[];
}

export type WindowConfig = WindowShot | WindowPanel | WindowMeeting;

export interface DesktopConfig {
  wallpaperHue: number;
  dockApps: string[];
  windows: WindowConfig[];
}

export const V2_DESKTOPS: Record<Exclude<ModeId, "global">, DesktopConfig> = {
  work: {
    wallpaperHue: 200,
    dockApps: ["Teams", "Outlook", "Slack", "Chrome", "Finder"],
    windows: [
      { kind: "shot", src: "/images/screens/teams.png", x: "4%", y: "12%", w: "56%", h: "62%", z: 3 },
      { kind: "shot", src: "/images/screens/outlook.png", x: "50%", y: "38%", w: "46%", h: "48%", z: 4 },
      { kind: "shot", src: "/images/screens/slack.png", x: "18%", y: "62%", w: "42%", h: "30%", z: 2 },
    ],
  },
  dev: {
    wallpaperHue: 32,
    dockApps: ["Cursor", "CodeAgentSwarm", "IntelliJ", "Terminal", "Chrome", "Finder"],
    windows: [
      { kind: "shot", src: "/images/screens/cursor.png", x: "3%", y: "10%", w: "60%", h: "70%", z: 3 },
      { kind: "shot", src: "/images/screens/codeagentswarm.png", x: "42%", y: "30%", w: "54%", h: "54%", z: 4 },
      { kind: "shot", src: "/images/screens/terminal.png", x: "20%", y: "62%", w: "44%", h: "30%", z: 2 },
    ],
  },
  ai: {
    wallpaperHue: 300,
    dockApps: ["Claude", "ChatGPT", "Cursor", "Notes", "Obsidian"],
    windows: [
      { kind: "shot", src: "/images/screens/claude.png", x: "2%", y: "10%", w: "58%", h: "74%", z: 3 },
      { kind: "shot", src: "/images/screens/chatgpt.png", x: "46%", y: "32%", w: "50%", h: "58%", z: 4 },
      {
        kind: "panel",
        app: "Notes",
        color: "#f9c847",
        x: "24%",
        y: "64%",
        w: "38%",
        h: "28%",
        z: 2,
        header: "Landing notes · Today",
        notepaper: true,
        rows: [
          { 0: "• Three directions" },
          { 0: "• Editorial · Minimal · Command" },
          { 0: "• Ship Friday" },
        ],
      },
    ],
  },
  yours: {
    wallpaperHue: 220,
    dockApps: ["Chrome", "Discord", "Slack", "ChatGPT", "Finder"],
    windows: [
      { kind: "shot", src: "/images/screens/youtube.png", x: "2%", y: "10%", w: "60%", h: "70%", z: 3 },
      { kind: "shot", src: "/images/screens/discord.png", x: "44%", y: "32%", w: "54%", h: "54%", z: 4 },
      { kind: "shot", src: "/images/screens/slack.png", x: "20%", y: "62%", w: "42%", h: "30%", z: 2 },
    ],
  },
};
