"""Bridge a container launcher to the controller's separate IPC and output channels."""

import base64
import json
import os
import subprocess
import sys
import threading


def main():
    environment = json.load(sys.stdin)
    argv = sys.argv[1:]
    read_fd, write_fd = os.pipe()
    argv[argv.index("--metadata-fd") + 1] = str(write_fd)
    metadata = bytearray()
    limit = 65536
    output_lock = threading.Lock()

    def emit(record):
        with output_lock:
            print(json.dumps(record), flush=True)

    def capture():
        with os.fdopen(read_fd, "rb") as pipe:
            metadata.extend(pipe.read(limit + 1))

    def forward(pipe, channel):
        with pipe:
            while chunk := os.read(pipe.fileno(), 8192):
                emit({"channel": channel, "content": base64.b64encode(chunk).decode()})

    with subprocess.Popen(argv, env=environment, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, pass_fds=(write_fd,)) as worker:
        os.close(write_fd)
        reader = threading.Thread(target=capture, daemon=True)
        reader.start()
        output = [
            threading.Thread(target=forward, args=(pipe, channel), daemon=True)
            for pipe, channel in ((worker.stdout, "stdout"), (worker.stderr, "stderr"))
        ]
        for thread in output:
            thread.start()
        status = worker.wait()
        threads = [reader, *output]
        for thread in threads:
            thread.join(timeout=1)
        complete = not any(thread.is_alive() for thread in threads)
        emit({"exit": status if complete else 2, "metadata": base64.b64encode(metadata).decode() if complete else ""})


if __name__ == "__main__":
    main()
