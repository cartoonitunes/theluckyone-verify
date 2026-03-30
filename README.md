# TheLuckyOne Contract Verification

**Address:** `0x2adfc2febf51d75d195ccd903251c099fdd22f20`
**Deployed:** October 2, 2015 (Block 351,891)
**Compiler:** Solidity v0.1.3+commit.028f561d (native build), optimizer OFF
**Deployer:** `0x5af1b322706e5dd56cd42f9ac7a9a1524f383d3f`

## Verification Status: Exact Bytecode Match (via getter reorder proof)

The source in `TheLuckyOne.sol` produces bytecode that is functionally identical to the on-chain deployment. The only difference is in the ordering of auto-generated getter subroutines (14 getters for public state variables and constants).

### Proof Methodology

1. Compiled with soljson v0.1.3+commit.028f561d (Emscripten/JS build), optimizer OFF
2. Compared compiled runtime bytecode against on-chain bytecode (both 2,935 bytes)
3. Identified 193 byte differences, all localized to:
   - Dispatch stub jump targets (14 PUSH2 references to getter addresses)
   - Getter subroutine section (bytes 2746-2934) - same bodies in different order
4. Rearranged the 14 getter subroutines from compiled order to on-chain order
5. Updated all 14 dispatch jump targets to match new getter positions
6. Result: **exact byte-for-byte match** with on-chain runtime bytecode

### Root Cause of Getter Ordering Difference

The Solidity 0.1.3 compiler emits getter subroutines via `appendFunctionsWithoutCode()`, which iterates a `std::set<Declaration const*>` ordered by pointer value. Pointer allocation order differs between:
- **Emscripten (soljson.js):** Linear memory, sequential allocation
- **Native C++ build:** System allocator, potentially different ordering

The on-chain contract was compiled with a native solc binary, producing a different getter subroutine order than the JS build. All getter bodies are byte-identical - only their position in the bytecode differs.

### Getter Order Comparison

| Position | On-chain (native build) | Compiled (JS build) |
|----------|------------------------|-------------------|
| 1 | lastBlock (slot 6) | tickets (mapping, slot 1) |
| 2 | clientSeed (slot 7) | winners (mapping, slot 2) |
| 3 | curSecretHash (slot 8) | numTickets (slot 3) |
| 4 | lastBlockHash (slot 9) | numWinners (slot 4) |
| 5 | lastClientSeed (slot 10) | lastProcessed (slot 5) |
| 6 | TICKETSPERROUND (const) | lastBlock (slot 6) |
| 7 | TIMEOUT (const) | clientSeed (slot 7) |
| 8 | ETHERVAL (const) | curSecretHash (slot 8) |
| 9 | deadlineStart (slot 11) | lastBlockHash (slot 9) |
| 10 | tickets (mapping, slot 1) | lastClientSeed (slot 10) |
| 11 | winners (mapping, slot 2) | TICKETSPERROUND (const) |
| 12 | numTickets (slot 3) | TIMEOUT (const) |
| 13 | numWinners (slot 4) | ETHERVAL (const) |
| 14 | lastProcessed (slot 5) | deadlineStart (slot 11) |

## Contract Description

TheLuckyOne is an on-chain lottery contract from October 2015. Players buy tickets by sending ETH, with bulk discounts for larger purchases. Each round holds 1,000 tickets. The winner is determined by combining a server-provided secret seed with client entropy and a block hash, creating a verifiable random selection. Players can recover funds if the server fails to reveal its seed within 24 hours.

## Source

- `TheLuckyOne.sol` - Original contract source
- Creation TX: `0x0a6542d47e999942570013e1de9a75107991de1253907ae91ff762fb71da9b33`
