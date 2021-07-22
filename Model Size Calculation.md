
Input:

- Assuming a 10 * 20 field, times channels
- 1 channel for the field
- 7 * 2 channels for hold and play pieces
- 7 * N channels for N previews
- Take N = 3, for 36 channels, for an input size of 7200

initialConv: 

- For most ConvBN, say we use 3x3 kernels
- Use width / channel count of 32, then 3 * 3 * 36 * 32 = 10368
- Bias for each channel, and batch norm params
- Say about 10k params here

residualBlocks: 

- Each has two ConvBN with 3 * 3 * 32 * 32, so 20k params
- Arbitrarily take 4 blocks, 80k params

policyConv1:

- Say 10k params

policyConv2:

- 32 channels to 8, 2~3k params

valueConv: 

- 1x1 ConvBN squashing to 1 channel, should be small

valueDense1: 

- From 200 to 32, so just over 6k

valueDense2: 

- Produce a single number... small

Output:

- (field size) * (hold or play piece) * (orientation)
- 200 * 2 * 4 = 1600

Shooting for an overall model size of 100~150k.
