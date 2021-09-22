# Zig NFSN

This is a zig library for interacting with the NearlyFreeSpeech.net REST API. 
Not everything is implemented, but the NearlyFreeSpeech.net API is also not completely implemented.
The main use case for the library was to make a ddns script so I could use my home server outside of my home.
Using zig probably increased the time required to implement this but I learned a lot doing it, so I'm satisfied.

## Building

For an x86_64 server running linux:

``` sh
gyro build -Drelease-safe -Dtarget=x86_64-linux-musl
```

The copy `zig-out/bin/nfsn-ddns` to your server.

## Using

`nfsn-ddns` will require some configuration to be useful. You will need something to make it run periodically. 
I made a systemd service, but a cronjob could also be made.

Put the following files in `/etc/systemd/system/`

`nfsn-ddns.service`
``` ini
// TODO: update README once I get the updated script uploaded to the server
[Unit]
Description=A dynamic dns client
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=oneshot
ExecStart=/path/to/nfsn-ddns
Environment=CONFIG_DIRECTORY=/path/to/config.json
LoadCredential=credentials.json:/path/to/credentials.json
```

`nfsn-ddns.timer`
``` ini
// TODO: update README once I get the updated script uploaded to the server
```

You will also need `ddns.json` and `credentials.json`. These can go wherever you want, but credentials.json should only be accessible to the `nfsn-ddns` service for security.
You will need to pass the directories they are in to `nfsn-ddns` using the environment variables `CREDENTIALS_DIRECTORY` and `CONFIG_DIRECTORY`.

`ddns.json`
``` json
{
    "domain": "yourdomain.com",
    "subdomain": "subdomain",
    "type": "A",
    "ttl": 3600
}
```

`credentials.json`
``` json
{
    "user": "yourusername",
    "apikey": "yourapikey"
}
```

## Dependencies

- [requestz](https://github.com/ducdetronquito/requestz)
- [h11](https://github.com/ducdetronquito/h11)
- [http](https://github.com/ducdetronquito/http)
- [iguanaTLS](https://github.com/alexnask/iguanaTLS)
- [zig-network](https://github.com/MasterQ32/zig-network)
