#define amd_bitalign (uint src0, uint src1, uint src2)((uint) (((((long)src0.s0) << 32) | (long)src1.s0) >> (src2.s0 & 31)))

#define SHL32(a,n) (amd_bitalign((a), bitselect(0U,     (a), (amd_bitalign(0U, ~0U, (n)))), (32U - (n))))
#define SHR32(a,n) (amd_bitalign(0U,  bitselect((a),     0U, (amd_bitalign(0U, ~0U, (32U - (n))))), (n)))
#define SHFRC32(a,b,n) (amd_bitalign((b), bitselect((a),     (b), (amd_bitalign(0U, ~0U, (32U - (n))))), (n)))
#define SHFRC32S(a,b,n) (amd_bitalign((b), (a), (n)))

#define BLOCK_SIZE         64U
#define BLAKE2S_BLOCK_SIZE 64U
#define BLAKE2S_OUT_SIZE   32U

__constant uint8 BLAKE2S_IV_Vec = {
	0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
	0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19
};
__constant uint BLAKE2S_SIGMA[10][16] = {
	{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
	{ 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 },
	{ 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4 },
	{ 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8 },
	{ 9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13 },
	{ 2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9 },
	{ 12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11 },
	{ 13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10 },
	{ 6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5 },
	{ 10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0 },
};
#define rotateR(x, n) rotate((uint)(x), (uint)(32 - (n)))

#define BLAKE_G(idx0, idx1, a, b, c, d, key) { \
	idx = BLAKE2S_SIGMA[idx0][idx1]; a += key[idx]; \
	a += b; d = rotate((uint)(d^a), (uint)16); \
	c += d; b = rotateR(b^c, 12); \
	idx = BLAKE2S_SIGMA[idx0][idx1+1]; a += key[idx]; \
	a += b; d = rotate((uint)(d^a), (uint)24); \
	c += d; b = rotateR(b^c, 7); \
}
#define BLAKE(a, b, c, d, key1,key2) { \
	a += key1; \
	a += b; d = rotate((uint)(d^a), (uint)16); \
	c += d; b = rotateR(b^c, 12); \
	a += key2; \
	a += b; d = rotate((uint)(d^a), (uint)24); \
	c += d; b = rotateR(b^c, 7); \
}

#define BLAKE_G_PRE(idx0,idx1, a, b, c, d, key) { \
	a += key[idx0]; \
	a += b; d = rotate((uint)(d^a), (uint)16); \
	c += d; b = rotateR(b^c, 12); \
	a += key[idx1]; \
	a += b; d = rotate((uint)(d^a), (uint)24); \
	c += d; b = rotateR(b^c, 7); \
}

#define BLAKE_G_PRE0(idx0,idx1, a, b, c, d, key) { \
	a += b; d = rotate((uint)(d^a), (uint)16); \
	c += d; b = rotateR(b^c, 12); \
	a += b; d = rotate((uint)(d^a), (uint)24); \
	c += d; b = rotateR(b^c, 7); \
}

#define BLAKE_G_PRE1(idx0,idx1, a, b, c, d, key) { \
	a += key[idx0]; \
	a += b; d = rotate((uint)(d^a), (uint)16); \
	c += d; b = rotateR(b^c, 12); \
	a += b; d = rotate((uint)(d^a), (uint)24); \
	c += d; b = rotateR(b^c, 7); \
}

#define BLAKE_G_PRE2(idx0,idx1, a, b, c, d, key) { \
	a += b; d = rotate((uint)(d^a), (uint)16); \
	c += d; b = rotateR(b^c, 12); \
	a += key[idx1]; \
	a += b; d = rotate((uint)(d^a), (uint)24); \
	c += d; b = rotateR(b^c, 7); \
}


static inline
void Blake2S_v2(uint *out, const uint*  inout, const  uint * TheKey)
{
	uint16 V;
	uint8 tmpblock;

	V.hi = BLAKE2S_IV_Vec;
	V.lo = BLAKE2S_IV_Vec;
	V.lo.s0 ^= 0x01012020;

	// Copy input block for later
	tmpblock = V.lo;

	V.hi.s4 ^= BLAKE2S_BLOCK_SIZE;

	//	{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
	BLAKE_G_PRE(0, 1, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, TheKey);
	BLAKE_G_PRE(2, 3, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, TheKey);
	BLAKE_G_PRE(4, 5, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, TheKey);
	BLAKE_G_PRE(6, 7, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, TheKey);
	BLAKE_G_PRE0(8, 9, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, TheKey);
	BLAKE_G_PRE0(10, 11, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, TheKey);
	BLAKE_G_PRE0(12, 13, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, TheKey);
	BLAKE_G_PRE0(14, 15, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, TheKey);
	// { 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 },
	BLAKE_G_PRE0(14, 10, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, TheKey);
	BLAKE_G_PRE1(4, 8, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, TheKey);
	BLAKE_G_PRE0(9, 15, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, TheKey);
	BLAKE_G_PRE2(13, 6, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, TheKey);
	BLAKE_G_PRE1(1, 12, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, TheKey);
	BLAKE_G_PRE(0, 2, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, TheKey);
	BLAKE_G_PRE2(11, 7, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, TheKey);
	BLAKE_G_PRE(5, 3, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, TheKey);
	// { 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4 },
	BLAKE_G_PRE0(11, 8, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, TheKey);
	BLAKE_G_PRE2(12, 0, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, TheKey);
	BLAKE_G_PRE(5, 2, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, TheKey);
	BLAKE_G_PRE0(15, 13, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, TheKey);
	BLAKE_G_PRE0(10, 14, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, TheKey);
	BLAKE_G_PRE(3, 6, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, TheKey);
	BLAKE_G_PRE(7, 1, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, TheKey);
	BLAKE_G_PRE2(9, 4, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, TheKey);
	// { 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8 },
	BLAKE_G_PRE1(7, 9, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, TheKey);
	BLAKE_G_PRE(3, 1, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, TheKey);
	BLAKE_G_PRE0(13, 12, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, TheKey);
	BLAKE_G_PRE0(11, 14, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, TheKey);
	BLAKE_G_PRE(2, 6, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, TheKey);
	BLAKE_G_PRE1(5, 10, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, TheKey);
	BLAKE_G_PRE(4, 0, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, TheKey);
	BLAKE_G_PRE0(15, 8, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, TheKey);
	// { 9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13 },
	BLAKE_G_PRE2(9, 0, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, TheKey);
	BLAKE_G_PRE(5, 7, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, TheKey);
	BLAKE_G_PRE(2, 4, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, TheKey);
	BLAKE_G_PRE0(10, 15, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, TheKey);
	BLAKE_G_PRE2(14, 1, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, TheKey);
	BLAKE_G_PRE0(11, 12, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, TheKey);
	BLAKE_G_PRE1(6, 8, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, TheKey);
	BLAKE_G_PRE1(3, 13, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, TheKey);
	// { 2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9 },
	BLAKE_G_PRE1(2, 12, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, TheKey);
	BLAKE_G_PRE1(6, 10, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, TheKey);
	BLAKE_G_PRE1(0, 11, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, TheKey);
	BLAKE_G_PRE2(8, 3, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, TheKey);
	BLAKE_G_PRE1(4, 13, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, TheKey);
	BLAKE_G_PRE(7, 5, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, TheKey);
	BLAKE_G_PRE0(15, 14, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, TheKey);
	BLAKE_G_PRE1(1, 9, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, TheKey);
	// { 12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11 },
	BLAKE_G_PRE2(12, 5, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, TheKey);
	BLAKE_G_PRE1(1, 15, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, TheKey);
	BLAKE_G_PRE0(14, 13, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, TheKey);
	BLAKE_G_PRE1(4, 10, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, TheKey);
	BLAKE_G_PRE(0, 7, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, TheKey);
	BLAKE_G_PRE(6, 3, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, TheKey);
	BLAKE_G_PRE2(9, 2, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, TheKey);
	BLAKE_G_PRE0(8, 11, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, TheKey);
	// { 13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10 },
	BLAKE_G_PRE0(13, 11, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, TheKey);
	BLAKE_G_PRE1(7, 14, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, TheKey);
	BLAKE_G_PRE2(12, 1, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, TheKey);
	BLAKE_G_PRE1(3, 9, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, TheKey);
	BLAKE_G_PRE(5, 0, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, TheKey);
	BLAKE_G_PRE2(15, 4, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, TheKey);
	BLAKE_G_PRE2(8, 6, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, TheKey);
	BLAKE_G_PRE(2, 10, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, TheKey);
	// { 6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5 },
	BLAKE_G_PRE1(6, 15, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, TheKey);
	BLAKE_G_PRE0(14, 9, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, TheKey);
	BLAKE_G_PRE2(11, 3, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, TheKey);
	BLAKE_G_PRE1(0, 8, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, TheKey);
	BLAKE_G_PRE2(12, 2, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, TheKey);
	BLAKE_G_PRE2(13, 7, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, TheKey);
	BLAKE_G_PRE(1, 4, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, TheKey);
	BLAKE_G_PRE2(10, 5, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, TheKey);
	// { 10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0 },
	BLAKE_G_PRE2(10, 2, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, TheKey);
	BLAKE_G_PRE2(8, 4, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, TheKey);
	BLAKE_G_PRE(7, 6, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, TheKey);
	BLAKE_G_PRE(1, 5, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, TheKey);
	BLAKE_G_PRE0(15, 11, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, TheKey);
	BLAKE_G_PRE0(9, 14, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, TheKey);
	BLAKE_G_PRE1(3, 12, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, TheKey);
	BLAKE_G_PRE2(13, 0, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, TheKey);

	V.lo ^= V.hi;
	V.lo ^= tmpblock;

	V.hi = BLAKE2S_IV_Vec;
	tmpblock = V.lo;

	V.hi.s4 ^= 128;
	V.hi.s6 = ~V.hi.s6;

	// { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
	BLAKE_G_PRE(0, 1, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, inout);
	BLAKE_G_PRE(2, 3, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, inout);
	BLAKE_G_PRE(4, 5, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, inout);
	BLAKE_G_PRE(6, 7, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, inout);
	BLAKE_G_PRE(8, 9, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, inout);
	BLAKE_G_PRE(10, 11, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, inout);
	BLAKE_G_PRE(12, 13, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, inout);
	BLAKE_G_PRE(14, 15, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, inout);
	// { 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 },
	BLAKE_G_PRE(14, 10, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, inout);
	BLAKE_G_PRE(4, 8, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, inout);
	BLAKE_G_PRE(9, 15, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, inout);
	BLAKE_G_PRE(13, 6, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, inout);
	BLAKE_G_PRE(1, 12, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, inout);
	BLAKE_G_PRE(0, 2, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, inout);
	BLAKE_G_PRE(11, 7, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, inout);
	BLAKE_G_PRE(5, 3, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, inout);
	// { 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4 },
	BLAKE_G_PRE(11, 8, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, inout);
	BLAKE_G_PRE(12, 0, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, inout);
	BLAKE_G_PRE(5, 2, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, inout);
	BLAKE_G_PRE(15, 13, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, inout);
	BLAKE_G_PRE(10, 14, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, inout);
	BLAKE_G_PRE(3, 6, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, inout);
	BLAKE_G_PRE(7, 1, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, inout);
	BLAKE_G_PRE(9, 4, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, inout);
	// { 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8 },
	BLAKE_G_PRE(7, 9, V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, inout);
	BLAKE_G_PRE(3, 1, V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, inout);
	BLAKE_G_PRE(13, 12, V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, inout);
	BLAKE_G_PRE(11, 14, V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, inout);
	BLAKE_G_PRE(2, 6, V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, inout);
	BLAKE_G_PRE(5, 10, V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, inout);
	BLAKE_G_PRE(4, 0, V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, inout);
	BLAKE_G_PRE(15, 8, V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, inout);

	BLAKE(V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, inout[9], inout[0]);
	BLAKE(V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, inout[5], inout[7]);
	BLAKE(V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, inout[2], inout[4]);
	BLAKE(V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, inout[10], inout[15]);
	BLAKE(V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, inout[14], inout[1]);
	BLAKE(V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, inout[11], inout[12]);
	BLAKE(V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, inout[6], inout[8]);
	BLAKE(V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, inout[3], inout[13]);

	BLAKE(V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, inout[2], inout[12]);
	BLAKE(V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, inout[6], inout[10]);
	BLAKE(V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, inout[0], inout[11]);
	BLAKE(V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, inout[8], inout[3]);
	BLAKE(V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, inout[4], inout[13]);
	BLAKE(V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, inout[7], inout[5]);
	BLAKE(V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, inout[15], inout[14]);
	BLAKE(V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, inout[1], inout[9]);

	BLAKE(V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, inout[12], inout[5]);
	BLAKE(V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, inout[1], inout[15]);
	BLAKE(V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, inout[14], inout[13]);
	BLAKE(V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, inout[4], inout[10]);
	BLAKE(V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, inout[0], inout[7]);
	BLAKE(V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, inout[6], inout[3]);
	BLAKE(V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, inout[9], inout[2]);
	BLAKE(V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, inout[8], inout[11]);
	// 13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10,
	BLAKE(V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, inout[13], inout[11]);
	BLAKE(V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, inout[7], inout[14]);
	BLAKE(V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, inout[12], inout[1]);
	BLAKE(V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, inout[3], inout[9]);
	BLAKE(V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, inout[5], inout[0]);
	BLAKE(V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, inout[15], inout[4]);
	BLAKE(V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, inout[8], inout[6]);
	BLAKE(V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, inout[2], inout[10]);
	// 6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5,
	BLAKE(V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, inout[6], inout[15]);
	BLAKE(V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, inout[14], inout[9]);
	BLAKE(V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, inout[11], inout[3]);
	BLAKE(V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, inout[0], inout[8]);
	BLAKE(V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, inout[12], inout[2]);
	BLAKE(V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, inout[13], inout[7]);
	BLAKE(V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, inout[1], inout[4]);
	BLAKE(V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, inout[10], inout[5]);
	// 10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0,
	BLAKE(V.lo.s0, V.lo.s4, V.hi.s0, V.hi.s4, inout[10], inout[2]);
	BLAKE(V.lo.s1, V.lo.s5, V.hi.s1, V.hi.s5, inout[8], inout[4]);
	BLAKE(V.lo.s2, V.lo.s6, V.hi.s2, V.hi.s6, inout[7], inout[6]);
	BLAKE(V.lo.s3, V.lo.s7, V.hi.s3, V.hi.s7, inout[1], inout[5]);
	BLAKE(V.lo.s0, V.lo.s5, V.hi.s2, V.hi.s7, inout[15], inout[11]);
	BLAKE(V.lo.s1, V.lo.s6, V.hi.s3, V.hi.s4, inout[9], inout[14]);
	BLAKE(V.lo.s2, V.lo.s7, V.hi.s0, V.hi.s5, inout[3], inout[12]);
	BLAKE(V.lo.s3, V.lo.s4, V.hi.s1, V.hi.s6, inout[13], inout[0]);

	V.lo ^= V.hi;
	V.lo ^= tmpblock;

	((uint8*)out)[0] = V.lo;
}


#define NEO_TID ((get_local_size(0) >> 1) * get_local_id(1) + (get_local_id(0) & 3))

#define WarpShuffle(result, a,  b,  c) \
	shared_mem[32 * (get_local_id(0) >> 2) + NEO_TID] = a; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	result = shared_mem[32 * (get_local_id(0) >> 2) + (NEO_TID&~(c - 1)) + (b&(c - 1))]; \
	barrier(CLK_LOCAL_MEM_FENCE); \

#define WarpShuffle3(a1,  a2,  a3,  b1,  b2,  b3,  c) \
	shared_mem[32 * (get_local_id(0) >> 2) + NEO_TID] = a1; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	a1 = shared_mem[32 * (get_local_id(0) >> 2) + (NEO_TID&~(c - 1)) + (b1&(c - 1))]; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	shared_mem[32 * (get_local_id(0) >> 2) + NEO_TID] = a2; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	a2 = shared_mem[32 * (get_local_id(0) >> 2) + (NEO_TID&~(c - 1)) + (b2&(c - 1))]; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	shared_mem[32 * (get_local_id(0) >> 2) + NEO_TID] = a3; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	a3 = shared_mem[32 * (get_local_id(0) >> 2) + (NEO_TID&~(c - 1)) + (b3&(c - 1))]; \
	barrier(CLK_LOCAL_MEM_FENCE);


#define SALSA(a,b,c,d) { \
	t = rotate((uint)(a+d), (uint)( 7U)); b ^= t; \
	t = rotate((uint)(b+a), (uint)( 9U)); c ^= t; \
	t = rotate((uint)(c+b), (uint)(13U)); d ^= t; \
	t = rotate((uint)(d+c), (uint)(18U)); a ^= t; \
}

#define SALSA_CORE(state) { \
	uint t; \
	SALSA(state.x, state.y, state.z, state.w); \
	WarpShuffle3(state.y, state.z, state.w, (get_local_id(0) & 3) + 3, (get_local_id(0) & 3) + 2, (get_local_id(0) & 3) + 1,4); \
	SALSA(state.x, state.w, state.z, state.y); \
	WarpShuffle3(state.y, state.z, state.w, (get_local_id(0) & 3) + 1, (get_local_id(0) & 3) + 2, (get_local_id(0) & 3) + 3,4); \
}

#define NEO_TID ((get_local_size(0) >> 1) * get_local_id(1) + (get_local_id(0) & 3))

#define WarpShuffle(result, a,  b,  c) \
	shared_mem[32 * (get_local_id(0) >> 2) + NEO_TID] = a; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	result = shared_mem[32 * (get_local_id(0) >> 2) + (NEO_TID&~(c - 1)) + (b&(c - 1))]; \
	barrier(CLK_LOCAL_MEM_FENCE); \

#define WarpShuffle3(a1,  a2,  a3,  b1,  b2,  b3,  c) \
	shared_mem[32 * (get_local_id(0) >> 2) + NEO_TID] = a1; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	a1 = shared_mem[32 * (get_local_id(0) >> 2) + (NEO_TID&~(c - 1)) + (b1&(c - 1))]; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	shared_mem[32 * (get_local_id(0) >> 2) + NEO_TID] = a2; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	a2 = shared_mem[32 * (get_local_id(0) >> 2) + (NEO_TID&~(c - 1)) + (b2&(c - 1))]; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	shared_mem[32 * (get_local_id(0) >> 2) + NEO_TID] = a3; \
	barrier(CLK_LOCAL_MEM_FENCE); \
	a3 = shared_mem[32 * (get_local_id(0) >> 2) + (NEO_TID&~(c - 1)) + (b3&(c - 1))]; \
	barrier(CLK_LOCAL_MEM_FENCE);


#define SALSA(a,b,c,d) { \
	t = rotate((uint)(a+d), (uint)( 7U)); b ^= t; \
	t = rotate((uint)(b+a), (uint)( 9U)); c ^= t; \
	t = rotate((uint)(c+b), (uint)(13U)); d ^= t; \
	t = rotate((uint)(d+c), (uint)(18U)); a ^= t; \
}

#define SALSA_CORE(state) { \
	uint t; \
	SALSA(state.x, state.y, state.z, state.w); \
	WarpShuffle3(state.y, state.z, state.w, (get_local_id(0) & 3) + 3, (get_local_id(0) & 3) + 2, (get_local_id(0) & 3) + 1,4); \
	SALSA(state.x, state.w, state.z, state.y); \
	WarpShuffle3(state.y, state.z, state.w, (get_local_id(0) & 3) + 1, (get_local_id(0) & 3) + 2, (get_local_id(0) & 3) + 3,4); \
}

uint4 salsa_small_scalar_rnd(const uint4 X, __local uint *shared_mem)
{
	uint4 state = X;

	#pragma nounroll
	for (int i = 0; i < 10; i++) {
		SALSA_CORE(state);
	}

	return (X + state);
}

void inline neoscrypt_salsa(uint4 XV[4], __local uint *shared_mem)
{
	uint4 temp;

	XV[0] = salsa_small_scalar_rnd(XV[0] ^ XV[3], shared_mem);
	temp = salsa_small_scalar_rnd(XV[1] ^ XV[0], shared_mem);
	XV[1] = salsa_small_scalar_rnd(XV[2] ^ temp, shared_mem);
	XV[3] = salsa_small_scalar_rnd(XV[3] ^ XV[1], shared_mem);
	XV[2] = temp;
}

#define CHACHA_STEP(a,b,c,d) { \
	a += b; d = rotate((uint)(d^a), (uint)16); \
	c += d; b = rotate((uint)(b^c), (uint)12); \
	a += b; d = rotate((uint)(d^a), (uint)8); \
	c += d; b = rotate((uint)(b^c), (uint)7); \
}

#define CHACHA_CORE_PARALLEL(state)	{ \
	CHACHA_STEP(state.x, state.y, state.z, state.w); \
	WarpShuffle3(state.y, state.z, state.w, (get_local_id(0) & 3) + 1, (get_local_id(0) & 3) + 2, (get_local_id(0) & 3) + 3,4); \
	CHACHA_STEP(state.x, state.y, state.z, state.w); \
	WarpShuffle3(state.y, state.z, state.w, (get_local_id(0) & 3) + 3, (get_local_id(0) & 3) + 2, (get_local_id(0) & 3) + 1,4); \
}

uint4 inline chacha_small_parallel_rnd(const uint4 X, __local uint *shared_mem)
{
	uint4 state = X;

	#pragma nounroll
	for (int i = 0; i < 10; i++) {
		CHACHA_CORE_PARALLEL(state);
	}
	return (X + state);
}

void inline neoscrypt_chacha(uint4 XV[4], __local uint *shared_mem)
{
	uint4 temp;

	XV[0] = chacha_small_parallel_rnd(XV[0] ^ XV[3], shared_mem);
	temp = chacha_small_parallel_rnd(XV[1] ^ XV[0], shared_mem);
	XV[1] = chacha_small_parallel_rnd(XV[2] ^ temp, shared_mem);
	XV[3] = chacha_small_parallel_rnd(XV[3] ^ XV[1], shared_mem);
	XV[2] = temp;
}

#define SHIFT 128U
#define TPB 32
#define TPB2 64

__attribute__((reqd_work_group_size(64, 1, 1)))

__attribute__((reqd_work_group_size(8, 8, 1)))

__attribute__((reqd_work_group_size(8, 8, 1)))

__kernel void hello_kernel(__global const float *a,
                           __global const float *b,
                           __global float *result)
{
    int gid = get_global_id(0);
    
    result[gid] = a[gid] + b[gid];
}

