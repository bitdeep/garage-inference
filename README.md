# garage-inference

**Build a real AI stack at home: one prosumer GPU running a language model, speech-to-text and voice cloning — with first-principles budgets and honest numbers.**

Most local-AI content stops at "it runs". This book is about the next step that nobody shows: *why* a serving recipe is shaped the way it is, what each setting costs in bytes and milliseconds, and how far your measured throughput is from what the hardware physically allows. The method is one line:

> **Budget before you build. Measure after you ship. Publish the gap.**

Every chapter is written from stacks that actually run — the same Docker Compose recipes, the same lifecycle code, the same GPU. When the stacks change, the chapters change. That is what "living" means here: the book is a description surface of working software, not a snapshot of good intentions.

## Chapters

| # | Chapter | Status |
|---|---|---|
| 00 | [Method: budget → design → measure → gap](00-method/README.md) | shipped |
| 01 | [LLM serving: Qwen3-8B FP8 on 24 GB](01-llm-serving/README.md) | shipped |
| 02 | [Speech-to-text: faster-whisper without deadlocks](02-speech-to-text/README.md) | shipped |
| 03 | [Voice cloning: pt-BR TTS that shares the GPU](03-voice-cloning/README.md) | shipped |
| 04 | [GPU lifecycle: one card, three models, zero surprises](04-gpu-lifecycle/README.md) | shipped |

## The stacks this book is written from

- [bitdeep/vllm-serving-stack](https://github.com/bitdeep/vllm-serving-stack) — vLLM, Qwen3-8B, FP8 weights and KV cache, explicit memory budget.
- [bitdeep/whisper-asr-stack](https://github.com/bitdeep/whisper-asr-stack) — Speaches + faster-whisper with tested unload fixes.
- [bitdeep/chatterbox-ptbr-server](https://github.com/bitdeep/chatterbox-ptbr-server) — Chatterbox Multilingual voice cloning for Brazilian Portuguese.
- [bitdeep/gpu-worker-orchestrator](https://github.com/bitdeep/gpu-worker-orchestrator) — the TypeScript SDK that owns the GPU lifecycle across all of the above.

Each chapter links to the exact commit it was verified against. Quantitative budgets are computed with the open-source [ai-infra-book calculator](https://github.com/bojieli/ai-infra-book) — pure Python, no GPU needed — and every number in this book can be recomputed from the pinned commands we publish.

## How this book stays alive

- Every shipped chapter ends with a **status line**: the stack commit and date it was verified against.
- `scripts/check-freshness.sh` compares each pinned commit with the stack's published HEAD. Drift is a prompt to review, not an error: docs-only commits don't invalidate a chapter; behavior, default or number changes trigger the chapter update.
- A change to a stack that alters behavior, defaults or measured numbers updates its chapter in the same change, with a [CHANGELOG](CHANGELOG.md) entry. Description drift is treated as a bug.
- Skeletons are labeled as skeletons. No chapter ships numbers that were not recomputed or measured for it.

## Work with me

I build self-hosted inference: memory budgeting, model lifecycle, API boundaries and deployment validation. For consulting or engineering opportunities, [contact bitdeep on X](https://x.com/_wrbr).

## License

[MIT](LICENSE)
