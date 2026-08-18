# Known issues in the LLM deobfuscation outputs

Status after the regeneration pass. 1508 of 1512 outputs (99.7%) are complete and
well-formed. The 4 exceptions are below.

## 1. DeepSeek capacity limits (3)

These three obfuscated contracts are larger than `deepseek-chat` can restate within
its 8192-token output ceiling. Retried at temperature 0.2, 0.5 and 0.8 — truncated
every time. No output file is written; a partial contract is worse than none.

| File | Obfuscated input |
|---|---|
| `deepseek_outputs/batch_01/batch01_contract_039_obf.sol` | 41,690 chars |
| `deepseek_outputs/batch_01/batch01_contract_104_obf.sol` | 80,229 chars |
| `deepseek_outputs/batch_02/batch02_contract_094_obf.sol` | 48,341 chars |

GPT-4o completed all three (16384-token ceiling). To close the gap, either split
these contracts per-contract-body and reassemble, or report DeepSeek coverage as
753/756 and note the cause.

## 2. Empty source contract (1) — upstream data defect

`batch01_contract_021` is **0 bytes in `original_contracts/`**. The empty file
propagated through the whole pipeline: solc emitted an empty `SourceUnit` AST,
BiAn emitted a 0-byte "obfuscated" contract, and it was counted in the 756.

- `chatgpt_outputs/batch_01/batch01_contract_021_obf.sol` — GPT-4o correctly
  refused, asking for the missing code. Not Solidity, but honest.
- `deepseek_outputs/batch_01/batch01_contract_021_obf.sol` — **DeepSeek invented a
  complete 7.4 KB `UniswapV2Pair` contract from the empty input.** The text is
  unique (not copied from any other output) and well-formed enough to pass every
  structural check: balanced braces, valid pragma, no fences. It is fabricated data.

**Recommended:** exclude `contract_021` from both models and from all counts. The
real obfuscated corpus is **755**, not 756. The runners now skip empty inputs before
the API call, so this cannot recur.

Related: `batch01_contract_196.sol` is Etherscan header text ("Contract Name: RTB2 /
Compiler Version...") rather than Solidity. It failed AST generation and never
entered the obfuscated set, so it is self-limiting — but it confirms the collection
step captured at least two bad files.

## Resolved

- **Markdown fences** — 851 of 1512 outputs were wrapped in ```` ```solidity ````
  fences despite the prompt forbidding them, so none would compile. Stripped from
  all outputs (1675 lines removed, 0 added, 0 non-fence lines changed). The runners
  now strip fences at write time.

- **Degenerate repetition (27 recovered of 30)** — outputs previously recorded as
  "truncated" were mostly not size-limited. The models collapsed into repetition
  loops until they exhausted max_tokens: `batch02_contract_169` repeated three
  declarations 508 times; `batch04_contract_028` emitted
  `getPlayerMaxMaxMax...MileReq`. Because the runners use `temperature=0`, a plain
  re-run is deterministic and reproduces the identical loop — recovery required
  escalating temperature (169 succeeded at 0.5, yielding 125 clean lines in place
  of 1537 degenerate ones). See `scripts/retry_degenerate.py`.

  This is worth reporting as a result: BiAn's 40-character hex identifiers drive
  LLMs into pathological repetition, a deobfuscation failure mode distinct from
  ordinary loss of naming information.
