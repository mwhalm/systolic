# -*- coding: utf-8 -*-
import numpy as np
import math

M = 40
K = 40
N = 40

TILE = 8

def matmul():
    np.random.seed(42)
    A = np.random.randint(-15, 16, size=(M, K))
    B = np.random.randint(-15, 16, size=(K, N))
    print("A =", A)
    print("B =", B)

    C = [[0 for _ in range(N)] for _ in range(M)]
    mac_count = 0

    for i in range(M):
        for j in range(N):
            acc = 0
            for k in range(K):
                acc += A[i][k] * B[k][j]
            C[i][j] = acc
            mac_count += 1

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
    np.savetxt("A.csv", A, fmt="%d", delimiter=",")
    np.savetxt("B.csv", B, fmt="%d", delimiter=",")
    np.savetxt("golden.csv", C, fmt="%d", delimiter=",")
    return C, mac_count

def conv2d():
    np.random.seed(42)

    IFM_SIZE = 40
    FILTER_SIZE = 8

    IFM = np.random.randint(-15, 16, size=(IFM_SIZE, IFM_SIZE))
    KERNEL = np.random.randint(-15, 16, size=(FILTER_SIZE, FILTER_SIZE))

    print("IFM =")
    print(IFM)

    print("KERNEL =")
    print(KERNEL)

    # -------------------------
    # im2col
    # -------------------------
    out_size = IFM_SIZE - FILTER_SIZE + 1

    A = []

    for r in range(out_size):
        for c in range(out_size):
            window = IFM[r:r+FILTER_SIZE, c:c+FILTER_SIZE]
            A.append(window.flatten())

    A = np.array(A)

    # Flatten kernel
    B = KERNEL.flatten().reshape(-1, 1)

    # GEMM
    C = np.matmul(A, B)

    # Reshape back to OFM
    OFM = C.reshape(out_size, out_size)

    print("OFM =")
    print(OFM)

    # -------------------------
    # Cycle model (reuse GEMM)
    # -------------------------
    M_conv = A.shape[0]      # 81
    K_conv = A.shape[1]      # 64
    N_conv = 1

    m_tiles = math.ceil(M_conv / TILE)
    k_tiles = math.ceil(K_conv / TILE)
    n_tiles = math.ceil(N_conv / TILE)

    tile_mults = m_tiles * k_tiles * n_tiles

    cycles_per_tile = 36
    predicted_cycles = tile_mults * cycles_per_tile

    total_macs = M_conv * K_conv * N_conv

    macs_per_cycle = total_macs / predicted_cycles
    peak_macs_per_cycle = TILE * TILE

    utilization = 100 * macs_per_cycle / peak_macs_per_cycle

    print("\n------CONVOLUTION REPORT--------")
    print(f"IFM Size         : {IFM_SIZE} x {IFM_SIZE}")
    print(f"Kernel Size      : {FILTER_SIZE} x {FILTER_SIZE}")
    print(f"Output Size      : {out_size} x {out_size}")

    print(f"\nGEMM Shape       : {M_conv} x {K_conv} * {K_conv} x {N_conv}")

    print(f"\nM Tiles          : {m_tiles}")
    print(f"K Tiles          : {k_tiles}")
    print(f"N Tiles          : {n_tiles}")

    print(f"\nTile Multiplies  : {tile_mults}")
    print(f"Predicted Cycles : {predicted_cycles}")

    print(f"\nTotal MACs       : {total_macs}")
    print(f"MACs/Cycle       : {macs_per_cycle:.2f}")
    print(f"Peak MACs/Cycle  : {peak_macs_per_cycle}")
    print(f"Utilization      : {utilization:.2f}%")

    np.savetxt("ifm.csv", IFM, fmt="%d", delimiter=",")
    np.savetxt("kernel.csv", KERNEL, fmt="%d", delimiter=",")
    np.savetxt("conv_golden.csv", OFM, fmt="%d", delimiter=",")

    return OFM

matmul()
conv2d()
