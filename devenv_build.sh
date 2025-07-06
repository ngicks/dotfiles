#!/bin/bash

podman image build . -f ./devenv.Dockerfile -t devenv
