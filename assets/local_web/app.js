/* Local song viewer served by the Songs Viewer desktop app.
   Data comes from the desktop's own library over HTTP; the currently played
   song arrives over SSE, so the page follows whatever the desktop selects. */

(function () {
    'use strict';

    // -------------------------------------------------------------- notation

    // Czech/German spelling: H is B natural, B is B flat.
    var NOTES_SHARP = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'H'];
    var NOTES_FLAT = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'B', 'H'];
    var NOTE_MAP = {
        C: 0, 'C#': 1, Db: 1,
        D: 2, 'D#': 3, Eb: 3,
        E: 4, Fb: 4,
        F: 5, 'F#': 6, Gb: 6,
        G: 7, 'G#': 8, Ab: 8,
        A: 9, 'A#': 10, B: 10, Bb: 10,
        H: 11, Cb: 11
    };
    var FLAT_KEYS = ['F', 'B', 'Eb', 'Ab', 'Db', 'Gb', 'Dm', 'Gm', 'Cm', 'Fm', 'Bm', 'Ebm'];

    function usesFlats(key) {
        return FLAT_KEYS.indexOf(key) !== -1;
    }

    function transposeChord(chord, semitones, useFlats) {
        if (semitones === 0) return chord;
        var match = /^([A-Ha-h][#b]?)(.*)/.exec(chord);
        if (!match) return chord;
        var index = NOTE_MAP[match[1]];
        if (index === undefined) return chord;
        var next = ((index + semitones) % 12 + 12) % 12;
        return (useFlats ? NOTES_FLAT : NOTES_SHARP)[next] + match[2];
    }

    function transposeKey(key, semitones) {
        return transposeChord(key, semitones, usesFlats(key));
    }

    function transposeContent(content, semitones) {
        if (semitones === 0) return content;
        var first = /\[([A-H][#b]?)/.exec(content);
        var key = first ? first[1] : 'C';
        var useFlats = usesFlats(transposeKey(key, semitones));
        return content.replace(/\[([^\]]+)\]/g, function (_, chord) {
            return '[' + transposeChord(chord, semitones, useFlats) + ']';
        });
    }

    function transposeLabel(semitones) {
        if (semitones === 0) return 'Originál';
        return (semitones > 0 ? '+' : '') + semitones;
    }

    function capoFor(semitones) {
        return ((-semitones % 12) + 12) % 12;
    }

    // ------------------------------------------------------------------ util

    var FONT_SIZES = [
        { label: 'XS', scale: 0.75 },
        { label: 'S', scale: 0.875 },
        { label: 'M', scale: 1 },
        { label: 'L', scale: 1.125 },
        { label: 'XL', scale: 1.25 },
        { label: '2XL', scale: 1.5 },
        { label: '3XL', scale: 1.875 },
        { label: '4XL', scale: 2.25 }
    ];

    function el(tag, className, text) {
        var node = document.createElement(tag);
        if (className) node.className = className;
        if (text !== undefined && text !== null) node.textContent = text;
        return node;
    }

    function clear(node) {
        while (node.firstChild) node.removeChild(node.firstChild);
    }

    function getJson(url) {
        return fetch(url).then(function (res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
        });
    }

    function extension(path) {
        var name = path.split('?')[0];
        var dot = name.lastIndexOf('.');
        return dot === -1 ? '' : name.slice(dot + 1).toLowerCase();
    }

    function youtubeEmbed(url) {
        var match = /(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/))([^&?#]+)/.exec(url);
        return match ? 'https://www.youtube.com/embed/' + match[1] : null;
    }

    // ----------------------------------------------------------------- state

    var state = {
        currentSongId: '',
        songCache: {},
        listCache: null,
        playlistsCache: null,
        chordLibrary: {},
        // Viewer preferences survive a song change: when the desktop moves to
        // the next song mid-service, the reader keeps their font size and
        // chord setting instead of being reset.
        showChords: false,
        semitones: 0,
        fontSizeIdx: 2,
        focusMode: false,
        search: '',
        searchInLyrics: false
    };

    var view = document.getElementById('view');
    var connection = document.getElementById('connection');
    var activePopover = null;

    // -------------------------------------------------------------- diagrams

    var NUM_STRINGS = 6;
    var NUM_FRETS = 5;
    var STRING_SPACING = 16;
    var FRET_SPACING = 20;
    var LEFT_MARGIN = 20;
    var TOP_MARGIN = 24;
    var SVG_NS = 'http://www.w3.org/2000/svg';

    function parsePosition(position) {
        return position.trim().split(/\s+/).map(function (v) {
            return v.toLowerCase() === 'x' ? 'x' : parseInt(v, 10);
        });
    }

    function startFretOf(frets) {
        var numeric = frets.filter(function (f) { return f !== 'x' && f > 0; });
        if (numeric.length === 0) return 0;
        if (Math.max.apply(null, numeric) <= 5) return 0;
        return Math.min.apply(null, numeric) - 1;
    }

    function svgNode(tag, attrs) {
        var node = document.createElementNS(SVG_NS, tag);
        for (var key in attrs) {
            if (Object.prototype.hasOwnProperty.call(attrs, key)) {
                node.setAttribute(key, String(attrs[key]));
            }
        }
        return node;
    }

    function buildDiagram(name, position) {
        var frets = parsePosition(position);
        var startFret = startFretOf(frets);
        var isOpen = startFret === 0;
        var width = LEFT_MARGIN + (NUM_STRINGS - 1) * STRING_SPACING + 16;
        var height = TOP_MARGIN + NUM_FRETS * FRET_SPACING + 10;

        var wrapper = el('div', 'diagram');
        wrapper.appendChild(el('span', 'diagram-name', name));

        var svg = svgNode('svg', { width: width, height: height, viewBox: '0 0 ' + width + ' ' + height });

        if (isOpen) {
            svg.appendChild(svgNode('rect', {
                x: LEFT_MARGIN - 1, y: TOP_MARGIN - 2,
                width: (NUM_STRINGS - 1) * STRING_SPACING + 2, height: 3,
                fill: '#fbbf24', rx: 1
            }));
        } else {
            var fretLabel = svgNode('text', {
                x: LEFT_MARGIN - 14, y: TOP_MARGIN + FRET_SPACING / 2 + 4,
                'font-size': 10, fill: '#a1a1aa', 'text-anchor': 'middle', 'font-family': 'monospace'
            });
            fretLabel.textContent = String(startFret);
            svg.appendChild(fretLabel);
        }

        for (var f = 0; f <= NUM_FRETS; f++) {
            svg.appendChild(svgNode('line', {
                x1: LEFT_MARGIN, y1: TOP_MARGIN + f * FRET_SPACING,
                x2: LEFT_MARGIN + (NUM_STRINGS - 1) * STRING_SPACING, y2: TOP_MARGIN + f * FRET_SPACING,
                stroke: '#52525b', 'stroke-width': (f === 0 && !isOpen) ? 1 : 0.5
            }));
        }

        for (var s = 0; s < NUM_STRINGS; s++) {
            svg.appendChild(svgNode('line', {
                x1: LEFT_MARGIN + s * STRING_SPACING, y1: TOP_MARGIN,
                x2: LEFT_MARGIN + s * STRING_SPACING, y2: TOP_MARGIN + NUM_FRETS * FRET_SPACING,
                stroke: '#71717a', 'stroke-width': 0.8
            }));
        }

        frets.forEach(function (fret, stringIdx) {
            var x = LEFT_MARGIN + stringIdx * STRING_SPACING;
            if (fret === 'x') {
                var muted = svgNode('text', {
                    x: x, y: TOP_MARGIN - 8, 'font-size': 10, fill: '#ef4444',
                    'text-anchor': 'middle', 'font-family': 'sans-serif', 'font-weight': 'bold'
                });
                muted.textContent = '×';
                svg.appendChild(muted);
                return;
            }
            if (fret === 0) {
                svg.appendChild(svgNode('circle', {
                    cx: x, cy: TOP_MARGIN - 10, r: 4, fill: 'none', stroke: '#a1a1aa', 'stroke-width': 1.5
                }));
                return;
            }
            var relative = fret - startFret;
            if (relative < 1 || relative > NUM_FRETS) return;
            svg.appendChild(svgNode('circle', {
                cx: x, cy: TOP_MARGIN + (relative - 0.5) * FRET_SPACING, r: 5.5, fill: '#fbbf24'
            }));
        });

        wrapper.appendChild(svg);
        return wrapper;
    }

    function closePopover() {
        if (!activePopover) return;
        document.body.removeChild(activePopover.node);
        activePopover = null;
    }

    function openPopover(anchor, name, positions) {
        if (activePopover && activePopover.name === name) {
            closePopover();
            return;
        }
        closePopover();

        var index = 0;
        var node = el('div', 'popover');
        var body = el('div');

        function renderDiagram() {
            clear(body);
            body.appendChild(buildDiagram(name, positions[index]));
            if (positions.length > 1) {
                body.appendChild(el('div', 'diagram-count', (index + 1) + '/' + positions.length));
            }
            prev.disabled = index === 0;
            next.disabled = index === positions.length - 1;
        }

        var prev = el('button', 'popover-nav', '‹');
        var next = el('button', 'popover-nav', '›');
        prev.addEventListener('click', function (e) {
            e.stopPropagation();
            if (index > 0) { index--; renderDiagram(); }
        });
        next.addEventListener('click', function (e) {
            e.stopPropagation();
            if (index < positions.length - 1) { index++; renderDiagram(); }
        });

        if (positions.length > 1) node.appendChild(prev);
        node.appendChild(body);
        if (positions.length > 1) node.appendChild(next);
        node.addEventListener('click', function (e) { e.stopPropagation(); });

        document.body.appendChild(node);
        renderDiagram();

        var rect = anchor.getBoundingClientRect();
        var size = node.getBoundingClientRect();
        var left = Math.min(Math.max(8, rect.left), window.innerWidth - size.width - 8);
        var top = rect.bottom + 8;
        if (top + size.height > window.innerHeight - 8) {
            top = Math.max(8, rect.top - size.height - 8);
        }
        node.style.left = left + 'px';
        node.style.top = top + 'px';

        activePopover = { node: node, name: name };
    }

    document.addEventListener('click', closePopover);
    document.addEventListener('keydown', function (e) {
        if (e.key !== 'Escape') return;
        if (activePopover) { closePopover(); return; }
        if (state.focusMode) { state.focusMode = false; render(); }
    });

    // ------------------------------------------------------------ song lines

    var CHORD_WIDTH_RATIO = 0.85;
    var MIN_GAP = 0.5;

    function buildChordLine(line, chordMap) {
        var wrapper = el('span', 'chord-line');
        var regex = /\[([^\]]+)\]([^[]*)/g;
        var segments = [];
        var firstChord = line.indexOf('[');
        if (firstChord > 0) segments.push({ chord: '', text: line.substring(0, firstChord) });

        var match;
        while ((match = regex.exec(line)) !== null) {
            segments.push({ chord: match[1], text: match[2] });
        }
        if (segments.length === 0) {
            wrapper.appendChild(el('span', 'lyrics', line));
            return wrapper;
        }

        var chords = [];
        var textPos = 0;
        segments.forEach(function (segment) {
            if (segment.chord) {
                var pos = textPos;
                if (chords.length > 0) {
                    var last = chords[chords.length - 1];
                    var minStart = last.position + last.chord.length * CHORD_WIDTH_RATIO + MIN_GAP;
                    if (pos < minStart) pos = minStart;
                }
                chords.push({ chord: segment.chord, position: pos });
            }
            textPos += segment.text.length;
        });

        chords.forEach(function (item) {
            var positions = chordMap ? chordMap[item.chord] : null;
            var hasDiagram = !!(positions && positions.length);

            // The offset is in `ch` of the lyric line, so it must be set on a
            // node that still has the lyric font size. The chord's own smaller
            // font lives on the inner span, or every chord would drift left.
            var slot = el('span', 'chord-slot');
            slot.style.left = item.position + 'ch';

            var node = el('span', hasDiagram ? 'chord has-diagram' : 'chord', item.chord);
            if (hasDiagram) {
                node.addEventListener('click', function (e) {
                    e.stopPropagation();
                    openPopover(node, item.chord, positions);
                });
            }

            slot.appendChild(node);
            wrapper.appendChild(slot);
        });

        wrapper.appendChild(el('span', 'lyrics', segments.map(function (s) { return s.text; }).join('')));
        return wrapper;
    }

    function buildSongContent(content, chordMap) {
        var container = el('div', 'song-content');
        content.split('\n').forEach(function (raw) {
            var line = raw.trim();
            if (line === '') {
                container.appendChild(el('div', 'song-blank'));
                return;
            }
            if (line.indexOf('# ') === 0) {
                var section = el('div', 'song-section');
                section.appendChild(el('span', null, line.substring(2)));
                container.appendChild(section);
                return;
            }
            if (line.indexOf('[') !== -1) {
                var withChords = el('div', 'song-line has-chords');
                withChords.appendChild(buildChordLine(line, chordMap));
                container.appendChild(withChords);
                return;
            }
            container.appendChild(el('div', 'song-line', line));
        });
        return container;
    }

    // ---------------------------------------------------------------- viewer

    function hasChords(content) {
        return /\[[A-H]/.test(content);
    }

    function displayContent(song) {
        var content = song.content;
        if (hasChords(content) && state.showChords) {
            content = transposeContent(content, state.semitones);
        }
        if (!state.showChords) {
            content = content.replace(/\[([^\]]*)\]/g, '');
        }
        return content;
    }

    /// The library merged with the song's own overrides.
    ///
    /// Lookups happen by the *displayed* chord name, which is why the whole
    /// library is needed: transposing a song asks for grips it never contained.
    function activeChordMap(song) {
        if (!state.showChords) return null;
        var map = {};
        var name;
        for (name in state.chordLibrary) {
            if (Object.prototype.hasOwnProperty.call(state.chordLibrary, name)) {
                map[name] = state.chordLibrary[name];
            }
        }
        for (name in song.chordOverrides || {}) {
            if (Object.prototype.hasOwnProperty.call(song.chordOverrides, name)) {
                map[name] = song.chordOverrides[name];
            }
        }
        return map;
    }

    function buildControls(song, compact) {
        if (!hasChords(song.content)) return null;

        var controls = el('div', compact ? 'controls is-compact' : 'controls');

        var toggle = el('button', state.showChords ? 'toggle-chords is-on' : 'toggle-chords',
            state.showChords ? '🎸 Bez akordů' : '🎸 Akordy');
        toggle.addEventListener('click', function () {
            state.showChords = !state.showChords;
            render();
        });
        controls.appendChild(toggle);

        if (!state.showChords) return controls;

        var transpose = el('div', 'transpose');
        var down = el('button', 'step', '−');
        down.title = 'Snížit o půltón';
        down.addEventListener('click', function () { state.semitones -= 1; render(); });

        var value = el('span', 'transpose-value', transposeLabel(state.semitones));

        var up = el('button', 'step', '+');
        up.title = 'Zvýšit o půltón';
        up.addEventListener('click', function () { state.semitones += 1; render(); });

        transpose.appendChild(down);
        transpose.appendChild(value);
        transpose.appendChild(up);

        if (state.semitones !== 0) {
            var reset = el('button', 'reset', 'Reset');
            reset.addEventListener('click', function () { state.semitones = 0; render(); });
            transpose.appendChild(reset);
        }
        controls.appendChild(transpose);

        var capo = capoFor(state.semitones);
        var capoBox = el('div', 'capo');
        capoBox.appendChild(el('span', 'capo-label', 'Kapo:'));
        capoBox.appendChild(el('span', capo === 0 ? 'capo-value' : 'capo-value is-set', String(capo)));
        controls.appendChild(capoBox);

        return controls;
    }

    function buildFontSize() {
        var box = el('div', 'font-size');

        var smaller = el('button', 'font-step', 'A−');
        smaller.title = 'Zmenšit písmo';
        smaller.disabled = state.fontSizeIdx === 0;
        smaller.addEventListener('click', function () {
            state.fontSizeIdx = Math.max(0, state.fontSizeIdx - 1);
            render();
        });

        var label = el('span', 'font-value', FONT_SIZES[state.fontSizeIdx].label);

        var bigger = el('button', 'font-step', 'A+');
        bigger.title = 'Zvětšit písmo';
        bigger.disabled = state.fontSizeIdx === FONT_SIZES.length - 1;
        bigger.addEventListener('click', function () {
            state.fontSizeIdx = Math.min(FONT_SIZES.length - 1, state.fontSizeIdx + 1);
            render();
        });

        box.appendChild(smaller);
        box.appendChild(label);
        box.appendChild(bigger);
        return box;
    }

    function songFontSize() {
        return (FONT_SIZES[state.fontSizeIdx].scale * 16) + 'px';
    }

    function buildAttachmentCard(title, files, imagesInline) {
        if (!files || files.length === 0) return null;
        var card = el('div', 'card');
        card.appendChild(el('h3', 'card-title', title));
        var row = el('div', imagesInline ? null : 'chip-row');

        files.forEach(function (file, i) {
            var ext = extension(file);
            var isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp'].indexOf(ext) !== -1;

            if (isImage && imagesInline) {
                var link = el('a');
                link.href = file;
                link.target = '_blank';
                link.rel = 'noopener noreferrer';
                var img = el('img');
                img.src = file;
                img.alt = files.length > 1 ? 'Noty – strana ' + (i + 1) : 'Noty';
                img.loading = 'lazy';
                img.style.width = '100%';
                img.style.borderRadius = '0.5rem';
                link.appendChild(img);
                row.appendChild(link);
                return;
            }

            var isPdf = ext === 'pdf';
            var chip = el('a', 'chip');
            chip.href = file;
            chip.target = '_blank';
            chip.rel = 'noopener noreferrer';
            chip.appendChild(el('span', null, isPdf ? '📄' : isImage ? '🎼' : '📁'));
            chip.appendChild(el('span', 'chip-label',
                (isPdf ? 'PDF' : isImage ? 'Noty' : 'Příloha') + (files.length > 1 ? ' ' + (i + 1) : '')));
            row.appendChild(chip);
        });

        card.appendChild(row);
        return card;
    }

    function buildNotesCard(notes) {
        if (!notes || notes.length === 0) return null;
        var card = el('div', 'card');
        card.appendChild(el('h3', 'card-title', '🎵 Poznámky k provedení'));
        var list = el('ul', 'note-list');
        notes.forEach(function (note) {
            var item = el('li');
            item.appendChild(el('span', 'note-index', note.index > 0 ? 'ř.' + note.index : ''));
            item.appendChild(el('span', null, note.noteText));
            list.appendChild(item);
        });
        card.appendChild(list);
        return card;
    }

    function buildVideosCard(videos) {
        if (!videos || videos.length === 0) return null;
        var card = el('div', 'card');
        card.appendChild(el('h3', 'card-title', '🎬 Videa'));
        videos.forEach(function (video, i) {
            var box = el('div', 'video');
            if (video.name) box.appendChild(el('p', 'song-card-author', video.name));
            var embed = youtubeEmbed(video.path);
            if (embed) {
                var frame = el('div', 'video-frame');
                var iframe = el('iframe');
                iframe.src = embed;
                iframe.title = video.name || 'Video ' + (i + 1);
                iframe.allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
                iframe.allowFullscreen = true;
                frame.appendChild(iframe);
                box.appendChild(frame);
            } else {
                var link = el('a', 'link-amber', '🎬 ' + (video.name || 'Otevřít video') + ' →');
                link.href = video.path;
                link.target = '_blank';
                link.rel = 'noopener noreferrer';
                box.appendChild(link);
            }
            card.appendChild(box);
        });
        return card;
    }

    function buildViewer(song) {
        var chordMap = activeChordMap(song);

        if (state.focusMode) {
            var overlay = el('div', 'focus');

            var bar = el('div', 'focus-bar');
            var back = el('button', 'focus-back', '← Zpět');
            back.addEventListener('click', function () { state.focusMode = false; render(); });
            bar.appendChild(back);
            bar.appendChild(el('span', 'focus-title', song.title));
            bar.appendChild(buildFontSize());
            overlay.appendChild(bar);

            var focusControls = buildControls(song, true);
            if (focusControls) {
                var wrap = el('div', 'focus-controls');
                wrap.appendChild(focusControls);
                overlay.appendChild(wrap);
            }

            var body = el('div', 'focus-body');
            body.style.setProperty('--song-size', songFontSize());
            body.appendChild(buildSongContent(displayContent(song), chordMap));
            overlay.appendChild(body);
            return overlay;
        }

        var viewer = el('div', 'viewer');

        var row = el('div', 'controls-row');
        var controls = buildControls(song, false);
        if (controls) {
            var grow = el('div', 'controls-grow');
            grow.appendChild(controls);
            row.appendChild(grow);
        }
        row.appendChild(buildFontSize());

        var fullscreen = el('button', 'fullscreen-button', '📖 Celá obrazovka');
        fullscreen.title = 'Zobrazit pouze text';
        fullscreen.addEventListener('click', function () { state.focusMode = true; render(); });
        row.appendChild(fullscreen);
        viewer.appendChild(row);

        var sheet = el('div', 'sheet');
        sheet.style.setProperty('--song-size', songFontSize());
        sheet.appendChild(buildSongContent(displayContent(song), chordMap));
        viewer.appendChild(sheet);

        var attachments = buildAttachmentCard('📎 Přílohy', song.sheets, false);
        if (attachments) viewer.appendChild(attachments);

        var notes = buildNotesCard(song.performanceNotes);
        if (notes) viewer.appendChild(notes);

        var videos = buildVideosCard(song.youtubeVideos);
        if (videos) viewer.appendChild(videos);

        return viewer;
    }

    function buildSongHeader(song, live) {
        var header = el('div');

        if (live) {
            var indicator = el('div', 'live');
            indicator.appendChild(el('span', 'live-dot'));
            indicator.appendChild(el('span', 'live-label', 'Právě hrajeme'));
            header.appendChild(indicator);
        }

        var block = el('div', 'song-header');
        block.appendChild(el('h1', 'song-title', song.title));

        var meta = el('div', 'song-meta');
        if (song.interpret) meta.appendChild(el('span', null, song.interpret));
        if (song.indexSongBook) meta.appendChild(el('span', 'song-index', '#' + song.indexSongBook));
        block.appendChild(meta);

        var tags = (song.tags || []).filter(function (t) { return t && t !== 'web'; });
        if (tags.length) {
            var tagRow = el('div', 'tags');
            tags.forEach(function (tag) { tagRow.appendChild(el('span', 'tag', '#' + tag)); });
            block.appendChild(tagRow);
        }

        header.appendChild(block);
        return header;
    }

    // ----------------------------------------------------------------- pages

    function renderNowPlaying() {
        if (!state.currentSongId) {
            var empty = el('div', 'empty');
            empty.appendChild(el('span', 'empty-icon', '🎵'));
            empty.appendChild(el('h1', null, 'Právě se nic nepřehrává'));
            empty.appendChild(el('p', null, 'Až začne hrát píseň, zobrazí se zde automaticky.'));
            var browse = el('a', 'button-primary', 'Procházet písně →');
            browse.href = '#/pisne';
            empty.appendChild(browse);
            view.appendChild(empty);
            return;
        }

        withSong(state.currentSongId, function (song) {
            if (state.focusMode) {
                view.appendChild(buildViewer(song));
                return;
            }
            var page = el('div', 'page');
            page.appendChild(buildSongHeader(song, true));
            page.appendChild(buildViewer(song));
            view.appendChild(page);
        });
    }

    function renderSongDetail(songId) {
        withSong(songId, function (song) {
            if (state.focusMode) {
                view.appendChild(buildViewer(song));
                return;
            }
            var page = el('div', 'page');
            var back = el('a', 'back-link', '← Zpět na písně');
            back.href = '#/pisne';
            page.appendChild(back);
            page.appendChild(buildSongHeader(song, song.id === state.currentSongId));
            page.appendChild(buildViewer(song));
            view.appendChild(page);
        });
    }

    function renderSongList() {
        var page = el('div', 'page page-wide');
        page.appendChild(el('h1', 'page-heading', 'Písně'));

        var input = el('input', 'search-input');
        input.type = 'search';
        input.placeholder = 'Hledat píseň, autora…';
        input.value = state.search;

        var option = el('label', 'search-option');
        var checkbox = el('input');
        checkbox.type = 'checkbox';
        checkbox.checked = state.searchInLyrics;
        option.appendChild(checkbox);
        option.appendChild(el('span', null, 'Hledat i v textech písní'));

        var results = el('div');

        function renderResults(songs) {
            clear(results);
            var query = state.search.trim().toLowerCase();
            var filtered = songs.filter(function (song) {
                if (!query) return true;
                if (song.title.toLowerCase().indexOf(query) !== -1) return true;
                if ((song.interpret || '').toLowerCase().indexOf(query) !== -1) return true;
                if ((song.tags || []).some(function (t) { return t.toLowerCase().indexOf(query) !== -1; })) return true;
                if (state.searchInLyrics) {
                    return (song.lyricsPlain || '').toLowerCase().indexOf(query) !== -1;
                }
                return false;
            });

            if (filtered.length === 0) {
                results.appendChild(el('p', 'muted', 'Žádné písně neodpovídají vyhledávání.'));
                return;
            }

            var grid = el('div', 'grid');
            filtered.forEach(function (song) { grid.appendChild(buildSongCard(song)); });
            results.appendChild(grid);
        }

        input.addEventListener('input', function () {
            state.search = input.value;
            if (state.listCache) renderResults(state.listCache);
        });
        checkbox.addEventListener('change', function () {
            state.searchInLyrics = checkbox.checked;
            if (state.listCache) renderResults(state.listCache);
        });

        page.appendChild(input);
        page.appendChild(option);
        page.appendChild(results);
        view.appendChild(page);

        if (state.listCache) {
            renderResults(state.listCache);
            return;
        }
        results.appendChild(el('p', 'muted', 'Načítám…'));
        getJson('/api/songs').then(function (songs) {
            state.listCache = songs;
            renderResults(songs);
        }).catch(function () {
            clear(results);
            results.appendChild(el('p', 'muted', 'Nepodařilo se načíst seznam písní.'));
        });
    }

    function buildSongCard(song) {
        var isCurrent = song.id === state.currentSongId;
        var card = el('a', isCurrent ? 'song-card is-current' : 'song-card');
        card.href = '#/pisne/' + encodeURIComponent(song.id);

        var head = el('div', 'song-card-head');
        head.appendChild(el('h2', 'song-card-title', song.title));
        var icons = el('div', 'song-card-icons');
        if (song.hasVideos) icons.appendChild(el('span', null, '🎬'));
        if (song.hasSheets) icons.appendChild(el('span', null, '🎼'));
        head.appendChild(icons);
        card.appendChild(head);

        if (song.interpret) card.appendChild(el('p', 'song-card-author', song.interpret));

        var badges = el('div', 'badge-row');
        (song.groups || []).filter(function (g) { return g && g !== 'web'; }).forEach(function (group) {
            badges.appendChild(el('span', 'badge', group));
        });
        if (song.indexSongBook) badges.appendChild(el('span', 'badge badge-amber', '#' + song.indexSongBook));
        if (isCurrent) badges.appendChild(el('span', 'badge badge-green', '▶ hraje'));
        card.appendChild(badges);

        return card;
    }

    function renderPlaylists() {
        var page = el('div', 'page page-wide');
        page.appendChild(el('h1', 'page-heading', 'Playlisty'));
        var results = el('div');
        page.appendChild(results);
        view.appendChild(page);

        function renderResults(playlists) {
            clear(results);
            if (playlists.length === 0) {
                results.appendChild(el('p', 'muted', 'Zatím tu nejsou žádné playlisty.'));
                return;
            }
            var grid = el('div', 'grid');
            playlists.forEach(function (playlist) {
                var card = el('a', 'song-card');
                card.href = '#/playlisty/' + encodeURIComponent(playlist.id);
                card.appendChild(el('h2', 'song-card-title', playlist.name));
                card.appendChild(el('p', 'song-card-author', playlist.songCount + ' ' + pluralSongs(playlist.songCount)));
                grid.appendChild(card);
            });
            results.appendChild(grid);
        }

        if (state.playlistsCache) {
            renderResults(state.playlistsCache);
            return;
        }
        results.appendChild(el('p', 'muted', 'Načítám…'));
        getJson('/api/playlists').then(function (playlists) {
            state.playlistsCache = playlists;
            renderResults(playlists);
        }).catch(function () {
            clear(results);
            results.appendChild(el('p', 'muted', 'Nepodařilo se načíst playlisty.'));
        });
    }

    function pluralSongs(count) {
        if (count === 1) return 'píseň';
        if (count >= 2 && count <= 4) return 'písně';
        return 'písní';
    }

    function renderPlaylistDetail(playlistId) {
        var page = el('div', 'page');
        var back = el('a', 'back-link', '← Zpět na playlisty');
        back.href = '#/playlisty';
        page.appendChild(back);
        var body = el('div');
        page.appendChild(body);
        view.appendChild(page);

        body.appendChild(el('p', 'muted', 'Načítám…'));
        getJson('/api/playlist/' + encodeURIComponent(playlistId)).then(function (playlist) {
            clear(body);
            body.appendChild(el('h1', 'page-heading', playlist.name));
            if (playlist.songs.length === 0) {
                body.appendChild(el('p', 'muted', 'Playlist je prázdný.'));
                return;
            }
            var list = el('ul', 'playlist-songs');
            playlist.songs.forEach(function (song, i) {
                var isCurrent = song.id === state.currentSongId;
                var item = el('li');
                var link = el('a', isCurrent ? 'playlist-song is-current' : 'playlist-song');
                link.href = '#/pisne/' + encodeURIComponent(song.id);
                link.appendChild(el('span', 'playlist-song-index', String(i + 1) + '.'));
                link.appendChild(el('span', 'playlist-song-title', song.title));
                if (isCurrent) {
                    var badge = el('span', 'badge badge-green', '▶ hraje');
                    badge.style.marginLeft = 'auto';
                    link.appendChild(badge);
                }
                item.appendChild(link);
                list.appendChild(item);
            });
            body.appendChild(list);
        }).catch(function () {
            clear(body);
            body.appendChild(el('p', 'muted', 'Playlist se nepodařilo načíst.'));
        });
    }

    function withSong(songId, build) {
        var cached = state.songCache[songId];
        if (cached) {
            build(cached);
            return;
        }
        var loading = el('div', 'empty');
        loading.appendChild(el('span', 'empty-icon', '🎵'));
        loading.appendChild(el('h1', null, 'Načítám…'));
        view.appendChild(loading);

        getJson('/api/song/' + encodeURIComponent(songId)).then(function (song) {
            state.songCache[songId] = song;
            render();
        }).catch(function () {
            clear(view);
            var error = el('div', 'empty');
            error.appendChild(el('span', 'empty-icon', '⚠️'));
            error.appendChild(el('h1', null, 'Píseň se nepodařilo načíst'));
            view.appendChild(error);
        });
    }

    // ---------------------------------------------------------------- router

    function currentRoute() {
        var hash = window.location.hash.replace(/^#/, '');
        var parts = hash.split('/').filter(Boolean);
        if (parts.length === 0) return { name: 'now' };
        if (parts[0] === 'pisne') {
            return parts.length > 1
                ? { name: 'song', id: decodeURIComponent(parts[1]) }
                : { name: 'songs' };
        }
        if (parts[0] === 'playlisty') {
            return parts.length > 1
                ? { name: 'playlist', id: decodeURIComponent(parts[1]) }
                : { name: 'playlists' };
        }
        return { name: 'now' };
    }

    function markNav(route) {
        var active = route.name === 'now' ? 'now'
            : (route.name === 'songs' || route.name === 'song') ? 'songs'
                : 'playlists';
        var links = document.querySelectorAll('[data-nav]');
        for (var i = 0; i < links.length; i++) {
            links[i].classList.toggle('is-active', links[i].getAttribute('data-nav') === active);
        }
    }

    function render() {
        closePopover();
        var route = currentRoute();
        markNav(route);
        document.body.classList.toggle('is-focus', state.focusMode);
        clear(view);

        switch (route.name) {
            case 'songs': renderSongList(); break;
            case 'song': renderSongDetail(route.id); break;
            case 'playlists': renderPlaylists(); break;
            case 'playlist': renderPlaylistDetail(route.id); break;
            default: renderNowPlaying();
        }
    }

    window.addEventListener('hashchange', function () {
        state.focusMode = false;
        render();
    });

    // ------------------------------------------------------------------- sse

    function setConnection(text, cls) {
        connection.textContent = text;
        connection.className = 'connection' + (cls ? ' ' + cls : '');
    }

    function onCurrentSong(songId) {
        var changed = songId !== state.currentSongId;
        state.currentSongId = songId;
        if (!changed) return;
        // A new song starts in its own key; the reader's own preferences stay.
        state.semitones = 0;
        render();
    }

    function connect() {
        var source = new EventSource('/events');

        source.addEventListener('open', function () {
            setConnection('Živě připojeno', 'is-live');
        });

        source.addEventListener('currentSong', function (e) {
            setConnection('Živě připojeno', 'is-live');
            try {
                onCurrentSong(JSON.parse(e.data).songId || '');
            } catch (err) {
                /* malformed frame — keep the last known song */
            }
        });

        source.addEventListener('error', function () {
            setConnection('Spojení přerušeno – obnovuji…', 'is-lost');
        });
    }

    // The first paint must not wait for the SSE handshake, otherwise a slow
    // Wi-Fi shows an empty page for a second after the QR code is scanned.
    getJson('/api/current-song')
        .then(function (data) { state.currentSongId = data.songId || ''; })
        .catch(function () { /* the SSE stream sends the same value */ })
        .then(function () {
            render();
            connect();
        });

    // Diagrams are an enhancement, so the page never waits for them; when they
    // land, only a song already on screen needs repainting.
    getJson('/api/chord-diagrams')
        .then(function (library) {
            state.chordLibrary = library || {};
            if (state.showChords) render();
        })
        .catch(function () { /* chord names stay plain text */ });
})();
