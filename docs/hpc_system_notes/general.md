# General Notes

## Get to Know Your Scheduler

HPC clusters always have a job scheduler which dispatches jobs submitted to a queue. You can refer to this official 
documentation for how to use the job scheduler.

- PBS Pro: [Documentation](https://help.nscc.sg/pbspro-quickstartguide/)
- SLURM: [Documentation](https://slurm.schedmd.com/documentation.html)

## How to Debug on HPC Cluster

### Use debug node

In general, HPC clusters provide a development node for you to test your code. For example, you can use the `dgx-dev` 
queue on NSCC to run interactive job and debug you code on one node with 4 GPUs.

### Use JupyterLab

Development nodes usually have resource limitation such as wall time. It is also bad when your terminal gets stuck as 
you have to quit and re-submit the job again. Thus, I would recommend to use JupyterLab to debug your job. This has 
several advantages:

1. You can have multiple terminals
2. You can edit your files
3. Your job is still running if you disconnect

If you are not a vim enthusiast (even though I highly recommend it as you can make it a pro IDE if you install plugins),
you can use JupyterLab for convenience.

You can refer to the [NSCC notes](nscc.md) on how to set up JupyterLab.

### Use IDE

You can refer to the following documentation on how to use IDE on clusters.
- VS Code: [documentation](https://code.visualstudio.com/docs/remote/ssh)
- PyCharm: [documentation](https://www.jetbrains.com/help/pycharm/tutorial-deployment-in-product.html#comparing)

## How to Run Many Short Experiments With a Single Job Submission

Sometimes, you may need to run many experiments while each experiment only takes several minutes. Thus, it is definitely
not a good idea to submit a job script for each experiment. For example, I only want to profile the peak memory usage 
in one iteration of my training process. In this case, it is recommended to use JupyterLab for experiments. This has
several advantages:

1. You don't have to worry about program error when you run many experiments. For example, when you only submit a job 
   to the scheduler, the job will get stuck if your program runs into out-of-memory. However, if you run JupyterLab,
   you can just terminate it with `ctrl+c` and continue with your next try.
2. JupyterLab is running in the job dispatched by the scheduler. Thus, the environment inherits variables passed by the 
   scheduler, for example, the `NODEFILE` variable of PBS Pro.

## How to Find Network Interface

Network interface needs to be specified for distributed training. This is to tell which interface to rely on for 
communication. For example, when running PyTorch distributed, you may find that your script stuck at the initialization
of the default process group. Usually this is because PyTorch does not know which interface to use to cross-node 
communication, or some found interfaces have issues. You can specify the network interface for communication by setting the
environment variables `NCCL_SOCKET_IFNAME` or `GLOO_SOCKET_IFNAME` depending on the backend of your choice.
You can check the available network interfaces by the command `ifconfig` or use 
[PyRoute2](https://github.com/svinota/pyroute2) if this command is not available. You can also get the host address in 
this way as well.

```python
from pyroute2 import NDB

ndb = NDB(log='debug')
print(ndb.addresses.summary())
```

For example, you can find `ib0` in the list on NSCC. It means InfiniBand and you can set `NCCL_SOCKET_IFNAME=ib0` in 
your script. Base on test, if you do not set this environment variable, your PyTorch initialization will stuck.

