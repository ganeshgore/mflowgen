The Modular VLSI Build System
==========================================================================

**Author**: Christopher Torng (clt67@cornell.edu)

Building VLSI implementations with millions of transistors is a
tremendous challenge for computer architecture and VLSI researchers,
and it is even more challenging to go beyond RTL to tape out fully
functional silicon prototypes for use as research vehicles. One of
the most challenging aspects of working with ASIC flows is managing
the many moving pieces (e.g., PDK, physical IP libraries,
ASIC-specific tools), which come from many different vendors and yet
must still be made to work together coherently. Once an ASIC flow
has been successfully assembled, it would be great to reuse it.
Unfortunately, teams typically end up with little reuse since new
designs may for example require slightly different ASIC flows,
target different technology nodes, or even use different vendors for
physical IP.

The Modular VLSI Build System is an open-source set of ASIC tool
scripts and makefiles for managing the moving pieces as well as a
carefully designed set of policies for minimizing the friction when
building new designs. The key idea is to avoid rigidly structured
ASIC flows that cannot be repurposed and to instead break the ASIC
flow into modular steps that can be re-assembled into different
flows. We also introduce the idea of an ASIC design kit (ADK), which
is the specific set of physical backend files required to
successfully build chips, as well as a unified and standard
interface to those files. A well-defined interface enables swapping
process and IP libraries without modification to the scripts that
use them. Finally, this approach embraces plugins that hook into
steps across the entire ASIC flow for customizing the flow in
design-specific ways.

This repository has been used to tape out multiple chips at Cornell
University in advanced process technology nodes (e.g., TSMC 28nm)
and in older process technology nodes (e.g., TSMC 180nm).

--------------------------------------------------------------------------
License
--------------------------------------------------------------------------

The Modular VLSI Build System is offered under the terms of the Open
Source Initiative BSD 3-Clause License. More information about this
license can be found here:

- http://choosealicense.com/licenses/bsd-3-clause
- http://opensource.org/licenses/BSD-3-Clause

--------------------------------------------------------------------------
Tool Dependencies
--------------------------------------------------------------------------

The existing steps are based on the following tools, but other tools
can be plugged into the flow as well.

- Synopsys Design Compiler
- Synopsys VCS
- Cadence Innovus
- Cadence Virtuoso
- Calibre
- Calibre DESIGNrev

The list of ASIC tool versions that this build system has been
verified with is listed later in this README.

--------------------------------------------------------------------------
Quick Start
--------------------------------------------------------------------------

This repo includes the Verilog for a greater common divisor unit
that can be used to demo the ASIC flow (designs/GcdUnit-demo.v).
This section steps through how to clone the repo and push this
design through synthesis and automatic place-and-route.

Clone the repo:

    % git clone git@github.com:cornell-brg/alloy-asic.git
    % cd alloy-asic
    % TOP=$PWD

Configure for the default ASIC flow:

    % cd $TOP
    % mkdir build && cd build
    % ../configure
    % make info  # <-- shows which design is being targeted
    % make graph # <-- shows which steps are in the configured flow
    % make list  # <-- shows most things you can do

Start with synthesis:

    % make synth         # <-- this can take about a minute
    % make runtimes      # <-- check how long each step took
    % make debug-synth   # <-- bring up synthesis results in the GUI

Continue with place-and-route:

    % make signoff       # <-- this can take about ten minutes
    % make debug-signoff # <-- bring up the final layout in the GUI

Run Calibre DRC and LVS:

    % make drc           # <-- these can run in parallel with -j
    % make lvs           # <-- these can run in parallel with -j

Other useful asic flow commands:

    % make               # Execute all steps
    % make info          # Prints useful design information
    % make debug-synth   # Open design vision for synth
    % make debug-init    # See floorplan in Innovus
    % make debug-place   # See placement and power routing in Innovus
    % make debug-signoff # See final design in Innovus
    % make graph         # Draws an ASCII dependency graph of steps
    % make list          # Shows most things you can do
    % make print.*       # Print any Makefile variable
    % make print         # Print contents of all variables in print_list
    % make runtimes      # Table of runtimes
    % make seed          # Just generates the build directories

The rest of this README describes the ASIC Design Kit interface, the
modularized steps, the organization of the repository, and the
verified tool versions in more detail.

--------------------------------------------------------------------------
ASIC Design Kit (ADK) Interface
--------------------------------------------------------------------------

The ADK interface is a standard set of filenames that are used
across all ASIC scripts in the flow. Regardless of how the actual
packages and IP libraries are downloaded, the ADK interface can be
created by making a single directory and copying or symlinking
(recommended) to the appropriate file in the backing store. The ADK
may include process technology files, physical IP libraries (e.g.,
IO cells, standard cells, memory compilers), as well as physical
verification decks (e.g., Calibre DRC/LVS).

Here is a minimal interface to an ASIC design kit containing only
the front-end views to a standard cell library and a routing
technology kit (**ADK files not included**). This interface is
useful for architectural design-space exploration of block-level
designs.

**Note**: The ADK-specific setup script is sourced by every ASIC
tool and specifies high-level ADK-specific information (e.g., the
list of filler cells, min/max routing metal layers, etc.).

```
adk.tcl                     -- ADK-specific setup script

rtk-max.tluplus             -- Interconnect parasitics (max timing)
rtk-min.tluplus             -- Interconnect parasitics (min timing)
rtk-typical.captable        -- Interconnect parasitics (typical)
rtk-tech.lef                -- Routing tech kit LEF
rtk-tech.tf                 -- Routing tech kit Milkyway techfile
rtk-tluplus.map             -- Routing tech kit TLUPlus map
rtk-stream-out.map          -- Stream-out layer map for final GDS

stdcells.db                 -- Standard cell library typical DB
stdcells.lef                -- Standard cell library LEF
stdcells.lib                -- Standard cell library typical Liberty
stdcells.mwlib              -- Standard cell library Milkyway
stdcells.v                  -- Standard cell library Verilog
```

Here is the more general-purpose ADK interface that we use in this
repository (**ADK files not included**):

```
adk.tcl                     -- ADK-specific setup script
alib                        -- Synopsys DC performance cache
calibre-drc-antenna.rule    -- Calibre DRC antenna rule deck
calibre-drc-block.rule      -- Calibre DRC block-level rule deck
calibre-drc-chip.rule       -- Calibre DRC chip-level rule deck
calibre-drc-wirebond.rule   -- Calibre DRC wire bond rule deck
calibre-fill.rule           -- Calibre ODPO/metal fill utility
calibre.layerprops          -- Calibre DRV display properties
calibre-lvs-DFM             -- Calibre LVS design-for-manufacture rules
calibre-lvs.rule            -- Calibre LVS rule deck
calibre-rcx-DFM             -- Calibre RCX design-for-manufacture rules
calibre-rcx.rule            -- Calibre RCX rules
calibre-rcx-rules           -- Calibre RCX rules
display.drf                 -- Cadence Virtuoso display file
iocells-bc.db               -- IO cell library best-case DB
iocells-bc.lib              -- IO cell library best-case Liberty
iocells-bondpads.gds        -- IO bondpad GDS
iocells-bondpads.lef        -- IO bondpad LEF
iocells.db                  -- IO cell library typical DB
iocells.gds                 -- IO cell library GDS
iocells.lef                 -- IO cell library LEF
iocells.lib                 -- IO cell library Liberty
iocells.spi                 -- IO cell library SPICE
iocells.v                   -- IO cell library Verilog
iocells-wc.db               -- IO cell library worst-case DB
iocells-wc.lib              -- IO cell library worst-case Liberty
klayout.lyp                 -- KLayout GDS viewer display file
pdk                         -- Link to PDK directory
pdk.layermap                -- PDK layer mapping file
pdk-rcbest-qrcTechFile      -- Interconnect parasitics (rcbest)
pdk-rcworst-qrcTechFile     -- Interconnect parasitics (rcworst)
pdk-typical-qrcTechFile     -- Interconnect parasitics (typical)
rtk-antenna-rules.tcl       -- Routing rules to avoid antennas
rtk-cbest.captable          -- Interconnect parasitics (cbest)
rtk-cworst.captable         -- Interconnect parasitics (cworst)
rtk-max.tluplus             -- Interconnect parasitics (max timing)
rtk-min.tluplus             -- Interconnect parasitics (min timing)
rtk-rcbest.captable         -- Interconnect parasitics (rcbest)
rtk-rcworst.captable        -- Interconnect parasitics (rcworst)
rtk-stream-in-milkyway.map  -- GDS-to-Milkyway layer map
rtk-stream-out.map          -- Stream-out layer map for final GDS
rtk-stream-out-milkyway.map -- Milkyway-to-GDS layer map
rtk-tech.lef                -- Routing tech kit LEF
rtk-tech.tf                 -- Routing tech kit Milkyway techfile
rtk-tluplus.map             -- Routing tech kit TLUPlus map
rtk-typical.captable        -- Interconnect parasitics (typical)
stdcells-bc.db              -- Standard cell library best-case DB
stdcells-bc.lib             -- Standard cell library best-case Liberty
stdcells.cdl                -- Standard cell library CDL for LVS
stdcells.db                 -- Standard cell library typical DB
stdcells.gds                -- Standard cell library GDS
stdcells.lef                -- Standard cell library LEF
stdcells.lib                -- Standard cell library typical Liberty
stdcells.mwlib              -- Standard cell library Milkyway
stdcells.v                  -- Standard cell library Verilog
stdcells-wc.db              -- Standard cell library worst-case DB
stdcells-wc.lib             -- Standard cell library worst-case Liberty
```

--------------------------------------------------------------------------
Modularized Steps
--------------------------------------------------------------------------

The key idea of a modular VLSI build system is to avoid rigidly
structured ASIC flows that cannot be repurposed and to instead break
the ASIC flow into modular steps that can be re-assembled into
different flows. Specifically, instead of having ASIC steps that
directly feed into the next steps, we design each step in modular
fashion with a collection directory for inputs and a handoff
directory for outputs. If we then describe the ASIC flow as a
dependency graph of these modular steps, then we can leverage the
build system to handle the edges of the graph by simply moving files
from the handoff of one step to the collection of the dependent step
before each step executes.

A minimal step is as simple as a variable specifying a command to
run in a single-line Makefile fragment. The build system then takes
care of hooking it into the flow.

```
command = echo "Hello world!"
```

A minimal set of steps for architectural design-space exploration of
block-level designs can include just the following steps:

```
dc-synthesis           -- Synthesize the design RTL

innovus-flowsetup      -- Generate the Innovus Foundation Flow
innovus-init           -- Initialize and floorplan the design
innovus-place          -- Place
innovus-cts            -- Clock tree synthesis
innovus-postctshold    -- Hold-fixing after clock tree synthesis
innovus-route          -- Routing
innovus-postroute      -- Timing optimization and final tweaks
innovus-signoff        -- Verifying the design + Generating results
```

Here is a broader list of example steps, of which a subset are
included in this repository for reference:

```
template-step          -- Template for creating new steps
template-step-verbose  -- Template for creating new steps with help

calibre-drc            -- Run block-level DRC (Calibre)
calibre-drc-sealed     -- Run seal-ring'ed DRC (Calibre)
calibre-drc-top        -- Run chip-level DRC (Calibre)
calibre-fill           -- Run the Calibre ODPO/metal fill utility
calibre-gds-merge      -- GDS merge the design with IP library GDS
calibre-lvs            -- Run block-level LVS (Calibre)
calibre-lvs-sealed     -- Run seal-ring'ed LVS (Calibre)
calibre-lvs-top        -- Run chip-level LVS (Calibre)
calibre-seal           -- GDS merge the design with the seal ring
dc-synthesis           -- Synthesize the design RTL
gen-sram-cdl           -- Generate CDL from memory compiler
gen-sram-db            -- Generate DB from memory compiler
gen-sram-gds           -- Generate GDS from memory compiler
gen-sram-lef           -- Generate LEF from memory compiler
gen-sram-lib           -- Generate Liberty from memory compiler
gen-sram-verilog       -- Generate Verilog from memory compiler
info                   -- Print useful summary information
innovus-flowsetup      -- Generate the Innovus Foundation Flow
innovus-init           -- Initialize and floorplan the design
innovus-place          -- Place
innovus-cts            -- Clock tree synthesis
innovus-postctshold    -- Hold-fixing after clock tree synthesis
innovus-route          -- Routing
innovus-postroute      -- Timing optimization and final tweaks
innovus-signoff        -- Verifying the design + Generating results
mosis                  -- Tarball + Generate checksum before tapeout
sim-prep               -- Simulation preparation
sim-rtl-hard           -- RTL simulation with hardened IP
summarize-area         -- Analysis pass summarizing post-syn area
vcs-aprff              -- Gate-level sim for functionality
vcs-aprff-build        -- Gate-level sim for functionality
vcs-aprffx             -- Gate-level sim for functionality with X
vcs-aprffx-build       -- Gate-level sim for functionality with X
vcs-aprsdf             -- Gate-level sim for timing
vcs-aprsdf-build       -- Gate-level sim for timing
vcs-aprsdfx            -- Gate-level sim for timing with X
vcs-aprsdfx-build      -- Gate-level sim for timing with X
vcs-common-build       -- Common step for VCS sim
vcs-rtl                -- Synopsys VCS RTL sim
vcs-rtl-build          -- Synopsys VCS RTL sim
```

--------------------------------------------------------------------------
Organization of the Repository
--------------------------------------------------------------------------

The repository is organized at the top level with individual
directories for modular steps, for the default flow, for custom
flows, and for the design source code:

```
alloy-asic/
│
├── Makefile.in   -- Primary makefile for the build system
│
├── designs/      -- RTL source code
│
├── default-flow/ -- Default flow for architectural design-space expl.
├── custom-flows/ -- Custom flows for VLSI exploration, chips, etc.
│
├── steps/        -- Collection of modular steps
│
│── utils/        -- Helper scripts
│
├── configure     -- Configure script to select an assembled ASIC flow
├── configure.ac  -- Autoconf configure script generatings "configure"
├── ctx.m4        -- Autoconf helper macros
│
└── LICENSE       -- License
```

An assembled flow brings together an ADK, the flow dependency graph,
the design source RTL, and a set of plugins for customizing the
steps. For example, the default flow is organized like this:

```
default-flow/
│
├── setup-adk.mk     -- ADK selection
├── setup-design.mk  -- Design
├── setup-flow.mk    -- Flow composed of modular steps
│
└── plugins/         -- Plugins that hook into steps
    ├── calibre/
    │   └── (calibre-plugins)
    ├── dc-synthesis/
    │   └── (dc-synthesis-plugins)
    └── innovus/
        └── (innovus-plugins)
```

Assembling a flow involves setting up the ADK, setting up the
design, assembling the ASIC flow from modular steps, and providing
plugins to customize the steps:

- **Setting up the ADK**: This just involves setting the "$adk\_dir"
  variable to point to the directory with the ADK symlinks.

- **Setting up the design**: This involves selecting the design to
  push as well as its top-level Verilog module name, the clock
  target, and the Verilog source file.

- **Assembling the ASIC flow**: To assemble an ASIC flow, list the
  steps and then specify for each step what the dependencies of that
  step are. See the default flow "setup-flow.mk" for an example.

- **Creating plugins for customization**: Plugin scripts are called
  from within steps and serve as user-defined hooks for customizing
  a step to a particular design. The default flow has default
  plugins that will work for a small subset of designs, but more
  complex designs (e.g., taping out a chip) will require heavy
  modifications to the plugin scripts.

Finally, the top-level "custom-flows" directory can hold additional
flows for different projects, and selecting between flows is done at
configuration time:

```
custom-flows/
│
├── designA/   -- ../configure --with-designA
├── designB/   -- ../configure --with-designB
└── designC/   -- ../configure --with-designC
```

Note that the top-level configure.ac must include an entry for each
custom flow for the configure script to work:

```
% cd $TOP
(add new entry for "designA" to the configure.ac)
% autoconf
% mkdir build && cd build
% ../configure --with-designA
```

--------------------------------------------------------------------------
Adding New Modular Steps to an ASIC Flow
--------------------------------------------------------------------------

Adding new steps is extremely low overhead, especially considering
that steps can be as simple as a variable specifying a command to
run (e.g., `command = echo "Hello world!"`) in a single-line
Makefile fragment. Within the top-level "steps" directory, each
sub-directory is a step. Therefore, we can add a new minimal step
and include a new configuration makefile fragment like this:

```
% cd $TOP/steps
% mkdir hello
% echo "commands.hello = echo Hello World" > hello/configure.mk
```

We can then modify the default flow, for example, so that this new
step always runs first. Add the new "hello" step to
`$TOP/default-flow/setup-flow.mk` like this:

```
steps = \
  hello \
  (...)

dependencies.hello = seed
```

Note that the "seed" step is provided by the build system and simply
creates all configured build directories. We have configured "hello"
to depend on "seed" and they will therefore run in that order.

Now we can run the new step, which will output "Hello World":

```
% cd $TOP                  #
% mkdir build && cd build  #
% ../configure             # <-- configure for the default flow

% make list                # <-- the new step "hello" is in the list!
% make graph               # <-- visualize the dependencies

% make hello               # <-- run the new step
```

Template step descriptions with additional built-in handles for
various convenient features of the build system are provided below:

- [Step Template](steps/template-step/configure.mk)
- [Step Template (verbose)](steps/template-step-verbose/configure.mk)

--------------------------------------------------------------------------
Verified Tool Versions
--------------------------------------------------------------------------

This build system has been verified with the following ASIC tool versions.

Synopsys Design Compiler:

```
% dc_shell-xg-t -v

dc_shell version    -  M-2016.12
dc_shell build date -  Nov 21, 2016
```

Synopsys VCS:

```
% vcs -ID

vcs script version : N-2017.12
Compiler version = VCS N-2017.12-1
VCS Build Date = Jan 18 2018 20:49:41
```

Cadence Innovus:

```
% innovus -version

@(#)CDS: Innovus v17.13-s098_1 (64bit) 02/08/2018 11:26 (Linux 2.6.18-194.el5)
@(#)CDS: NanoRoute 17.13-s098_1 NR180117-1602/17_13-UB (database version 2.30, 414.7.1) {superthreading v1.44}
@(#)CDS: AAE 17.13-s036 (64bit) 02/08/2018 (Linux 2.6.18-194.el5)
@(#)CDS: CTE 17.13-s031_1 () Feb  1 2018 09:16:44 ( )
@(#)CDS: SYNTECH 17.13-s011_1 () Jan 14 2018 01:24:42 ( )
@(#)CDS: CPE v17.13-s062
@(#)CDS: IQRC/TQRC 16.1.1-s220 (64bit) Fri Aug  4 09:53:48 PDT 2017 (Linux 2.6.18-194.el5)
@(#)CDS: OA 22.50-p063 Fri Feb  3 19:45:13 2017
@(#)CDS: SGN 10.10-p124 (19-Aug-2014) (64 bit executable)
@(#)CDS: RCDB 11.10
```

Cadence Virtuoso:

```
% virtuoso -V

@(#)$CDS: virtuoso version 6.1.7-64b 01/24/2018 13:57 (sjfhw315) $
```

Calibre:

```
% calibre -version

//  Calibre v2018.1_27.18    Thu Mar 1 14:53:23 PST 2018
//  Calibre Utility Library   v0-8_2-2017-1    Thu Aug 3 00:36:49 PDT 2017
//  Litho Libraries v2018.1_27.18  Thu Mar 1 14:53:23 PST 2018
```

Calibre DESIGNrev:

```
% calibredrv -version

//  Calibre DESIGNrev v2018.1_27.18    Thu Mar 1 14:53:23 PST 2018
//  Calibre Utility Library   v0-8_2-2017-1    Thu Aug 3 00:36:49 PDT 2017
```

Some parts of the Makefile are dependent on Bash (verified with
version 4.2.46(2)).

