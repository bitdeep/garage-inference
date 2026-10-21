# Changelog

The book is a description surface of the stacks it teaches. Every change to
a stack that alters behavior, defaults or numbers updates the matching
chapter here in the same change — this log records when and why.

## 2026-10-20

- Chapter 04 now describes the optional resident engine pair in SDK 0.1.5,
  revision `539f365`. Audio can advance during LLM generation. Model
  lifecycle operations remain exclusive. The chapter separates the new
  contract tests from the older functional smoke timings.

## 2026-09-16

- Models the stacks run (Qwen3-8B, faster-whisper small and large-v3,
  Chatterbox pt-BR, Kokoro, Qwen3-TTS) published as a
  [Hugging Face collection](https://huggingface.co/collections/bitdeep/garage-inference-self-hosted-ai-on-one-24-gb-gpu),
  each note linking back to its stack and chapter; linked from the README.
  Docs-only: no chapter, default or number changed.

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
- First living-loop cycle completed end to end: the SDK shipped
  [v0.1.3](https://github.com/bitdeep/gpu-worker-orchestrator/releases/tag/v0.1.3)
  (requested `voice` now overrides the engine default, with tests), the
  orchestrator README linked chapter 04, and this book recorded the
  behavior change in the same session.
