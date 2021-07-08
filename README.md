# mssql-testing

### Microsoft SQL Server Docker image with some convenience tools for software testing

Features

- Attach databases from a JSON file

    **ATTACH_PATH** env variable, must be a path for a file or directory containing one or more `.json` files, each consisting of an array of databases, which can have zero to N databases.

    *dbName*: The name of the database

    *dbFiles*: An array of one or many absolute paths to the .MDF and .LDF files.

    Example:
    ```JSON
    [
        {
            "dbName": "MaxDb",
            "dbFiles": ["/volume/maxtest/maxtest.mdf",
            "/volume/maxtest/maxtest_log.ldf"]
        },
        {
            "dbName": "PerryDb",
            "dbFiles": ["/volume/perrytest/perrytest.mdf",
            "/volume/perrytest/perrytest_log.ldf"]
        }
    ]
    ```

- Enable CLR Y|N

    **ENABLE_CLR** env variable, must be "Y" to enable the common language runtime (CLR), enabling .Net assemblies to run as stored procedures.

- No-Policy weak passwords

    **SA_NO_POLICY_PASSWORD** env variable, allowing to define a weak password, such as "1234".

    Note that **SA_PASSWORD** is still required and must be set with a strong password, which will be reset by the weak one if defined

- Configurable AUTO_CLOSE ON|OFF

    **AUTO_CLOSE** env variable, can be set to "ON" to enabled database auto close when no connections were active. Default is "OFF"

- Configurable MAX_MEMORY

    **MAX_MEMORY** env variable, can be set to an integer representing the max amount of megabytes used by SQL cache.

- Execute your SQL Server in a fake datetime

    **RUN_AS_DATE** env variable, can be set to a date in the `yyyy-MM-dd` format, regardless of the system clock.


## Usage:

```bash
docker run -d \
-p 1433:1433 \
-v /volume:/volume \
-e ACCEPT_EULA=Y \
-e SA_PASSWORD="St5rOng%Pass@rD_" \
-e ATTACH_PATH="/volume/attach.json" \
-e ENABLE_CLR=Y \
-e SA_NO_POLICY_PASSWORD="1234" \
-e AUTO_CLOSE=ON \
-e MAX_MEMORY=1024
-e RUN_AS_DATE="2019-11-25"
batiati/mssql-testing
```

## Building

```bash
git clone https://github.com/batiati/mssql-testing ./mssql-testing
cd ./mssql-testing
docker build . --tag mssql-testing
```

## License

* This project is a free and unencumbered software released into the public domain. Plese visit [unlicense.org](https://unlicense.org/) for more details.

