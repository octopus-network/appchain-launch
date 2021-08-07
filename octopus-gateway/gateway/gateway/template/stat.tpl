{
    "name": "stat",
    "keys": [
        "stat@#^*&"
    ],
    "port": 7002,
    "session": {
        "key": "sid",
        "signed": false,
        "maxAge": 2592000000,
        "httpOnly": false
    },
    "limit": {
        "daily": {
            "0": 1000000,
            "1": 5000000
        },
        "project": {
            "0": 20,
            "1": 100
        }
    },
    "projects": 100,
    "timeout": 5000,
    "requests": 1000,
    "test": true,
    "chain": {},
    "redis": {
        "host": "",
        "port": "",
        "password": "",
        "cert": ""
    },
    "etcd": {
        "hosts": "",
        "username": "",
        "password": ""
    },
    "kafka": {
        "hosts": "",
        "topic": "",
        "sasl": {
            "mechanism": "",
            "username": "",
            "password": ""
        }
    }
}