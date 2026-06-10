# -*- coding: utf-8 -*-
import numpy as np
import math

M = 40
K = 40
N = 40

TILE = 8

np.random.seed(42)

A = np.random.randint(-15, 16, size=(M, K))
B = np.random.randint(-15, 16, size=(K, N))
print("A =", A)
print("B =", B)

C = A @ B
print ("C = ", C)
print("A shape =", A.shape)
print("B shape =", B.shape)
print("C shape =", C.shape)

np.savetxt("A.csv", A, fmt="%d", delimiter=",")
np.savetxt("B.csv", B, fmt="%d", delimiter=",")
np.savetxt("golden.csv", C, fmt="%d", delimiter=",")

#cycle model
m_tiles = math.ceil(M / TILE)
k_tiles = math.ceil(K / TILE)
n_tiles = math.ceil(N / TILE)
tile_mults = m_tiles * k_tiles * n_tiles

cycles_per_tile = 36
#CHOOSE   1
#LOAD     1
#COMPUTE 24
#DRAIN    9
#DONE     1
#---------
#36 cycles

predicted_cycles = tile_mults * cycles_per_tile

total_macs = M * K * N

macs_per_cycle = total_macs / predicted_cycles

peak_macs_per_cycle = TILE * TILE

utilization = 100 * macs_per_cycle / peak_macs_per_cycle

print("\n------SYSTOLIC ARRAY REPORT--------")

print(f"Matrix Size      : {M} x {K} * {K} x {N}")
print(f"Tile Size        : {TILE} x {TILE}")

print(f"\nM Tiles          : {m_tiles}")
print(f"K Tiles          : {k_tiles}")
print(f"N Tiles          : {n_tiles}")

print(f"\nTile Multiplies  : {tile_mults}")

print(f"Cycles/Tile      : {cycles_per_tile}")
print(f"Predicted Cycles : {predicted_cycles}")

print(f"\nTotal MACs       : {total_macs}")

print(f"MACs/Cycle       : {macs_per_cycle:.2f}")

print(f"Peak MACs/Cycle  : {peak_macs_per_cycle}")

print(f"Utilization      : {utilization:.2f}%")
