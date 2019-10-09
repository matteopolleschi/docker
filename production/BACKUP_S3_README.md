## Backup usage examples

Docker:
```sh
$ docker run --network=<odoo network> -e AWS_ACCESS_KEY_ID=<key> -e AWS_SECRET_ACCESS_KEY=<secret> -e S3_BUCKET=<my-bucket> -e S3_PREFIX=<backup> -e ODOO_MASTER_PASSWORD=<password> -e DATABASES=<comma-separated list of database names> -e SCHEDULE=<backup frequency> quay.io/avoinsystems/odoo-backup-restore-s3
```

## Configuration options can be passed as environment variables.

| Variable                | Purpose                   |Default   |
| ----------------------- | ------------------------- | -------- |
| `ODOO_HOST`             | Odoo container hostname   | `odoo`   |
| `ODOO_PORT`             | Odoo container port       | `8069`   |
| `ODOO_MASTER_PASSWORD`  | Odoo master password      | `admin`  |
| `ODOO_VERSION`          | Odoo version number (8, 9, 10, 11 or 12) | `11` |
| `DATABASES`             | A single database or comma-separated list of databases   |   |
| `AWS_ACCESS_KEY_ID`     | Amazon AWS Access Key ID  |          |
| `AWS_SECRET_ACCESS_KEY` | Amazon AWS Secret Access Key |       |
| `AWS_REGION`            | The default AWS region       |  |
| `S3_BUCKET`             | Amazon AWS S3 bucket name    |  |
| `S3_PATH`               | The backup path inside the bucket, a.k.a. prefix   |`backup`   |
| `RESTORE_FILENAME`      | Which backup file to restore. Only used when restoring backup.  If empty, the latest backup will be restored |   |
| `SCHEDULE`              | Backup frequency. `single` = backup only once. See all available options [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules).  |`single`   |
| `CHECK_URL`             | A URL to call with a GET request after a successful backup   |   |
| `PROTOCOL`              | The protocol to use (`xmlrpc`, `http`). HTTP is more memory-efficient. | `xmlrpc` |
