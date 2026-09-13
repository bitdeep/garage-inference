# 04 · GPU lifecycle: one card, three models, zero surprises

Running each model successfully does not mean they fit **together**. This
chapter is about the layer that makes an LLM, a transcription service and a
voice engine share one GPU without stepping on each other. The running code
is [bitdeep/gpu-worker-orchestrator](https://github.com/bitdeep/gpu-worker-orchestrator)
(`@bitdeep/inference-sdk`, TypeScript, zero runtime dependencies).

## The bug that motivates everything

In an integration smoke of the full pipeline, adding Whisper large-v3 next
to the resident vLLM, Kokoro and Qwen3 engines left **~18 MiB free** on the
tighter reference machine — the next allocation would simply die. The fix
was not more VRAM: the SDK now releases Whisper before heavy synthesis,
*inside the same GPU lock*. Same card, same models; after the fix the same
scenario keeps **~3.5 GiB free**. That ~3.5 GB gap is the entire value of
lifecycle discipline, measured.

## The design: one owner, one lock

- **Every GPU operation goes through one process-local queue** — chat,
  transcription, synthesis, idle sweeps, batch jobs. A failed request
  releases the queue, so one crash cannot wedge the card.
- **The idle timer shares the lock with generation.** An idle unload
  cannot interrupt a long generation halfway, because the sweep cannot
  run while a request holds the lock. (Without this, your power-saving
  feature kills your slowest requests.)
- **Acquisition order is designed, not accidental.** Cloning needs a
  reference transcript; when absent, the SDK transcribes the reference
  *before* acquiring the synthesis lock — avoiding recursive acquisition.
  Heavy voices yield before ASR; unload failure stops the synthesis path
  instead of stacking another model on a card that may not have room.
- **Request parameters stay requests.** An app-requested `voice` overrides
  the engine's configured default, and the response reports the voice
  actually sent; engine defaults apply only when the request is silent
  (SDK 0.1.3).

```
App → SDK: synthesize(reference_audio)
SDK → ASR: transcribe reference (VAD-filtered)
SDK → ASR: unload resident model
SDK → TTS: start engine, wait for readiness (503→200)
SDK → TTS: register reference, synthesize
```

Weights stay cached on disk; only *residency* moves. Reloading is a
warm-start, which is why the measured handoffs in chapters 02–03 are
seconds, not minutes.

## Boundaries that stay explicit

| Concern | Owner |
|---|---|
| Auth, queues, retries, customer identity | your application |
| Model requests, VAD gates, lifecycle transitions | the SDK |
| Container allowlist, volumes, real free memory | deployment |
| Public HTTP surface of each stack | the stack recipes (01–03) |

The Docker controller is allowlist-based, but mounting the Docker socket
still grants real host authority — run it in a trusted worker.

## The full loop, measured

Functional smoke — hub → worker → SDK → GPU, synthetic text and speech
only, two reference machines (timings include RPC and engine loads):

| Flow | Machine A | Machine B |
|---|---:|---:|
| Chat (fixed expected answer) | 63 ms | 303 ms |
| Lightweight voice (Kokoro), synthetic reference | 85 ms | 550 ms |
| Voice clone (Chatterbox) | 17.1 s | 24.7 s |
| Whisper → Qwen3 handoff | 18.8 s | 28.0 s |
| New reference: Whisper reload → Qwen3 | 22.5 s | 38.5 s |

Every output was decoded and energy-checked; every unload confirmed by the
engine. Functional evidence of correct sequencing — not a benchmark.

## Still open (measured on purpose)

- Load/unload transition times per model, isolated.
- Sustained mixed workload (chat → transcribe → clone loop) on one card.
- Idle policy vs. reload cost: when keeping a model warm stops paying off.

---

**Status:** verified against [bitdeep/gpu-worker-orchestrator@`fb584c2`](https://github.com/bitdeep/gpu-worker-orchestrator/commit/fb584c2) (SDK 0.1.3; handoff smoke ran on 0.1.1) · 2026-09-13 · transition timings from a functional smoke; isolated per-model measurements pending.
