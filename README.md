# TheLuckyOne Bytecode Verification

Bytecode verification proof for **TheLuckyOne** - an on-chain lottery contract from October 2015.

## Contract

| Field | Value |
|-------|-------|
| Address | [`0x2adfc2febf51d75d195ccd903251c099fdd22f20`](https://www.ethereumhistory.com/contract/0x2adfc2febf51d75d195ccd903251c099fdd22f20) |
| Block | 310,456 |
| Date | October 1, 2015 |
| ETH Balance | 56.83 ETH (locked) |
| Runtime Size | 2,935 bytes |
| Compiler | soljson v0.1.3+commit.028f561d |
| Optimizer | Off |

## Verification

```bash
./verify.sh
```

### Match Details

| Section | Bytes | Status |
|---------|-------|--------|
| Dispatch table (0-953) | 954 | EXACT MATCH |
| Function bodies (1575-2709) | 1,135 | EXACT MATCH |
| Getter body blocks (2710-2935) | 225 | All 15 blocks identical |
| **Total** | **2,935** | **100% semantic match** |

All executable logic is byte-for-byte identical. The 15 auto-generated getter subroutines contain identical bytecode but are placed in a different order within the binary. This is a cosmetic compilation artifact (likely from Mix IDE vs browser-solidity) that does not affect contract behavior.

## How It Works

TheLuckyOne is a provably fair lottery where:

1. **Ticket purchase**: Send 1 ETH to buy a ticket (tiered pricing for bulk purchases)
2. **Round completion**: After 1,000 tickets (TICKETSPERROUND), the round is sealed
3. **Entropy sources**: Winner is determined by XOR of server secret, client seed (rolling SHA3 of all ticket purchases), and block hash
4. **Payout**: Server reveals the secret seed, winner receives the pot (1,000 ETH)
5. **Timeout protection**: If the server fails to reveal the seed within 24 hours (TIMEOUT), players can recover their funds via `recoverLostFunds()`

### Constants

| Name | Value | Purpose |
|------|-------|---------|
| TICKETSPERROUND | 1,000 | Tickets per lottery round |
| TIMEOUT | 86,400 (24 hours) | Deadline for server seed reveal |
| ETHERVAL | 1 ETH | Price per ticket |

### Key Functions

- `revealAndPayout(curSecret, nextSecretHash)` - Server reveals seed, pays winner, starts next round
- `recoverLostFunds()` - Players recover ETH if server abandons the game
- `adminWithdraw()` - Owner withdraws excess funds (keeps enough for payouts)
- `sha3clone(input)` - Public SHA3 helper for seed verification

## Source Structure

The original developer declared functions before state variables, a syntax supported by Solidity v0.1.3:

```
contract TheLuckyOne {
    // Functions first
    function TheLuckyOne(bytes32 initialSecretHash) { ... }
    function revealAndPayout(...) { ... }
    function recoverLostFunds() { ... }
    function adminWithdraw() { ... }
    function getTimeElapsed() { ... }
    function sha3clone(...) { ... }

    // State variables after
    address owner;
    mapping(uint => address) public tickets;
    ...

    // Fallback (ticket purchase)
    function () { ... }
}
```

## Methodology

1. Decompiled on-chain bytecode to identify all 19 function selectors
2. Mapped selectors to function signatures using the Solidity v0.1.3 compiler (4byte.directory gave incorrect names due to selector collisions)
3. Reconstructed storage layout from fallback function analysis (12 storage slots)
4. Identified function declaration order from compiled body placement
5. Verified every opcode matches between compiled and on-chain bytecode
6. Confirmed getter body blocks are identical content in different arrangement order

## Files

- `TheLuckyOne.sol` - Reconstructed source code
- `verify.sh` - Automated verification script
- `README.md` - This file

## Links

- [EthereumHistory](https://www.ethereumhistory.com)
- [awesome-ethereum-proofs](https://github.com/cartoonitunes/awesome-ethereum-proofs)
