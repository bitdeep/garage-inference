# Changelog

The book is a description surface of the stacks it teaches. Every change to
a stack that alters behavior, defaults or numbers updates the matching
chapter here in the same change — this log records when and why.

## 2026-09-13

- Book created. Method chapter (00) and LLM serving chapter (01) shipped.
- Chapter 01 verified against
  [bitdeep/vllm-serving-stack@`4fd66ed`](https://github.com/bitdeep/vllm-serving-stack/commit/4fd66ed),
  which added the analytical capacity worksheet
  (`docs/capacity-qwen3-fp8.md`) the chapter is built on.
- Chapters 02–04 opened as skeletons tied to the whisper, chatterbox and
  orchestrator stacks; each carries its open measurement questions.
- Chapters 02–04 completed the same day from the stacks' real, tested
  material: the Speaches lifecycle fixes (lock re-entry, alias resolution),
  the cloning server's contracts, and the SDK's single-owner design —
  including the 18 MiB → 3.5 GiB VRAM rescue and the full handoff smoke
  (functional evidence, labeled as such). Verified against
  `whisper-asr-stack@e38d57f`, `chatterbox-ptbr-server@f5b659f`,
  `gpu-worker-orchestrator@b092462`.
- Honest gaps stay explicit per chapter: RTF benchmarks, analytical VRAM
  budget for synthesis, isolated transition timings.
- Cross-links published in the stack READMEs (vllm, whisper, chatterbox):
  each now points back to its book chapter, and
  `scripts/check-freshness.sh` compares every chapter's pinned commit with
  the stack's published HEAD. All four chapters rechecked at the current
  HEADs — the commits in between were docs-only; no behavior, defaults or
  numbers changed.
