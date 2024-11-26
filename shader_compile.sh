#!/usr/bin/bash

glslc ./shaders/test.vert -o ./shaders/test.vert.spv
glslc ./shaders/test.frag -o ./shaders/test.frag.spv
# naga ./shaders/test.vert ./shaders/test.vert.spv --input-kind glsl --shader-stage vert
# naga ./shaders/test.frag ./shaders/test.frag.spv --input-kind glsl --shader-stage frag

