import type { Metadata, Viewport } from "next";
import { Playfair_Display } from "next/font/google";
import "./globals.css";

const playfair = Playfair_Display({
  subsets: ["latin"],
  weight: ["400"],
  style: ["normal", "italic"],
  variable: "--font-playfair",
  display: "swap",
});

export const metadata: Metadata = {
  title: "DeskModes — One Mac. Every mode.",
  description:
    "A focused workspace isn't 40 open apps. It's the right six. DeskModes switches your Mac into the mode you need in one second.",
  keywords: ["macOS", "productivity", "focus", "apps", "workspace", "utility"],
  authors: [{ name: "DeskModes" }],
  openGraph: {
    title: "DeskModes — One Mac. Every mode.",
    description:
      "Switch modes to close clutter, open the right apps, and stay focused automatically.",
    type: "website",
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title: "DeskModes — One Mac. Every mode.",
    description:
      "Switch modes to close clutter, open the right apps, and stay focused automatically.",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#0c0c0e",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={playfair.variable}>
      <body>{children}</body>
    </html>
  );
}
