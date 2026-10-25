import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Petshop & Klinik Hewan",
  description: "Sistem Operasional Pet Shop dan Klinik Hewan",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="id">
      <body className="antialiased">{children}</body>
    </html>
  );
}