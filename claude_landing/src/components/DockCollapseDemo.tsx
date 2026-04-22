"use client";

import { useEffect, useState } from "react";
import { MODES, type ModeId } from "@/lib/modes";
import { BrandIcon } from "./BrandIcon";

const CLUTTER_APPS = [
  "Finder", "Safari", "Chrome", "Mail", "Messages", "Slack", "Teams", "Discord",
  "Zoom", "Spotify", "WhatsApp", "Telegram", "Notion", "Obsidian", "ChatGPT", "Claude",
  "Cursor", "VSCode", "IntelliJ", "Terminal", "Figma", "Linear", "Dropbox", "Drive",
  "Calendar", "Photos", "Notes", "Reminders", "Maps", "Music", "Xcode", "Preview",
];

const MODE_ESSENTIALS: Record<Exclude<ModeId, "yours" | "global">, string[]> = {
  work: ["Teams", "Outlook", "Slack", "Chrome", "Finder"],
  dev: ["Cursor", "IntelliJ", "Terminal", "Chrome", "Finder"],
  ai: ["Claude", "ChatGPT", "Cursor", "Notes", "Obsidian"],
};

const ICON_SIZE = 26;
const SLOT_SPACING = 4;

export function DockCollapseDemo() {
  const [active, setActive] = useState(0);
  const [cleaning, setCleaning] = useState(false);
  const [modeSelected, setModeSelected] = useState(false);
  const mode = MODES[active];
  const essentialsKey = mode.id as Exclude<ModeId, "yours" | "global">;
  const essentials = MODE_ESSENTIALS[essentialsKey] ?? MODE_ESSENTIALS.work;

  useEffect(() => {
    const timers: ReturnType<typeof setTimeout>[] = [];
    const schedule = (fn: () => void, ms: number) => {
      timers.push(setTimeout(fn, ms));
    };

    const runCycle = () => {
      setCleaning(false);
      setModeSelected(false);
      schedule(() => setModeSelected(true), 700);
      schedule(() => setCleaning(true), 1100);
      schedule(() => {
        setActive((a) => (a + 1) % 3);
        runCycle();
      }, 3400);
    };

    runCycle();

    return () => {
      timers.forEach(clearTimeout);
    };
  }, []);

  return (
    <section
      style={{
        position: "relative",
        padding: "60px 40px 80px",
        maxWidth: 1360,
        margin: "0 auto",
      }}
    >
      <div style={{ textAlign: "center", marginBottom: 56 }}>
        <div
          style={{
            fontSize: 12,
            color: "rgba(255,255,255,0.4)",
            letterSpacing: 3,
            textTransform: "uppercase",
            marginBottom: 16,
          }}
        >
          One click. Clean dock.
        </div>
        <h2
          style={{
            fontFamily: "var(--font-playfair), Georgia, serif",
            fontWeight: 400,
            fontStyle: "italic",
            fontSize: 56,
            lineHeight: 1.1,
            letterSpacing: -1.5,
            margin: 0,
          }}
        >
          From{" "}
          <span
            style={{
              color: "#ef4444",
              textDecoration: "line-through",
              textDecorationColor: "rgba(239,68,68,0.5)",
            }}
          >
            chaos
          </span>{" "}
          to focus.
        </h2>
        <p
          style={{
            fontSize: 16,
            color: "rgba(255,255,255,0.55)",
            maxWidth: 520,
            margin: "20px auto 0",
            lineHeight: 1.6,
          }}
        >
          Watch your Dock shed 25+ apps and keep only what the mode needs. No manual cleanup. No distractions.
        </p>
      </div>

      <div
        style={{
          position: "relative",
          borderRadius: 20,
          overflow: "hidden",
          background: `
            radial-gradient(ellipse 70% 40% at 50% 15%, ${mode.tint}22 0%, transparent 60%),
            linear-gradient(180deg, #1a1a1f 0%, #0a0a0c 100%)
          `,
          border: "1px solid rgba(255,255,255,0.06)",
          minHeight: 170,
          padding: "18px 20px 20px",
          transition: "background 700ms",
          maxWidth: 1100,
          margin: "0 auto",
        }}
      >
        <div
          style={{
            position: "absolute",
            top: 18,
            left: "50%",
            transform: "translateX(-50%)",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            zIndex: 2,
            pointerEvents: "none",
          }}
        >
          <div style={{ display: "flex", alignItems: "center" }}>
            {MODES.slice(0, 3).map((m, i) => {
              const isActive = modeSelected && i === active;
              return (
                <div
                  key={m.id}
                  style={{
                    marginLeft: i === 0 ? 0 : -10,
                    transition: "transform 500ms cubic-bezier(.22,.9,.3,1), filter 500ms, opacity 500ms",
                    transform: isActive ? "translateY(-2px) scale(1.18)" : "scale(0.86)",
                    zIndex: isActive ? 3 : 1,
                  }}
                >
                  <div style={{ position: "relative" }}>
                    <div
                      style={{
                        position: "absolute",
                        inset: -10,
                        borderRadius: "50%",
                        background: `radial-gradient(circle, ${m.tint}66 0%, transparent 60%)`,
                        opacity: isActive ? 1 : 0,
                        transition: "opacity 500ms",
                        filter: "blur(8px)",
                        pointerEvents: "none",
                      }}
                    />
                    <img
                      src={m.img}
                      alt={m.label}
                      style={{
                        width: 40,
                        height: 40,
                        objectFit: "contain",
                        position: "relative",
                        zIndex: 2,
                        display: "block",
                        filter: isActive
                          ? `drop-shadow(0 6px 14px ${m.tint}99) drop-shadow(0 0 6px ${m.tint}55)`
                          : "grayscale(0.7) brightness(0.65)",
                        opacity: isActive ? 1 : 0.55,
                        transition: "all 500ms",
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
          <div
            style={{
              marginTop: 10,
              fontFamily: "var(--font-playfair), Georgia, serif",
              fontStyle: "italic",
              fontWeight: 400,
              fontSize: 14,
              letterSpacing: -0.2,
              color: modeSelected ? mode.tint : "rgba(255,255,255,0.3)",
              transition: "color 500ms, opacity 500ms",
              opacity: modeSelected ? 1 : 0.5,
              minHeight: 18,
            }}
          >
            {modeSelected ? `${mode.label} mode` : "Pick a mode"}
          </div>
        </div>

        <div
          style={{
            position: "absolute",
            bottom: 20,
            left: 0,
            right: 0,
            display: "flex",
            justifyContent: "center",
            pointerEvents: "none",
            padding: "0 20px",
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexWrap: "nowrap",
              padding: "6px 10px",
              background: "rgba(60,60,70,0.5)",
              backdropFilter: "blur(28px) saturate(180%)",
              WebkitBackdropFilter: "blur(28px) saturate(180%)",
              borderRadius: 14,
              border: "1px solid rgba(255,255,255,0.1)",
              boxShadow: "0 20px 60px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.15)",
              transition: "padding 600ms cubic-bezier(.22,.9,.3,1)",
              maxWidth: "100%",
            }}
          >
            {CLUTTER_APPS.map((appName, i) => {
              const isEssential = essentials.includes(appName);
              const isVisible = !cleaning || isEssential;
              const isLast = i === CLUTTER_APPS.length - 1;

              const dropY = 18 + ((i * 7) % 14);
              const dropRotate = ((i * 13) % 40) - 20;

              const staggerMs = i * 4;

              return (
                <div
                  key={appName}
                  style={{
                    flexShrink: 0,
                    width: isVisible ? ICON_SIZE : 0,
                    marginRight: isVisible ? (isLast ? 0 : SLOT_SPACING) : 0,
                    opacity: isVisible ? 1 : 0,
                    transform: isVisible
                      ? "translateY(0) scale(1) rotate(0deg)"
                      : `translateY(${dropY}px) scale(0.3) rotate(${dropRotate}deg)`,
                    transformOrigin: "center bottom",
                    transition: [
                      `width 520ms cubic-bezier(.4,0,.2,1) ${staggerMs}ms`,
                      `margin-right 520ms cubic-bezier(.4,0,.2,1) ${staggerMs}ms`,
                      `opacity 360ms ease ${staggerMs}ms`,
                      `transform 520ms cubic-bezier(.4,0,.2,1) ${staggerMs}ms`,
                    ].join(", "),
                    overflow: "visible",
                    pointerEvents: "none",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    height: ICON_SIZE,
                  }}
                >
                  <BrandIcon name={appName} size={ICON_SIZE} />
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}
