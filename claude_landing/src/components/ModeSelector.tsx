"use client";

import { MODES } from "@/lib/modes";

export interface ModeSelectorProps {
  active: number;
  onPick: (index: number) => void;
}

export function ModeSelector({ active, onPick }: ModeSelectorProps) {
  return (
    <div
      style={{
        position: "absolute",
        top: -54,
        left: "50%",
        transform: "translateX(-50%)",
        display: "flex",
        alignItems: "center",
        zIndex: 10,
        padding: "0 20px",
      }}
    >
      {MODES.slice(0, 4).map((m, i) => {
        const isActive = i === active;
        return (
          <button
            key={m.id}
            onClick={() => onPick(i)}
            onMouseEnter={() => onPick(i)}
            title={`${m.label} Mode`}
            style={{
              background: "none",
              border: "none",
              padding: 0,
              cursor: "pointer",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              marginLeft: i === 0 ? 0 : -22,
              transition: "transform 400ms cubic-bezier(.22,.9,.3,1)",
              transform: isActive ? "translateY(-6px) scale(1.14)" : "translateY(0) scale(0.9)",
              zIndex: isActive ? 3 : 1,
            }}
          >
            <div style={{ position: "relative" }}>
              <div
                style={{
                  position: "absolute",
                  inset: -20,
                  borderRadius: "50%",
                  background: `radial-gradient(circle, ${m.tint}66 0%, transparent 60%)`,
                  opacity: isActive ? 1 : 0,
                  transition: "opacity 500ms",
                  filter: "blur(14px)",
                  pointerEvents: "none",
                }}
              />
              <img
                src={m.img}
                alt={m.label}
                style={{
                  width: 68,
                  height: 68,
                  objectFit: "contain",
                  position: "relative",
                  zIndex: 2,
                  display: "block",
                  filter: isActive
                    ? `drop-shadow(0 14px 28px ${m.tint}99) drop-shadow(0 0 14px ${m.tint}55)`
                    : "grayscale(0.5) brightness(0.75)",
                  opacity: isActive ? 1 : 0.7,
                  transition: "all 500ms",
                }}
              />
            </div>
          </button>
        );
      })}
    </div>
  );
}
