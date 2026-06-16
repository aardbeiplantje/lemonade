#!/bin/bash
lemonade config set llamacpp.backend=rocm
lemonade config set sdcpp.backend=rocm
lemonade config set whispercpp.backend=vulkan
lemonade config set extra_models_dir=/models
lemonade config set ctx_size=1000000
lemonade config set rocm_channel=stable
lemonade config set enable_dgpu_gtt=true
lemonade config set disable_model_filtering=false
lemonade config set log_level=debug
lemonade config set host=::
lemonade config set port=9000
