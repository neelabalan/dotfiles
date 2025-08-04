# original idea from https://github.com/mawoka-myblock/mubert
# alias zone='python3 <filepath>'
# ctrl+c and ctrl+z to exit
import os
import sys
import json
import time
import subprocess
import tempfile
import threading
import pathlib
import shelve

import requests

cookies = {}
headers = {'user-agent': 'MubertAndroid'}
payload = {
    'method': 'AppGetPages',
    'params': {'timestamp': 0},
    'application': 'Mubert',
    'language': 'en',
    'os': 'Android',
    'sandbox': False,
    'version': '4.2.0',
}


def set_cookies():
    response = requests.get('https://mubert.com')
    cookie_path = pathlib.Path().resolve() / 'cookie'
    if not cookie_path.exists():
        with shelve.open(str(cookie_path), 'c') as cookie:
            cookie['mat'] = cookies['mat'] = response.cookies['mat']
            cookie['mat_id'] = cookies['mat_id'] = response.cookies['mat_id']
    else:
        with shelve.open(str(cookie_path), 'r') as cookie:
            cookies['mat'] = cookie['mat']
            cookies['mat_id'] = cookie['mat_id']


def get_streams():
    jsonpath = pathlib.Path().resolve() / 'mubert.json'
    response = {}
    if jsonpath.exists():
        with open(str(jsonpath), 'r') as file:
            response = json.load(file)
    else:
        response = requests.post(
            'https://api-app.mubert.com/v2/AppGetPages',
            json=payload,
            cookies=cookies,
            headers=headers,
        ).json()

    return response


def extract_url_names(response):
    data = {}
    pages = response.get('data').get('pages')
    for section in pages:
        for unit in section.get('units'):
            streams = unit.get('streams')
            if streams:
                for stream in unit.get('streams'):
                    data[stream.get('title') or unit.get('name')] = stream.get('url')
    return data


def download_stream(filename, url):
    io_stream = requests.get(
        url,
        cookies=cookies,
        headers=headers,
        stream=True,
    )
    with open(filename, 'ab') as file:
        for line in io_stream.iter_content():
            file.write(line)


def get_choice_of_stream(data):
    echo_text = '\n'.join(data.keys())
    stream = subprocess.Popen('echo -n "{}" | fzf'.format(echo_text), shell=True, stdout=subprocess.PIPE).communicate()[
        0
    ]
    return stream.decode('utf-8').replace('\n', '')


def run():
    set_cookies()
    response = get_streams()
    data = extract_url_names(response)
    stream = get_choice_of_stream(data)
    if stream:
        url = data.get(str(stream))
        fd, filename = tempfile.mkstemp(suffix='.mp3')
        try:
            download = threading.Thread(target=download_stream, args=(filename, data.get(stream)))
            download.start()
            time.sleep(10)
            subprocess.run(['mpv', filename])
        except (KeyboardInterrupt, SystemExit):
            download.join()
            sys.exit()


if __name__ == '__main__':
    run()
