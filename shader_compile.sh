#!/usr/bin/bash

naga ./shaders/test.frag.wgsl ./shaders/test.frag.spv --keep-coordinate-space
naga ./shaders/test.vert.wgsl ./shaders/test.vert.spv --keep-coordinate-space