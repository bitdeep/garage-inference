# 00 · Method: budget → design → measure → gap

Everything in this book uses the same loop, borrowed from computer
architecture and applied to home GPUs:

1. **Budget.** Before running anything, compute what the workload costs in
   the two currencies that matter: bytes resident (what must fit in VRAM)
   and bytes moved (what limits your speed). For an LLM this is weights +
   KV cache; for speech models it is weights + audio workspace.
2. **Design.** Choose settings so the worst case fits the card: context
   length × concurrency × per-sequence cost ≤ the memory you are willing to
   give up. Make the trade explicit instead of discovering it under load.
3. **Measure.** Run the real workload and record tokens/second, latency
   percentiles and memory counters. A number without its workload is
   marketing.
4. **Publish the gap.** Compare measurement against the physical ceiling
   (a bandwidth roofline for decode, a compute roofline for prefill). The
   gap is not embarrassment — it is the only honest map of what tuning can
   still buy.

## The tools

- **The [ai-infra-book calculator](https://github.com/bojieli/ai-infra-book)** —
  open-source, pure-Python tool that derives weights, KV cache and per-step
  FLOPs from official model configs, plus rooflines from official hardware
  specs. We pin a commit and publish the exact commands next to every number.
- **Roofline in one line:** time ≥ max(FLOPs ÷ peak FLOPs/s, bytes ÷
  bandwidth). Whichever term wins names your bottleneck. Home GPUs win at
  bandwidth; decode almost always loses to it.

## Rules of thumb the book uses

- Decode is **bandwidth-bound**: every generated token re-reads the weights
  and the whole visible context. Context and concurrency are paid on every
  single token.
- Prefill is **compute-bound**: processing a prompt is tensor-core work;
  the weights are read once.
- KV cache is the **context tax**: it grows with sequence length × batch,
  and quantizing it halves the bill at a small quality cost you should
  measure for your task.
- Sharing one GPU between models is a **lifecycle problem**, not a memory
  problem: the hard part is who unloads, when, without deadlocking.
