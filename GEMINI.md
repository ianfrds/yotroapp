# Project Rules & Invariants: Money Tracker

## 1. Automatic `context.md` Synchronization (MANDATORY)
Whenever any file is created, modified, deleted, or refactored in this project (including `lib/`, `web/`, `.github/`, `pubspec.yaml`, or project configs):
1. **Immediate Sync:** The AI agent MUST update `context.md` before concluding the response or turn.
2. **What to Update in `context.md`:**
   - **Section 2 (Codebase Map):** Reflect newly created, deleted, or renamed files.
   - **Section 3 (Feature & Business Logic):** Update specifications if behavior, models, or provider methods changed.
   - **Section 6 (Checklist & Status):** Mark completed items `[x]`, add new tasks or active roadmap items.
   - **Section 7 (Handover Notes):** Record critical context for the next AI session or model handover.
3. **Parity Invariant:**
   - Maintain 100% parity between Flutter code (`lib/`) and the standalone Web Runner (`web/index.html`).
   - If UI visual tokens, colors, or components change, update `design.md` alongside `context.md`.

---

## 2. Design System & Anti-Slop Enforcement
- **No Decorative Emojis:** Never use decorative emojis in user-facing UI copy, buttons, or category icons. Use clean geometric vector icons (Lucide / Material icons).
- **Typography Pairing:**
  - `Inter Tight`: Bold display financial amounts, total balance, metric values, and prominent headings.
  - `Manrope`: Body copy, subheadings, date/wallet chips, form labels, and navigation.
- **Color Discipline:** Stick strictly to the dark matte slate/sapphire palette (`#09101C`, `#0B2244`, `#121620`, `#181C26`). Avoid generic AI purple/pink gradients outside the designated hero card.

---

## 3. Financial Core Invariants
- **Transfer Neutrality:** Transaksi bertipe `transfer` WAJIB netral (memindahkan saldo antar-dompet tanpa menambah atau mengurangi total pemasukan/pengeluaran global).
- **Budget Thresholds:** Peringatan visual wajib aktif saat pengeluaran mencapai 80% (amber/warning) dan 100% (merah/danger).
- **Data Persistence:** Seluruh perubahan transaksi, dompet, kategori, dan budget wajib diserialisasikan ke penyimpanan lokal (`SharedPreferences` di Flutter, `localStorage` di Web).
- **Restore Safety:** Restore data wajib memvalidasi format JSON dan menyediakan pilihan `Merge Data` atau `Replace Data`.

---

## 4. Persona & Communication
- Pertahankan gaya komunikasi cerdas dan ringkas (*terse smart caveman*): langsung ke jawaban teknis, tanpa basa-basi, pertahankan semua tautan berkas `file://` dan blok kode verbatim.

