# Known issues in the LLM deobfuscation outputs

Auto-derived from the output files. These are **result-quality** issues, not formatting
ones — the contract text itself is incomplete, so these files will not compile. They are
left in place unmodified so the run stays reproducible; re-run the affected contracts to
resolve them.

Detected by two independent signals, unioned: (a) the file does not end in `}` or `;`,
(b) the original response contained an opening ```` ```solidity ```` fence with no closing
fence. 23 files trip both, 8 trip only one.

## 1. Truncated outputs (30)

The model hit its response token cap mid-file.

| Model | File | Ends with |
|---|---|---|
| GPT-4o | `deobfuscation/chatgpt_outputs/batch_02/batch02_contract_169_obf.sol` | `uint256 public` |
| GPT-4o | `deobfuscation/chatgpt_outputs/batch_04/batch04_contract_028_obf.sol` | `return MAX_MAX_MAX_MAX` |
| GPT-4o | `deobfuscation/chatgpt_outputs/batch_05/batch05_contract_007.sol_obf.sol` | `mapping` |
| GPT-4o | `deobfuscation/chatgpt_outputs/batch_05/batch05_contract_132.sol_obf.sol` | `uint256 public constant` |
| GPT-4o | `deobfuscation/chatgpt_outputs/batch_05/batch05_contract_165.sol_obf.sol` | `uint256 countOfInvestorsDV_ADV_ADV_ADV_ADV_ADV_ADV_ADV_ADV_A` |
| GPT-4o | `deobfuscation/chatgpt_outputs/batch_05/batch05_contract_193.sol_obf.sol` | `function swapWithHintAndFeeAndGasAndDestAndHintAndFeeAndGasA` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_008_obf.sol` | `function getMarket() public view returns (IMarket);` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_010_obf.sol` | `uint` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_039_obf.sol` | `price.currentInGameTokWinRatio = _currentIn` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_044_obf.sol` | `function getSlippageFee(uint amount) internal pure returns (` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_047_obf.sol` | `if (config.tokenSupply_ > 0) {` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_049_obf.sol` | `eth[writer] = eth[writer].add(calls` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_060_obf.sol` | `return rateProvider.getRate(msg.sender, soldTokens` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_093_obf.sol` | `emit payComisionSponsorETH(_in` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_104_obf.sol` | `minimumBond = nextMinimumB` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_107_obf.sol` | `if (currentHalfYear >` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_01/batch01_contract_109_obf.sol` | `currentEpoch = E` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_02/batch02_contract_046_obf.sol` | `function withdrawEther` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_02/batch02_contract_056_obf.sol` | `return c` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_02/batch02_contract_076_obf.sol` | `emit LogMinimumEpochIntervalUpdated(minimumEpochInterval, ne` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_02/batch02_contract_094_obf.sol` | `function oraclize_query(uint` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_02/batch02_contract_104_obf.sol` | `.getSiteInfo(explore` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_02/batch02_contract_128_obf.sol` | `if (transferInternal(from, to, value` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_03/batch03_contract_095_obf.sol` | `destAddress.transfer(expectedDestAmount);` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_03/batch03_contract_100_obf.sol` | `require(IERC721(_nftAddress).isApprovedForAll(linkdropMaster` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_03/batch03_contract_166_obf.sol` | `function getVertexStorageLink(uint256 _tokenId) external vie` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_04/batch04_contract_066_obf.sol` | `ke` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_05/batch05_contract_089.sol_obf.sol` | `balanceOf[payee] = balance` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_05/batch05_contract_093.sol_obf.sol` | `m` |
| DeepSeek | `deobfuscation/deepseek_outputs/batch_05/batch05_contract_174.sol_obf.sol` | `if (current` |

Re-run with a higher output-token limit, or split the contract before sending.

## 2. Model refusals (1)

The response is prose, not Solidity — the contract never reached the model.

| Model | File | First line |
|---|---|---|
| GPT-4o | `deobfuscation/chatgpt_outputs/batch_01/batch01_contract_021_obf.sol` | I'm sorry, but I need the obfuscated contract code to assist you with de-obfusca |

Re-run these individually.

## Affected share

31 of 1512 outputs (2.1%). The remaining
1481 are complete.

## Resolved

- **Markdown fences** — 851 of 1512 outputs were wrapped in ```` ```solidity ```` fences
  despite the prompt forbidding them. Stripped from all outputs (1675 fence lines removed,
  zero lines added); the runner scripts now strip fences at write time so this cannot recur.
  No contract text was altered.
