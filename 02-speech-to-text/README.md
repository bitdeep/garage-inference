# 02 · Speech-to-text: faster-whisper without deadlocks

Speech recognition is usually the *second* model people put on a home GPU —
and the first time they meet a problem LLM tutorials never mention: a model
that must **leave** the GPU on demand, cleanly, while other work waits. The
running recipe is
[bitdeep/whisper-asr-stack](https://github.com/bitdeep/whisper-asr-stack):
Speaches + faster-whisper behind an OpenAI-compatible transcription
endpoint, pinned image, persistent model storage.

## Why unload is a feature, not an admin detail

On a shared card, a transcription server that cannot release its model is a
memory bug waiting for your next workload. Chapter 01's budget assumed the
LLM can use most of the card; that is only true if Whisper actually gets
out of the way. So this stack treats unload as a first-class operation with
real HTTP semantics:

| Situation | Response |
|---|---|
| Model unloaded | `204` |
| Unknown model | `404` |
| Model still in use | `409` |

## Two real bugs this stack fixed upstream

The pinned Speaches base had two defects on its lifecycle route, both
reproduced with tests that fail against the original image and pass against
this project's build ([details](https://github.com/bitdeep/whisper-asr-stack/blob/main/docs/lifecycle.md)):

1. **A lock held across its own callback.** `unload_model()` held the
   manager lock and called the model's `unload()` — whose callback tried to
   acquire the same non-reentrant lock again. The request hung even after
   the model logged that it was unloaded. The fix looks up the model under
   the lock, releases it, *then* unloads; the model's own lock and
   reference count still protect active inference.
2. **Alias resolution on unload.** Transcription resolves `whisper-1` to a
   concrete model ID, but the DELETE route took a plain string — so
   unloading by the documented alias returned `404`. The fix applies the
   same validator, so every route speaks the same identity.

The lesson generalizes: **lifecycle code is concurrency code.** Lock
ordering, re-entrancy and identity resolution are where "it works in the
demo" goes to die. Patch scripts verify upstream source hashes before
touching anything, so a new base image forces a fresh review instead of
silently mis-applying.

## What a real handoff costs

Functional smoke of the full pipeline — transcribe a voice reference, then
hand the GPU to the Qwen3 voice engine (SDK owns the lifecycle, chapter 04),
timings include RPC and engine loads, two reference machines:

| Flow | Machine A | Machine B |
|---|---:|---:|
| Transcribe reference → synthesize with Qwen3 | 18.8 s | 28.0 s |
| Same, with a *new* reference (Whisper reload included) | 22.5 s | 38.5 s |

Speaches logs confirmed `HTTP 200` transcriptions followed by `204` unloads
on every alternation. These are functional evidence that the handoff
completes and memory is released — **not** a WER or throughput benchmark.

## Still open (measured on purpose)

- Real-time factor per Whisper size on the reference GPU.
- Time from `DELETE /api/ps` to VRAM actually free.
- Queueing behavior when transcription competes with synthesis.

---

**Status:** verified against [bitdeep/whisper-asr-stack@`4fd89e7`](https://github.com/bitdeep/whisper-asr-stack/commit/4fd89e7) · 2026-09-13 · lifecycle fixes covered by regression tests; handoff timings from a functional smoke, not a benchmark.
