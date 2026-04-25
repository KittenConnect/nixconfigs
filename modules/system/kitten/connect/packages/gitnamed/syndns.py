#!/usr/bin/env python3
#-*- coding: utf-8 -*-

# vim: tabstop=4 shiftwidth=4 softtabstop=4

# Copyright 2012 PubYun, LLC.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

"""Sync script for GitNamed."""

import os
import sys
import hashlib
import json
import subprocess

settingsPath = os.getenv("GITNAMED_SCRIPTS", os.getcwd() + "/script")
sys.path.insert(0, settingsPath)
import settings

named_conf_master = os.path.join(settings.named_path, 'named.conf.master')
named_conf_slave = os.path.join(settings.named_path, 'named.conf.slave')
named_conf = os.path.join(settings.named_path, 'named.conf')

transfer_key_name = 'master2slave'

transfer_key = u'''
key %s {
    algorithm hmac-md5;
    secret "%s";
};

''' % (transfer_key_name, settings.transfer_key_body)

nameconf_master = u'''zone "%s" {
    type master;
    check-names warn;
    file "zones/%s";
    %s;
    allow-transfer {
        %s;
    };
%s};
'''

nameconf_slave = u'''zone "%s" {
    type slave;
    check-names warn;
    file "zones/%s";
    masters {
        %s;
    };
};
'''

dyndns_update = u'''         update-policy { grant *.%s. self . A AAAA; };\n'''

all_slave = ' '.join('%s;' % slave_ip
                     for (slave_ip, system) in settings.slave_ips.items())

notify_str = 'also-notify {%s}' % all_slave

def is_file(name):
    return os.path.isfile(os.path.join(settings.zones_path, name))

def get_master(z):
    transfer_key = 'key %s' % transfer_key_name;
    if z in settings.dzones:
        # key = settings.dzones[z]
        dstring = dyndns_update % z
        # transfer_key += '; key %s' % key
    else:
        dstring = ''
    return nameconf_master%(z, z, notify_str, transfer_key, dstring)

def reload_slave(slave_ip, system):
    user = settings.get_user(system)
    sys.stdout.write("reloading %s\n" % slave_ip)

    # copy named.conf.slave to slave
    slave_arg = '%s@%s:%s' % (user, slave_ip, settings.named_path)
    code = subprocess.call(['scp', '-i', settings.ssh_key, named_conf, named_conf_slave,
                            slave_arg])
    if code:
        sys.stderr.write('copy %s to slave %s failed\n' %
                (named_conf_slave, slave_ip))
        sys.exit(-1)

    # reload slave dns
    rndc_conf = '%s/rndc.conf' % settings.named_path
    code = subprocess.call('ssh %s@%s -i %s '
                            '/run/current-system/sw/bin/gitnamed-reload -c %s -s localhost reload' %
                            (user, slave_ip, settings.ssh_key, rndc_conf), shell=True)
    if code:
        sys.stderr.write('reload slave name server %s failed\n' % slave_ip)
        sys.exit(-1)

def file_hash(file):
    with open(file, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()

def main():

    os.chdir(settings.named_path)

    settingsFile = "%s/settings.py" % settingsPath
    previous_programH = file_hash(__file__)
    previous_settingsH = file_hash(settingsFile)

    # pull code from git repo
    code = subprocess.call('git pull origin master', shell=True)
    if code:
        sys.stderr.write('git pull code failed\n')

    if previous_programH != file_hash(__file__) or previous_settingsH != file_hash(settingsFile):
        sys.stderr.write('git pull changed code\n')
        os.execv(sys.executable, [sys.executable] + sys.argv)

    # get all zones, exclude journal file
    zones = [f for f in os.listdir(settings.zones_path)
                 if is_file(f) and not f.endswith('.jnl')]

    dzones_conf = '%s/dzones.key' % settings.named_path
    dzones_sops_conf = '%s.sops' % dzones_conf
    if os.path.isfile(dzones_sops_conf):
        code = subprocess.call('sops decrypt %s.sops > %s' % (dzones_conf, dzones_conf), shell=True)
        sys.stderr.write('dzones.key fingerprint is %s\n' % file_hash('dzones.key'))

    # create named.conf.master
    with open(named_conf_master, 'w') as f:
        f.write('include "%s/named.conf";\n\n' % settings.named_path)
        f.write(transfer_key)
        f.write('\n'.join([get_master(z) for z in zones]))

    # create named.conf.slave
    with open(named_conf_slave, 'w') as f:
        f.write('include "%s/named.conf";\n\n' % settings.named_path)
        f.write(transfer_key)
        f.write('server %s { keys %s; };\n\n' %
                (settings.master_ip, transfer_key_name))
        f.write('\n'.join([nameconf_slave%(z, z,
            settings.master_ip) for z in zones]))

    # reload master dns
    rndc_conf = '%s/rndc.conf' % settings.named_path
    code = subprocess.call('rndc -c %s -s localhost reload' %
                           rndc_conf, shell=True)
    if code:
        sys.stderr.write('reload master name server failed\n')
        sys.exit(-1)

    for (slave_ip,system) in settings.slave_ips.items():
        reload_slave(slave_ip, system)

if __name__ == '__main__':
    main()
