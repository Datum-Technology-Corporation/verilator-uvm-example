# UVM with Verilator example

Copyright (c) 2025 Antmicro

This is a basic example of how to use [UVM](https://www.accellera.org/downloads/standards/uvm) with [Verilator](https://github.com/verilator/verilator).

First, we need to build Verilator.
You may need to install some dependencies:

```sh
sudo apt update -y
sudo apt install -y bison flex libfl-dev help2man z3
# You may already have these:
sudo apt install -y git autoconf make g++ perl python3
```

Then, clone and build latest Verilator:

```sh
git clone https://github.com/verilator/verilator
pushd verilator
autoconf
./configure
make -j `nproc`
popd
```

For the full instructions, visit Verilator's [documentation](https://verilator.org/guide/latest/install.html).

Next, download the UVM code:
```sh
wget https://www.accellera.org/images/downloads/standards/uvm/UVM-1800.2-2020.3.1.tar.gz
tar -xvzf UVM-1800.2-2020.3.1.tar.gz
```

Now, set up the `UVM_HOME` environment variable to point to the extracted UVM sources.
We also need `PATH` to point to Verilator:

```sh
UVM_HOME="$(pwd)/1800.2-2020.3.1/src"
PATH="$(pwd)/verilator/bin:$PATH"
```

To build the simulation, run:

```sh
verilator -Wno-fatal --binary -j $(nproc) --top-module tbench_top \
    +incdir+$UVM_HOME +define+UVM_NO_DPI +incdir+$(pwd) \
    $UVM_HOME/uvm_pkg.sv $(pwd)/sig_pkg.sv $(pwd)/tb.sv
```

Finally, run the simulation:

```sh
./obj_dir/Vtbench_top +UVM_TESTNAME=sig_model_test
```

## Running with iSim

[iSim](https://tn-si.com) is a SystemVerilog + VHDL simulator that ships a
pre-compiled UVM library, so none of the setup above is needed for it: there
is no UVM tarball to download and no `UVM_HOME` to set. `isim.sh` in this
directory builds and runs the bench:

    ./isim.sh

It accepts the usual overrides as environment variables --- `UVM_TESTNAME`,
`ISIM_TOP`, `ISIM_WORK`, and `ISIM_VLOG`/`ISIM_ELAB`/`ISIM` if the tools are
not on `PATH`:

    UVM_TESTNAME=sig_model_test ./isim.sh

The three commands it runs are upstream's own build with exactly two
substitutions --- `$UVM_HOME/uvm_pkg.sv` and `+incdir+$UVM_HOME` are replaced
by `-uvm`, which maps the shipped library --- and `+define+UVM_NO_DPI`
dropped, since that is a Verilator capability workaround and iSim's UVM DPI
surface is real. The two explicit sources and `+incdir+$(pwd)` are unchanged,
so the nine `.svh` class files resolve as `include`s. One file is added:
`sig_if.sv`. Verilator finds the `sig_if` interface by searching its include
directories for a matching file name; iSim, like other commercial simulators,
compiles only the sources it is given, so the script names it.

These commands are deliberately NOT in a fenced code block. `.github/workflows/test.yml`
runs `tuttest README.md | bash -`, and with no snippet name `tuttest` emits
*every* fenced block in this file; a fenced iSim block would therefore run on
a CI runner that has no iSim installed and fail the job on every push. The
indented form keeps this section out of `tuttest`'s output and leaves the
Verilator CI job doing exactly what it did before.
