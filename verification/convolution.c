#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <x86intrin.h>
#include <time.h>

#define IMG 16
#define FILTER 8
#define OUT (IMG - FILTER + 1)

int main() {

    int image[IMG][IMG];
    int kernel[FILTER][FILTER];
    int output[OUT][OUT];

    srand(42);

    for(int i=0;i<IMG;i++)
        for(int j=0;j<IMG;j++)
            image[i][j]=(rand()%31)-15;

    for(int i=0;i<FILTER;i++)
        for(int j=0;j<FILTER;j++)
            kernel[i][j]=(rand()%31)-15;

    struct timespec start,end;

    clock_gettime(CLOCK_MONOTONIC,&start);
    uint64_t start_cycle = __rdtsc();

    for(int r=0;r<OUT;r++) {
        for(int c=0;c<OUT;c++) {

            int sum = 0;

            for(int kr=0;kr<FILTER;kr++) {
                for(int kc=0;kc<FILTER;kc++) {
                    sum += image[r+kr][c+kc] *
                           kernel[kr][kc];
                }
            }

            output[r][c] = sum;
        }
    }
    clock_gettime(CLOCK_MONOTONIC,&end);
    uint64_t end_cycle = __rdtsc();
    printf("CPU cycles = %lu\n", end_cycle - start_cycle);
    double elapsed =
        (end.tv_sec-start.tv_sec) +
        (end.tv_nsec-start.tv_nsec)*1e-9;

    printf("CPU convolution time = %.9f seconds\n", elapsed);

    return 0;
}
