# 03 · Voice cloning: pt-BR TTS that shares the GPU

Voice cloning is the workload that makes a home GPU feel like a studio —
and the one with the least honest material online. The running recipe is
[bitdeep/chatterbox-ptbr-server](https://github.com/bitdeep/chatterbox-ptbr-server):
Chatterbox Multilingual V3 behind a small FastAPI service for Brazilian
Portuguese synthesis, built for coexistence on a shared card.

## Anatomy of a cloning request

```
reference.wav ──┐
                ├─► HTTP API ──► Chatterbox (GPU) ──► PCM WAV
"Olá, tudo bem?"┘
```

The pieces that matter:

- **Reference audio is data, not config.** It arrives by upload (WAV/MP3,
  capped at 8 MiB per file), is listed, and lives in a volume separate from
  model weights. Capping and separating inputs is what keeps a synthesis
  service from becoming an accidental file host.
- **Readiness is a contract.** `GET /api/model-info` returns `200` only
  when the model is loaded, `503` while loading or after unload. A
   health check that conflates "process listening" with "model resident"
  makes orchestrators fire requests into cold VRAM.
- **Unload is explicit** (`POST /api/unload`), and the Compose service runs
  with `restart: "no"` — the container's lifecycle belongs to a manager
  (chapter 04), not to Docker's restart policy.
- **Privacy by construction:** the server never logs synthesis text or
  audio, and each trust boundary gets its own instance and reference
  volume.

## What a clone costs today

Functional smoke on two reference machines (timings include RPC; audio
duration checked by decode):

| Flow | Machine A | Machine B |
|---|---:|---:|
| Clone a short sentence (synthesis only) | 17.1 s | 24.7 s |
| Audio produced | 3.9 s | 3.6 s |

Derived from that smoke: roughly **4–7× slower than real time** for a
short cloned sentence — fine for pre-rendered content and notifications,
not yet for live conversation. These are functional evidence, not a
speech-quality or latency benchmark.

## Why the first-principles budget is still open

Unlike the LLM chapter, this stack does not yet publish an analytical
budget, because synthesis models mix encoder, duration model and vocoder
stages whose peak VRAM is not a single multiplication. The stack's own
validation rule says it plainly: validate the peak on your hardware before
sharing the GPU. What we can say from the smoke: cloning coexists with an
FP8 LLM and Whisper **only** when unload discipline works (chapter 02) and
a single owner sequences the transitions (chapter 04).

## Still open (measured on purpose)

- Peak VRAM while resident, and unload latency.
- Time-to-first-audio vs. chunk length for streaming use.
- pt-BR quality knobs: reference length, chunk boundaries.

---

**Status:** verified against [bitdeep/chatterbox-ptbr-server@`f5b659f`](https://github.com/bitdeep/chatterbox-ptbr-server/commit/f5b659f) · 2026-09-13 · timings from a functional smoke; analytical VRAM budget pending.
