# Song viewer

App for musicians.
In this application, you can write songs with chords, sheet music, add links to youtube playbacks, present song lyrics for listeners, etc.
You can sync songs and accounts connected to the app through PocketBase.
The application is intended for iOS, Android, MacOS, Windows, Linux and the web.

## Getting Started

### 1. Clone this repository

```bash
git clone <repository-url>
cd songs_viewer_bloc
```

### 2. Install Flutter dependencies

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 3. Set up PocketBase server

See [PocketBase Setup](#pocketbase-setup) below.

### 4. Configure the app

Copy the config template and fill in your PocketBase credentials:

```bash
mkdir -p ~/.songviewer && chmod 700 ~/.songviewer
cp pocketbase_config.example.json ~/.songviewer/pocketbase_config.json
chmod 600 ~/.songviewer/pocketbase_config.json
```

The credentials live **only** in `~/.songviewer/pocketbase_config.json`. That file is
never committed and is deliberately not bundled as an app asset, so no build ships it —
alternatively, leave it out entirely and enter the server and credentials in the app
settings, which writes the same file.

Edit `~/.songviewer/pocketbase_config.json`:

```json
{
  "pocketbaseUrl": "https://your-pocketbase-url.com",
  "email": "your-admin@email.com",
  "password": "your-password"
}
```

Alternatively, you can configure PocketBase connection directly in the app settings (Settings > PocketBase Settings).

### 5. Run the app

```bash
flutter run
```

---

## PocketBase Setup

### Option A: Local development

1. Download PocketBase v0.36+ from [pocketbase.io](https://pocketbase.io/docs/)
2. Run:
   ```bash
   ./pocketbase serve
   ```
3. Open the Admin UI at `http://127.0.0.1:8090/_/`
4. Create an admin account
5. Import collections (see below)

### Option B: Deploy on Coolify (self-hosted)

1. Log in to your Coolify dashboard
2. Create a new **Docker** service
3. Use the official PocketBase Docker image:
   - Image: `ghcr.io/muchobien/pocketbase:latest`
   - Or build from the official Dockerfile
4. Configure the service:
   - **Port mapping**: `8090:8090`
   - **Persistent storage**: Mount a volume to `/pb_data` (e.g., `/data/pocketbase:/pb_data`)
   - This ensures your data survives container restarts
5. Set up a domain/subdomain in Coolify (e.g., `pb.yourdomain.com`)
6. Enable HTTPS (Coolify handles Let's Encrypt automatically)
7. Deploy the service
8. Open `https://pb.yourdomain.com/_/` to access the Admin UI
9. Create the first admin account

### Import Collections

After PocketBase is running:

1. Open the Admin UI (`http://your-pb-url/_/`)
2. Go to **Settings** > **Import collections**
3. Paste the contents of `pocketbase_collections.json` from this repository
4. Click **Review** and then **Confirm and import**

This creates all required collections:
- `songs` — Song data with lyrics, chords, metadata
- `playlists` — Named playlists with song references
- `app_users` — Application users with roles (viewer, editor, admin, superuser)
- `groups` — Song groups/categories
- `realtime_state` — Realtime state sync (current song, QR links)
- `uploads` — File uploads for sheet music (PDF/images)

### Create a PocketBase User

The app authenticates via the PocketBase `users` collection (not `app_users`):

1. In Admin UI, go to **Collections** > **users**
2. Create a new record with email and password
3. Use these credentials in `~/.songviewer/pocketbase_config.json` or in the app settings

---

## Work in progress

## Flutter launcher icons 

run this command to generate icons
```bash
dart pub get
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
dart pub get
dart run flutter_launcher_icons
```



## Screenshots


<div></div>
<img src="screenshots/screenshot_01.png" width="50%" height="50%" />
</div>


<div>
<img src="screenshots/screenshot_02.png" width="50%" height="50%" />
</div>


<div>
<img src="screenshots/screenshot_03.png" width="50%" height="50%" />
</div>


<div>
<img src="screenshots/screenshot_04.png" width="50%" height="50%" />
</div>


<div>
<img src="screenshots/screenshot_05.png" width="50%" height="50%" />
</div>