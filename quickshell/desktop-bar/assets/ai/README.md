# AI Provider Marks

These are upstream brand assets, not generic glyphs or original artwork.

- `claude.svg`: Claude's SVG favicon, downloaded from
  https://assets-proxy.anthropic.com/claude-ai/v2/assets/v1/cd02a42d9-Vq_H3mgS.svg
  and linked by https://claude.ai/.
- `OpenAI-*-monoblossom.svg`: unmodified assets from
  https://cdn.openai.com/brand/OpenAI-Logos-2025.zip.
  Brand guidelines: https://openai.com/brand/.

The OpenAI mark identifies the Codex provider. It is not a distinct Codex logo.
Trademarks remain the property of their respective owners.

Walker resolves `claude-brand` and `codex-brand` through relative
symlinks in `$HOME/.local/share/icons/hicolor/scalable/apps`. Their backup copies
are in `HOME_FILES/.local/share/icons/hicolor/scalable/apps`. Restore those
symlinks along with these assets. Walker's theme generator selects a black or
white OpenAI asset in `walker/themes/current/codex.svg` for contrast; Claude
retains its original brand color.
