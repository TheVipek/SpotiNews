return {
  name = "SpotifyNews",
  version = "0.0.1",
  description = "Simple bot deveoped with Discordia",
  tags = { "lua", "lit", "luvit" },
  license = "MIT",
  author = { name = "TheVipek", email = "thevipek0552@gmail.com" },
  homepage = "https://github.com/SpotifyNews",
  dependencies = {
    "SinisterRectus/discordia@2.11.2",
    "creationix/base64@2.0.0",
    "creationix/base64url@2.0.0",
    "creationix/coro-channel@3.0.3",
    "creationix/coro-http@3.2.3",
    "creationix/coro-net@3.3.1",
    "creationix/coro-websocket@3.1.1",
    "creationix/coro-wrapper@3.1.0",
    "creationix/pathjoin@2.0.0",
    "creationix/sha1@1.0.4",
    "creationix/websocket-codec@3.0.2",
    "luvit/http-codec@3.0.7",
    "luvit/json@2.5.2",
    "luvit/resource@2.1.0",
    "luvit/secure-socket@1.2.3"
  },
  files = {
    "**.lua",
    "!test*"
  }
}
