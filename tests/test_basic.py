#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : test_basic.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson Ignacio da Silva (aignacio) <anderson@aignacio.com>
# Date              : 12.07.2023
# Last Modified Date: 21.08.2024
import random
import cocotb
import os
import logging
import pytest
import copy

from random import randrange
from const.const import cfg
from cocotb_test.simulator import run
from cocotb.triggers import ClockCycles
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.regression import TestFactory
from cocotb.result import TestFailure
from cocotbext.axi import AxiBus, AxiMaster, AxiSlave, AxiRam, AxiResp


async def setup_dut(dut, cycles):
    cocotb.start_soon(Clock(dut.clk, *cfg.CLK_100MHz).start())
    dut.arst.value = 1
    await ClockCycles(dut.clk, cycles)
    dut.arst.value = 0


@cocotb.test()
async def run_test(dut):
    await setup_dut(dut, cfg.RST_CYCLES)

    n = 1000
    ram_size = 2**12
    axi_master = AxiMaster(AxiBus.from_prefix(dut, "slave"), dut.clk, dut.arst)
    axi_ram = AxiRam(
        AxiBus.from_prefix(dut, "master"), dut.clk, dut.arst, size=ram_size
    )

    addr = [random.randint(0, ram_size - 1) & 0xFFFFFFFC for _ in range(n)]
    data = [random.randint(0, (2**32 - 1)) for _ in range(n)]

    for addr, data in zip(addr, data):
        await axi_master.write(
            addr, bytearray(data.to_bytes(4, byteorder="little")), size=2
        )
        rdata = await axi_master.read(addr, 4)
        assert rdata.data == axi_ram.read(addr, 4), "Mismatch between data"


def test_basic():
    """
    Dispatch few AXI txns through register slice bridge to AXI RAM

    Test ID: 1
    """
    module = os.path.splitext(os.path.basename(__file__))[0]
    SIM_BUILD = os.path.join(
        cfg.TESTS_DIR, f"../../run_dir/sim_build_{cfg.SIMULATOR}_{module}"
    )
    extra_args_sim = cfg.EXTRA_ARGS
    plus_args_sim = cfg.PLUS_ARGS

    run(
        python_search=[cfg.TESTS_DIR],
        includes=cfg.INC_DIR,
        verilog_sources=cfg.VERILOG_SOURCES,
        toplevel=cfg.TOPLEVEL,
        timescale=cfg.TIMESCALE,
        module=module,
        sim_build=SIM_BUILD,
        extra_args=extra_args_sim,
        plus_args=plus_args_sim,
        waves=1,
    )
