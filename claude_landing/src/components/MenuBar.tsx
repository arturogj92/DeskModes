export interface MenuBarProps {
  dark?: boolean;
}

export function MenuBar({ dark = true }: MenuBarProps) {
  const bg = dark ? "rgba(28,28,30,0.65)" : "rgba(245,245,247,0.75)";
  const fg = dark ? "rgba(255,255,255,0.92)" : "rgba(0,0,0,0.85)";
  const sub = dark ? "rgba(255,255,255,0.55)" : "rgba(0,0,0,0.5)";

  return (
    <div
      style={{
        height: 26,
        width: "100%",
        backdropFilter: "blur(20px)",
        WebkitBackdropFilter: "blur(20px)",
        background: bg,
        color: fg,
        display: "flex",
        alignItems: "center",
        padding: "0 12px",
        fontSize: 12,
        fontWeight: 500,
        gap: 14,
        borderBottom: `1px solid ${dark ? "rgba(255,255,255,0.06)" : "rgba(0,0,0,0.08)"}`,
      }}
    >
      <div style={{ display: "flex", alignItems: "center", gap: 10, flex: 1 }}>
        <span style={{ fontWeight: 700 }}>{"\uF8FF"}</span>
        <span style={{ fontWeight: 600 }}>Finder</span>
        <span style={{ color: sub }}>File</span>
        <span style={{ color: sub }}>Edit</span>
        <span style={{ color: sub }}>View</span>
        <span style={{ color: sub }}>Window</span>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 10, color: sub }}>
        <img
          src="/images/MenuBarIcon.png"
          alt="DeskModes"
          style={{
            width: 16,
            height: 16,
            objectFit: "contain",
            filter: dark ? "invert(1) brightness(1.5)" : "none",
            opacity: 0.85,
          }}
        />
        <svg width="22" height="11" viewBox="0 0 22 11" fill="none">
          <rect x="0.5" y="0.5" width="18" height="10" rx="2.5" stroke={fg} strokeOpacity="0.85" fill="none" />
          <rect x="2" y="2" width="15" height="7" rx="1.2" fill={fg} fillOpacity="0.85" />
          <rect x="19.5" y="3.5" width="1.8" height="4" rx="0.6" fill={fg} fillOpacity="0.6" />
        </svg>
        <svg width="14" height="11" viewBox="0 0 14 11" fill="none">
          <path
            d="M7 9.2 a0.9 0.9 0 1 1 0 0.01"
            stroke={fg}
            strokeOpacity="0.9"
            strokeWidth="1.1"
            fill={fg}
            fillOpacity="0.9"
          />
          <path
            d="M3.8 6.3 C 5.6 4.8, 8.4 4.8, 10.2 6.3"
            stroke={fg}
            strokeOpacity="0.85"
            strokeWidth="1.2"
            strokeLinecap="round"
            fill="none"
          />
          <path
            d="M1.8 4 C 4.8 1.3, 9.2 1.3, 12.2 4"
            stroke={fg}
            strokeOpacity="0.7"
            strokeWidth="1.2"
            strokeLinecap="round"
            fill="none"
          />
        </svg>
        <span>Wed 21 Apr  14:02</span>
      </div>
    </div>
  );
}
