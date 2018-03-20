#!/usr/bin/python

import base64
import httplib
import json
import os
import os.path
import urllib
from Cookie import SimpleCookie

class API():
    def __init__(self, address, port):
        self.connection = httplib.HTTPConnection(address, port)
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
        response = self.send('POST', '/service/extdirect', 'application/json', json.dumps(payload))
        result_payload = json.loads(response.read().decode())
        return result_payload['result']

def build_maven2_proxy_config(name, version_policy, remote_url):
    return [{"attributes": {"maven": {"versionPolicy": version_policy, "layoutPolicy": "STRICT"}, "proxy": {"remoteUrl": remote_url, "contentMaxAge": 1440, "metadataMaxAge": 1440}, "httpclient": {"blocked": False, "autoBlock": True, "connection": {"useTrustStore": False}}, "storage": {"blobStoreName": "default", "strictContentTypeValidation": True}, "negativeCache": {"enabled": True, "timeToLive": 1440}}, "name": name, "format": "", "type": "", "url": "", "online": True, "authEnabled": False, "httpRequestSettings": False, "recipe": "maven2-proxy"}]

api = API('127.0.0.1', 8081)

found_repos = {}
result = api.call('coreui_Repository', 'readReferences', [{'page': 1, 'start': 0, 'limit': 100, 'filter': [{'property': 'applyPermissions', 'value': True}]}])
for item in result['data']:
    found_repos[item['name']] = item

autovivify_repos = []
if not 'docker-hosted' in found_repos:
    autovivify_repos.append([{'attributes': {'docker': {'httpPort': 8082, 'forceBasicAuth': False, 'v1Enabled': True}, 'storage': {'blobStoreName': 'default', 'strictContentTypeValidation': True, 'writePolicy': 'ALLOW'}}, 'name': 'docker-hosted', 'format': '', 'type': '', 'url': '', 'online': True, 'recipe': 'docker-hosted'}])
if not 'docker-proxy' in found_repos:
    autovivify_repos.append([{"attributes": {"docker": {"forceBasicAuth": False, "v1Enabled": True}, "proxy": {"remoteUrl": "https://registry-1.docker.io", "contentMaxAge": 1440, "metadataMaxAge": 1440}, "dockerProxy": {"indexType": "REGISTRY"}, "httpclient": {"blocked": False, "autoBlock": True, "connection": {"useTrustStore": False}}, "storage": {"blobStoreName": "default", "strictContentTypeValidation": True}, "negativeCache": {"enabled": True, "timeToLive": 1440}}, "name": "docker-proxy", "format": "", "type": "", "url": "", "online": True, "authEnabled": False, "httpRequestSettings": False, "recipe": "docker-proxy"}])
if not 'docker-group' in found_repos:
    autovivify_repos.append([{"attributes": {"docker": {"httpPort": 8083, "forceBasicAuth": False, "v1Enabled": True}, "storage": {"blobStoreName": "default", "strictContentTypeValidation": True}, "group": {"memberNames": ["docker-hosted", "docker-proxy"]}}, "name": "docker-group", "format": "", "type": "", "url": "", "online": True, "recipe": "docker-group"}])

if not 'spring-milestone' in found_repos:
    autovivify_repos.append(build_maven2_proxy_config('spring-milestone', 'RELEASE', 'https://repo.spring.io/milestone'))
if not 'spring-snapshot' in found_repos:
    autovivify_repos.append(build_maven2_proxy_config('spring-snapshot', 'SNAPSHOT', 'https://repo.spring.io/snapshot'))
if not 'rabbit-milestone' in found_repos:
    autovivify_repos.append(build_maven2_proxy_config('rabbit-milestone', 'RELEASE', 'https://dl.bintray.com/rabbitmq/maven-milestones'))

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

    for data in autovivify_repos:
        api.call('coreui_Repository', 'create', data)

    result = api.call('coreui_Repository', 'read', None)
    maven_members = []
    maven_repo = None
    for full_repo in result['data']:
        if full_repo['name'] == 'maven-public':
            maven_repo = full_repo
            maven_members = full_repo['attributes']['group']['memberNames']

    autovivify_maven_members = []
    if maven_members.count('spring-milestone') == 0:
        autovivify_maven_members.append('spring-milestone')
    if maven_members.count('spring-snapshot') == 0:
        autovivify_maven_members.append('spring-snapshot')
    if maven_members.count('rabbit-milestone') == 0:
        autovivify_maven_members.append('rabbit-milestone')

    if len(autovivify_maven_members) and maven_repo:
        maven_repo['attributes']['group']['memberNames'] = maven_members + autovivify_maven_members
        api.call('coreui_Repository', 'update', [maven_repo])

    if not os.path.isfile('/nexus-data/healthcheck'):
        os.mkdir('/nexus-data/healthcheck')
    open('/nexus-data/healthcheck/first-time', 'w').close()

