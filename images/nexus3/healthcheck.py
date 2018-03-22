#!/usr/bin/python

import base64
import httplib
import json
import os
import os.path
import urllib
from Cookie import SimpleCookie

class API():
    def __init__(self, address, port, encoder):
        self.connection = httplib.HTTPConnection(address, port)
        self.encoder = encoder
        self.cookies = SimpleCookie()
        self.tid = 1
        self.logged_in = False

    '''private'''
    def send_cookies(self, connection):
        headerAndValue = self.cookies.output(attrs=[], header='')
        if len(headerAndValue):
            self.connection.putheader('Cookie', headerAndValue)

    '''private'''
    def save_cookies(self, response):
        set_cookie = response.getheader('Set-Cookie')
        if not set_cookie:
            return
        self.cookies.load(set_cookie)

    '''private'''
    def send(self, method, url, contentType, body):
        connection = self.connection
        connection.putrequest(method, url)
        connection.putheader('X-Nexus-UI', 'True')
        if contentType:
            connection.putheader('Content-Type', contentType)
            connection.putheader('Content-Length', len(body))
        self.send_cookies(connection)
        connection.endheaders(body)
        response = connection.getresponse()
        self.save_cookies(response)
        return response

    def login(self, username, password):
        login_data = {'username': base64.b64encode(username), 'password': base64.b64encode(password)}
        response = self.send('POST', '/service/rapture/session', 'application/x-www-form-urlencoded; charset=UTF-8', urllib.urlencode(login_data))
        response.read()
        self.logged_in = True
        return response

    def call(self, obj, method, data):
        tid = self.tid
        self.tid += 1
        payload = {'action': obj, 'method': method, 'data': data, 'type': 'rpc', 'tid': tid}
        response = self.send('POST', '/service/extdirect', 'application/json', json.dumps(payload, cls = self.encoder))
        result_payload = json.loads(response.read().decode())
        return result_payload['result']

class RepoAttrDocker(object):
    key = 'docker'

    def __init__(self, **args):
        self.httpPort = args.get('docker_httpPort', None)
        self.forceBasicAuth = args.get('docker_forceBasicAuth', False)
        self.v1Enabled = args.get('docker_v1Enabled', True)

class RepoAttrProxy(object):
    key = 'proxy'

    def __init__(self, **args):
        self.remoteUrl = args['proxy_remoteUrl']
        self.contentMaxAge = args.get('proxy_contentMaxAge', 1440)
        self.metadataMaxAge = args.get('proxy_metadataMaxAge', 1440)

class RepoAttrDockerProxy(object):
    key = 'dockerProxy'

    def __init__(self, **args):
        self.indexType = args.get('dockerProxy_indexType', 'REGISTRY')

class RepoAttrHttpClient(object):
    key = 'httpclient'

    def __init__(self, **args):
        self.blocked = args.get('httpClient_blocked', False)
        self.autoBlock = args.get('httpClient_autoBlock', True)
        self.connection = {'httpClient_useTrustStore': args.get('httpClient_connection_useTrustStore', False)}

class RepoAttrStorage(object):
    key = 'storage'

    def __init__(self, **args):
        self.blobStoreName = args.get('storage_blobStoreName', 'default')
        self.strictContentTypeValidation = args.get('storage_strictContentTypeValidation', True)
        self.writePolicy = args.get('storage_writePolicy')

class RepoAttrNegativeCache(object):
    key = 'negativeCache'

    def __init__(self, **args):
        self.enabled = args.get('negativeCache_enabled', True)
        self.timeToLive = args.get('negativeCache_timeToLive', 1440)

class RepoAttrGroup(object):
    key = 'group'

    def __init__(self, **args):
        self.memberNames = args['group_memberNames']

def serializeOne(instance):
    result = {}
    attributeList = []
    for name, value in instance.__dict__.items():
        #print('Trying %s=%s' % (name, value))
        if name == 'attributes':
            attributeList = value
            continue
        if not value == None:
            result[name] = value
    result['attributes'] = attributes = {}
    for attribute in attributeList[::-1]:
        key = attribute.__class__.key
        if key in attributes:
            continue
        attributes[key] = serializeOne(attribute)
    return result

class Repo(object):
    def __init__(self, **args):
        self.name = args['name']
        self.format = args.get('format', '')
        self.type = args.get('type', '')
        self.url = args.get('url', '')
        self.online = args.get('online', True)
        self.authEnabled = args.get('authEnabled', False)
        self.httpRequestSettings = args.get('httpRequestSettings', False)
        self.attributes = []
        self.attributes.append(RepoAttrStorage(**args))

    def serialize(self):
        result = serializeOne(self)
        foo = self.__class__.__dict__
        result['recipe'] = self.__class__.__dict__.get('recipe')
        print(result)
        return result

class ProxyRepo(Repo):
    def __init__(self, **args):
        super(ProxyRepo, self).__init__(**args)
        self.attributes.append(RepoAttrProxy(**args))
        self.attributes.append(RepoAttrHttpClient(**args))
        self.attributes.append(RepoAttrNegativeCache(**args))

class GroupRepo(Repo):
    def __init__(self, **args):
        super(GroupRepo, self).__init__(**args)
        self.attributes.append(RepoAttrGroup(**args))

class DockerRepo(Repo):
    def __init__(self, **args):
        super(DockerRepo, self).__init__(**args)
        self.attributes.append(RepoAttrDocker(**args))

class DockerHostedRepo(DockerRepo):
    recipe = 'docker-hosted'

    def __init__(self, **args):
        args['storage_writePolicy'] = 'ALLOW'
        super(DockerHostedRepo, self).__init__(**args)

class DockerProxyRepo(ProxyRepo, DockerRepo):
    recipe = 'docker-proxy'

    def __init__(self, **args):
        super(DockerProxyRepo, self).__init__(**args)
        self.attributes.append(RepoAttrDockerProxy(**args))

class DockerGroupRepo(GroupRepo, DockerRepo):
    recipe = 'docker-group'

    def __init__(self, **args):
        super(DockerGroupRepo, self).__init__(**args)

class RepoAttrMaven2(object):
    key = 'maven'

    def __init__(self, **args):
        self.versionPolicy = args['maven_versionPolicy']
        self.layoutPolicy = args.get('maven_layoutPolicy', 'STRICT')

class Maven2Repo(Repo):
    def __init__(self, **args):
        super(Maven2Repo, self).__init__(**args)
        self.attributes.append(RepoAttrMaven2(**args))

class Maven2GroupRepo(GroupRepo, DockerRepo):
    recipe = 'maven2-group'

    def __init__(self, **args):
        super(Maven2GroupRepo, self).__init__(**args)

class Maven2ProxyRepo(ProxyRepo, Maven2Repo):
    recipe = 'maven2-proxy'

    def __init__(self, **args):
        super(Maven2ProxyRepo, self).__init__(**args)

class CustomEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Repo):
            return o.serialize()
        return super(CustomEncoder, self).default(o)

api = API('127.0.0.1', 8081, CustomEncoder)

found_repos = {}
result = api.call('coreui_Repository', 'readReferences', [{'page': 1, 'start': 0, 'limit': 100, 'filter': [{'property': 'applyPermissions', 'value': True}]}])
for item in result['data']:
    found_repos[item['name']] = item

autovivify_repos = []
if not 'docker-hosted' in found_repos:
    autovivify_repos.append(DockerHostedRepo(name = 'docker-hosted', docker_httpPort = 8082))
if not 'docker-proxy' in found_repos:
    autovivify_repos.append(DockerProxyRepo(name = 'docker-proxy', proxy_remoteUrl = 'https://registry-1.docker.io'))
if not 'docker-group' in found_repos:
    autovivify_repos.append(DockerGroupRepo(name = 'docker-group', docker_httpPort = 8083, group_memberNames = ['docker-hosted', 'docker-proxy']))

if not 'spring-milestone' in found_repos:
    autovivify_repos.append(Maven2ProxyRepo(name = 'spring-milestone', maven_versionPolicy = 'RELEASE', proxy_remoteUrl = 'https://repo.spring.io/milestone'))
if not 'spring-snapshot' in found_repos:
    autovivify_repos.append(Maven2ProxyRepo(name = 'spring-snapshot', maven_versionPolicy = 'SNAPSHOT', proxy_remoteUrl = 'https://repo.spring.io/snapshot'))
if not 'rabbit-milestone' in found_repos:
    autovivify_repos.append(Maven2ProxyRepo(name = 'rabbit-milestone', maven_versionPolicy = 'RELEASE', proxy_remoteUrl = 'https://dl.bintray.com/rabbitmq/maven-milestones'))
if not 'localdev-maven-group' in found_repos:
    autovivify_repos.append(Maven2GroupRepo(name = 'localdev-maven-group', group_memberNames = ['maven-public', 'spring-milestone', 'spring-snapshot', 'rabbit-milestone']))

if len(autovivify_repos):
    if os.path.isfile('/nexus-data/healthcheck/first-time'):
        exit(1)

    api.login('admin', 'admin123')

    result = api.call('coreui_RealmSettings', 'read', None)
    found_realms = result['data']['realms']

    autovivify_realms = []
    if found_realms.count('DockerToken') == 0:
        autovivify_realms.append('DockerToken')

    if len(autovivify_realms):
        api.call('coreui_RealmSettings', 'update', [{'realms': found_realms + autovivify_realms}])

    for repo in autovivify_repos:
        foo = api.call('coreui_Repository', 'create', [repo])

    if not os.path.isfile('/nexus-data/healthcheck'):
        os.mkdir('/nexus-data/healthcheck')
    open('/nexus-data/healthcheck/first-time', 'w').close()

