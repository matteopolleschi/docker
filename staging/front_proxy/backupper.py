import boto3, os
import datetime as dt
from botocore.client import Config
from boto3.s3.transfer import S3Transfer


def rm_file(path):
    os.system('rm {}*'.format(path.split('.')[0]))


class Backup:

    def __init__(self):
        # storage stuff
        self.key = os.environ.get("DO_STORAGE_KEY")
        self.secret = os.environ.get("DO_STORAGE_SECRET")
        self.region = os.environ.get("DO_REGION", "nyc3")
        self.endpoint = os.environ.get("DO_ENDPOINT", "https://nyc3.digitaloceanspaces.com")
        self.bucket = os.environ.get("DO_BUCKET")
        self.remote_dir = os.environ.get("DO_REMOTE_DIR")
        # db stuff
        self.db_uri = os.environ.get("DB_URI")
        # encryption for better safe
        self.file_password = os.environ.get("FILE_PASSWORD")
        self.client = self._get_client()
        self.transfer = S3Transfer(self.client)


    def _get_client(self):
        session = boto3.session.Session()
        return session.client('s3',
                              region_name=self.region,
                              endpoint_url=self.endpoint,
                              aws_access_key_id=self.key,
                              aws_secret_access_key=self.secret)

    def _rotate_dumps(self):
        dumps = []
        raw_lst = self.client.list_objects(Bucket=self.bucket, Prefix=self.remote_dir)['Contents']
        for d in raw_lst:
            if 'dump_' in d['Key']:
                dumps.append({'full_path': d['Key'],
                              'name': d['Key'].split('/')[-1],
                              'last_modified': d['LastModified']})
        dumps = sorted(dumps, key=lambda k: k['last_modified'], reverse=True)
        if len(dumps) > 7:
            for_del = dumps[7:]
            for i in for_del:
                self.client.delete_object(Bucket=self.bucket, Key=i['full_path'])

    def _rotate_dirs(self, prefix):
        dirs = []
        raw_lst = self.client.list_objects(Bucket=self.bucket, Prefix="{}/{}"\
                                           .format(self.remote_dir, prefix))['Contents']
        for d in raw_lst:
            dirs.append({'full_path': d['Key'],
                         'name': d['Key'].split('/')[-1],
                         'last_modified': d['LastModified']})
        dirs = sorted(dirs, key=lambda k: k['last_modified'], reverse=True)
        if len(dirs) > 7:
            for_del = dirs[7:]
            for i in for_del:
                self.client.delete_object(Bucket=self.bucket, Key=i['full_path'])

    # upload then remove the temp file
    def _upload_file(self, file_path, remote_path=None):
        if remote_path is None:
            remote_path = "{}/{}".format(self.remote_dir, file_path.split("/")[-1])
        self.transfer.upload_file(file_path, self.bucket, remote_path)
        rm_file(file_path)

    # replacing existing file with encrypted one
    def _encrypt_file(self, file_path):
        output = file_path+".enc"
        command = "openssl enc -aes-256-cbc -in {input} -out {output} -k {password}"\
            .format(input=file_path, output=output, password=self.file_password)
        status = os.system(command)
        if status != 0:
            raise Exception("Encryption failed")
        return output


    def dir_dump(self, path_to_dir, prefix, encrypt=True):
        curr_datetime = dt.datetime.utcnow().strftime('%d%m%Y_%H%M%S')
        file_path = "/tmp/{}_{}.tar.gz".format(prefix, curr_datetime)
        command = "tar -czvf {} {}".format(file_path, path_to_dir)
        status = os.system(command)
        if status != 0:
            raise Exception("Error taring directory")
        if encrypt:
            file_path = self._encrypt_file(file_path)
        self._upload_file(file_path)
        self._rotate_dirs(prefix)


    def db_dump(self, encrypt=True):
        path = '/tmp/dump_{}.sql.gz'.format(dt.datetime.utcnow().strftime('%d%m%Y_%H%M%S'))

        command = "pg_dump --dbname={db_uri} | gzip > {path}"\
            .format(db_uri=self.db_uri, path=path)
        status = os.system(command)
        if status == 0:
            if encrypt:
                path = self._encrypt_file(path)
            self._upload_file(path)
            self._rotate_dumps()
            print "Ok"
        else:
            print "Error"


if __name__ == '__main__':
    b = Backup()
    b.db_dump()

