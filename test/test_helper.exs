ExUnit.configure(seed: elem(:os.timestamp, 2))
ExUnit.start()
Code.load_file("test/messages.exs")
Code.load_file("test/random_init.exs")
