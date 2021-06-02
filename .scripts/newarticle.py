# format
'''
+++
title = "some title"
date = YYYY-MM-DD
[taxonomies]
tags = ["tag1", "tag2"]
+++
'''

import json
import datetime

def run():
    date = datetime.datetime.now().strftime('%Y-%m-%d')
    file_name = '_'.join([
        input('filename: ').strip(),
        date,
    ]) + '.md'

    title = json.dumps(input('title: ').strip())

    # expected comma seperated input
    tags = json.dumps(
        list(
            map(
                lambda x: x.strip(), 
                input('tags: ').split(',')
            )
        )
    )
    content = '\n'.join([
        '+++',
        'title = {}'.format(title),
        'date = {}'.format(date),
        '[taxonomies]',
        'tags = {}'.format(tags),
        '+++',
        '\n\n',
        '<!-- more -->'
    ])
    with open(file_name, 'w') as file:
        file.write(content)

if __name__ == '__main__':
    run()
