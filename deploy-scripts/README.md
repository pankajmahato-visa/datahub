# Steps to run individual modules

Create `env` folder in the root `/datahub` directory

This `env` folder will have the environment variables which would be overwritten with the TAR ball's contents

Inside the `env` folder the files should be like below

For GMS

`datahub-gms.env` --> This will override the entire TAR ball's  contents

`datahub-gms-creds.env` --> This will supplement new or override individual variables. Recommend for supplementing with credentials and certian variables overriding

For Frontend

`datahub-frontend.env`

`datahub-frontend-creds.env`

This is how folder structure should be

    datahub
        |-datahub-latest
        |-datahub-previous
        |env
            |-datahub-frontend-creds.env
            |-datahub-frontend-prod.env
            |-datahub-frontend.env
            |-datahub-gms-creds.env
            |-datahub-gms.env

# Datahub GMS
cd into datahub-latest/datahub-gms
`cd datahub-latest/datahub-gms`

Run as background process
`nohup sh start.sh > /dev/null 2> datahub-gms.log < /dev/null & echo $! > datahub-gms.pid`

Stop  background running gms service ( replace `-15` with `-9` to force kill)
`[ -f datahub-gms.pid ] && cat datahub-gms.pid | xargs kill -15 || true`

Run as forground process
`./start.sh`

# Datahub Frontend
cd into datahub-latest/datahub-gms
`cd datahub-latest/datahub-frontend`

Run as background process
`nohup sh start.sh > /dev/null 2> datahub-frontend.log < /dev/null & echo $! > datahub-frontend.pid`

Stop  background running gms service ( replace `-15` with `-9` to force kill)
`[ -f datahub-frontend.pid ] && cat datahub-frontend.pid | xargs kill -15 || true`

Run as forground process
`./start.sh`
