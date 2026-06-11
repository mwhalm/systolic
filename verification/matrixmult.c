#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <x86intrin.h>

#define M 40
#define K 40
#define N 40

int main() {

    int A[M][K];
    int B[K][N];
    int C[M][N];

    srand(42);

    for(int i=0;i<M;i++)
        for(int j=0;j<K;j++)
            A[i][j]=(rand()%31)-15;

    for(int i=0;i<K;i++)
        for(int j=0;j<N;j++)
            B[i][j]=(rand()%31)-15;

    struct timespec start,end;
    uint64_t start_cycle = __rdtsc();
    clock_gettime(CLOCK_MONOTONIC,&start);

    for(int i=0;i<M;i++) {
        for(int j=0;j<N;j++) {

            int sum = 0;

            for(int k=0;k<K;k++) {
                sum += A[i][k] * B[k][j];
            }

            C[i][j] = sum;
        }
    }

    clock_gettime(CLOCK_MONOTONIC,&end);

    uint64_t end_cycle = __rdtsc();
	
     double elapsed =
        (end.tv_sec-start.tv_sec) +
        (end.tv_nsec-start.tv_nsec)*1e-9;

    printf("CPU convolution time = %.9f seconds\n", elapsed);
    printf("CPU cycles = %lu\n", end_cycle - start_cycle);


    return 0;
}
