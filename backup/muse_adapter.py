import numpy as np
from pylsl import StreamInlet, resolve_byprop


class MuseStreamAdapter:
    def __init__(self, stream_type: str = "EEG", timeout: float = 10.0):
        self.stream_type = stream_type
        self.timeout = timeout
        self.inlet = None
        self.channel_labels = None

    def connect(self):
        print(f"Looking for an LSL stream of type '{self.stream_type}'...")
        streams = resolve_byprop("type", self.stream_type, timeout=self.timeout)

        if not streams:
            raise RuntimeError("No EEG LSL stream found. Make sure `muselsl stream` is running.")

        self.inlet = StreamInlet(streams[0], max_buflen=360)
        info = self.inlet.info()

        print(f"Connected to stream: {info.name()}")

        # Try to read channel labels if available
        self.channel_labels = []
        desc = info.desc()
        ch = desc.child("channels").child("channel")
        while ch.name():
            label = ch.child_value("label")
            self.channel_labels.append(label if label else f"ch{len(self.channel_labels)}")
            ch = ch.next_sibling()

        if self.channel_labels:
            print("Channel labels:", self.channel_labels)
        else:
            print("No channel labels found in stream metadata.")

    def pull_sample(self):
        if self.inlet is None:
            raise RuntimeError("Muse stream is not connected.")

        sample, timestamp = self.inlet.pull_sample(timeout=5.0)
        if sample is None:
            return None, None

        return np.asarray(sample, dtype=np.float32), timestamp