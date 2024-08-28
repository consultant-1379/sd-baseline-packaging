import sys
import argparse
from argparse import Namespace
import logging
from am_package_manager.generator import generate
from vnfsdk_pkgtools.packager import csar
import os


def __check_arguments(args):
    if not os.path.exists(args.helm):
        raise ValueError('The specified helm chart doesn\'t exist')
    if args.scripts:
        if not os.path.exists(args.scripts):
            raise ValueError('The specified scripts folder doesn\'t exist')


def generate_func(args):
    logging.debug('Args: '+str(args))
    __check_arguments(args)
    docker_file = generate.create_docker_tar(args.helm)
    generate.create_source(args, docker_file)
    filename = str(args.name)+'.csar'
    try:
        os.remove(filename)
        logging.info('Deleted pre-existing csar file with the name: {0}'.format(filename))
    except OSError:
        logging.debug('no pre-existing csar file to delete')
    csar_args = Namespace(helm="Definitions/otherTemplates/" + args.helm, csar_name=filename, manifest='', history='', tests='', licenses='', debug='', created_by='Ericsson')
    csar.write('source', 'Definitions/TOSCA.yaml', filename, logging, csar_args)


def parse_args(args_list):
    """
    CLI entry point
    """

    parser = argparse.ArgumentParser(description='CSAR File Utilities')

    subparsers = parser.add_subparsers(help='generate')
    generate = subparsers.add_parser('generate')
    generate.set_defaults(func=generate_func)
    generate.add_argument(
        '-hm',
        '--helm',
        help='The Helm chart to use to generate the csar file',
        required=True
    )
    generate.add_argument(
        '-n',
        '--name',
        help='The name to give the generated csar file',
        required=True
    )
    generate.add_argument(
        '-s',
        '--scripts',
        help='the path to a folder which contains scripts to be included in the csar file'
    )

    return parser.parse_args(args_list)


def __configure_logging(logging):
    logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s', level=logging.INFO)


def main():
    __configure_logging(logging)
    args = parse_args(sys.argv[1:])
    args.func(args)


if __name__ == '__main__':
    main()
