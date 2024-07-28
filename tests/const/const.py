#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : const.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 12.07.2023
# Last Modified Date: 27.07.2024
import os
import glob


class cfg:
    RST_CYCLES = 3
    CLK_100MHz = (10, "ns")
    TIMEOUT_TEST = (CLK_100MHz[0] * 200, "ns")
    TIMEOUT_TEST = (CLK_100MHz[0] * 200, "ns")

    TOPLEVEL = str(os.getenv("DUT"))
    SIMULATOR = str(os.getenv("SIM"))

    TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
    INC_DIR = [os.path.join(TESTS_DIR, "../../bus_arch_sv_pkg")]
    RTL_DIR = os.path.join(TESTS_DIR, "../../rtl")
    SKID_DIR = os.path.join(TESTS_DIR, "../../skid_buffer/rtl")
    BUS_PKG_DIR = os.path.join(TESTS_DIR, "../../bus_arch_sv_pkg")

    VERILOG_SOURCES = []  # The sequence below is important...
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f"{BUS_PKG_DIR}/*.sv", recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f"{RTL_DIR}/*.v", recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f"{RTL_DIR}/*.sv", recursive=True)
    VERILOG_SOURCES = VERILOG_SOURCES + glob.glob(f"{SKID_DIR}/*.sv", recursive=True)

    EXTRA_ENV = {}
    EXTRA_ENV["COCOTB_HDL_TIMEPRECISION"] = os.getenv("TIMEPREC")
    EXTRA_ENV["COCOTB_HDL_TIMEUNIT"] = os.getenv("TIMEUNIT")
    TIMESCALE = os.getenv("TIMEUNIT") + "/" + os.getenv("TIMEPREC")

    if SIMULATOR == "verilator":
        EXTRA_ARGS = [
            "--trace-fst",
            "--coverage",
            "--coverage-line",
            "--coverage-toggle",
            "--trace-structs",
            "--Wno-UNOPTFLAT",
            "--Wno-REDEFMACRO",
        ]
    else:
        EXTRA_ARGS = []
