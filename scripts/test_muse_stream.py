from muse_adapter import MuseStreamAdapter


def main():
    adapter = MuseStreamAdapter()
    adapter.connect()

    print("Reading 10 samples from Muse EEG stream...")
    for i in range(10):
        sample, ts = adapter.pull_sample()
        if sample is None:
            print("No sample received.")
            continue
        print(f"{i+1:02d} | timestamp={ts:.3f} | len={len(sample)} | sample={sample}")


if __name__ == "__main__":
    main()