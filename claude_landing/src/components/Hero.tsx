"use client";

import { useEffect, useState } from "react";
import { MODES } from "@/lib/modes";
import { MacBook } from "./MacBook";
import { ModeSelector } from "./ModeSelector";

export function Hero() {
  const [active, setActive] = useState(0);
  const [touched, setTouched] = useState(0);
  const mode = MODES[active];

  useEffect(() => {
    const id = setInterval(() => {
      if (Date.now() - touched > 6000) {
        setActive((a) => (a + 1) % 3);
      }
    }, 5000);
    return () => clearInterval(id);
  }, [touched]);

  const pick = (i: number) => {
    setActive(i);
    setTouched(Date.now());
  };

  return (
    <div
      style={{
        background: "#0c0c0e",
        color: "#fff",
        minHeight: "100vh",
        overflow: "hidden",
        position: "relative",
      }}
    >
      <div
        style={{
          position: "absolute",
          top: -200,
          left: "50%",
          transform: "translateX(-50%)",
          width: 1200,
          height: 800,
          borderRadius: "50%",
          background: `radial-gradient(circle, ${mode.tint}33 0%, transparent 60%)`,
          filter: "blur(100px)",
          transition: "background 800ms ease",
          zIndex: 0,
          pointerEvents: "none",
        }}
      />

      <header
        style={{
          position: "relative",
          zIndex: 10,
          padding: "16px 40px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          maxWidth: 1360,
          margin: "0 auto",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10, fontSize: 15, fontWeight: 600 }}>
          <img src="/images/AppIcon.png" alt="DeskModes" style={{ width: 26, height: 26, borderRadius: 6 }} />
          DeskModes
        </div>
        <nav style={{ display: "flex", gap: 32, fontSize: 14, color: "rgba(255,255,255,0.55)" }}>
          <a href="#modes" style={{ color: "inherit", textDecoration: "none" }}>
            Modes
          </a>
          <a href="#pricing" style={{ color: "inherit", textDecoration: "none" }}>
            Pricing
          </a>
          <a href="#about" style={{ color: "inherit", textDecoration: "none" }}>
            About
          </a>
        </nav>
        <a
          href="#get"
          style={{
            padding: "9px 18px",
            borderRadius: 999,
            background: "#fff",
            color: "#000",
            fontSize: 13,
            fontWeight: 600,
            textDecoration: "none",
          }}
        >
          Get DeskModes
        </a>
      </header>

      <section
        style={{
          position: "relative",
          zIndex: 2,
          maxWidth: 1280,
          margin: "0 auto",
          padding: "20px 40px 40px",
        }}
      >
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gridTemplateRows: "auto auto",
            columnGap: 56,
            rowGap: 20,
            alignItems: "start",
          }}
        >
          <div style={{ gridColumn: 1, gridRow: "1 / span 2", alignSelf: "center" }}>
            <h1
              style={{
                fontFamily: "var(--font-playfair), Georgia, serif",
                fontWeight: 400,
                fontSize: 60,
                lineHeight: 1,
                letterSpacing: -1.5,
                margin: 0,
              }}
            >
              One Mac.
              <br />
              <em
                style={{
                  color: mode.tint,
                  fontStyle: "italic",
                  fontWeight: 400,
                  transition: "color 500ms",
                }}
              >
                Every
              </em>{" "}
              mode.
            </h1>
            <p
              style={{
                fontSize: 16,
                color: "rgba(255,255,255,0.65)",
                lineHeight: 1.5,
                margin: "18px 0 22px",
                maxWidth: 440,
              }}
            >
              A focused workspace isn&apos;t 40 open apps. It&apos;s the <em>right</em> six. DeskModes switches your Mac
              into the mode you need in one second.
            </p>
            <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
              <a
                href="#try"
                style={{
                  padding: "12px 20px",
                  borderRadius: 999,
                  background: "#fff",
                  color: "#000",
                  fontSize: 14,
                  fontWeight: 600,
                  textDecoration: "none",
                }}
              >
                Try free for 3 days
              </a>
              <a
                href="#buy"
                style={{
                  padding: "12px 20px",
                  borderRadius: 999,
                  background: "transparent",
                  color: "#fff",
                  fontSize: 14,
                  fontWeight: 500,
                  textDecoration: "none",
                  border: "1px solid rgba(255,255,255,0.2)",
                }}
              >
                Buy · $3
              </a>
            </div>
          </div>

          <div style={{ position: "relative", gridColumn: 2, gridRow: 1 }}>
            <MacBook mode={mode} />
            <ModeSelector active={active} onPick={pick} />
          </div>

          <div style={{ gridColumn: 2, gridRow: 2 }}>
            <ModesGrid active={active} onPick={pick} />
          </div>
        </div>
      </section>
    </div>
  );
}

function ModesGrid({ active, onPick }: { active: number; onPick: (i: number) => void }) {
  return (
    <div>
      <div
        style={{
          fontSize: 11,
          color: "rgba(255,255,255,0.4)",
          letterSpacing: 3,
          textTransform: "uppercase",
          textAlign: "center",
          marginBottom: 18,
        }}
      >
        Four modes
      </div>
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: 12,
        }}
      >
        {MODES.slice(0, 4).map((m, i) => {
          const isActive = i === active;
          const title = m.id === "yours" ? "Make it yours" : `${m.label} Mode`;
          const description =
            m.id === "yours"
              ? "Build your own. Pick the apps, name it, save it."
              : m.brief;
          return (
            <div
              key={m.id}
              onMouseEnter={() => onPick(i)}
              onClick={() => onPick(i)}
              style={{
                position: "relative",
                padding: "16px 16px 18px",
                borderRadius: 14,
                cursor: "pointer",
                background: isActive
                  ? `linear-gradient(180deg, ${m.tint}14 0%, rgba(255,255,255,0.02) 100%)`
                  : "rgba(255,255,255,0.02)",
                border: `1px solid ${isActive ? `${m.tint}55` : "rgba(255,255,255,0.06)"}`,
                boxShadow: isActive
                  ? `0 20px 50px -20px ${m.tint}55, inset 0 1px 0 rgba(255,255,255,0.04)`
                  : "inset 0 1px 0 rgba(255,255,255,0.03)",
                transition: "background 300ms, border 300ms, box-shadow 300ms",
                minHeight: 148,
                display: "flex",
                flexDirection: "column",
              }}
            >
              <img
                src={m.img}
                alt={m.label}
                style={{
                  width: 38,
                  height: 38,
                  objectFit: "contain",
                  filter: isActive
                    ? `drop-shadow(0 10px 20px ${m.tint}66)`
                    : "drop-shadow(0 6px 14px rgba(0,0,0,0.35))",
                  marginBottom: 10,
                  transition: "filter 300ms",
                }}
              />
              <div
                style={{
                  fontSize: 16,
                  fontWeight: 600,
                  letterSpacing: -0.3,
                  marginBottom: 6,
                }}
              >
                {title}
              </div>
              <div
                style={{
                  fontSize: 12,
                  lineHeight: 1.5,
                  color: "rgba(255,255,255,0.55)",
                  flex: 1,
                }}
              >
                {description}
              </div>
              <div
                style={{
                  marginTop: 14,
                  fontSize: 11,
                  color: isActive ? m.tint : "rgba(255,255,255,0.35)",
                  fontFamily: "'SF Mono', Menlo, monospace",
                  letterSpacing: 0.5,
                  transition: "color 300ms",
                }}
              >
                #{i + 1}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
