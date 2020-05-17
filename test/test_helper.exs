ExUnit.configure(seed: elem(:os.timestamp(), 2))
ExUnit.start()
Code.require_file("test/messages.exs")
Code.require_file("test/random_init.exs")
