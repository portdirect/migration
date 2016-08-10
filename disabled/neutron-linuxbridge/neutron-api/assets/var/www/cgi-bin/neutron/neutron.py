from oslo_config import cfg
from paste import deploy

from neutron.common import config
from neutron.common import wsgi

CONF = cfg.CONF

config_files = ['/etc/neutron/api-paste.ini','/etc/neutron/neutron.conf','/etc/neutron/plugins/ml2/ml2_conf.ini']
config.parse_args([], default_config_files=config_files)


conf = config_files[0]
name = "neutron"

options = deploy.appconfig('config:%s' % conf, name=name)

application = deploy.loadapp('config:%s' % conf, name=name)
