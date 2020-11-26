#!/usr/bin/python2

from __future__ import print_function

SSH_PORT = 41017

import subprocess
import os
import tempfile
import shutil
import stat
import sys

with open(os.environ["PBS_NODEFILE"], "r") as f:
    hosts = dict()
    for host in f:
        host = host.strip()
        cnt = hosts.get(host, 0)
        cnt += 1
        hosts[host] = cnt

hstrings = ["{0}:{1}".format(h, s) for (h, s) in hosts.items()]    

def generate_ssh_config_file():
    sections = []

    for host in hosts:
        sections.append(
            ("Host {0}\n"
             "\tPort {1}\n"
             "\tStrictHostKeyChecking no\n".format(host, SSH_PORT)))
    return "\n".join(sections)

    
tempdir = tempfile.mkdtemp(dir=os.getenv("HOME") + "/sshcont")
print("Created temporary config directory:", tempdir)
print("bind mount that directory under $HOME/.ssh")

os.chmod(tempdir, stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR)

configfile = tempdir + "/config"
with open(configfile, "w") as f:
    f.write(generate_ssh_config_file())
os.chmod(configfile, stat.S_IRUSR | stat.S_IWUSR)


keyfile = tempdir + "/id_rsa"
pubkey = tempdir + "/authorized_keys"
out = subprocess.Popen("dropbearkey -t rsa -f {0}".format(keyfile), shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
out.wait()
if out.returncode != 0:
    raise RuntimeError("return not zero")
out = out.stdout.read()

with open(pubkey, "w") as f:
    f.write(out.splitlines()[1])
subprocess.check_call("dropbearconvert dropbear openssh {0} {1}".format(keyfile, keyfile), shell=True)
os.chmod(pubkey, stat.S_IRUSR | stat.S_IWUSR)

os.environ["NTUHPC_OPENMPI_HOSTSPEC"] =  ",".join(hstrings)
os.environ["NTUHPC_SSH_DIR"] = tempdir
os.environ["NTUHPC_OPENMPI_HOSTCOUNT"] = str(len(hosts))
os.environ["NTUHPC_OPENMPI_SLOTCOUNT"] = str(sum(hosts.values()))
try:
    subprocess.check_call(" ".join(sys.argv[1:]), shell=True)
finally:
    shutil.rmtree(tempdir)
