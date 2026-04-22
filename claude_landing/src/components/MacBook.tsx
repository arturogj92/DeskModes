import { BrandIcon } from "./BrandIcon";
import { MenuBar } from "./MenuBar";
import { Window } from "./Window";
import { V2_DESKTOPS, type Mode } from "@/lib/modes";

export interface MacBookProps {
  mode: Mode;
}

export function MacBook({ mode }: MacBookProps) {
  const desktop = mode.id === "global" ? V2_DESKTOPS.work : V2_DESKTOPS[mode.id];

  return (
    <div style={{ width: "100%" }}>
      <div
        style={{
          background: "linear-gradient(180deg, #2a2a2d 0%, #1a1a1d 100%)",
          borderRadius: "14px 14px 0 0",
          padding: "8px 8px 0",
          boxShadow: "0 0 0 1px rgba(255,255,255,0.06), 0 30px 80px rgba(0,0,0,0.6)",
          position: "relative",
        }}
      >
        <div
          style={{
            position: "absolute",
            top: 0,
            left: "50%",
            transform: "translateX(-50%)",
            width: "18%",
            height: 14,
            background: "#0a0a0c",
            borderRadius: "0 0 10px 10px",
            zIndex: 4,
          }}
        />
        <div
          style={{
            aspectRatio: "16 / 10",
            borderRadius: "6px 6px 0 0",
            overflow: "hidden",
            background: "#000",
            position: "relative",
          }}
        >
          <div
            key={`wp-${mode.id}`}
            style={{
              position: "absolute",
              inset: 0,
              background: `
                radial-gradient(ellipse 70% 50% at 50% 30%, ${mode.tint}30 0%, transparent 55%),
                linear-gradient(180deg, oklch(0.2 0.035 ${desktop.wallpaperHue}) 0%, oklch(0.08 0.015 ${desktop.wallpaperHue}) 100%)
              `,
              transition: "background 700ms",
            }}
          />
          <div style={{ position: "relative", zIndex: 2 }}>
            <MenuBar />
          </div>
          <div key={`wins-${mode.id}`} style={{ position: "absolute", inset: 0 }}>
            {desktop.windows.map((w, i) => (
              <Window key={i} win={w} idx={i} />
            ))}
          </div>
          <div
            style={{
              position: "absolute",
              bottom: 7,
              left: "50%",
              transform: "translateX(-50%)",
              display: "flex",
              alignItems: "center",
              gap: 5,
              padding: 4,
              background: "rgba(40,40,45,0.55)",
              backdropFilter: "blur(16px)",
              WebkitBackdropFilter: "blur(16px)",
              borderRadius: 10,
              border: "1px solid rgba(255,255,255,0.12)",
              zIndex: 5,
            }}
          >
            {desktop.dockApps.map((a) => (
              <BrandIcon key={a} name={a} size={22} />
            ))}
          </div>
        </div>
      </div>
      <div
        style={{
          height: 11,
          background: "linear-gradient(180deg, #cfcfd4 0%, #9a9aa0 100%)",
          borderRadius: "0 0 8px 8px",
          margin: "0 -3%",
          position: "relative",
        }}
      >
        <div
          style={{
            position: "absolute",
            top: 0,
            left: "50%",
            transform: "translateX(-50%)",
            width: "16%",
            height: 3,
            background: "#777",
            borderRadius: "0 0 5px 5px",
          }}
        />
      </div>
    </div>
  );
}
