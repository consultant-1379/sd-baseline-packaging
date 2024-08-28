#!/usr/bin/python
import os
from subprocess import Popen, PIPE
import docker
import shutil
import logging


def __get_images(helm_chart):
    command = 'helm template ' + helm_chart + ' --set ingress.hostname=a | grep "image:" | sed -n "s/^.*image:\s*\(.*\)\s*$/\\1/p" | tr -d "\\"" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//" | uniq'
    logging.info('Command is: '+str(command))
    helm = Popen(command, shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    images, err = helm.communicate()
    if str(err):
        raise EnvironmentError('Helm command failed with error message: {0}'.format(str(err)))
    logging.info('Images are: '+str(images))
    return __extract_image_information(images)


def __extract_image_information(images):
    logging.info('Images is: '+str(images))
    imageList = []
    for image in images.strip().split('\n'):
        logging.info('Image: '+str(image))
        if not image.strip():
            continue
        split = image.strip().split(':')
        logging.info(str(split[0]))
        logging.info('Repo is: ' + split[0] + ' and tag is: ' + split[1])
        imageList.append({"repo": split[0], "tag": split[1]})
    return imageList


def __pull_images(images):
    logging.info('Pulling the images')
    client = docker.from_env(timeout=int(600))
    for image in images:
        client.images.pull(repository=image.get("repo"), tag=image.get("tag"))
        logging.info("Pulled {0} version {1}".format(image.get("repo"), image.get("tag")))
    client.close()


def __save_images_to_tar(images, docker_save_filename):
    logging.info('Saving images to tar')
    list_of_images = ''
    for image in images:
        list_of_images += ' ' + image.get("repo") + ':' + image.get("tag")
    logging.debug('List of images: '+list_of_images)
    # I can't use the docker api as the save method doesn't support multiple images.
    # https://github.com/docker/docker-py/issues/1149
    save = Popen('docker save -o ' + docker_save_filename + ' ' + list_of_images, shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    output, err = save.communicate()
    if str(output) or str(err):
        logging.debug('Std Out: '+str(output))
        logging.debug('Std Err: '+str(err))


def create_docker_tar(helm_chart):
    logging.debug('Helm chart: '+str(helm_chart))
    images = __get_images(helm_chart)
    __pull_images(images)
    docker_save_filename = 'docker.tar'
    __save_images_to_tar(images, docker_save_filename)
    return docker_save_filename


def create_source(args, docker_file):
    # TODO if this is executed concurrently the source folder will get corrupted. Make the source folder unique.
    # but that brings it's own challenges. cleaning up!
    try:
        shutil.rmtree('source')
    except OSError:
        logging.debug('no source folder to delete')
    os.makedirs('source')
    os.makedirs('source/Definitions')
    os.makedirs('source/Definitions/otherTemplates')
    os.makedirs('source/Files')
    os.makedirs('source/Files/images')
    if args.scripts:
        shutil.copytree(args.scripts, 'source/Scripts')
    shutil.copy(args.helm, 'source/Definitions/otherTemplates')
    shutil.move(docker_file, 'source/Files/images')
    entry = open('source/Definitions/TOSCA.yaml', 'w')
    entry.write('template base file')
    entry.close()

    command = 'helm template ' + args.helm + ' --set ingress.hostname=a | grep "image:" | sed -n "s/^.*image:\s*\(.*\)\s*$/\\1/p" | tr -d "\\"" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//" | uniq'
    logging.info('Command is: '+str(command))
    helm = Popen(command, shell=True, stdin=PIPE, stdout=PIPE, stderr=PIPE)
    images, err = helm.communicate()
    if str(err):
        raise EnvironmentError('Helm command failed with error message: {0}'.format(str(err)))
    logging.info('Images are: '+str(images))
    entry1 = open('source/Files/images.txt', 'w')
    entry1.write(images)
    entry1.close()