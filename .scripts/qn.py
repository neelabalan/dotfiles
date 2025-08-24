#!/usr/bin/env python3

import argparse
import datetime
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile


def get_config_path() -> pathlib.Path:
    return pathlib.Path.home() / '.dotfiles' / '.qn.json'


def get_default_config() -> dict[str, str]:
    return {
        'notes_dir': '~/notes',
        'backup_dir': '~/backups',
        'editor': 'code',
        'encryption_tool': 'age',
        'append_note': 'inbox.md',
    }


def load_config() -> dict[str, str]:
    config_path = get_config_path()
    if not config_path.exists():
        return get_default_config()

    try:
        with open(config_path) as f:
            config = json.load(f)
        return {**get_default_config(), **config}
    except (json.JSONDecodeError, OSError):
        return get_default_config()


def save_config(config: dict[str, str]) -> None:
    config_path = get_config_path()
    config_path.parent.mkdir(parents=True, exist_ok=True)

    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)


def expand_path(path_str: str) -> pathlib.Path:
    return pathlib.Path(os.path.expanduser(path_str)).resolve()


def get_notes_dir() -> pathlib.Path:
    config = load_config()
    notes_dir = expand_path(config['notes_dir'])
    notes_dir.mkdir(parents=True, exist_ok=True)
    return notes_dir


def open_in_editor(file_path: pathlib.Path) -> None:
    config = load_config()
    editor = config['editor']

    try:
        subprocess.run([editor, str(file_path)], check=True)
    except subprocess.CalledProcessError:
        print(f'Failed to open {file_path} with {editor}')
        sys.exit(1)
    except FileNotFoundError:
        print(f"Editor '{editor}' not found")
        sys.exit(1)


def create_note() -> None:
    notes_dir = get_notes_dir()
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    note_path = notes_dir / f'{timestamp}.md'

    note_path.touch()
    open_in_editor(note_path)


def create_daily_note() -> None:
    notes_dir = get_notes_dir()
    today = datetime.date.today()
    daily_path = notes_dir / 'daily' / f'{today.strftime("%Y%m%d")}.md'

    daily_path.parent.mkdir(parents=True, exist_ok=True)
    if not daily_path.exists():
        daily_path.write_text(f'# Daily Note - {today.strftime("%Y-%m-%d")}\n\n')

    open_in_editor(daily_path)


def create_weekly_note() -> None:
    notes_dir = get_notes_dir()
    today = datetime.date.today()
    year, week, _ = today.isocalendar()
    weekly_dir = notes_dir / 'weekly' / f'{year}W{week:02d}'

    weekly_dir.mkdir(parents=True, exist_ok=True)
    index_path = weekly_dir / 'index.md'

    if not index_path.exists():
        week_start = today - datetime.timedelta(days=today.weekday())
        week_end = week_start + datetime.timedelta(days=6)
        index_path.write_text(
            f'# Weekly Notes - Week {week}, {year}\n'
            f'## {week_start.strftime("%Y-%m-%d")} to {week_end.strftime("%Y-%m-%d")}\n\n'
        )

    open_in_editor(index_path)


def create_monthly_note() -> None:
    notes_dir = get_notes_dir()
    today = datetime.date.today()
    monthly_path = notes_dir / 'monthly' / f'{today.strftime("%Y%m")}.md'

    monthly_path.parent.mkdir(parents=True, exist_ok=True)
    if not monthly_path.exists():
        monthly_path.write_text(f'# Monthly Note - {today.strftime("%B %Y")}\n\n')

    open_in_editor(monthly_path)


def open_notes_directory() -> None:
    notes_dir = get_notes_dir()

    if sys.platform == 'darwin':
        subprocess.run(['open', str(notes_dir)])
    elif sys.platform.startswith('linux'):
        subprocess.run(['xdg-open', str(notes_dir)])
    elif sys.platform == 'win32':
        subprocess.run(['explorer', str(notes_dir)])
    else:
        print(f'Notes directory: {notes_dir}')


def backup_notes(encrypt: bool = False) -> None:
    config = load_config()
    notes_dir = expand_path(config['notes_dir'])
    backup_dir = expand_path(config['backup_dir'])

    if not notes_dir.exists():
        print('Notes directory does not exist')
        return

    backup_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')

    if encrypt:
        encryption_tool = config['encryption_tool']
        backup_file = backup_dir / f'notes_backup_{timestamp}.tar.gz.enc'

        with tempfile.NamedTemporaryFile(suffix='.tar.gz', delete=False) as temp_file:
            temp_path = pathlib.Path(temp_file.name)

        try:
            subprocess.run(['tar', '-czf', str(temp_path), '-C', str(notes_dir.parent), notes_dir.name], check=True)

            if encryption_tool == 'age':
                subprocess.run(['age', '-r', 'age1...', '-o', str(backup_file), str(temp_path)], check=True)
            elif encryption_tool == 'gpg':
                subprocess.run(
                    ['gpg', '--symmetric', '--cipher-algo', 'AES256', '--output', str(backup_file), str(temp_path)],
                    check=True,
                )

            print(f'Encrypted backup created: {backup_file}')
        except subprocess.CalledProcessError:
            print('Backup encryption failed')
        finally:
            temp_path.unlink(missing_ok=True)
    else:
        backup_file = backup_dir / f'notes_backup_{timestamp}.tar.gz'
        try:
            subprocess.run(['tar', '-czf', str(backup_file), '-C', str(notes_dir.parent), notes_dir.name], check=True)
            print(f'Backup created: {backup_file}')
        except subprocess.CalledProcessError:
            print('Backup failed')


def initialize_config() -> None:
    config_path = get_config_path()

    if config_path.exists():
        response = input(f'Config file already exists at {config_path}. Overwrite? (y/N): ')
        if response.lower() != 'y':
            return

    config = get_default_config()
    save_config(config)
    print(f'Configuration initialized at {config_path}')

    notes_dir = expand_path(config['notes_dir'])
    notes_dir.mkdir(parents=True, exist_ok=True)
    print(f'Notes directory created at {notes_dir}')


def append_to_note(text: str) -> None:
    config = load_config()
    notes_dir = get_notes_dir()
    append_file = notes_dir / config['append_note']

    timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    entry = f'\n## {timestamp}\n{text}\n'

    if not append_file.exists():
        append_file.write_text(f'# {config["append_note"]}\n')

    with open(append_file, 'a') as f:
        f.write(entry)

    print(f'Appended to {append_file}')


def count_words_in_file(file_path: pathlib.Path) -> int:
    try:
        content = file_path.read_text(encoding='utf-8', errors='ignore')
        words = re.findall(r'\b\w+\b', content)
        return len(words)
    except OSError:
        return 0


def extract_tags_from_file(file_path: pathlib.Path) -> set[str]:
    try:
        content = file_path.read_text(encoding='utf-8', errors='ignore')
        tags = set(re.findall(r'#(\w+)', content))
        return tags
    except OSError:
        return set()


def get_file_creation_date(file_path: pathlib.Path) -> datetime.datetime:
    try:
        stat = file_path.stat()
        return datetime.datetime.fromtimestamp(stat.st_ctime)
    except OSError:
        return datetime.datetime.min


def show_statistics() -> None:
    notes_dir = get_notes_dir()

    if not notes_dir.exists():
        print('Notes directory does not exist')
        return

    markdown_files = list(notes_dir.rglob('*.md'))

    if not markdown_files:
        print('No markdown files found')
        return

    total_words = 0
    all_tags: set[str] = set()
    total_size = 0
    creation_dates: list[datetime.datetime] = []

    for file_path in markdown_files:
        total_words += count_words_in_file(file_path)
        all_tags.update(extract_tags_from_file(file_path))

        try:
            total_size += file_path.stat().st_size
        except OSError:
            pass

        creation_dates.append(get_file_creation_date(file_path))

    creation_dates.sort()
    earliest = creation_dates[0] if creation_dates else datetime.datetime.min
    latest = creation_dates[-1] if creation_dates else datetime.datetime.min

    size_mb = total_size / (1024 * 1024)

    print('Notes Statistics:')
    print(f'  Total files: {len(markdown_files)}')
    print(f'  Total words: {total_words:,}')
    print(f'  Unique tags: {len(all_tags)}')
    print(f'  Total size: {size_mb:.2f} MB')

    if earliest != datetime.datetime.min:
        print(f'  Earliest note: {earliest.strftime("%Y-%m-%d")}')
        print(f'  Latest note: {latest.strftime("%Y-%m-%d")}')

    if all_tags:
        sorted_tags = sorted(all_tags)
        if len(sorted_tags) <= 10:
            print(f'  Tags: {", ".join(sorted_tags)}')
        else:
            print(f'  Top tags: {", ".join(sorted_tags[:10])}...')


def main() -> None:
    parser = argparse.ArgumentParser(description='Quick Notes CLI')
    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    subparsers.add_parser('daily', help='Create/open daily note')
    subparsers.add_parser('weekly', help='Create/open weekly folder')
    subparsers.add_parser('monthly', help='Create/open monthly note')
    subparsers.add_parser('open', help='Open notes directory')
    subparsers.add_parser('init', help='Initialize configuration')
    subparsers.add_parser('stats', help='Show note statistics')

    backup_parser = subparsers.add_parser('backup', help='Backup notes')
    backup_parser.add_argument('--encrypt', action='store_true', help='Encrypt backup')

    append_parser = subparsers.add_parser('append', aliases=['a'], help='Append text to note')
    append_parser.add_argument('text', nargs='+', help='Text to append')

    args = parser.parse_args()

    if args.command == 'daily':
        create_daily_note()
    elif args.command == 'weekly':
        create_weekly_note()
    elif args.command == 'monthly':
        create_monthly_note()
    elif args.command == 'open':
        open_notes_directory()
    elif args.command == 'backup':
        backup_notes(args.encrypt)
    elif args.command == 'init':
        initialize_config()
    elif args.command in ['append', 'a']:
        text = ' '.join(args.text)
        append_to_note(text)
    elif args.command == 'stats':
        show_statistics()
    else:
        create_note()


if __name__ == '__main__':
    main()
