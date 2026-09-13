# 01 · LLM serving: Qwen3-8B FP8 on a 24 GB GPU

How to shape a local OpenAI-compatible endpoint so it fits a single
prosumer card, keeps its promises under concurrency, and knows how close it
runs to the silicon's limits. The running recipe is
[bitdeep/vllm-serving-stack](https://github.com/bitdeep/vllm-serving-stack)
(vLLM pinned by digest, Qwen3-8B, FP8 weights and KV cache).

## Step 1 — Weigh the model

An 8-billion-parameter model is not "8 GB". Its real bill is:

- **Weights**: parameters × bytes per parameter. FP8 → 8.19 GB. BF16 →
  16.38 GB, already 68% of a 24 GB card before a single token exists.
- **KV cache**: the context tax. For Qwen3-8B it is 72 KiB per token in
  FP8 (144 KiB in BF16) — a constant you pay for *every* token of *every*
  concurrent sequence.

FP8 is not a rounding trick here. Quantizing weights **and** KV cache
roughly halves both terms of the bill, and that is exactly what turns
"fits with no room" into "fits with a usable pool".

## Step 2 — Price the context

Multiply the tax: one sequence at the 24,576-token context costs 1.81 GB;
eight of them cost 14.50 GB. Add the weights and the worst case is ~22.7 GB
on a 24 GB card. This single multiplication explains every default in the
recipe:

| Setting | Value | Why |
|---|---|---|
| `QUANTIZATION` / `KV_CACHE_DTYPE` | `fp8` | halves weights and context tax |
| `MAX_MODEL_LEN` | 24576 | caps the per-sequence worst case |
| `MAX_NUM_SEQS` | 8 | caps the concurrency multiplier |
| `GPU_MEMORY_UTILIZATION` | 0.50 | leaves the rest of the card for ASR/TTS co-tenants |

The subtle part: `MAX_NUM_SEQS` is a **scheduler cap, not a capacity
promise**. At full context, eight sequences need utilization ≈ 0.95; at
0.50 the pool honestly holds ~2 full-length sequences or 8 comfortably
shorter ones. Knowing which knob buys back concurrency when traffic gets
long-context is the difference between tuning and guessing.

`--enforce-eager` gives up CUDA-graph speedups for a predictable memory
footprint — the right trade when the budget must stay honest and the card
has co-tenants.

## Step 3 — Know your ceiling before you benchmark

One decode step (batch 8, full context) must move ~22.7 GB through HBM
against 237 GFLOPs of math — an arithmetic intensity of ~10 FLOPs/byte on a
GPU whose ridge point is ~655. **Decode is 63× closer to being a bandwidth
problem than a compute problem**:

- ceiling ≈ 22.5 ms per step → **~355 tok/s aggregate, ~44 tok/s per
  sequence**
- single stream, short context: weights dominate → **~123 tok/s ceiling**

Prefill flips the sign: an 8k prompt is ~134 TFLOPs of tensor-core work
against ~15 ms of weight reads — compute-bound, and the reason long prompts
stall generation for everyone in the batch.

These ceilings are first-principles bounds (official peak, efficiency 1.0),
not measurements. That is the point: they are the fixed yardstick your
measured numbers chase.

## Step 4 — Measure and publish the gap

Benchmark your workload and log tokens/second next to the ceiling. The
workspace traffic, scheduler overhead and non-matrix work that keep you at
70–90% of the bound are exactly what tuning (chunked prefill, prefix
reuse, schedule policy) can attack next — and the gap tells you when
you are done.

The full budget tables, utilization scenarios and recomputation commands
live in the stack repo:
[docs/capacity-qwen3-fp8.md](https://github.com/bitdeep/vllm-serving-stack/blob/main/docs/capacity-qwen3-fp8.md).

---

**Status:** verified against [bitdeep/vllm-serving-stack@`0338342`](https://github.com/bitdeep/vllm-serving-stack/commit/0338342) · 2026-09-13 · numbers recomputed from pinned calculator, not measured on silicon (that is your Step 4).
