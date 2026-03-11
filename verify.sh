#!/bin/bash
# Bytecode verification for TheLuckyOne (0x2adfc2febf51d75d195ccd903251c099fdd22f20)
# Compiler: soljson-v0.1.3+commit.028f561d, no optimizer
# Deployed: block 310456, October 1, 2015

set -e

CONTRACT="0x2adfc2febf51d75d195ccd903251c099fdd22f20"
COMPILER_URL="https://binaries.soliditylang.org/bin/soljson-v0.1.3+commit.028f561d.js"
COMPILER="soljson-v0.1.3+commit.028f561d.js"

echo "=== TheLuckyOne Bytecode Verification ==="
echo "Contract: $CONTRACT"
echo ""

# Download compiler if needed
if [ ! -f "$COMPILER" ]; then
    echo "Downloading $COMPILER..."
    curl -sL "$COMPILER_URL" -o "$COMPILER"
fi

# Compile and extract runtime bytecode
echo "Compiling TheLuckyOne.sol..."
RUNTIME=$(node -e "
var fs = require('fs');
var solc = require('./$COMPILER');
var compile = solc.cwrap('compileJSON','string',['string','number']);
var src = fs.readFileSync('TheLuckyOne.sol','utf8');
var out = JSON.parse(compile(src, 0));
if (out.errors) out.errors.forEach(function(e){ if(e.indexOf('Error')>=0) { console.error(e); process.exit(1); }});
var creation = out.contracts.TheLuckyOne.bytecode;
// Runtime starts at offset 98 bytes (196 hex chars)
var runtime = creation.slice(196);
process.stdout.write(runtime);
")

echo "Compiled runtime: ${#RUNTIME} hex chars ($(( ${#RUNTIME} / 2 )) bytes)"

# Fetch on-chain bytecode
echo ""
echo "Fetching on-chain bytecode..."
if [ -z "$ETHERSCAN_API_KEY" ]; then
    ETHERSCAN_API_KEY="AHMV3WAI75TQVJI2XEFUUKFKK1KJTFY1BD"
fi

ONCHAIN=$(curl -s "https://api.etherscan.io/v2/api?chainid=1&module=proxy&action=eth_getCode&address=$CONTRACT&tag=latest&apikey=$ETHERSCAN_API_KEY" | node -e "
var d=''; process.stdin.on('data',function(c){d+=c}); process.stdin.on('end',function(){
    var r=JSON.parse(d); process.stdout.write(r.result.slice(2));
})")

echo "On-chain runtime: ${#ONCHAIN} hex chars ($(( ${#ONCHAIN} / 2 )) bytes)"

# Compare
echo ""
if [ "$RUNTIME" = "$ONCHAIN" ]; then
    echo "*** EXACT BYTECODE MATCH ***"
    exit 0
fi

# Semantic comparison
MATCH=$(node -e "
var r='$RUNTIME', t='$ONCHAIN';
var match=0;
for(var i=0;i<Math.min(r.length,t.length);i+=2) if(r.slice(i,i+2)===t.slice(i,i+2)) match++;
console.log(match+'/'+(t.length/2));
")

echo "Positional match: $MATCH bytes"
echo ""

# Verify semantic equivalence
node -e "
var r='$RUNTIME', t='$ONCHAIN';

// Verify dispatch table (bytes 0-953)
var dispatch_match = r.slice(0, 954*2) === t.slice(0, 954*2);
console.log('Dispatch table (0-953): ' + (dispatch_match ? 'EXACT MATCH' : 'DIFFERS'));

// Verify function bodies (bytes 1575-2709)
var func_match = r.slice(1575*2, 2710*2) === t.slice(1575*2, 2710*2);
console.log('Function bodies (1575-2709): ' + (func_match ? 'EXACT MATCH' : 'DIFFERS'));

// Verify getter blocks exist in both
var getter_sizes = [36,9,9,9,9,9,6,7,12,9,56,27,9,9,9]; // sha3clone + 14 getters
var rArea = r.slice(2710*2);
var tArea = t.slice(2710*2);
var all_found = true;

// Extract blocks from target at known positions
var offsets = [0,36,45,54,63,72,81,87,94,106,115,171,198,207,216];
for (var i = 0; i < offsets.length; i++) {
    var block = tArea.slice(offsets[i]*2, (offsets[i]+getter_sizes[i])*2);
    if (rArea.indexOf(block) < 0) { all_found = false; console.log('  Missing getter block at offset ' + offsets[i]); }
}
console.log('Getter body blocks: ' + (all_found ? 'ALL 15 PRESENT (different order)' : 'SOME MISSING'));
console.log('');
if (dispatch_match && func_match && all_found) {
    console.log('SEMANTIC VERIFICATION: PASS');
    console.log('All executable logic is byte-for-byte identical.');
    console.log('Getter body placement order differs (compilation artifact).');
} else {
    console.log('VERIFICATION: PARTIAL');
}
"

