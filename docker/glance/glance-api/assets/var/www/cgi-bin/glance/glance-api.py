from oslo_config import cfg
from paste import deploy

from glance.common import config
from glance.common import wsgi

CONF = cfg.CONF

config_files = ['/etc/glance/glance-api-paste.ini','/etc/glance/glance-api.conf']
config.parse_args([], default_config_files=config_files)


conf = config_files[1]
name = "glance-api-keystone"

options = deploy.appconfig('config:%s' % conf, name=name)

application = deploy.loadapp('config:%s' % conf, name=name)
