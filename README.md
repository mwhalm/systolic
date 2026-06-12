# Reconfigurable Systolic Array for Matrix Multiplication and Convolution


## Run on UC Davis Kemper Hall 2107 Computers with this flow:

### 1. Clone this repostitory

git clone https://github.com/mwhalm/systolic.git

### 2. CD into the run directory

cd systolic/run

### 3. Compile with Synopsys VCS with UVM enabled

Configure systolic array size, matrix sizes, and data width in tb/sys_pkg.sv

#### For Matrix Multiplication:
vcs -full64 -ntb_opts uvm-1.1 +define+MM -f run.f

#### For Convolution:
vcs -full64 -ntb_opts uvm-1.1 +define+CONV -f run.f

##### If printing the matrices is desired:

Add +define+PRINT to the previous command

### 4. Simulate Command

./simv +UVM_TESTNAME=sys_test +UVM_VERBOSITY=UVM_MEDIUM +ntb_random_seed_automatic

### 5. Repeat for other matrix configurations
