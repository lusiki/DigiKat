"""Persist exact software and hardware provenance, without corpus text."""
import importlib.metadata, platform, subprocess
import torch
from voices_common import atomic_json, utc, workdir
packages={d.metadata['Name']:d.version for d in importlib.metadata.distributions()}
atomic_json(workdir()/'environment.json',dict(created_utc=utc(),python=platform.python_version(),
    packages=packages,cuda_available=torch.cuda.is_available(),torch_cuda=torch.version.cuda,
    gpu=torch.cuda.get_device_name(0) if torch.cuda.is_available() else None))
print('Environment recorded; GPU available:',torch.cuda.is_available())
