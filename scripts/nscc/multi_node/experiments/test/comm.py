import torch
import os
import horovod.torch as hvd
import socket

hvd.init()

os.environ['MASTER_ADDR']="localhost"
os.environ['MASTER_PORT']="6002"

hostname = socket.gethostname()

# rank = os.getenv('OMPI_COMM_WORLD_RANK', '0')
rank = hvd.local_rank()
world = hvd.size()
# world = os.getenv("OMPI_COMM_WORLD_SIZE", '1')

print("rank: {}, world size: {}, hostname: {}".format(rank, world, hostname))
print("trying to initliaze dist")
torch.distributed.init_process_group(
    backend="nccl",
    world_size=world, rank=rank)
print("init successful on hostname: {}".format(hostname))