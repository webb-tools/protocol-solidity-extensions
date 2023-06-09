pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/sha256/sha256.circom";

// Computes a SHA256 hash of all inputs packed into a byte array
// Field elements are padded to 256 bits with zeroes
template TreeUpdateArgsHasher(nLeaves) {
    signal input oldRoot;
    signal input newRoot;
    signal input pathIndices;
    /* signal input instances[nLeaves]; */
    signal input leaves[nLeaves];
    /* signal input blocks[nLeaves]; */
    signal output out;

    var header = 256 + 256 + 32;
    var bitsPerLeaf = 256; // + 160 + 32;
    component hasher = Sha256(header + nLeaves * bitsPerLeaf);

    // the range check on old root is optional, it's enforced by smart contract anyway
    component bitsOldRoot = Num2Bits_strict();
    component bitsNewRoot = Num2Bits_strict();
    component bitsPathIndices = Num2Bits(32);
    component bitsInstance[nLeaves];
    component bitsHash[nLeaves];
    component bitsBlock[nLeaves];

    bitsOldRoot.in <== oldRoot;
    bitsNewRoot.in <== newRoot;
    bitsPathIndices.in <== pathIndices;

    var index = 0;

    hasher.in[index] <== 0;
    index += 1;
    hasher.in[index] <== 0;
    index += 1;
    for(var i = 0; i < 254; i++) {
        hasher.in[index] <== bitsOldRoot.out[253 - i];
        index += 1;
    }
    hasher.in[index] <== 0;
    index += 1;
    hasher.in[index] <== 0;
    index += 1;
    for(var i = 0; i < 254; i++) {
        hasher.in[index] <== bitsNewRoot.out[253 - i];
        index += 1;
    }
    for(var i = 0; i < 32; i++) {
        hasher.in[index] <== bitsPathIndices.out[31 - i];
        index += 1;
    }
    for(var leaf = 0; leaf < nLeaves; leaf++) {
        // the range check on hash is optional, it's enforced by the smart contract anyway
        bitsHash[leaf] = Num2Bits_strict();
        /* bitsInstance[leaf] = Num2Bits(160); */
        /* bitsBlock[leaf] = Num2Bits(32); */
        bitsHash[leaf].in <== leaves[leaf];
        /* bitsInstance[leaf].in <== instances[leaf]; */
        /* bitsBlock[leaf].in <== blocks[leaf]; */
        hasher.in[index] <== 0;
        index += 1;
        hasher.in[index] <== 0;
        index += 1;
        for(var i = 0; i < 254; i++) {
            hasher.in[index] <== bitsHash[leaf].out[253 - i];
            index += 1;
        }
        /* for(var i = 0; i < 160; i++) { */
        /*     hasher.in[index++] <== bitsInstance[leaf].out[159 - i]; */
        /* } */
        /* for(var i = 0; i < 32; i++) { */
        /*     hasher.in[index++] <== bitsBlock[leaf].out[31 - i]; */
        /* } */
    }
    component b2n = Bits2Num(256);
    for (var i = 0; i < 256; i++) {
        b2n.in[i] <== hasher.out[255 - i];
    }
    out <== b2n.out;
}
