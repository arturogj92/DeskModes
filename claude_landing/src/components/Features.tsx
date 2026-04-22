import React from "react";
import { MODES } from "@/lib/modes";
import { DockCollapseDemo } from "./DockCollapseDemo";
import { CmdTabOverlay } from "./CmdTabOverlay";

export function Features() {
  return (
    <section
      style={{
        background: "#0c0c0e",
        color: "#fff",
        padding: "40px 40px 140px",
      }}
    >
      <div style={{ maxWidth: 1180, margin: "0 auto" }}>
        <div style={{ maxWidth: 800, margin: "0 auto 100px", textAlign: "center", padding: "0 20px" }}>
          <div
            style={{
              fontSize: 12,
              color: "rgba(255,255,255,0.4)",
              letterSpacing: 3,
              textTransform: "uppercase",
              marginBottom: 24,
            }}
          >
            Chapter One
          </div>
          <h2
            style={{
              fontFamily: "var(--font-playfair), Georgia, serif",
              fontWeight: 400,
              fontStyle: "italic",
              fontSize: 56,
              lineHeight: 1.15,
              letterSpacing: -1.5,
              margin: 0,
            }}
          >
            &ldquo;Your Mac slowly turns
            <br />
            into noise.&rdquo;
          </h2>
          <div style={{ marginTop: 24, fontSize: 14, color: "rgba(255,255,255,0.5)" }}>
            Every designer, dev, and founder we talked to said this.
          </div>
        </div>

        <div
          style={{
            position: "relative",
            borderRadius: 24,
            overflow: "hidden",
            marginBottom: 120,
          }}
        >
          <img src="/images/toomuchapps.png" alt="Too many apps" style={{ width: "100%", display: "block" }} />
          <div
            style={{
              position: "absolute",
              inset: 0,
              background:
                "linear-gradient(180deg, transparent 30%, rgba(12,12,14,0.6) 70%, #0c0c0e 100%)",
            }}
          />
          <CmdTabOverlay />
          <div
            style={{
              position: "absolute",
              bottom: 40,
              left: 48,
              right: 48,
              display: "flex",
              justifyContent: "space-between",
              alignItems: "flex-end",
              gap: 40,
            }}
          >
            <div>
              <div
                style={{
                  fontSize: 13,
                  color: "rgba(255,255,255,0.6)",
                  letterSpacing: 2,
                  textTransform: "uppercase",
                  marginBottom: 10,
                }}
              >
                The problem
              </div>
              <h3
                style={{
                  fontSize: 36,
                  fontWeight: 500,
                  letterSpacing: -1,
                  margin: 0,
                  maxWidth: 520,
                }}
              >
                Too many apps. A full Dock. Cmd+Tab chaos.
              </h3>
            </div>
            <div
              style={{
                fontSize: 14,
                color: "rgba(255,255,255,0.55)",
                maxWidth: 320,
                lineHeight: 1.6,
              }}
            >
              Before you can focus, you have to clean everything manually. Every. Single. Day.
            </div>
          </div>
        </div>
      </div>

      <DockCollapseDemo />

      <div style={{ maxWidth: 1180, margin: "0 auto" }}>
        <div style={{ marginBottom: 120 }}>
          <div style={{ textAlign: "center", marginBottom: 32 }}>
            <div
              style={{
                fontSize: 12,
                color: "rgba(255,255,255,0.4)",
                letterSpacing: 3,
                textTransform: "uppercase",
                marginBottom: 16,
              }}
            >
              Chapter Two
            </div>
            <h3
              style={{
                fontFamily: "var(--font-playfair), Georgia, serif",
                fontStyle: "italic",
                fontWeight: 400,
                fontSize: 52,
                lineHeight: 1.1,
                letterSpacing: -1.3,
                margin: 0,
              }}
            >
              Work in modes, not mess.
            </h3>
          </div>
          <div
            style={{
              display: "flex",
              justifyContent: "center",
              alignItems: "center",
              gap: 24,
              flexWrap: "wrap",
            }}
          >
            {MODES.slice(0, 4).map((m) => (
              <img
                key={m.id}
                src={m.img}
                alt={m.label}
                style={{
                  width: 140,
                  height: 140,
                  objectFit: "contain",
                  filter: `drop-shadow(0 16px 28px ${m.tint}66)`,
                }}
              />
            ))}
          </div>
        </div>

        <div
          style={{
            borderRadius: 24,
            padding: "72px 48px",
            textAlign: "center",
            background:
              "radial-gradient(ellipse at 50% 30%, rgba(77,208,225,0.12) 0%, transparent 70%), rgba(255,255,255,0.02)",
            border: "1px solid rgba(255,255,255,0.06)",
          }}
        >
          <div
            style={{
              fontSize: 12,
              color: "rgba(255,255,255,0.4)",
              letterSpacing: 3,
              textTransform: "uppercase",
              marginBottom: 16,
            }}
          >
            Chapter Three
          </div>
          <h3
            style={{
              fontFamily: "var(--font-playfair), Georgia, serif",
              fontStyle: "italic",
              fontWeight: 400,
              fontSize: 52,
              letterSpacing: -1.3,
              margin: "0 0 16px",
            }}
          >
            One click. Clean workspace.
          </h3>
          <p
            style={{
              fontSize: 17,
              color: "rgba(255,255,255,0.55)",
              maxWidth: 520,
              margin: "0 auto 32px",
              lineHeight: 1.6,
            }}
          >
            Closes apps that don&apos;t belong. Opens the ones you need. From the menu bar or a global hotkey.
          </p>
          <div
            style={{
              display: "inline-flex",
              alignItems: "center",
              gap: 6,
              padding: "10px 14px",
              background: "rgba(0,0,0,0.4)",
              borderRadius: 10,
              border: "1px solid rgba(255,255,255,0.1)",
            }}
          >
            {["⌃", "⌥", "⌘", "M"].map((k, i) => (
              <React.Fragment key={i}>
                <kbd
                  style={{
                    minWidth: 30,
                    height: 30,
                    display: "inline-flex",
                    alignItems: "center",
                    justifyContent: "center",
                    background: "rgba(255,255,255,0.08)",
                    border: "1px solid rgba(255,255,255,0.14)",
                    borderRadius: 6,
                    fontSize: 13,
                    fontFamily: "'SF Mono', Menlo, monospace",
                  }}
                >
                  {k}
                </kbd>
                {i < 3 && <span style={{ color: "rgba(255,255,255,0.25)" }}>+</span>}
              </React.Fragment>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
