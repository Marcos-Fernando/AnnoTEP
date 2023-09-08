import zipfile
import tarfile
import os
import shutil

#compactando no formato .zip
def zip_folder(origin_folder, dest_zip):
    shutil.make_archive(dest_zip, 'zip', origin_folder)

#compactando no formato tar.gz
def tar_folder(origin_folder, dest_tar_gz):
    shutil.make_archive(dest_tar_gz, 'gztar', origin_folder)
