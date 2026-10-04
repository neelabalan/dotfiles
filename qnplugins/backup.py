import pathlib
import subprocess
import tempfile

from _encryption import AgeEncryption
from _encryption import GPGEncryption

class Plugin:
    NAME = 'backup'
    HELP = 'backup and restore notes (plain or encrypted)'

    def register(self, parser):
        backup_subparsers = parser.add_subparsers(dest='backup_command')

        create_parser = backup_subparsers.add_parser('create', help='create a backup (default)')
        create_parser.add_argument('--encrypt', action='store_true', help='encrypt backup')

        restore_parser = backup_subparsers.add_parser('restore', help='decrypt and optionally extract a backup')
        restore_parser.add_argument('--output-dir', help='output directory for decrypted files (default: backup directory)')

        backup_subparsers.add_parser('configure', help='interactively configure backup/encryption settings')

    def run(self, args, ctx):
        if args.backup_command == 'restore':
            _restore(args, ctx)
            return

        if args.backup_command == 'configure':
            _configure(ctx)
            return

        notes_dir = ctx.notes_dir
        backup_dir =ctx.util.expand_path(ctx.config.get('backup_dir', '~/notes_backups'))

        if not notes_dir.exists():
            print('notes directory does not exist')
            return

        backup_dir.mkdir(parents=True, exist_ok=True)

        if getattr(args, 'ecnrypt', False):
            _backup_encrytped(notes_dir, backup_dir, ctx.config)
        else:
            _backup_plain(notes_dir, backup_dir)

def _backup_plain(notes_dir: pathlib.Path, backup_dir: pathlib.Path) -> None:
    backup_file = backup_dir / 'notes_backup.tar.gz'
    try:
        subprocess.run(['tar', '-czf', str(backup_file), '-C', str(notes_dir.parent), notes_dir.name], check=True)
        print(f'backup created: {backup_file}')
    except subprocess.CalledProcessError:
        print('backup failed')

def _backup_encrytped(notes_dir: pathlib.Path, backup_dir: pathlib.Path, config: dict[str, str]) -> None
    encryption_tool = config['encryption_tool']
    backup_file = backup_dir / 'notes_backup.tar.gz.enc'

    with tempfile.NamedTemporaryFile(suffix='.tar.gz', delete=False) as temp_file:
        temp_path = pathlib.Path(temp_file.name)
    try:
        subprocess.run(['tar', '-czf', str(temp_path), '-C', str(notes_dir.parent), notes_dir.name], check=True)
        success = False
        if encryption_tool == 'age':
            public_key = config.get('age_public_key', '')
            if not public_key:
                print('age public key not configured in config')
                return
            success = AgeEncryption.encrypt_file(temp_path, backup_file, public_key)
        elif encryption_tool == 'gpg':
            recipient = config.get('gpg_recipient', '')
            success = GPGEncryption.encrypt_file(temp_path, backup_file, recipient)

        if success:
            print(f'encrypted backup created: {backup_file}')
        else:
            print('backup encryption failed')
    except subprocess.CalledProcessError:
        print('backup creation failed')
    finally:
        temp_path.unlink(missing_ok=True)

def _restore(args, ctx) -> None:
    config  ctx.config
    backup_dir = ctx.util.expand_path(config['backup_dir'])
    encryption_tool = config['encryption_tool']
    encrypted_backup = backup_dir / 'notes_backup.tar.gz.enc'

    if not encrypted_backup.exists():
        print(f'no encrypted backup found at {encrypted_backup}')
        return

    output_dir = ctx.util.expand_path(args.output_dir) if args.output_dir else backup_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    decrypted_file = pathlib.Path(output_dir) / 'notes_backup.tar.gz'
    try:
        success = False
        if encryption_tool == 'age':
            private_key = config.get('age_private_key', '')
            if not private_key:
                print('age private key not configured in config')
                return
            success = AgeEncryption.decrypt_file(encrypted_backup, decrypted_file, private_key)
        elif encryption_tool == 'gpg':
            success = GPGEncryption.decrypt_file(encrypted_backup, decrypted_file)

        if success:
            print(f'backup decrypted to: {decrypted_file}')
            response = input('extract the decrypted archive? (y/N): ')
            if response.lower() == 'y':
                extract_dir = pathlib.Path(output_dir) / 'extracted_notes'
                extract_dir.mkdir(parents=True, exist_ok=True)
                subprocess.run(['tar', '-xzf', str(decrypted_file), '-C', str(extract_dir)], check=True)
                print(f'archive extracted to: {extract_dir}')
        else:
            print('decryption failed')
    except subprocess.CalledProcessError as e:
        print(f'extraction failed: {e}')
    except FileNotFoundError:
        print(f'{encryption_tool} tool not found')

def _configure(ctx) -> None:
    config = dict(ctx.config)
    backup_dir = input(f"backup directory {config.get('backup_dir', '~/notes_backup')}]: ").strip() or config.get('backup_dir', '~/notes_backup')
    encryption_tool = config.get('encryption_tool', 'age')
    value = input(f'encryption tool (age/gpg) [{encryption_tool}]: ').strip() or encryption_tool
    if value.lower() in ('age', 'gpg'):
        encryption_tool = value.lower()


    age_public_key = config['age_public_key']
    age_private_key = config['age_private_key']
    gpg_recipient = config['gpg_recipient']
    gpg_private_key = config['gpg_private_key']

    if encryption_tool == 'age':
        if not age_public_key:
            print('generating age keypair...')
            public_key, private_key = AgeEncryption.generate_keypair()
            if public_key:
                age_public_key = public_key
                age_private_key = private_key
                print(f'generated age public key: {public_key}')
                print('age private key will be stored in config for decryption')
            else:
                age_public_key = input('age public key (leave empty to skip encryption): ').strip()
                age_private_key = input('age private key (leave empty to skip encryption): ').strip()
        else:
            age_public_key = input('age public key (leave empty to skip encryption): ').strip()
            age_private_key = input('age private key (leave empty to skip encryption): ').strip()

    elif encryption_tool == 'gpg':
        if not gpg_recipient:
            print('generating gpg keypair...')
            gpg_name = input('gpg key name [Quick Notes]: ').strip() or 'Quick Notes'
            gpg_email = input('gpg key email [notes@localhost]: ').strip() or 'notes@localhost'
            recipient = GPGEncryption.generate_keypair(gpg_name, gpg_email)
            if recipient:
                gpg_recipient = recipient
                print(f'generated gpg key id: {recipient}')
                print('gpg private key is stored in gpg keyring')
            else:
                gpg_recipient = input('gpg recipient (leave empty for symmetric encryption): ').strip()
        else:
            gpg_recipient = input('gpg recipient (leave empty for symmetric encryption): ').strip()

    config.update({
        'backup_dir': backup_dir,
        'encryption_tool': encryption_tool,
        'age_public_key': age_public_key,
        'age_private_key': age_private_key,
        'gpt_recipient': gpg_recipient
    })
    ctx.util.save_config(config)
    print('backup config saved')
