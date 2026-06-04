import numpy as np

tile = np.random.randint(-200, 200, (8,8))

max_val = np.max(np.abs(tile))
shift = max(0, int(np.log2(max_val)) - 7)

quant = tile >> shift

print(tile)
print(quant)