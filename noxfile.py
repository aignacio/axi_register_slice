#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# File              : noxfile.py
# License           : MIT license <Check LICENSE>
# Author            : Anderson I. da Silva (aignacio) <anderson@aignacio.com>
# Date              : 08.10.2023
# Last Modified Date: 27.07.2024

import nox


@nox.session(python=["3.6", "3.7", "3.8", "3.9", "3.10", "3.12"])
def run(session):
    session.env["DUT"] = "axi_register_slice"
    session.env["SIM"] = "verilator"
    # session.env['SIM'] = 'verilator'
    session.env["TIMEPREC"] = "1ps"
    session.env["TIMEUNIT"] = "1ns"
    session.install(
        "pytest",
        "pytest-xdist",
        "pytest-split",
        "cocotb >= 1.8.0",
        "cocotb-test",
    )
    session.run(
        "pytest",
        "--ignore=skid_buffer/tests/test_basic.py"
        "-rP",
        "-n",
        "auto",
        *session.posargs
    )
